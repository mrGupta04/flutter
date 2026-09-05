const VEHICLE_TYPE_CATALOG = [
  { id: 'basic', label: 'Basic Ambulance', aliases: ['basic ambulance', 'basic'] },
  { id: 'bls', label: 'Basic Life Support', aliases: ['basic life support', 'bls'] },
  { id: 'als', label: 'Advanced Life Support', aliases: ['advanced life support', 'als'] },
  { id: 'icu', label: 'ICU Ambulance', aliases: ['icu ambulance', 'icu'] },
  { id: 'neonatal', label: 'Neonatal Ambulance', aliases: ['neonatal ambulance', 'neonatal'] },
  {
    id: 'patient_transport',
    label: 'Patient Transport Vehicle',
    aliases: ['patient transport', 'patient transport vehicle', 'ptv'],
  },
];

const EQUIPMENT_KEYS = [
  'oxygen',
  'ventilator',
  'cardiac_monitor',
  'icu',
  'stretcher',
  'wheelchair',
  'neonatal',
  'medical_attendant',
  'defibrillator',
  'aed',
];

const EMERGENCY_CATEGORIES = [
  { id: 'accident', label: 'Accident' },
  { id: 'breathing_difficulty', label: 'Breathing difficulty' },
  { id: 'chest_pain', label: 'Chest pain' },
  { id: 'unconsciousness', label: 'Unconsciousness' },
  { id: 'trauma', label: 'Trauma' },
  { id: 'pregnancy', label: 'Pregnancy-related emergency' },
  { id: 'critical_illness', label: 'Critical illness' },
  { id: 'other', label: 'Other' },
];

const DESTINATION_TYPES = ['hospital', 'home', 'clinic', 'other'];

const VEHICLE_STATUSES = [
  'AVAILABLE',
  'BUSY',
  'OFFLINE',
  'MAINTENANCE',
  'EMERGENCY_ONLY',
];

const DRIVER_STATUSES = [
  'AVAILABLE',
  'ON_TRIP',
  'OFFLINE',
  'ON_BREAK',
  'SUSPENDED',
];

const BOOKING_STATUSES = [
  'requested',
  'searching_ambulance',
  'ambulance_assigned',
  'driver_accepted',
  'accepted',
  'dispatched',
  'driver_en_route',
  'en_route',
  'arrived_at_pickup',
  'arrived',
  'patient_picked_up',
  'en_route_to_destination',
  'arrived_at_destination',
  'trip_completed',
  'completed',
  'cancelled',
  'rejected',
  'expired',
  'no_answer',
  'failed',
];

const ACTIVE_TRIP_STATUSES = [
  'searching_ambulance',
  'ambulance_assigned',
  'driver_accepted',
  'accepted',
  'dispatched',
  'driver_en_route',
  'en_route',
  'arrived_at_pickup',
  'arrived',
  'patient_picked_up',
  'en_route_to_destination',
  'arrived_at_destination',
];

const TERMINAL_STATUSES = [
  'trip_completed',
  'completed',
  'cancelled',
  'rejected',
  'expired',
  'no_answer',
  'failed',
];

const USER_CANCEL_REASONS = [
  { id: 'no_longer_needed', label: 'No longer needed' },
  { id: 'found_another', label: 'Found another ambulance' },
  { id: 'incorrect_location', label: 'Incorrect location' },
  { id: 'duplicate', label: 'Duplicate request' },
  { id: 'other', label: 'Other' },
];

const PROVIDER_CANCEL_REASONS = [
  { id: 'vehicle_issue', label: 'Vehicle issue' },
  { id: 'driver_unavailable', label: 'Driver unavailable' },
  { id: 'route_issue', label: 'Route issue' },
  { id: 'emergency_reassignment', label: 'Emergency reassignment' },
  { id: 'other', label: 'Other' },
];

const DEFAULT_FARE_RULES = {
  currency: 'INR',
  nightStartHour: 22,
  nightEndHour: 6,
  emergencySurchargeEnabled: true,
  cashEnabled: true,
  emergencyPayWhen: 'after_trip',
  scheduledPayWhen: 'after_accept',
  cancelFreeMinutes: 5,
  types: {
    basic: {
      baseFare: 400,
      perKm: 18,
      perMinute: 2,
      typeCharge: 0,
      emergencySurcharge: 80,
      nightMultiplier: 1.15,
      waitingPerMinute: 2,
    },
    bls: {
      baseFare: 550,
      perKm: 22,
      perMinute: 3,
      typeCharge: 80,
      emergencySurcharge: 100,
      nightMultiplier: 1.15,
      waitingPerMinute: 3,
    },
    als: {
      baseFare: 800,
      perKm: 28,
      perMinute: 4,
      typeCharge: 150,
      emergencySurcharge: 150,
      nightMultiplier: 1.2,
      waitingPerMinute: 4,
    },
    icu: {
      baseFare: 1400,
      perKm: 40,
      perMinute: 6,
      typeCharge: 350,
      emergencySurcharge: 200,
      nightMultiplier: 1.25,
      waitingPerMinute: 6,
    },
    neonatal: {
      baseFare: 1600,
      perKm: 42,
      perMinute: 6,
      typeCharge: 400,
      emergencySurcharge: 200,
      nightMultiplier: 1.25,
      waitingPerMinute: 6,
    },
    patient_transport: {
      baseFare: 300,
      perKm: 14,
      perMinute: 1,
      typeCharge: 0,
      emergencySurcharge: 0,
      nightMultiplier: 1.1,
      waitingPerMinute: 1,
    },
  },
  equipmentCharges: {
    oxygen: 80,
    ventilator: 250,
    cardiac_monitor: 150,
    icu: 300,
    stretcher: 0,
    wheelchair: 40,
    neonatal: 200,
    medical_attendant: 200,
    defibrillator: 150,
    aed: 80,
  },
};

function normalizeVehicleType(value) {
  const raw = String(value || '').trim().toLowerCase();
  if (!raw) return '';
  const match = VEHICLE_TYPE_CATALOG.find(
    (item) => item.id === raw || item.aliases.includes(raw) || item.label.toLowerCase() === raw,
  );
  return match ? match.id : raw.replace(/\s+/g, '_');
}

function vehicleTypeLabel(id) {
  const match = VEHICLE_TYPE_CATALOG.find((item) => item.id === id);
  return match?.label || id || 'Ambulance';
}

function catalogPayload() {
  return {
    vehicleTypes: VEHICLE_TYPE_CATALOG,
    equipment: EQUIPMENT_KEYS.map((id) => ({
      id,
      label: id
        .split('_')
        .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
        .join(' '),
    })),
    emergencyCategories: EMERGENCY_CATEGORIES,
    destinationTypes: DESTINATION_TYPES,
    userCancelReasons: USER_CANCEL_REASONS,
    providerCancelReasons: PROVIDER_CANCEL_REASONS,
    vehicleStatuses: VEHICLE_STATUSES,
    driverStatuses: DRIVER_STATUSES,
    disclaimer:
      'This service is for ambulance transportation and dispatch only. It does not diagnose patients, recommend treatment, or replace professional emergency services such as 112 / 108.',
  };
}

module.exports = {
  VEHICLE_TYPE_CATALOG,
  EQUIPMENT_KEYS,
  EMERGENCY_CATEGORIES,
  DESTINATION_TYPES,
  VEHICLE_STATUSES,
  DRIVER_STATUSES,
  BOOKING_STATUSES,
  ACTIVE_TRIP_STATUSES,
  TERMINAL_STATUSES,
  USER_CANCEL_REASONS,
  PROVIDER_CANCEL_REASONS,
  DEFAULT_FARE_RULES,
  normalizeVehicleType,
  vehicleTypeLabel,
  catalogPayload,
};
