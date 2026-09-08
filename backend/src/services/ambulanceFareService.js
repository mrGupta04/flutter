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

function resolveProviderRates(provider, vehicle) {
  if (!provider && !vehicle) return null;
  const perKm = Number(vehicle?.perKm ?? provider?.perKm);
  const baseFare = Number(vehicle?.baseFare ?? provider?.baseFare);
  const minFare = Number(vehicle?.minFare ?? provider?.minFare);
  if (![perKm, baseFare, minFare].some((value) => Number.isFinite(value) && value > 0)) {
    return null;
  }
  return {
    perKm: Number.isFinite(perKm) && perKm > 0 ? perKm : undefined,
    baseFare: Number.isFinite(baseFare) && baseFare >= 0 ? baseFare : undefined,
    minFare: Number.isFinite(minFare) && minFare > 0 ? minFare : undefined,
  };
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
  providerRates = null,
}) {
  const typeId = normalizeVehicleType(vehicleType) || 'basic';
  const typeRules = rules.types?.[typeId] || rules.types?.basic || {};
  const night = isNightHour(at, rules);
  const equipment = requestedEquipmentList(requirements);
  const equipmentCharge = equipment.reduce((sum, key) => {
    return sum + Number(rules.equipmentCharges?.[key] || 0);
  }, 0);

  const baseFare = Number(
    providerRates?.baseFare ?? typeRules.baseFare ?? 0,
  );
  const perKm = Number(providerRates?.perKm ?? typeRules.perKm ?? 0);
  const distanceCharge = perKm * Math.max(0, Number(distanceKm) || 0);
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
  let total = roundMoney(subtotal + nightCharge);
  let additionalCharge = 0;
  if (providerRates?.minFare && total < providerRates.minFare) {
    additionalCharge = roundMoney(providerRates.minFare - total);
    total = roundMoney(providerRates.minFare);
  }

  return {
    baseFare: roundMoney(baseFare),
    distanceCharge: roundMoney(distanceCharge),
    timeCharge: roundMoney(timeCharge),
    typeCharge: roundMoney(typeCharge),
    equipmentCharge: roundMoney(equipmentCharge),
    emergencySurcharge: roundMoney(emergencySurcharge),
    nightCharge,
    waitingCharge: roundMoney(waitingCharge),
    additionalCharge,
    total,
    estimated: Boolean(estimated),
    currency: rules.currency || 'INR',
    distanceKm: Number(distanceKm) || 0,
    durationMinutes: Number(durationMinutes) || 0,
    vehicleType: typeId,
    perKm,
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
    fare: calculateFare({ ...input, rules, estimated: true, providerRates: input.providerRates }),
    policy: {
      emergencyPayWhen: rules.emergencyPayWhen,
      scheduledPayWhen: rules.scheduledPayWhen,
      cashEnabled: rules.cashEnabled !== false,
      cancelFreeMinutes: rules.cancelFreeMinutes,
    },
    disclaimer:
      input.isEmergency
        ? 'This is an estimated fare. Final charges may vary with actual distance, waiting time, and configured pricing rules.'
        : 'Fare uses the assigned ambulance provider’s per-km rate.',
  };
}

module.exports = {
  calculateFare,
  getFareRules,
  upsertFareRules,
  estimateFare,
  resolveProviderRates,
  requestedEquipmentList,
};
