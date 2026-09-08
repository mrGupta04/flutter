const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const Ambulance = require('./models/Ambulance');
const AmbulanceBooking = require('./models/AmbulanceBooking');
const { toAmbulance, toVehicle, toDriver } = require('./ambulanceMappers');
const {
  VEHICLE_STATUSES,
  DRIVER_STATUSES,
  normalizeVehicleType,
  vehicleTypeLabel,
} = require('./ambulanceConstants');
const { writeAmbulanceAudit } = require('./ambulanceAuditRepositories');
const { isActiveTrip } = require('../services/ambulanceStatus');

function fail(message, statusCode = 400) {
  const err = new Error(message);
  err.statusCode = statusCode;
  throw err;
}

async function loadProvider(ambulanceId) {
  const doc = await Ambulance.findOne({ id: ambulanceId });
  if (!doc) fail('Ambulance provider not found', 404);
  return doc;
}

function normalizeVehiclePayload(input, existing = {}) {
  return {
    id: existing.id || input.id || uuidv4(),
    registrationNumber: input.registrationNumber ?? existing.registrationNumber,
    vehicleType: vehicleTypeLabel(
      normalizeVehicleType(input.vehicleType ?? existing.vehicleType),
    ) || input.vehicleType || existing.vehicleType,
    make: input.make ?? existing.make,
    model: input.model ?? existing.model,
    year: input.year ?? existing.year,
    color: input.color ?? existing.color,
    capacity: input.capacity ?? existing.capacity,
    hasOxygen: input.hasOxygen ?? existing.hasOxygen ?? false,
    hasVentilator: input.hasVentilator ?? existing.hasVentilator ?? false,
    hasDefibrillator: input.hasDefibrillator ?? existing.hasDefibrillator ?? false,
    hasStretcher: input.hasStretcher ?? existing.hasStretcher ?? true,
    hasAed: input.hasAed ?? existing.hasAed ?? false,
    hasCardiacMonitor: input.hasCardiacMonitor ?? existing.hasCardiacMonitor ?? false,
    hasWheelchair: input.hasWheelchair ?? existing.hasWheelchair ?? false,
    hasIcuCapability: input.hasIcuCapability ?? existing.hasIcuCapability ?? false,
    hasNeonatalCapability: input.hasNeonatalCapability ?? existing.hasNeonatalCapability ?? false,
    hasMedicalAttendant: input.hasMedicalAttendant ?? existing.hasMedicalAttendant ?? false,
    equipment: input.equipment ?? existing.equipment ?? [],
    status: VEHICLE_STATUSES.includes(input.status) ? input.status : existing.status || 'OFFLINE',
    assignedDriverId: input.assignedDriverId ?? existing.assignedDriverId,
    serviceRadiusKm: input.serviceRadiusKm ?? existing.serviceRadiusKm,
    baseFare: input.baseFare != null ? Number(input.baseFare) : existing.baseFare,
    perKm: input.perKm != null ? Number(input.perKm) : existing.perKm,
    minFare: input.minFare != null ? Number(input.minFare) : existing.minFare,
    photoFrontUrl: input.photoFrontUrl ?? existing.photoFrontUrl,
    photoBackUrl: input.photoBackUrl ?? existing.photoBackUrl,
    photoInteriorUrl: input.photoInteriorUrl ?? existing.photoInteriorUrl,
    currentBookingId: existing.currentBookingId,
    currentLatitude: existing.currentLatitude,
    currentLongitude: existing.currentLongitude,
    lastLocationAt: existing.lastLocationAt,
  };
}

function normalizeDriverPayload(input, existing = {}) {
  const next = {
    id: existing.id || input.id || uuidv4(),
    fullName: input.fullName ?? existing.fullName,
    mobileNumber: input.mobileNumber ?? existing.mobileNumber,
    email: input.email ?? existing.email,
    dateOfBirth: input.dateOfBirth ?? existing.dateOfBirth,
    drivingLicenseNumber: input.drivingLicenseNumber ?? existing.drivingLicenseNumber,
    drivingLicenseExpiry: input.drivingLicenseExpiry ?? existing.drivingLicenseExpiry,
    emtCertificationNumber: input.emtCertificationNumber ?? existing.emtCertificationNumber,
    emtCertificationExpiry: input.emtCertificationExpiry ?? existing.emtCertificationExpiry,
    assignedVehicleId: input.assignedVehicleId ?? existing.assignedVehicleId,
    photoUrl: input.photoUrl ?? existing.photoUrl,
    backgroundCheckConsent: input.backgroundCheckConsent ?? existing.backgroundCheckConsent ?? false,
    status: DRIVER_STATUSES.includes(input.status) ? input.status : existing.status || 'OFFLINE',
    verificationStatus: input.verificationStatus ?? existing.verificationStatus ?? 'pending',
    emergencyContactName: input.emergencyContactName ?? existing.emergencyContactName,
    emergencyContactPhone: input.emergencyContactPhone ?? existing.emergencyContactPhone,
    isOnline: input.isOnline ?? existing.isOnline ?? false,
    pinHash: existing.pinHash,
    currentBookingId: existing.currentBookingId,
  };
  if (input.pin) {
    next.pinHash = bcrypt.hashSync(String(input.pin), 10);
  }
  return next;
}

async function upsertVehicle(ambulanceId, input, actor) {
  const doc = await loadProvider(ambulanceId);
  const vehicles = (doc.vehicles || []).map((item) => (item.toObject ? item.toObject() : item));
  const existing = vehicles.find((item) => item.id === input.id);
  if (
    existing?.currentBookingId &&
    input.status === 'AVAILABLE' &&
    existing.status !== 'AVAILABLE'
  ) {
    fail('This ambulance is assigned to an active trip and cannot be marked available');
  }
  const next = normalizeVehiclePayload(input, existing || {});
  const updated = existing
    ? vehicles.map((item) => (item.id === next.id ? { ...item, ...next } : item))
    : [...vehicles, next];
  doc.vehicles = updated;
  doc.vehicleCount = updated.length;
  doc.vehicleTypes = [...new Set(updated.map((item) => item.vehicleType).filter(Boolean))];
  await doc.save();
  await writeAmbulanceAudit({
    actorId: actor?.actorId,
    actorRole: actor?.actorRole,
    action: existing ? 'ambulance_modified' : 'ambulance_added',
    entityType: 'AmbulanceVehicle',
    entityId: next.id,
    ambulanceId,
    previousValue: existing || null,
    newValue: next,
  });
  return toVehicle(next);
}

async function upsertDriver(ambulanceId, input, actor) {
  const doc = await loadProvider(ambulanceId);
  const drivers = (doc.drivers || []).map((item) => (item.toObject ? item.toObject() : item));
  const existing = drivers.find((item) => item.id === input.id);
  const next = normalizeDriverPayload(input, existing || {});
  const updated = existing
    ? drivers.map((item) => (item.id === next.id ? { ...item, ...next } : item))
    : [...drivers, next];
  doc.drivers = updated;
  await doc.save();
  await writeAmbulanceAudit({
    actorId: actor?.actorId,
    actorRole: actor?.actorRole,
    action: existing ? 'driver_modified' : 'driver_added',
    entityType: 'AmbulanceDriver',
    entityId: next.id,
    ambulanceId,
    previousValue: existing ? { ...existing, pinHash: undefined } : null,
    newValue: { ...next, pinHash: undefined },
  });
  return toDriver(next);
}

async function setVehicleStatus(ambulanceId, vehicleId, status, actor) {
  if (!VEHICLE_STATUSES.includes(status)) fail('Invalid vehicle status');
  const doc = await loadProvider(ambulanceId);
  const vehicle = (doc.vehicles || []).find((item) => item.id === vehicleId);
  if (!vehicle) fail('Ambulance not found', 404);
  if (vehicle.currentBookingId && status === 'AVAILABLE') {
    const booking = await AmbulanceBooking.findOne({ id: vehicle.currentBookingId });
    if (booking && isActiveTrip(booking.status)) {
      fail('This ambulance is assigned to an active trip and cannot become available');
    }
  }
  const previous = vehicle.status;
  vehicle.status = status;
  await doc.save();
  await writeAmbulanceAudit({
    actorId: actor?.actorId,
    actorRole: actor?.actorRole,
    action: 'ambulance_modified',
    entityType: 'AmbulanceVehicle',
    entityId: vehicleId,
    ambulanceId,
    previousValue: { status: previous },
    newValue: { status },
  });
  return toVehicle(vehicle);
}

function resolvePresenceDriver(doc, driverId) {
  const drivers = doc.drivers || [];
  if (driverId) {
    return drivers.find((item) => item.id === driverId) || null;
  }
  return (
    drivers.find((item) => item.isOnline && item.status !== 'SUSPENDED') ||
    drivers.find((item) => item.status !== 'SUSPENDED') ||
    null
  );
}

function resolvePresenceVehicle(doc, driver) {
  const vehicles = doc.vehicles || [];
  return (
    vehicles.find((item) => item.id === driver.assignedVehicleId) ||
    vehicles.find((item) => item.assignedDriverId === driver.id) ||
    vehicles.find((item) => !item.currentBookingId && item.status !== 'MAINTENANCE') ||
    null
  );
}

async function setDriverPresence({ ambulanceId, driverId, online, status, latitude, longitude }) {
  const doc = await loadProvider(ambulanceId);
  const driver = resolvePresenceDriver(doc, driverId);
  if (!driver) fail('Driver not found. Add a driver in Fleet first.', 404);
  if (driver.status === 'SUSPENDED') fail('Driver is suspended', 403);
  if (online != null) {
    driver.isOnline = Boolean(online);
    driver.status = driver.isOnline ? 'AVAILABLE' : 'OFFLINE';
    if (driver.isOnline) driver.lastOnlineAt = new Date();
  }
  if (status && DRIVER_STATUSES.includes(status)) driver.status = status;
  if (Number.isFinite(Number(latitude)) && Number.isFinite(Number(longitude))) {
    driver.currentLatitude = Number(latitude);
    driver.currentLongitude = Number(longitude);
    driver.lastLocationAt = new Date();
  }

  const vehicle = resolvePresenceVehicle(doc, driver);
  if (vehicle && !vehicle.currentBookingId && vehicle.status !== 'MAINTENANCE') {
    if (driver.isOnline) {
      vehicle.status = 'AVAILABLE';
      vehicle.assignedDriverId = vehicle.assignedDriverId || driver.id;
      driver.assignedVehicleId = driver.assignedVehicleId || vehicle.id;
      if (Number.isFinite(driver.currentLatitude) && Number.isFinite(driver.currentLongitude)) {
        vehicle.currentLatitude = driver.currentLatitude;
        vehicle.currentLongitude = driver.currentLongitude;
        vehicle.lastLocationAt = driver.lastLocationAt;
      }
    } else if (vehicle.status !== 'BUSY') {
      vehicle.status = 'OFFLINE';
    }
  }

  await doc.save();
  return toDriver(driver);
}

async function findDriverByMobile(mobile) {
  const clean = String(mobile || '').replace(/\D/g, '').slice(-10);
  if (clean.length !== 10) return null;
  const providers = await Ambulance.find({ 'drivers.mobileNumber': new RegExp(`${clean}$`) });
  for (const provider of providers) {
    const driver = (provider.drivers || []).find((item) =>
      String(item.mobileNumber || '').replace(/\D/g, '').endsWith(clean),
    );
    if (driver) {
      return { provider: toAmbulance(provider), driver: toDriver(driver, { includeSecrets: true }), raw: driver };
    }
  }
  return null;
}

async function updateOperationsSettings(ambulanceId, input, actor) {
  const doc = await loadProvider(ambulanceId);
  const fields = [
    'serviceRadiusKm',
    'serviceArea',
    'supportedCities',
    'available24x7',
    'emergencyAvailable',
    'operatingHoursStart',
    'operatingHoursEnd',
    'cashPaymentEnabled',
    'latitude',
    'longitude',
    'baseFare',
    'perKm',
    'minFare',
  ];
  const previous = {};
  const next = {};
  fields.forEach((field) => {
    if (input[field] !== undefined) {
      previous[field] = doc[field];
      const numeric = ['baseFare', 'perKm', 'minFare', 'serviceRadiusKm', 'latitude', 'longitude'];
      const value = numeric.includes(field) ? Number(input[field]) : input[field];
      if (numeric.includes(field) && !Number.isFinite(value)) return;
      doc[field] = value;
      next[field] = value;
    }
  });
  await doc.save();
  await writeAmbulanceAudit({
    actorId: actor?.actorId,
    actorRole: actor?.actorRole,
    action: 'ambulance_modified',
    entityType: 'AmbulanceProvider',
    entityId: ambulanceId,
    ambulanceId,
    previousValue: previous,
    newValue: next,
  });
  return toAmbulance(doc);
}

async function assignVehicleToDriver(ambulanceId, vehicleId, driverId, actor) {
  const doc = await loadProvider(ambulanceId);
  const vehicle = (doc.vehicles || []).find((item) => item.id === vehicleId);
  const driver = (doc.drivers || []).find((item) => item.id === driverId);
  if (!vehicle || !driver) fail('Vehicle or driver not found', 404);
  vehicle.assignedDriverId = driverId;
  driver.assignedVehicleId = vehicleId;
  await doc.save();
  await writeAmbulanceAudit({
    actorId: actor?.actorId,
    actorRole: actor?.actorRole,
    action: 'ambulance_modified',
    entityType: 'AmbulanceVehicle',
    entityId: vehicleId,
    ambulanceId,
    newValue: { assignedDriverId: driverId },
  });
  return { vehicle: toVehicle(vehicle), driver: toDriver(driver) };
}

async function releaseFleetAssignment({ ambulanceId, vehicleId, driverId }) {
  const update = {
    'vehicles.$[vehicle].status': 'AVAILABLE',
    'vehicles.$[vehicle].currentBookingId': null,
    'drivers.$[driver].status': 'AVAILABLE',
    'drivers.$[driver].currentBookingId': null,
  };
  await Ambulance.updateOne(
    { id: ambulanceId },
    { $set: update },
    {
      arrayFilters: [{ 'vehicle.id': vehicleId }, { 'driver.id': driverId }],
    },
  );
}

module.exports = {
  upsertVehicle,
  upsertDriver,
  setVehicleStatus,
  setDriverPresence,
  findDriverByMobile,
  updateOperationsSettings,
  assignVehicleToDriver,
  releaseFleetAssignment,
};
