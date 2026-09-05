const AmbulanceBooking = require('./models/AmbulanceBooking');
const { toAmbulanceBooking } = require('./ambulanceMappers');
const {
  createOrder: createRazorpayOrder,
  verifyPaymentSignature,
  createRefund,
  isMockMode,
} = require('../services/razorpayService');
const { writeAmbulanceAudit } = require('./ambulanceAuditRepositories');
const { emitAmbulanceEvent } = require('../services/ambulanceRealtime');
const { notifyAmbulanceStatus } = require('../services/ambulanceNotificationService');

const PAYMENT_HOLD_MINUTES = Number(process.env.PAYMENT_HOLD_MINUTES || 15);

function fail(message, statusCode = 400) {
  const err = new Error(message);
  err.statusCode = statusCode;
  throw err;
}

async function createAmbulancePaymentOrder(bookingId, patientId) {
  const booking = await AmbulanceBooking.findOne({ id: bookingId });
  if (!booking) fail('Booking not found', 404);
  if (patientId && booking.patientId && booking.patientId !== patientId) {
    fail('Not authorized for this booking', 403);
  }
  if (booking.paymentStatus === 'paid' || booking.paymentStatus === 'cash') {
    fail('This booking is already paid');
  }
  if (booking.paymentMethod === 'cash') {
    fail('This booking is set for cash payment');
  }
  const amount = Number(booking.fare?.total || 0);
  const amountInPaise = Math.round(amount * 100);
  if (amountInPaise < 100) fail('Fare must be at least ₹1 before payment');

  const razorpayOrder = await createRazorpayOrder({
    amountInPaise,
    receipt: booking.id.slice(0, 40),
    notes: { ambulanceBookingId: booking.id, type: 'ambulance_trip' },
  });

  booking.razorpayOrderId = razorpayOrder.id;
  booking.paymentStatus = 'pending';
  booking.paymentExpiresAt = new Date(Date.now() + PAYMENT_HOLD_MINUTES * 60 * 1000);
  await booking.save();

  return {
    booking: toAmbulanceBooking(booking),
    razorpayOrder,
    amountInPaise,
    keyId: isMockMode() ? null : process.env.RAZORPAY_KEY_ID,
    mock: isMockMode(),
    prefill: {
      name: booking.patientName,
      email: booking.patientEmail || undefined,
      contact: booking.patientMobile,
    },
  };
}

async function confirmAmbulancePayment({
  bookingId,
  razorpayOrderId,
  razorpayPaymentId,
  razorpaySignature,
  actor,
}) {
  const booking = await AmbulanceBooking.findOne({ id: bookingId });
  if (!booking) fail('Booking not found', 404);
  if (booking.paymentStatus === 'paid') return toAmbulanceBooking(booking);

  if (!isMockMode()) {
    const valid = verifyPaymentSignature({
      orderId: razorpayOrderId,
      paymentId: razorpayPaymentId,
      signature: razorpaySignature,
    });
    if (!valid) fail('Payment verification failed');
  }

  if (booking.razorpayOrderId && booking.razorpayOrderId !== razorpayOrderId) {
    fail('Payment order mismatch');
  }

  booking.razorpayOrderId = razorpayOrderId;
  booking.razorpayPaymentId = razorpayPaymentId;
  booking.paymentStatus = 'paid';
  await booking.save();

  const publicBooking = toAmbulanceBooking(booking);
  emitAmbulanceEvent('ambulance_payment_updated', {
    bookingId,
    patientId: booking.patientId,
    ambulanceId: booking.ambulanceId,
    paymentStatus: 'paid',
  });
  notifyAmbulanceStatus(publicBooking, {
    patientBody: 'Ambulance payment successful.',
    patientType: 'prescription_paid',
    providerTitle: 'Payment received',
  }).catch(() => {});
  await writeAmbulanceAudit({
    actorId: actor?.actorId,
    actorRole: actor?.actorRole,
    action: 'payment_confirmed',
    entityType: 'AmbulanceBooking',
    entityId: bookingId,
    ambulanceId: booking.ambulanceId,
  });
  return publicBooking;
}

async function markCashPayment(bookingId, ambulanceId, actor) {
  const booking = await AmbulanceBooking.findOneAndUpdate(
    {
      id: bookingId,
      ambulanceId,
      paymentStatus: { $in: ['unpaid', 'pending', 'failed'] },
    },
    { $set: { paymentStatus: 'cash', paymentMethod: 'cash' } },
    { new: true },
  );
  if (!booking) fail('Unable to mark cash payment', 409);
  emitAmbulanceEvent('ambulance_payment_updated', {
    bookingId,
    patientId: booking.patientId,
    ambulanceId,
    paymentStatus: 'cash',
  });
  await writeAmbulanceAudit({
    actorId: actor?.actorId,
    actorRole: actor?.actorRole,
    action: 'payment_confirmed',
    entityType: 'AmbulanceBooking',
    entityId: bookingId,
    ambulanceId,
    newValue: { method: 'cash' },
  });
  return toAmbulanceBooking(booking);
}

async function refundAmbulancePayment(bookingId, actor) {
  const booking = await AmbulanceBooking.findOne({ id: bookingId });
  if (!booking) fail('Booking not found', 404);
  if (booking.paymentStatus !== 'paid') fail('Only paid bookings can be refunded');
  const amountInPaise = Math.round(Number(booking.fare?.total || 0) * 100);
  if (booking.razorpayPaymentId && !isMockMode()) {
    await createRefund({
      paymentId: booking.razorpayPaymentId,
      amountInPaise,
    });
  }
  booking.paymentStatus = 'refunded';
  booking.refundAmount = Number(booking.fare?.total || 0);
  await booking.save();
  emitAmbulanceEvent('ambulance_payment_updated', {
    bookingId,
    patientId: booking.patientId,
    ambulanceId: booking.ambulanceId,
    paymentStatus: 'refunded',
  });
  return toAmbulanceBooking(booking);
}

module.exports = {
  createAmbulancePaymentOrder,
  confirmAmbulancePayment,
  markCashPayment,
  refundAmbulancePayment,
};
