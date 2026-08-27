const ConsultationBooking = require('../db/models/ConsultationBooking');
const { slotDateTime, slotEndFromStart } = require('./slotDateTime');

const OPEN_RESERVATION_STATUSES = [
  'held',
  'pending',
  'awaiting_doctor_approval',
  'pending_nurse_approval',
  'approved_pending_payment',
  'payment_pending',
];

/** Cancel holds/pending bookings for a slot so it cannot be completed after SELF_BUSY/DISCARDED. */
async function cancelOpenReservationsForSlot({
  doctorId,
  nurseId,
  consultationType,
  weekStartDate,
  dayOfWeek,
  startHour,
  startMinute = 0,
}) {
  if (!consultationType || weekStartDate == null) return 0;
  if (!Number.isInteger(dayOfWeek) || !Number.isInteger(startHour)) return 0;

  const slotStart = slotDateTime(
    weekStartDate,
    dayOfWeek,
    startHour,
    startMinute,
  );
  const slotEnd = slotEndFromStart(slotStart, consultationType);

  const filter = {
    consultationType,
    status: { $in: OPEN_RESERVATION_STATUSES },
    slotStart: { $lt: slotEnd },
    slotEnd: { $gt: slotStart },
  };
  if (doctorId) filter.doctorId = doctorId;
  if (nurseId) filter.nurseId = nurseId;

  const result = await ConsultationBooking.updateMany(filter, {
    $set: {
      status: 'cancelled',
      paymentStatus: 'failed',
    },
  });
  return result.modifiedCount || 0;
}

module.exports = {
  OPEN_RESERVATION_STATUSES,
  cancelOpenReservationsForSlot,
};
