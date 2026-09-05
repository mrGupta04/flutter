const {
  ACTIVE_TRIP_STATUSES,
  TERMINAL_STATUSES,
} = require('../db/ambulanceConstants');

const CANONICAL = {
  requested: 'requested',
  searching_ambulance: 'searching_ambulance',
  ambulance_assigned: 'ambulance_assigned',
  driver_accepted: 'driver_accepted',
  accepted: 'driver_accepted',
  dispatched: 'driver_en_route',
  driver_en_route: 'driver_en_route',
  en_route: 'driver_en_route',
  arrived_at_pickup: 'arrived_at_pickup',
  arrived: 'arrived_at_pickup',
  patient_picked_up: 'patient_picked_up',
  en_route_to_destination: 'en_route_to_destination',
  arrived_at_destination: 'arrived_at_destination',
  trip_completed: 'trip_completed',
  completed: 'trip_completed',
  cancelled: 'cancelled',
  rejected: 'rejected',
  expired: 'expired',
  no_answer: 'no_answer',
  failed: 'failed',
};

const USER_LABELS = {
  requested: 'Request received',
  searching_ambulance: 'Searching for an ambulance',
  ambulance_assigned: 'Ambulance assigned',
  driver_accepted: 'Ambulance confirmed',
  driver_en_route: 'Ambulance is on the way',
  arrived_at_pickup: 'Ambulance has arrived',
  patient_picked_up: 'Patient picked up',
  en_route_to_destination: 'Heading to destination',
  arrived_at_destination: 'Destination reached',
  trip_completed: 'Trip completed',
  cancelled: 'Cancelled',
  rejected: 'Declined',
  expired: 'Request expired',
  no_answer: 'No ambulance accepted',
  failed: 'Request failed',
};

const TRANSITIONS = {
  requested: [
    'searching_ambulance',
    'ambulance_assigned',
    'accepted',
    'cancelled',
    'rejected',
    'expired',
    'failed',
  ],
  searching_ambulance: [
    'ambulance_assigned',
    'cancelled',
    'expired',
    'no_answer',
    'failed',
  ],
  ambulance_assigned: [
    'driver_accepted',
    'accepted',
    'searching_ambulance',
    'cancelled',
    'failed',
  ],
  driver_accepted: ['driver_en_route', 'dispatched', 'en_route', 'cancelled'],
  accepted: ['driver_en_route', 'dispatched', 'en_route', 'cancelled'],
  dispatched: [
    'driver_en_route',
    'en_route',
    'arrived_at_pickup',
    'arrived',
    'cancelled',
  ],
  driver_en_route: ['arrived_at_pickup', 'arrived', 'cancelled'],
  en_route: ['arrived_at_pickup', 'arrived', 'cancelled'],
  arrived_at_pickup: ['patient_picked_up', 'cancelled'],
  arrived: ['patient_picked_up', 'cancelled'],
  patient_picked_up: ['en_route_to_destination'],
  en_route_to_destination: ['arrived_at_destination'],
  arrived_at_destination: ['trip_completed', 'completed'],
  trip_completed: [],
  completed: [],
  cancelled: [],
  rejected: [],
  expired: [],
  no_answer: [],
  failed: [],
};

const USER_CANCEL_ALLOWED = new Set([
  'requested',
  'searching_ambulance',
  'ambulance_assigned',
  'driver_accepted',
  'accepted',
  'dispatched',
  'driver_en_route',
  'en_route',
]);

const PROVIDER_CANCEL_ALLOWED = new Set([
  ...USER_CANCEL_ALLOWED,
  'arrived_at_pickup',
  'arrived',
]);

function canonicalStatus(status) {
  return CANONICAL[status] || status;
}

function userFacingLabel(status) {
  return USER_LABELS[canonicalStatus(status)] || status;
}

function canTransition(from, to) {
  const allowed = TRANSITIONS[from] || [];
  return allowed.includes(to);
}

function assertTransition(from, to) {
  if (from === to) return;
  if (!canTransition(from, to)) {
    const err = new Error(`Cannot change booking from ${from} to ${to}`);
    err.statusCode = 400;
    err.code = 'INVALID_STATUS_TRANSITION';
    throw err;
  }
}

function isActiveTrip(status) {
  return ACTIVE_TRIP_STATUSES.includes(status);
}

function isTerminal(status) {
  return TERMINAL_STATUSES.includes(status);
}

function canUserCancel(status) {
  return USER_CANCEL_ALLOWED.has(status);
}

function canProviderCancel(status) {
  return PROVIDER_CANCEL_ALLOWED.has(status);
}

function timelineFor(status) {
  const steps = [
    { key: 'requested', label: 'Request sent' },
    { key: 'searching_ambulance', label: 'Searching' },
    { key: 'driver_accepted', label: 'Ambulance confirmed' },
    { key: 'driver_en_route', label: 'On the way' },
    { key: 'arrived_at_pickup', label: 'Arrived at pickup' },
    { key: 'patient_picked_up', label: 'Patient picked up' },
    { key: 'en_route_to_destination', label: 'Heading to destination' },
    { key: 'arrived_at_destination', label: 'Destination reached' },
    { key: 'trip_completed', label: 'Completed' },
  ];
  const current = canonicalStatus(status);
  const order = steps.map((s) => s.key);
  const currentIndex = Math.max(0, order.indexOf(current));
  const terminalFail = ['cancelled', 'rejected', 'expired', 'no_answer', 'failed'].includes(
    current,
  );
  return steps.map((step, index) => ({
    ...step,
    done: !terminalFail && (index < currentIndex || current === 'trip_completed'),
    current: !terminalFail && canonicalStatus(step.key) === current,
  }));
}

module.exports = {
  CANONICAL,
  USER_LABELS,
  TRANSITIONS,
  canonicalStatus,
  userFacingLabel,
  canTransition,
  assertTransition,
  isActiveTrip,
  isTerminal,
  canUserCancel,
  canProviderCancel,
  timelineFor,
};
