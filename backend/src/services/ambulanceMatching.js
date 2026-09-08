const { distanceKm } = require('../utils/geoDistance');
const { normalizeVehicleType } = require('../db/ambulanceConstants');

const DEFAULT_RADIUS_KM = Number(process.env.AMBULANCE_DISPATCH_INITIAL_RADIUS_KM || 15);
const FALLBACK_KMH = Number(process.env.AMBULANCE_FALLBACK_KMH || 30);

function vehicleHasEquipment(vehicle, requirements = {}) {
  const checks = [
    [requirements.oxygen, vehicle.hasOxygen],
    [requirements.ventilator, vehicle.hasVentilator],
    [requirements.cardiacMonitor, vehicle.hasCardiacMonitor || vehicle.hasDefibrillator],
    [requirements.icuSupport, vehicle.hasIcuCapability],
    [requirements.stretcher, vehicle.hasStretcher !== false],
    [requirements.wheelchair, vehicle.hasWheelchair],
    [requirements.neonatal, vehicle.hasNeonatalCapability],
    [requirements.medicalAttendant, vehicle.hasMedicalAttendant],
  ];
  return checks.every(([needed, has]) => !needed || Boolean(has));
}

function vehicleTypeMatches(requestedType, vehicleType) {
  if (!requestedType) return true;
  return normalizeVehicleType(requestedType) === normalizeVehicleType(vehicleType);
}

function isProviderDispatchable(provider, { emergency = true } = {}) {
  if (!provider) return false;
  if (provider.isDisabled || provider.isSuspended) return false;
  if (provider.verificationStatus !== 'verified' && !provider.isApproved) return false;
  if (emergency && provider.emergencyAvailable === false) return false;
  return true;
}

function isVehicleDispatchable(vehicle, { emergency = true, allowOffline = false } = {}) {
  if (!vehicle) return false;
  if (vehicle.currentBookingId) return false;
  const status = vehicle.status || 'OFFLINE';
  if (status === 'BUSY' || status === 'MAINTENANCE') return false;
  if (status === 'OFFLINE') return Boolean(allowOffline);
  if (status === 'EMERGENCY_ONLY' && !emergency) return false;
  return status === 'AVAILABLE' || status === 'EMERGENCY_ONLY';
}

function isDriverDispatchable(driver, { allowOffline = false } = {}) {
  if (!driver) return false;
  if (driver.status === 'SUSPENDED') return false;
  if (driver.currentBookingId) return false;
  if (driver.verificationStatus === 'rejected') return false;
  if (allowOffline) return true;
  return driver.isOnline === true || driver.status === 'AVAILABLE';
}

function pointFor(vehicle, driver, provider) {
  if (Number.isFinite(vehicle?.currentLatitude) && Number.isFinite(vehicle?.currentLongitude)) {
    return { latitude: vehicle.currentLatitude, longitude: vehicle.currentLongitude };
  }
  if (Number.isFinite(driver?.currentLatitude) && Number.isFinite(driver?.currentLongitude)) {
    return { latitude: driver.currentLatitude, longitude: driver.currentLongitude };
  }
  if (Number.isFinite(provider?.latitude) && Number.isFinite(provider?.longitude)) {
    return { latitude: provider.latitude, longitude: provider.longitude };
  }
  return null;
}

function etaMinutesFromKm(km) {
  if (!Number.isFinite(km)) return null;
  return Math.max(1, Math.round((km / FALLBACK_KMH) * 60));
}

function findMatchingCandidates({
  providers,
  pickupLatitude,
  pickupLongitude,
  requestedType,
  requirements = {},
  emergency = true,
  radiusKm = DEFAULT_RADIUS_KM,
  excludeVehicleIds = [],
  excludeAmbulanceIds = [],
  preferredAmbulanceId,
}) {
  const pickupReady =
    Number.isFinite(Number(pickupLatitude)) && Number.isFinite(Number(pickupLongitude));
  const excludedVehicles = new Set((excludeVehicleIds || []).filter(Boolean));
  const excludedProviders = new Set((excludeAmbulanceIds || []).filter(Boolean));
  const matches = [];

  for (const provider of providers || []) {
    if (excludedProviders.has(provider.id)) continue;
    if (!isProviderDispatchable(provider, { emergency })) continue;

    const radius = Number(provider.serviceRadiusKm || radiusKm || DEFAULT_RADIUS_KM);
    const vehicles = provider.vehicles || [];
    const drivers = provider.drivers || [];

    const preferred = preferredAmbulanceId && provider.id === preferredAmbulanceId;

    for (const vehicle of vehicles) {
      if (excludedVehicles.has(vehicle.id)) continue;
      if (!isVehicleDispatchable(vehicle, { emergency, allowOffline: preferred })) continue;
      if (!vehicleTypeMatches(requestedType, vehicle.vehicleType)) continue;
      if (!vehicleHasEquipment(vehicle, requirements)) continue;

      const driver =
        drivers.find((item) => item.id === vehicle.assignedDriverId) ||
        drivers.find((item) => item.assignedVehicleId === vehicle.id) ||
        drivers.find((item) => isDriverDispatchable(item, { allowOffline: preferred })) ||
        (preferred ? drivers.find((item) => item.status !== 'SUSPENDED') : null);

      if (!isDriverDispatchable(driver, { allowOffline: preferred })) continue;

      const point = pointFor(vehicle, driver, provider);
      let distance = null;
      if (pickupReady && point) {
        distance = distanceKm(
          Number(pickupLatitude),
          Number(pickupLongitude),
          point.latitude,
          point.longitude,
        );
        const vehicleRadius = Number(vehicle.serviceRadiusKm || radius);
        if (Number.isFinite(distance) && distance > vehicleRadius) continue;
      }

      const etaMinutes = etaMinutesFromKm(distance);
      matches.push({
        ambulanceId: provider.id,
        ambulanceServiceName: provider.serviceName,
        vehicleId: vehicle.id,
        vehicleType: vehicle.vehicleType,
        vehicleRegistration: vehicle.registrationNumber,
        driverId: driver.id,
        driverName: driver.fullName,
        driverMobile: driver.mobileNumber,
        distanceKm: distance,
        etaMinutes,
        latitude: point?.latitude ?? null,
        longitude: point?.longitude ?? null,
        score: Number.isFinite(distance) ? distance : 9999,
      });
    }
  }

  matches.sort((a, b) => {
    const aPreferred = preferredAmbulanceId && a.ambulanceId === preferredAmbulanceId ? 0 : 1;
    const bPreferred = preferredAmbulanceId && b.ambulanceId === preferredAmbulanceId ? 0 : 1;
    if (aPreferred !== bPreferred) return aPreferred - bPreferred;
    if (a.score !== b.score) return a.score - b.score;
    return String(a.vehicleId).localeCompare(String(b.vehicleId));
  });
  return matches;
}

function findMatchingCandidatesPreferType(opts) {
  const typed = findMatchingCandidates(opts);
  if (!opts.requestedType) return typed;
  const any = findMatchingCandidates({ ...opts, requestedType: undefined });
  const seen = new Set(typed.map((item) => item.vehicleId));
  return [...typed, ...any.filter((item) => !seen.has(item.vehicleId))];
}

function nextDispatchBatch(candidates, { batchSize = 2, alreadyOffered = [] } = {}) {
  const offered = new Set(alreadyOffered);
  return (candidates || [])
    .filter((item) => !offered.has(item.vehicleId))
    .slice(0, Math.max(1, Number(batchSize) || 1));
}

module.exports = {
  DEFAULT_RADIUS_KM,
  vehicleHasEquipment,
  vehicleTypeMatches,
  isProviderDispatchable,
  isVehicleDispatchable,
  isDriverDispatchable,
  findMatchingCandidates,
  findMatchingCandidatesPreferType,
  nextDispatchBatch,
  etaMinutesFromKm,
};
