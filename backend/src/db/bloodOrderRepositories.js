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

  if (isCash) {
    await reserveInventory(data.bloodBankId, data.bloodGroup, data.units);
  }

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
    status: 'pending',
    isEmergency: Boolean(data.isEmergency),
    notes: data.notes,
    estimatedDeliveryTime: data.estimatedDeliveryTime,
    paymentExpiresAt: isCash
      ? null
      : new Date(Date.now() + PAYMENT_HOLD_MINUTES * 60 * 1000),
  });

  const publicOrder = toBloodOrder(order);

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

async function updateOrderStatus(orderId, status, extra = {}) {
  const order = await BloodOrder.findOne({ id: orderId });
  if (!order) return null;

  const updates = { status, ...extra };

  if (status === 'accepted') {
    updates.estimatedDeliveryTime =
      extra.estimatedDeliveryTime || new Date(Date.now() + 2 * 60 * 60 * 1000);
  }

  if (status === 'rejected') {
    if (order.paymentStatus === 'paid' || order.paymentMethod === 'cash') {
      await releaseReservedUnits(order.bloodBankId, order.bloodGroup, order.units);
    }
  }

  if (status === 'delivered') {
    await fulfillReservedUnits(order.bloodBankId, order.bloodGroup, order.units);
    updates.paymentStatus =
      order.paymentMethod === 'cash' && order.paymentStatus !== 'paid'
        ? 'collected'
        : 'paid';
  }

  await BloodOrder.updateOne({ id: orderId }, { $set: updates });
  const updated = await findOrderById(orderId);

  notifyBloodOrderStatusChange(updated, status).catch((err) =>
    console.error('[blood-order] status notify failed:', err.message),
  );

  return updated;
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
  listAllOrders,
  calculatePricing,
};
