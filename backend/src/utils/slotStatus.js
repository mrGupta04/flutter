const SLOT_STATUS = {
  AVAILABLE: 'AVAILABLE',
  SELF_BUSY: 'SELF_BUSY',
  DISCARDED: 'DISCARDED',
  BOOKED: 'BOOKED',
};

const SLOT_STATUS_VALUES = Object.values(SLOT_STATUS);

const PROVIDER_SETTABLE_STATUSES = [
  SLOT_STATUS.AVAILABLE,
  SLOT_STATUS.SELF_BUSY,
  SLOT_STATUS.DISCARDED,
];

function normalizeSlotStatus(value, available = false) {
  const raw = String(value || '').trim().toUpperCase();
  if (SLOT_STATUS_VALUES.includes(raw)) return raw;
  return available ? SLOT_STATUS.AVAILABLE : SLOT_STATUS.DISCARDED;
}

function resolveSlotStatus(slot) {
  if (!slot) return SLOT_STATUS.DISCARDED;
  return normalizeSlotStatus(slot.status, slot.available);
}

function isSlotBookable(slot) {
  return resolveSlotStatus(slot) === SLOT_STATUS.AVAILABLE;
}

function isSlotOnSchedule(slot) {
  const status = resolveSlotStatus(slot);
  return (
    status === SLOT_STATUS.AVAILABLE ||
    status === SLOT_STATUS.SELF_BUSY ||
    status === SLOT_STATUS.BOOKED
  );
}

function isSlotVisibleToPatients(slot) {
  const status = resolveSlotStatus(slot);
  return status === SLOT_STATUS.AVAILABLE || status === SLOT_STATUS.SELF_BUSY;
}

function withSlotStatus(slot, status) {
  const next = SLOT_STATUS_VALUES.includes(status)
    ? status
    : SLOT_STATUS.DISCARDED;
  return {
    ...(slot || {}),
    status: next,
    available: next === SLOT_STATUS.AVAILABLE,
  };
}

function bookingRejectionForStatus(status) {
  switch (status) {
    case SLOT_STATUS.SELF_BUSY:
      return 'This slot is unavailable.';
    case SLOT_STATUS.DISCARDED:
      return 'This slot is no longer available.';
    case SLOT_STATUS.BOOKED:
      return 'This slot was just booked. Please choose another time.';
    default:
      return 'Selected time slot is not available';
  }
}

module.exports = {
  SLOT_STATUS,
  SLOT_STATUS_VALUES,
  PROVIDER_SETTABLE_STATUSES,
  normalizeSlotStatus,
  resolveSlotStatus,
  isSlotBookable,
  isSlotOnSchedule,
  isSlotVisibleToPatients,
  withSlotStatus,
  bookingRejectionForStatus,
};
