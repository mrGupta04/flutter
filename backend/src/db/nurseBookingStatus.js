/** Nurse home-visit booking state helpers. Keep doctor statuses unchanged. */

const NURSE_PAYMENT_MINUTES = parseInt(
  process.env.NURSE_PAYMENT_MINUTES || '10',
  10,
);

const CONSULTATION_TYPE = 'book_home';

const STATUS = {
  HELD: 'held',
  PENDING_NURSE_APPROVAL: 'pending_nurse_approval',
  NURSE_REJECTED: 'nurse_rejected',
  PAYMENT_PENDING: 'payment_pending',
  PAYMENT_EXPIRED: 'payment_expired',
  CONFIRMED: 'confirmed',
  CANCELLED: 'cancelled',
  LEGACY_AWAITING_APPROVAL: 'awaiting_doctor_approval',
  LEGACY_APPROVED_PENDING_PAYMENT: 'approved_pending_payment',
};

const ACTIVE_SLOT_STATUSES = [
  STATUS.HELD,
  'pending',
  STATUS.PENDING_NURSE_APPROVAL,
  STATUS.LEGACY_AWAITING_APPROVAL,
  STATUS.PAYMENT_PENDING,
  STATUS.LEGACY_APPROVED_PENDING_PAYMENT,
  STATUS.CONFIRMED,
];

const PAYMENT_PENDING_STATUSES = [
  STATUS.PAYMENT_PENDING,
  STATUS.LEGACY_APPROVED_PENDING_PAYMENT,
];

const APPROVAL_PENDING_STATUSES = [
  STATUS.PENDING_NURSE_APPROVAL,
  STATUS.LEGACY_AWAITING_APPROVAL,
];

function isPaymentPendingStatus(status) {
  return PAYMENT_PENDING_STATUSES.includes(status);
}

function isApprovalPendingStatus(status) {
  return APPROVAL_PENDING_STATUSES.includes(status);
}

function isActiveSlotStatus(status) {
  return ACTIVE_SLOT_STATUSES.includes(status);
}

function remainingPaymentSeconds(booking, now = new Date()) {
  if (!booking?.paymentExpiresAt) return 0;
  return Math.max(
    0,
    Math.ceil((new Date(booking.paymentExpiresAt).getTime() - now.getTime()) / 1000),
  );
}

function workflowStatus(booking) {
  const status = booking?.status;
  const progress = booking?.visitProgress;
  if (status === STATUS.CANCELLED) return 'CANCELLED';
  if (status === STATUS.NURSE_REJECTED) return 'NURSE_REJECTED';
  if (status === STATUS.PAYMENT_EXPIRED) return 'PAYMENT_EXPIRED';
  if (isApprovalPendingStatus(status)) return 'PENDING_NURSE_APPROVAL';
  if (isPaymentPendingStatus(status)) return 'PAYMENT_PENDING';
  if (status === STATUS.CONFIRMED) {
    if (progress === 'completed') return 'COMPLETED';
    if (progress === 'visit_started') return 'SERVICE_STARTED';
    if (progress === 'arrived') return 'NURSE_ARRIVED';
    if (progress === 'en_route') return 'NURSE_STARTED_TRIP';
    return 'CONFIRMED';
  }
  if (status === STATUS.HELD) return 'SLOT_HELD';
  return String(status || '').toUpperCase();
}

function overlapFilter(nurseId, slotStart, slotEnd, { excludeId } = {}) {
  const filter = {
    nurseId,
    consultationType: CONSULTATION_TYPE,
    status: { $in: ACTIVE_SLOT_STATUSES },
    slotStart: { $lt: slotEnd },
    slotEnd: { $gt: slotStart },
  };
  if (excludeId) {
    filter.id = { $ne: excludeId };
  }
  return filter;
}

function paymentWindowExpiresAt(from = new Date()) {
  return new Date(from.getTime() + NURSE_PAYMENT_MINUTES * 60 * 1000);
}

module.exports = {
  NURSE_PAYMENT_MINUTES,
  CONSULTATION_TYPE,
  STATUS,
  ACTIVE_SLOT_STATUSES,
  PAYMENT_PENDING_STATUSES,
  APPROVAL_PENDING_STATUSES,
  isPaymentPendingStatus,
  isApprovalPendingStatus,
  isActiveSlotStatus,
  remainingPaymentSeconds,
  workflowStatus,
  overlapFilter,
  paymentWindowExpiresAt,
};
