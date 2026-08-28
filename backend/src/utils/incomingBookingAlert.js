const { formatSlotLabel } = require('./slotDateTime');

const PENDING_APPROVAL_STATUSES = [
  'awaiting_doctor_approval',
  'pending_nurse_approval',
];

function incomingBookingAlertSeconds() {
  const parsed = parseInt(process.env.INCOMING_BOOKING_ALERT_SECONDS || '90', 10);
  if (!Number.isFinite(parsed)) return 90;
  return Math.min(600, Math.max(15, parsed));
}

function toIso(value) {
  if (!value) return null;
  const date = value instanceof Date ? value : new Date(value);
  return Number.isNaN(date.getTime()) ? null : date.toISOString();
}

function locationLine(booking) {
  return [booking.patientAddress, booking.patientCity, booking.patientState]
    .filter((part) => part && String(part).trim())
    .join(', ');
}

function defaultServiceLabel(providerRole) {
  switch (String(providerRole || '').toLowerCase()) {
    case 'nurse':
      return 'Home Nurse Visit';
    case 'lab':
      return 'Lab Home Collection';
    case 'ambulance':
      return 'Ambulance Request';
    case 'hospital':
      return 'Hospital Visit';
    default:
      return 'Home Doctor Visit';
  }
}

/**
 * Shared payload for incoming booking request alerts (doctor, nurse, later lab/ambulance).
 */
function buildIncomingBookingAlertData(booking, { service, providerRole } = {}) {
  const role = providerRole || (booking.nurseId ? 'nurse' : 'doctor');
  const slotStart = booking.slotStart ? new Date(booking.slotStart) : null;
  const slotEnd = booking.slotEnd ? new Date(booking.slotEnd) : null;
  const slotLabel =
    slotStart && slotEnd && !Number.isNaN(slotStart.getTime())
      ? formatSlotLabel(slotStart, slotEnd)
      : '';
  const alertSeconds = incomingBookingAlertSeconds();
  const location = locationLine(booking);
  return {
    bookingId: booking.id,
    action: 'home_visit_request',
    providerRole: role,
    patientName: booking.patientName || 'Patient',
    service: service || defaultServiceLabel(role),
    date: toIso(booking.slotStart),
    time: slotLabel,
    location: location || 'Patient Home',
    status: booking.status || 'awaiting_doctor_approval',
    approvalExpiresAt: toIso(booking.approvalExpiresAt),
    alertExpiresAt: new Date(Date.now() + alertSeconds * 1000).toISOString(),
    alertSeconds: String(alertSeconds),
  };
}

async function expireAndNotifyApprovalTimeouts(filter = {}) {
  const ConsultationBooking = require('../db/models/ConsultationBooking');
  const now = new Date();
  const due = await ConsultationBooking.find({
    ...filter,
    status: { $in: PENDING_APPROVAL_STATUSES },
    approvalExpiresAt: { $lte: now },
  });

  for (const booking of due) {
    booking.status = 'cancelled';
    booking.paymentStatus = 'failed';
    booking.cancelledAt = now;
    booking.cancelledBy = 'system';
    booking.cancellationReason = booking.nurseId
      ? 'Nurse approval window expired'
      : 'Doctor approval window expired';
    try {
      const { appendStatusHistory } = require('../db/bookingLifecycleHelpers');
      appendStatusHistory(booking, 'cancelled', 'system');
    } catch (_) {
      // History helper is optional for lean/legacy docs.
    }
    await booking.save();

    try {
      const { emitBookingStatusUpdate } = require('../services/trackingSocket');
      emitBookingStatusUpdate(booking);
    } catch (err) {
      console.warn('[IncomingBooking] expire emit failed:', err.message);
    }

    const providerId = booking.nurseId || booking.doctorId;
    const userType = booking.nurseId ? 'nurse' : 'doctor';
    if (!providerId) continue;
    try {
      const {
        createAndPushNotification,
      } = require('../db/notificationRepositories');
      await createAndPushNotification({
        userId: providerId,
        userType,
        title: 'Booking request expired',
        body: `The request from ${booking.patientName || 'a patient'} expired because it was not accepted in time.`,
        type: 'booking_cancelled',
        data: {
          bookingId: booking.id,
          action: 'booking_expired',
          status: 'expired',
          providerRole: userType,
        },
      });
    } catch (err) {
      console.warn('[IncomingBooking] expire notify failed:', err.message);
    }
  }

  return due.length;
}

module.exports = {
  incomingBookingAlertSeconds,
  buildIncomingBookingAlertData,
  expireAndNotifyApprovalTimeouts,
  PENDING_APPROVAL_STATUSES,
};
