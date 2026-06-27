const express = require('express');
const { sendSuccess, sendError } = require('../utils/response');
const { authOptional } = require('../middleware/auth');
const {
  createPendingBookingForPayment,
  confirmBookingAfterPayment,
  createPaymentOrderForBooking,
} = require('../db/bookingRepositories');
const {
  createOrder,
  verifyPaymentSignature,
  isMockMode,
} = require('../services/razorpayService');

const router = express.Router();

const PAYMENT_HOLD_MINUTES = parseInt(process.env.PAYMENT_HOLD_MINUTES || '15', 10);

// POST /payments/create-order — reserve slot and create Razorpay order
router.post('/create-order', authOptional, async (req, res) => {
  try {
    const body = req.body || {};
    const {
      bookingId,
      doctorId,
      consultationType = 'online_consult',
      patientName,
      patientMobile,
      patientEmail,
      patientNotes,
      patientAddress,
      patientCity,
      patientState,
      patientPincode,
      visitReason,
      dayOfWeek,
      startHour,
      slotStart,
    } = body;

    let booking;
    let doctorName;

    if (bookingId) {
      const result = await createPaymentOrderForBooking(bookingId);
      booking = result.booking;
      doctorName = result.doctorName;
    } else {
      if (!doctorId) {
        return sendError(res, 'doctorId is required', 400);
      }

      const patientId =
        req.auth?.type === 'patient' ? req.auth.patientId : undefined;

      const result = await createPendingBookingForPayment(
        {
          doctorId,
          patientId,
          consultationType,
          patientName,
          patientMobile,
          patientEmail,
          patientNotes,
          patientAddress,
          patientCity,
          patientState,
          patientPincode,
          visitReason,
          dayOfWeek,
          startHour,
          slotStart,
        },
        PAYMENT_HOLD_MINUTES,
      );
      booking = result.booking;
      doctorName = result.doctorName;
    }

    const amountInPaise = Math.round((booking.consultationFee || 0) * 100);
    if (amountInPaise < 100) {
      return sendError(res, 'Consultation fee must be at least ₹1', 400);
    }

    const order = await createOrder({
      amountInPaise,
      receipt: booking.id.slice(0, 40),
      notes: {
        bookingId: booking.id,
        doctorId: booking.doctorId,
        consultationType: booking.consultationType,
      },
    });

    booking.razorpayOrderId = order.id;
    await booking.save();

    return sendSuccess(res, {
      statusCode: 201,
      data: {
        bookingId: booking.id,
        orderId: order.id,
        amount: amountInPaise,
        amountInRupees: booking.consultationFee,
        currency: 'INR',
        keyId: isMockMode() ? null : process.env.RAZORPAY_KEY_ID,
        doctorName,
        consultationType: booking.consultationType,
        consultationFee: booking.consultationFee,
        paymentExpiresAt: booking.paymentExpiresAt,
        mock: isMockMode(),
        prefill: {
          name: booking.patientName,
          email: booking.patientEmail || undefined,
          contact: booking.patientMobile,
        },
      },
    });
  } catch (err) {
    console.error(err);
    const status = err.statusCode || 500;
    return sendError(res, err.message || 'Could not create payment order', status);
  }
});

// POST /payments/verify — confirm booking after successful payment
router.post('/verify', authOptional, async (req, res) => {
  try {
    const {
      bookingId,
      razorpayOrderId,
      razorpayPaymentId,
      razorpaySignature,
    } = req.body || {};

    if (!bookingId) {
      return sendError(res, 'bookingId is required', 400);
    }

    if (!isMockMode()) {
      if (!razorpayOrderId || !razorpayPaymentId || !razorpaySignature) {
        return sendError(res, 'Payment details are required', 400);
      }
      const valid = verifyPaymentSignature({
        orderId: razorpayOrderId,
        paymentId: razorpayPaymentId,
        signature: razorpaySignature,
      });
      if (!valid) {
        return sendError(res, 'Payment verification failed', 400);
      }
    } else if (!razorpayOrderId || !razorpayPaymentId) {
      return sendError(res, 'Payment details are required', 400);
    }

    const data = await confirmBookingAfterPayment({
      bookingId,
      razorpayOrderId,
      razorpayPaymentId,
      razorpaySignature,
    });

    return res.status(200).json({
      success: true,
      message: 'Payment successful. Booking confirmed.',
      statusCode: 200,
      data,
    });
  } catch (err) {
    console.error(err);
    const status = err.statusCode || 500;
    return sendError(res, err.message || 'Payment verification failed', status);
  }
});

module.exports = router;
