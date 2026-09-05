const { v4: uuidv4 } = require('uuid');
const BloodOrder = require('./models/BloodOrder');
const BloodBank = require('./models/BloodBank');
const { toBloodOrder } = require('./bloodBankModuleMappers');
const {
  reserveInventory,
  fulfillReservedUnits,
  releaseReservedUnits,
} = require('./bloodInventoryRepositories');
const {
  reserveUnitsAtomically,
  releaseReservation,
  fulfillReservation,
  findActiveReservation,
} = require('./bloodReservationRepositories');
const { appendStatusHistory, listStatusHistory, writeAudit } = require('./bloodAuditRepositories');
const { emitBloodEvent } = require('../services/bloodRealtime');
const { actorFromAuth } = require('../middleware/bloodBankAuth');
const {
  createOrder: createRazorpayOrder,
  verifyPaymentSignature,
  isMockMode,
} = require('../services/razorpayService');
const {
  notifyBloodOrderPlaced,
  notifyBloodOrderStatusChange,
} = require('../services/bloodBankNotificationService');

const PAYMENT_HOLD_MINUTES = parseInt(process.env.PAYMENT_HOLD_MINUTES || '15', 10);

async function findOrderById(id) {
  const doc = await BloodOrder.findOne({ id });
  return toBloodOrder(doc);
}

async function findOrderDocById(id) {
  return BloodOrder.findOne({ id });
}

async function listOrdersByBloodBank(bloodBankId, { status, page = 1, pageSize = 20 } = {}) {
  const filter = { bloodBankId };
  if (status) filter.status = status;

  const totalCount = await BloodOrder.countDocuments(filter);
  const totalPages = Math.max(1, Math.ceil(totalCount / pageSize));
  const skip = (page - 1) * pageSize;

  const docs = await BloodOrder.find(filter)
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(pageSize);

  return {
    orders: docs.map(toBloodOrder),
    pagination: {
      currentPage: page,
      totalPages,
      pageSize,
      totalCount,
      hasNextPage: page < totalPages,
    },
  };
}

async function listOrdersByPatient(patientId, { page = 1, pageSize = 20 } = {}) {
  const filter = { patientId };
  const totalCount = await BloodOrder.countDocuments(filter);
  const totalPages = Math.max(1, Math.ceil(totalCount / pageSize));
  const skip = (page - 1) * pageSize;

  const docs = await BloodOrder.find(filter)
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(pageSize);

  return {
    orders: docs.map(toBloodOrder),
    pagination: {
      currentPage: page,
      totalPages,
      pageSize,
      totalCount,
      hasNextPage: page < totalPages,
    },
  };
}

function calculatePricing(bank, componentType, units, couponCode) {
  const component = (bank.bloodComponents || []).find(
    (c) => c.componentId === componentType && c.enabled !== false,
  );
  const unitPrice = component?.discountPriceInr ?? component?.priceInr ?? 0;
  const baseAmount = unitPrice * units;
  let discountAmount = 0;

  const activeOffer = (bank.offers || []).find((o) => {
    if (!o.offerAvailable || !o.active) return false;
    const now = new Date();
    if (o.validFrom && now < new Date(o.validFrom)) return false;
    if (o.validTill && now > new Date(o.validTill)) return false;
    if (o.minimumOrderAmount && baseAmount < o.minimumOrderAmount) return false;
    return true;
  });

  if (activeOffer) {
    if (activeOffer.discountType === 'percentage' && activeOffer.discountValue) {
      discountAmount = Math.round((baseAmount * activeOffer.discountValue) / 100);
    } else if (activeOffer.discountType === 'flat' && activeOffer.discountValue) {
      discountAmount = activeOffer.discountValue;
    }
  }

  return {
    baseAmount,
    discountAmount,
    totalAmount: Math.max(0, baseAmount - discountAmount),
    couponCode: couponCode || null,
  };
}

async function createBloodOrder(data) {
  const bankDoc = await BloodBank.findOne({ id: data.bloodBankId });
  if (!bankDoc || bankDoc.verificationStatus !== 'verified' || bankDoc.isSuspended) {
    const err = new Error('Blood bank not available');
    err.statusCode = 400;
    throw err;
  }

  const bank = bankDoc.toObject();
  const pricing = calculatePricing(bank, data.componentType, data.units, data.couponCode);
  const paymentMethod = data.paymentMethod || 'online';
  const isCash = paymentMethod === 'cash';

  if (!Number(data.units) || Number(data.units) < 1) {
    const err = new Error('Units must be greater than zero');
    err.statusCode = 400;
    throw err;
  }

  if (isCash) {
    await reserveInventory(data.bloodBankId, data.bloodGroup, data.units);
  }

  const initialStatus = data.isEmergency ? 'blood_bank_notified' : 'pending';
  const order = await BloodOrder.create({
    id: data.id || uuidv4(),
    bloodBankId: data.bloodBankId,
    patientId: data.patientId,
    patientName: data.patientName,
    patientMobile: data.patientMobile,
    patientEmail: data.patientEmail,
    patientAge: data.patientAge,
    patientGender: data.patientGender,
    hospitalName: data.hospitalName,
    hospitalAddress: data.hospitalAddress,
    doctorName: data.doctorName,
    doctorContact: data.doctorContact,
    requiredDate: data.requiredDate,
    requiredTime: data.requiredTime,
    requestType: data.requestType || (data.isEmergency ? 'emergency' : 'normal'),
    bloodGroup: data.bloodGroup,
    componentType: data.componentType,
    units: data.units,
    prescriptionUrl: data.prescriptionUrl,
    deliveryMethod: data.deliveryMethod || 'self_pickup',
    deliveryAddress: data.deliveryAddress,
    deliveryDate: data.deliveryDate,
    deliveryTimeSlot: data.deliveryTimeSlot,
    couponCode: pricing.couponCode,
    discountAmount: pricing.discountAmount,
    baseAmount: pricing.baseAmount,
    totalAmount: pricing.totalAmount,
    paymentMethod,
    paymentStatus: isCash ? 'pending' : 'awaiting_payment',
    status: initialStatus,
    isEmergency: Boolean(data.isEmergency),
    notes: data.notes,
    deliveryContact: data.deliveryContact,
    deliveryStatus:
      data.deliveryMethod && data.deliveryMethod !== 'self_pickup'
        ? 'pending'
        : 'not_applicable',
    estimatedDeliveryTime: data.estimatedDeliveryTime,
    paymentExpiresAt: isCash
      ? null
      : new Date(Date.now() + PAYMENT_HOLD_MINUTES * 60 * 1000),
  });

  const publicOrder = toBloodOrder(order);
  await appendStatusHistory({
    requestId: publicOrder.id,
    requestKind: 'order',
    toStatus: initialStatus,
    actorId: data.patientId || 'patient',
    actorRole: 'patient',
    note: 'Request created',
  });
  emitBloodEvent('blood_request_created', {
    patientId: publicOrder.patientId,
    bloodBankId: publicOrder.bloodBankId,
    requestId: publicOrder.id,
    orderId: publicOrder.id,
    isEmergency: publicOrder.isEmergency,
  });

  if (isCash) {
    notifyBloodOrderPlaced(publicOrder).catch((err) =>
      console.error('[blood-order] notify placed failed:', err.message),
    );
  }

  return publicOrder;
}

async function createPaymentOrderForBloodOrder(orderId) {
  const order = await findOrderDocById(orderId);
  if (!order) {
    const err = new Error('Order not found');
    err.statusCode = 404;
    throw err;
  }

  if (order.paymentMethod !== 'online') {
    const err = new Error('This order does not require online payment');
    err.statusCode = 400;
    throw err;
  }

  if (order.paymentStatus === 'paid') {
    const err = new Error('Order is already paid');
    err.statusCode = 400;
    throw err;
  }

  if (order.paymentExpiresAt && new Date() > order.paymentExpiresAt) {
    const err = new Error('Payment window expired. Please place a new order.');
    err.statusCode = 400;
    throw err;
  }

  const bank = await BloodBank.findOne({ id: order.bloodBankId });
  const amountInPaise = Math.round((order.totalAmount || 0) * 100);
  if (amountInPaise < 100) {
    const err = new Error('Order amount must be at least ₹1');
    err.statusCode = 400;
    throw err;
  }

  const razorpayOrder = await createRazorpayOrder({
    amountInPaise,
    receipt: order.id.slice(0, 40),
    notes: {
      bloodOrderId: order.id,
      bloodBankId: order.bloodBankId,
      type: 'blood_order',
    },
  });

  order.razorpayOrderId = razorpayOrder.id;
  if (!order.paymentExpiresAt) {
    order.paymentExpiresAt = new Date(Date.now() + PAYMENT_HOLD_MINUTES * 60 * 1000);
  }
  await order.save();

  return {
    order: toBloodOrder(order),
    bloodBankName: bank?.institutionName || 'Blood bank',
    razorpayOrder,
    amountInPaise,
    keyId: isMockMode() ? null : process.env.RAZORPAY_KEY_ID,
    mock: isMockMode(),
    prefill: {
      name: order.patientName,
      email: order.patientEmail || undefined,
      contact: order.patientMobile,
    },
  };
}

async function confirmBloodOrderAfterPayment({
  orderId,
  razorpayOrderId,
  razorpayPaymentId,
  razorpaySignature,
}) {
  const order = await findOrderDocById(orderId);
  if (!order) {
    const err = new Error('Order not found');
    err.statusCode = 404;
    throw err;
  }

  if (order.paymentStatus === 'paid') {
    return toBloodOrder(order);
  }

  if (!isMockMode()) {
    const valid = verifyPaymentSignature({
      orderId: razorpayOrderId,
      paymentId: razorpayPaymentId,
      signature: razorpaySignature,
    });
    if (!valid) {
      const err = new Error('Payment verification failed');
      err.statusCode = 400;
      throw err;
    }
  }

  if (order.razorpayOrderId && order.razorpayOrderId !== razorpayOrderId) {
    const err = new Error('Payment order mismatch');
    err.statusCode = 400;
    throw err;
  }

  await reserveInventory(order.bloodBankId, order.bloodGroup, order.units);

  order.razorpayOrderId = razorpayOrderId;
  order.razorpayPaymentId = razorpayPaymentId;
  order.paymentStatus = 'paid';
  order.status = 'pending';
  await order.save();

  const publicOrder = toBloodOrder(order);
  notifyBloodOrderPlaced(publicOrder).catch((err) =>
    console.error('[blood-order] notify after payment failed:', err.message),
  );

  return publicOrder;
}

const TERMINAL_STATUSES = new Set(['rejected', 'cancelled', 'expired', 'completed', 'delivered']);
const ACCEPT_ONCE = new Set(['accepted', 'blood_reserved', 'ready_for_collection', 'blood_ready']);

async function updateOrderStatus(orderId, status, extra = {}, auth = {}) {
  const order = await BloodOrder.findOne({ id: orderId });
  if (!order) return null;
  const actor = actorFromAuth(auth);

  if (TERMINAL_STATUSES.has(order.status) && order.status !== status) {
    const err = new Error('Request expired or already closed');
    err.statusCode = 400;
    throw err;
  }

  if (status === 'accepted' && ACCEPT_ONCE.has(order.status)) {
    const err = new Error('This request was already accepted');
    err.statusCode = 409;
    throw err;
  }

  const updates = { status, ...extra };
  const fromStatus = order.status;

  if (status === 'accepted') {
    updates.estimatedDeliveryTime =
      extra.estimatedDeliveryTime || new Date(Date.now() + 2 * 60 * 60 * 1000);
    updates.chatEnabled = true;
    if (!order.reservationId) {
      try {
        const reservation = await reserveUnitsAtomically({
          bloodBankId: order.bloodBankId,
          bloodGroup: order.bloodGroup,
          componentType: order.componentType,
          units: order.units,
          requestId: order.id,
          actorId: actor.actorId,
          actorRole: actor.actorRole,
        });
        updates.reservationId = reservation.id;
        updates.reservationExpiresAt = reservation.expiresAt;
        updates.status = 'blood_reserved';
      } catch (err) {
        if (err.statusCode === 409 || /Insufficient/i.test(err.message)) {
          const mapped = new Error('Insufficient units');
          mapped.statusCode = 409;
          throw mapped;
        }
        throw err;
      }
    }
  }

  if (status === 'blood_reserved' && !order.reservationId) {
    const reservation = await reserveUnitsAtomically({
      bloodBankId: order.bloodBankId,
      bloodGroup: order.bloodGroup,
      componentType: order.componentType,
      units: order.units,
      requestId: order.id,
      actorId: actor.actorId,
      actorRole: actor.actorRole,
    });
    updates.reservationId = reservation.id;
    updates.reservationExpiresAt = reservation.expiresAt;
  }

  if (status === 'rejected' || status === 'cancelled' || status === 'expired') {
    if (order.reservationId) {
      await releaseReservation(order.reservationId, actor);
    } else if (order.paymentStatus === 'paid' || order.paymentMethod === 'cash') {
      await releaseReservedUnits(order.bloodBankId, order.bloodGroup, order.units);
    }
  }

  if (['ready_for_collection', 'blood_ready'].includes(status)) {
    updates.chatEnabled = true;
  }

  if (['collected', 'delivered', 'completed'].includes(status)) {
    if (order.reservationId) {
      await fulfillReservation(order.reservationId, actor);
    } else {
      await fulfillReservedUnits(order.bloodBankId, order.bloodGroup, order.units);
    }
    updates.paymentStatus =
      order.paymentMethod === 'cash' && order.paymentStatus !== 'paid'
        ? 'collected'
        : 'paid';
    if (status === 'collected') updates.status = 'completed';
    if (status === 'delivered') updates.status = 'completed';
  }

  await BloodOrder.updateOne({ id: orderId }, { $set: updates });
  const updated = await findOrderById(orderId);

  await appendStatusHistory({
    requestId: orderId,
    requestKind: 'order',
    fromStatus,
    toStatus: updated.status,
    actorId: actor.actorId,
    actorRole: actor.actorRole,
    note: extra.rejectionReason || extra.notes,
    metadata: { rejectionReasonCode: extra.rejectionReasonCode },
  });
  await writeAudit({
    ...actor,
    action: `blood_request_${updated.status}`,
    entityType: 'BloodOrder',
    entityId: orderId,
    bloodBankId: order.bloodBankId,
    previousValue: { status: fromStatus },
    newValue: { status: updated.status },
  });

  const eventMap = {
    accepted: 'blood_request_accepted',
    blood_reserved: 'blood_reserved',
    rejected: 'blood_request_rejected',
    ready_for_collection: 'blood_ready',
    blood_ready: 'blood_ready',
    collected: 'blood_collected',
    delivered: 'blood_request_completed',
    completed: 'blood_request_completed',
    cancelled: 'blood_request_cancelled',
    expired: 'blood_request_cancelled',
  };
  emitBloodEvent(eventMap[updated.status] || 'blood_request_updated', {
    patientId: updated.patientId,
    bloodBankId: updated.bloodBankId,
    requestId: updated.id,
    orderId: updated.id,
    status: updated.status,
  });

  notifyBloodOrderStatusChange(updated, updated.status).catch((err) =>
    console.error('[blood-order] status notify failed:', err.message),
  );

  return updated;
}

async function cancelBloodOrder(orderId, patientId, reason) {
  const order = await BloodOrder.findOne({ id: orderId });
  if (!order) return null;
  if (patientId && order.patientId && order.patientId !== patientId) {
    const err = new Error('Unauthorized access');
    err.statusCode = 403;
    throw err;
  }
  return updateOrderStatus(orderId, 'cancelled', { rejectionReason: reason }, {
    type: 'patient',
    patientId,
  });
}

async function getOrderWithHistory(orderId) {
  const order = await findOrderById(orderId);
  if (!order) return null;
  const history = await listStatusHistory(orderId);
  const reservation = order.reservationId
    ? await findActiveReservation(orderId)
    : null;
  return { ...order, statusHistory: history, reservation };
}

async function listAllOrders({ status, page = 1, pageSize = 20 } = {}) {
  const filter = {};
  if (status) filter.status = status;

  const totalCount = await BloodOrder.countDocuments(filter);
  const totalPages = Math.max(1, Math.ceil(totalCount / pageSize));
  const skip = (page - 1) * pageSize;

  const docs = await BloodOrder.find(filter)
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(pageSize);

  return {
    orders: docs.map(toBloodOrder),
    pagination: {
      currentPage: page,
      totalPages,
      pageSize,
      totalCount,
      hasNextPage: page < totalPages,
    },
  };
}

module.exports = {
  findOrderById,
  listOrdersByBloodBank,
  listOrdersByPatient,
  createBloodOrder,
  createPaymentOrderForBloodOrder,
  confirmBloodOrderAfterPayment,
  updateOrderStatus,
  cancelBloodOrder,
  getOrderWithHistory,
  listAllOrders,
  calculatePricing,
};
