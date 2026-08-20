const crypto = require('crypto');
const { v4: uuidv4 } = require('uuid');
const ConsultationBooking = require('./models/ConsultationBooking');
const MockPayment = require('./models/MockPayment');
const { findNurseById } = require('./nurseRepositories');
const { appendStatusHistory } = require('./bookingLifecycleHelpers');
const { notifyPatient, createAndPushNotification } = require('./notificationRepositories');
const {
  formatNurseBookingResponse,
  expirePendingNurseBookings,
  isPaymentPendingStatus,
  remainingPaymentSeconds,
} = require('./nurseBookingRepositories');
const { STATUS } = require('./nurseBookingStatus');

function generateMockTransactionId() {
  return `MOCK_${crypto.randomBytes(8).toString('hex')}`;
}

function assertPatientOwnsBooking(booking, auth) {
  if (auth?.type !== 'patient' || !auth.patientId) {
    const err = new Error('Patient authentication required');
    err.statusCode = 401;
    throw err;
  }
  if (!booking.patientId || booking.patientId !== auth.patientId) {
    const err = new Error('You do not own this booking');
    err.statusCode = 403;
    throw err;
  }
}

async function processMockPayment({ bookingId, result, amount, auth }) {
  const outcome = String(result || '').trim().toUpperCase();
  if (outcome !== 'SUCCESS' && outcome !== 'FAILED') {
    const err = new Error('result must be SUCCESS or FAILED');
    err.statusCode = 400;
    throw err;
  }
  if (!bookingId) {
    const err = new Error('bookingId is required');
    err.statusCode = 400;
    throw err;
  }

  const booking = await ConsultationBooking.findOne({ id: bookingId });
  if (!booking) {
    const err = new Error('Booking not found');
    err.statusCode = 404;
    throw err;
  }

  const isNurseBooking =
    booking.providerType === 'nurse' ||
    (Boolean(booking.nurseId) && !booking.doctorId);
  if (!isNurseBooking) {
    const err = new Error('Mock payment is only available for nurse bookings');
    err.statusCode = 400;
    throw err;
  }

  assertPatientOwnsBooking(booking, auth);

  if (booking.nurseId) {
    await expirePendingNurseBookings(booking.nurseId);
  }
  const fresh = await ConsultationBooking.findOne({ id: bookingId });
  if (!fresh) {
    const err = new Error('Booking not found');
    err.statusCode = 404;
    throw err;
  }

  if (fresh.status === STATUS.CONFIRMED && fresh.paymentStatus === 'paid') {
    const existing = await MockPayment.findOne({
      bookingId,
      status: 'SUCCESS',
    }).sort({ createdAt: -1 });
    const nurse = await findNurseById(fresh.nurseId);
    return {
      alreadyConfirmed: true,
      payment: existing ? existing.toObject() : null,
      booking: formatNurseBookingResponse(fresh, nurse),
    };
  }

  if (!isPaymentPendingStatus(fresh.status)) {
    const err = new Error('This booking is not awaiting payment');
    err.statusCode = 409;
    throw err;
  }

  const now = new Date();
  if (fresh.paymentExpiresAt && new Date(fresh.paymentExpiresAt) <= now) {
    fresh.status = STATUS.PAYMENT_EXPIRED;
    fresh.paymentStatus = 'expired';
    fresh.cancelledAt = now;
    fresh.cancelledBy = 'system';
    appendStatusHistory(fresh, STATUS.PAYMENT_EXPIRED, 'system');
    await fresh.save();
    try {
      await notifyPatient(fresh, {
        title: 'Payment window expired',
        body: 'Your booking expired because payment was not completed within 10 minutes.',
        type: 'payment_expired',
      });
    } catch (err) {
      console.error('[MockPayment] expire notify failed:', err.message);
    }
    const err = new Error('Payment window expired. Please book again.');
    err.statusCode = 410;
    throw err;
  }

  const expectedAmount = Number(fresh.consultationFee || 0);
  if (amount != null && amount !== '') {
    const provided = Number(amount);
    if (!Number.isFinite(provided) || Math.abs(provided - expectedAmount) > 0.009) {
      const err = new Error('Amount does not match the booking fee');
      err.statusCode = 400;
      throw err;
    }
  }

  if (outcome === 'FAILED') {
    fresh.paymentStatus = 'failed';
    await fresh.save();
    const payment = await MockPayment.create({
      id: uuidv4(),
      bookingId: fresh.id,
      userId: auth.patientId,
      amount: expectedAmount,
      paymentMethod: 'MOCK',
      transactionId: generateMockTransactionId(),
      status: 'FAILED',
    });
    try {
      await notifyPatient(fresh, {
        title: 'Payment failed',
        body: `Payment failed. You can try again before the 10-minute payment window expires. ${remainingPaymentSeconds(fresh)} seconds remaining.`,
        type: 'payment_failed',
      });
    } catch (err) {
      console.error('[MockPayment] fail notify failed:', err.message);
    }
    const { emitBookingStatusUpdate } = require('../services/trackingSocket');
    emitBookingStatusUpdate(fresh);
    const nurse = await findNurseById(fresh.nurseId);
    return {
      alreadyConfirmed: false,
      payment: payment.toObject(),
      booking: formatNurseBookingResponse(fresh, nurse),
    };
  }

  const transactionId = generateMockTransactionId();
  const updated = await ConsultationBooking.findOneAndUpdate(
    {
      id: bookingId,
      status: { $in: ['payment_pending', 'approved_pending_payment'] },
      paymentExpiresAt: { $gt: now },
    },
    {
      $set: {
        status: STATUS.CONFIRMED,
        paymentStatus: 'paid',
        paymentProvider: 'mock',
        paymentMethod: 'MOCK',
        mockTransactionId: transactionId,
        amountPaid: expectedAmount,
        paidAt: now,
      },
    },
    { new: true },
  );

  if (!updated) {
    const latest = await ConsultationBooking.findOne({ id: bookingId });
    if (latest?.status === STATUS.CONFIRMED && latest.paymentStatus === 'paid') {
      const existing = await MockPayment.findOne({
        bookingId,
        status: 'SUCCESS',
      }).sort({ createdAt: -1 });
      const nurse = await findNurseById(latest.nurseId);
      return {
        alreadyConfirmed: true,
        payment: existing ? existing.toObject() : null,
        booking: formatNurseBookingResponse(latest, nurse),
      };
    }
    const err = new Error('Could not confirm payment. Please try again.');
    err.statusCode = 409;
    throw err;
  }

  appendStatusHistory(updated, STATUS.CONFIRMED, 'patient');
  await updated.save();

  const payment = await MockPayment.create({
    id: uuidv4(),
    bookingId: updated.id,
    userId: auth.patientId,
    amount: expectedAmount,
    paymentMethod: 'MOCK',
    transactionId,
    status: 'SUCCESS',
  });

  try {
    await notifyPatient(updated, {
      title: 'Booking confirmed',
      body: 'Your nurse booking is confirmed.',
      type: 'booking_confirmed',
    });
    if (updated.nurseId) {
      await createAndPushNotification({
        userId: updated.nurseId,
        userType: 'nurse',
        title: 'Booking confirmed',
        body: 'A new nurse booking has been confirmed.',
        type: 'booking_confirmed',
        data: { bookingId: updated.id },
      });
    }
  } catch (err) {
    console.error('[MockPayment] confirm notify failed:', err.message);
  }

  try {
    const { emitBookingStatusUpdate } = require('../services/trackingSocket');
    emitBookingStatusUpdate(updated);
  } catch (err) {
    console.warn('[MockPayment] status emit failed:', err.message);
  }

  const nurse = await findNurseById(updated.nurseId);
  return {
    alreadyConfirmed: false,
    payment: payment.toObject(),
    booking: formatNurseBookingResponse(updated, nurse),
  };
}

module.exports = {
  processMockPayment,
};
