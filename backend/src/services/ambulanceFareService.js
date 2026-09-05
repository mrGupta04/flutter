const AmbulanceFareConfig = require('../db/models/AmbulanceFareConfig');
const {
  DEFAULT_FARE_RULES,
  normalizeVehicleType,
  EQUIPMENT_KEYS,
} = require('../db/ambulanceConstants');

const CONFIG_ID = 'default';

function roundMoney(value) {
  return Math.round((Number(value) || 0) * 100) / 100;
}

function isNightHour(date, rules) {
  const hour = (date instanceof Date ? date : new Date()).getHours();
  const start = Number(rules.nightStartHour ?? 22);
  const end = Number(rules.nightEndHour ?? 6);
  if (start === end) return false;
  if (start > end) return hour >= start || hour < end;
  return hour >= start && hour < end;
}

function requestedEquipmentList(requirements = {}) {
  const map = {
    oxygen: requirements.oxygen,
    ventilator: requirements.ventilator,
    cardiac_monitor: requirements.cardiacMonitor,
    icu: requirements.icuSupport,
    stretcher: requirements.stretcher,
    wheelchair: requirements.wheelchair,
    neonatal: requirements.neonatal,
    medical_attendant: requirements.medicalAttendant,
  };
  return EQUIPMENT_KEYS.filter((key) => map[key]);
}

function calculateFare({
  rules = DEFAULT_FARE_RULES,
  vehicleType,
  distanceKm = 0,
  durationMinutes = 0,
  waitingMinutes = 0,
  requirements = {},
  isEmergency = false,
  at = new Date(),
  estimated = true,
}) {
  const typeId = normalizeVehicleType(vehicleType) || 'basic';
  const typeRules = rules.types?.[typeId] || rules.types?.basic || {};
  const night = isNightHour(at, rules);
  const equipment = requestedEquipmentList(requirements);
  const equipmentCharge = equipment.reduce((sum, key) => {
    return sum + Number(rules.equipmentCharges?.[key] || 0);
  }, 0);

  const baseFare = Number(typeRules.baseFare || 0);
  const distanceCharge = Number(typeRules.perKm || 0) * Math.max(0, Number(distanceKm) || 0);
  const timeCharge =
    Number(typeRules.perMinute || 0) * Math.max(0, Number(durationMinutes) || 0);
  const typeCharge = Number(typeRules.typeCharge || 0);
  const waitingCharge =
    Number(typeRules.waitingPerMinute || 0) * Math.max(0, Number(waitingMinutes) || 0);
  const emergencySurcharge =
    isEmergency && rules.emergencySurchargeEnabled
      ? Number(typeRules.emergencySurcharge || 0)
      : 0;

  let subtotal =
    baseFare +
    distanceCharge +
    timeCharge +
    typeCharge +
    equipmentCharge +
    waitingCharge +
    emergencySurcharge;
  const nightCharge = night
    ? roundMoney(subtotal * (Number(typeRules.nightMultiplier || 1) - 1))
    : 0;
  const total = roundMoney(subtotal + nightCharge);

  return {
    baseFare: roundMoney(baseFare),
    distanceCharge: roundMoney(distanceCharge),
    timeCharge: roundMoney(timeCharge),
    typeCharge: roundMoney(typeCharge),
    equipmentCharge: roundMoney(equipmentCharge),
    emergencySurcharge: roundMoney(emergencySurcharge),
    nightCharge,
    waitingCharge: roundMoney(waitingCharge),
    additionalCharge: 0,
    total,
    estimated: Boolean(estimated),
    currency: rules.currency || 'INR',
    distanceKm: Number(distanceKm) || 0,
    durationMinutes: Number(durationMinutes) || 0,
    vehicleType: typeId,
    night,
  };
}

async function getFareRules() {
  const doc = await AmbulanceFareConfig.findOne({ id: CONFIG_ID }).lean();
  if (!doc?.rules) return DEFAULT_FARE_RULES;
  return {
    ...DEFAULT_FARE_RULES,
    ...doc.rules,
    types: { ...DEFAULT_FARE_RULES.types, ...(doc.rules.types || {}) },
    equipmentCharges: {
      ...DEFAULT_FARE_RULES.equipmentCharges,
      ...(doc.rules.equipmentCharges || {}),
    },
  };
}

async function upsertFareRules(rules, updatedBy) {
  const next = {
    ...DEFAULT_FARE_RULES,
    ...(rules || {}),
    types: { ...DEFAULT_FARE_RULES.types, ...(rules?.types || {}) },
    equipmentCharges: {
      ...DEFAULT_FARE_RULES.equipmentCharges,
      ...(rules?.equipmentCharges || {}),
    },
  };
  await AmbulanceFareConfig.findOneAndUpdate(
    { id: CONFIG_ID },
    { $set: { id: CONFIG_ID, rules: next, updatedBy: updatedBy || 'admin' } },
    { upsert: true },
  );
  return next;
}

async function estimateFare(input) {
  const rules = await getFareRules();
  return {
    fare: calculateFare({ ...input, rules, estimated: true }),
    policy: {
      emergencyPayWhen: rules.emergencyPayWhen,
      scheduledPayWhen: rules.scheduledPayWhen,
      cashEnabled: rules.cashEnabled !== false,
      cancelFreeMinutes: rules.cancelFreeMinutes,
    },
    disclaimer:
      input.isEmergency
        ? 'This is an estimated fare. Final charges may vary with actual distance, waiting time, and configured pricing rules.'
        : 'Fare is calculated from configured ambulance pricing rules.',
  };
}

module.exports = {
  calculateFare,
  getFareRules,
  upsertFareRules,
  estimateFare,
  requestedEquipmentList,
};
