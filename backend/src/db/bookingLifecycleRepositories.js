const ConsultationBooking = require('./models/ConsultationBooking');
const {
  appendStatusHistory,
  buildVisitTimeline,
} = require('./bookingLifecycleHelpers');
const { createAndPushNotification } = require('./notificationRepositories');
const { formatSlotLabel } = require('../utils/slotDateTime');

const CANCEL_FREE_HOURS = Number(process.env.CANCEL_FREE_HOURS || 2);
const NO_SHOW_FEE_PERCENT = Number(process.env.NO_SHOW_FEE_PERCENT || 50);

function hoursUntilSlot(slotStart) {
  return (new Date(slotStart).getTime() - Date.now()) / (1000 * 60 * 60);
}

function getCancellationPolicy(booking) {
  const hoursLeft = hoursUntilSlot(booking.slotStart);
  const isPaid =
    booking.paymentStatus === 'paid' && Number(booking.amountPaid || 0) > 0;
  const canCancel = [
    'awaiting_doctor_approval',
    'approved_pending_payment',
    'pending',
    'confirmed',
  ].includes(booking.status);

  let refundEligible = false;
  let refundPercent = 0;
  let message = '';

  if (!canCancel) {
    message = 'This booking can no longer be cancelled.';
  } else if (!isPaid) {
    refundEligible = false;
    refundPercent = 0;
    message = 'You can cancel free of charge (no payment collected).';
  } else if (hoursLeft >= CANCEL_FREE_HOURS) {
    refundEligible = true;
    refundPercent = 100;
    message = `Full refund if cancelled at least ${CANCEL_FREE_HOURS} hours before the visit.`;
  } else if (hoursLeft > 0) {
    refundEligible = true;
    refundPercent = 100 - NO_SHOW_FEE_PERCENT;
    message = `Within ${CANCEL_FREE_HOURS} hours: ${NO_SHOW_FEE_PERCENT}% fee applies (${refundPercent}% refund).`;
  } else {
    refundEligible = false;
    refundPercent = 0;
    message = 'Visit time has passed. Cancellation may be treated as a no-show.';
  }

  return {
    canCancel,
    hoursLeft: Math.round(hoursLeft * 10) / 10,
    cancelFreeHours: CANCEL_FREE_HOURS,
    noShowFeePercent: NO_SHOW_FEE_PERCENT,
    refundEligible,
    refundPercent,
    message,
  };
}

async function assertBookingActor(booking, auth) {
  const isPatient =
    auth?.type === 'patient' && auth.patientId === booking.patientId;
  const isDoctor =
    auth?.type === 'doctor' &&
    booking.doctorId &&
    auth.doctorId === booking.doctorId;
  const isNurse =
    auth?.type === 'nurse' &&
    booking.nurseId &&
    auth.nurseId === booking.nurseId;
  if (!isPatient && !isDoctor && !isNurse) {
    const err = new Error('Not allowed for this booking');
    err.statusCode = 403;
    throw err;
  }
  return { isPatient, isDoctor, isNurse };
}

async function cancelBooking(bookingId, auth, reason) {
  const booking = await ConsultationBooking.findOne({ id: bookingId });
  if (!booking) {
    const err = new Error('Booking not found');
    err.statusCode = 404;
    throw err;
  }

  const { isPatient, isDoctor, isNurse } = await assertBookingActor(booking, auth);
  const policy = getCancellationPolicy(booking);
  if (!policy.canCancel) {
    const err = new Error(policy.message);
    err.statusCode = 409;
    throw err;
  }

  const actor = isPatient ? 'patient' : isDoctor ? 'doctor' : 'nurse';
  const wasPaid = booking.paymentStatus === 'paid';
  let refundResult = null;

  booking.status = 'cancelled';
  booking.cancelledAt = new Date();
  booking.cancelledBy = actor;
  booking.cancellationReason = String(reason || '').trim() || undefined;
  booking.refundEligible = wasPaid && policy.refundEligible;
  booking.refundPercent = wasPaid ? policy.refundPercent : 0;

  if (wasPaid && policy.refundEligible && policy.refundPercent > 0) {
    const paidAmount = Number(booking.amountPaid || booking.consultationFee || 0);
    const refundRupees = Math.round((paidAmount * policy.refundPercent) / 100);
    const amountInPaise = refundRupees * 100;

    if (booking.razorpayPaymentId && amountInPaise > 0) {
      try {
        const { createRefund } = require('../services/razorpayService');
        refundResult = await createRefund({
          paymentId: booking.razorpayPaymentId,
          amountInPaise:
            policy.refundPercent >= 100 ? undefined : amountInPaise,
          notes: {
            bookingId: booking.id,
            cancelledBy: actor,
            refundPercent: String(policy.refundPercent),
          },
        });
        booking.razorpayRefundId = refundResult.id;
        booking.refundedAt = new Date();
        booking.paymentStatus = 'refunded';
      } catch (refundErr) {
        console.error('[Cancel] Razorpay refund failed:', refundErr.message);
        const err = new Error(
          `Cancellation saved but refund failed: ${refundErr.message}`,
        );
        err.statusCode = 502;
        // Still cancel the booking; mark refund pending via eligible flag
        booking.paymentStatus = 'paid';
        booking.refundEligible = true;
        appendStatusHistory(booking, 'cancelled', actor);
        appendStatusHistory(booking, 'refund_failed', 'system');
        await booking.save();
        throw err;
      }
    } else {
      // Mock / no payment id — ledger refund
      booking.paymentStatus = 'refunded';
      booking.refundedAt = new Date();
    }
  } else if (!wasPaid) {
    booking.paymentStatus = 'failed';
  }

  appendStatusHistory(booking, 'cancelled', actor);
  await booking.save();

  // Notify counterpart
  try {
    if (isPatient) {
      if (booking.doctorId) {
        await createAndPushNotification({
          userId: booking.doctorId,
          userType: 'doctor',
          title: 'Booking cancelled',
          body: `${booking.patientName} cancelled their appointment.`,
          type: 'booking_cancelled',
          data: { bookingId },
        });
      } else if (booking.nurseId) {
        await createAndPushNotification({
          userId: booking.nurseId,
          userType: 'nurse',
          title: 'Booking cancelled',
          body: `${booking.patientName} cancelled their visit.`,
          type: 'booking_cancelled',
          data: { bookingId },
        });
      }
    } else if (booking.patientId) {
      await createAndPushNotification({
        userId: booking.patientId,
        userType: 'patient',
        title: 'Booking cancelled',
        body: 'Your appointment was cancelled by the provider.',
        type: 'booking_cancelled',
        data: { bookingId },
      });
    }
  } catch (err) {
    console.error('[Cancel] notify failed:', err.message);
  }

  return {
    booking: booking.toObject(),
    policy,
    timeline: buildVisitTimeline(booking),
    refund: refundResult
      ? {
          id: refundResult.id,
          amount: refundResult.amount ?? null,
          status: refundResult.status || 'processed',
          mock: Boolean(refundResult.mock),
        }
      : null,
  };
}

async function rescheduleBooking(bookingId, auth, { slotStart, slotEnd, dayOfWeek, startHour }) {
  const booking = await ConsultationBooking.findOne({ id: bookingId });
  if (!booking) {
    const err = new Error('Booking not found');
    err.statusCode = 404;
    throw err;
  }

  const { isPatient } = await assertBookingActor(booking, auth);
  if (!isPatient) {
    const err = new Error('Only the patient can reschedule');
    err.statusCode = 403;
    throw err;
  }

  if (!['confirmed', 'pending', 'approved_pending_payment'].includes(booking.status)) {
    const err = new Error('This booking cannot be rescheduled');
    err.statusCode = 409;
    throw err;
  }

  if (hoursUntilSlot(booking.slotStart) < CANCEL_FREE_HOURS) {
    const err = new Error(
      `Reschedule only allowed at least ${CANCEL_FREE_HOURS} hours before the visit`,
    );
    err.statusCode = 400;
    throw err;
  }

  const newStart = new Date(slotStart);
  const newEnd = new Date(slotEnd || new Date(newStart.getTime() + 60 * 60 * 1000));
  if (Number.isNaN(newStart.getTime()) || Number.isNaN(newEnd.getTime())) {
    const err = new Error('Invalid slot times');
    err.statusCode = 400;
    throw err;
  }
  if (newStart <= new Date()) {
    const err = new Error('New slot must be in the future');
    err.statusCode = 400;
    throw err;
  }

  // Conflict check
  const providerFilter = booking.doctorId
    ? { doctorId: booking.doctorId }
    : { nurseId: booking.nurseId };
  const conflict = await ConsultationBooking.findOne({
    ...providerFilter,
    id: { $ne: booking.id },
    slotStart: newStart,
    status: {
      $in: [
        'confirmed',
        'pending',
        'held',
        'awaiting_doctor_approval',
        'approved_pending_payment',
      ],
    },
  }).lean();
  if (conflict) {
    const err = new Error('That slot is no longer available');
    err.statusCode = 409;
    throw err;
  }

  booking.slotStart = newStart;
  booking.slotEnd = newEnd;
  if (dayOfWeek != null) booking.dayOfWeek = Number(dayOfWeek);
  if (startHour != null) booking.startHour = Number(startHour);
  booking.reminderSentAt = null;
  appendStatusHistory(booking, 'rescheduled', 'patient');
  await booking.save();

  try {
    const providerId = booking.doctorId || booking.nurseId;
    const userType = booking.doctorId ? 'doctor' : 'nurse';
    if (providerId) {
      await createAndPushNotification({
        userId: providerId,
        userType,
        title: 'Visit rescheduled',
        body: `${booking.patientName} moved the visit to ${formatSlotLabel(newStart, newEnd)}.`,
        type: 'booking_rescheduled',
        data: { bookingId },
      });
    }
  } catch (err) {
    console.error('[Reschedule] notify failed:', err.message);
  }

  return {
    booking: booking.toObject(),
    timeline: buildVisitTimeline(booking),
  };
}

async function updateVisitProgress(bookingId, auth, progress) {
  const allowed = ['en_route', 'arrived', 'completed'];
  if (!allowed.includes(progress)) {
    const err = new Error('Invalid visit progress');
    err.statusCode = 400;
    throw err;
  }

  const booking = await ConsultationBooking.findOne({ id: bookingId });
  if (!booking) {
    const err = new Error('Booking not found');
    err.statusCode = 404;
    throw err;
  }

  const { isDoctor, isNurse } = await assertBookingActor(booking, auth);
  if (!isDoctor && !isNurse) {
    const err = new Error('Only the provider can update visit progress');
    err.statusCode = 403;
    throw err;
  }
  if (booking.status !== 'confirmed') {
    const err = new Error('Visit must be confirmed');
    err.statusCode = 409;
    throw err;
  }
  if (booking.consultationType !== 'book_home') {
    const err = new Error('Visit progress applies to home visits only');
    err.statusCode = 400;
    throw err;
  }

  booking.visitProgress = progress;
  appendStatusHistory(booking, progress, isDoctor ? 'doctor' : 'nurse');
  await booking.save();

  if (booking.patientId && progress === 'en_route') {
    try {
      await createAndPushNotification({
        userId: booking.patientId,
        userType: 'patient',
        title: isNurse ? 'Nurse on the way' : 'Doctor on the way',
        body: 'Your home visit provider is on the way.',
        type: 'en_route',
        data: { bookingId },
      });
    } catch (err) {
      console.error('[VisitProgress] notify failed:', err.message);
    }
  }

  return {
    booking: booking.toObject(),
    timeline: buildVisitTimeline(booking),
  };
}

async function getBookingTimeline(bookingId, auth) {
  const booking = await ConsultationBooking.findOne({ id: bookingId }).lean();
  if (!booking) {
    const err = new Error('Booking not found');
    err.statusCode = 404;
    throw err;
  }
  await assertBookingActor(booking, auth);
  return {
    bookingId: booking.id,
    status: booking.status,
    paymentStatus: booking.paymentStatus,
    visitProgress: booking.visitProgress || null,
    policy: getCancellationPolicy(booking),
    timeline: buildVisitTimeline(booking),
  };
}

async function markNoShow(bookingId, auth) {
  const booking = await ConsultationBooking.findOne({ id: bookingId });
  if (!booking) {
    const err = new Error('Booking not found');
    err.statusCode = 404;
    throw err;
  }
  const { isDoctor, isNurse } = await assertBookingActor(booking, auth);
  if (!isDoctor && !isNurse) {
    const err = new Error('Only the provider can mark a no-show');
    err.statusCode = 403;
    throw err;
  }
  if (booking.status !== 'confirmed') {
    const err = new Error('Only confirmed visits can be marked no-show');
    err.statusCode = 409;
    throw err;
  }
  if (new Date(booking.slotEnd) > new Date()) {
    const err = new Error('Cannot mark no-show before the visit ends');
    err.statusCode = 400;
    throw err;
  }

  booking.noShowMarkedAt = new Date();
  booking.noShowFeePercent = NO_SHOW_FEE_PERCENT;
  appendStatusHistory(booking, 'no_show', isDoctor ? 'doctor' : 'nurse');
  await booking.save();

  return booking.toObject();
}

module.exports = {
  getCancellationPolicy,
  cancelBooking,
  rescheduleBooking,
  updateVisitProgress,
  getBookingTimeline,
  markNoShow,
  CANCEL_FREE_HOURS,
  NO_SHOW_FEE_PERCENT,
};
