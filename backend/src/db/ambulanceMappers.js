const {
  normalizeVehicleType,
  vehicleTypeLabel,
} = require('./ambulanceConstants');
const { userFacingLabel, timelineFor, canonicalStatus } = require('../services/ambulanceStatus');

function normalizeVerificationStatus(status) {
  if (status === 'verifier_approved') return 'under_review';
  return status;
}

function toVehicle(v) {
  if (!v) return null;
  return {
    id: v.id,
    registrationNumber: v.registrationNumber,
    vehicleType: v.vehicleType,
    vehicleTypeId: normalizeVehicleType(v.vehicleType),
    vehicleTypeLabel: vehicleTypeLabel(normalizeVehicleType(v.vehicleType)),
    make: v.make,
    model: v.model,
    year: v.year,
    color: v.color,
    capacity: v.capacity,
    hasOxygen: Boolean(v.hasOxygen),
    hasVentilator: Boolean(v.hasVentilator),
    hasDefibrillator: Boolean(v.hasDefibrillator),
    hasStretcher: Boolean(v.hasStretcher),
    hasAed: Boolean(v.hasAed),
    hasCardiacMonitor: Boolean(v.hasCardiacMonitor),
    hasWheelchair: Boolean(v.hasWheelchair),
    hasIcuCapability: Boolean(v.hasIcuCapability),
    hasNeonatalCapability: Boolean(v.hasNeonatalCapability),
    hasMedicalAttendant: Boolean(v.hasMedicalAttendant),
    equipment: v.equipment || [],
    status: v.status || 'OFFLINE',
    assignedDriverId: v.assignedDriverId || null,
    currentBookingId: v.currentBookingId || null,
    currentLatitude: v.currentLatitude != null ? Number(v.currentLatitude) : null,
    currentLongitude: v.currentLongitude != null ? Number(v.currentLongitude) : null,
    lastLocationAt: v.lastLocationAt || null,
    serviceRadiusKm: v.serviceRadiusKm != null ? Number(v.serviceRadiusKm) : null,
    rcBookUrl: v.rcBookUrl,
    insuranceUrl: v.insuranceUrl,
    fitnessCertificateUrl: v.fitnessCertificateUrl,
    pollutionCertificateUrl: v.pollutionCertificateUrl,
    photoFrontUrl: v.photoFrontUrl,
    photoBackUrl: v.photoBackUrl,
    photoInteriorUrl: v.photoInteriorUrl,
  };
}

function toDriver(d, { includeSecrets = false } = {}) {
  if (!d) return null;
  return {
    id: d.id,
    fullName: d.fullName,
    mobileNumber: d.mobileNumber,
    email: d.email,
    dateOfBirth: d.dateOfBirth,
    drivingLicenseNumber: d.drivingLicenseNumber,
    drivingLicenseExpiry: d.drivingLicenseExpiry,
    emtCertificationNumber: d.emtCertificationNumber,
    emtCertificationExpiry: d.emtCertificationExpiry,
    assignedVehicleId: d.assignedVehicleId,
    governmentIdUrl: d.governmentIdUrl,
    drivingLicenseUrl: d.drivingLicenseUrl,
    emtCertificateUrl: d.emtCertificateUrl,
    photoUrl: d.photoUrl,
    backgroundCheckConsent: Boolean(d.backgroundCheckConsent),
    status: d.status || 'OFFLINE',
    verificationStatus: d.verificationStatus || 'pending',
    emergencyContactName: d.emergencyContactName || null,
    emergencyContactPhone: d.emergencyContactPhone || null,
    isOnline: Boolean(d.isOnline),
    hasPin: Boolean(d.pinHash),
    currentLatitude: d.currentLatitude != null ? Number(d.currentLatitude) : null,
    currentLongitude: d.currentLongitude != null ? Number(d.currentLongitude) : null,
    lastLocationAt: d.lastLocationAt || null,
    lastOnlineAt: d.lastOnlineAt || null,
    currentBookingId: d.currentBookingId || null,
    pinHash: includeSecrets ? d.pinHash : undefined,
  };
}

function toAmbulance(doc, { includeFleetSecrets = false } = {}) {
  if (!doc) return null;
  const d = doc.toObject ? doc.toObject() : doc;
  return {
    id: d.id,
    serviceName: d.serviceName,
    ownerName: d.ownerName,
    email: d.email,
    mobileNumber: d.mobileNumber,
    countryCode: d.countryCode || '91',
    profilePicture: d.profilePicture,
    emergencyContact: d.emergencyContact,
    licenseNumber: d.licenseNumber,
    registrationNumber: d.registrationNumber,
    panNumber: d.panNumber,
    gstNumber: d.gstNumber,
    companyRegistrationNumber: d.companyRegistrationNumber,
    vehicleCount: d.vehicleCount,
    vehicleTypes: d.vehicleTypes || [],
    vehicles: (d.vehicles || []).map((v) => toVehicle(v)).filter(Boolean),
    drivers: (d.drivers || [])
      .map((driver) => toDriver(driver, { includeSecrets: includeFleetSecrets }))
      .filter(Boolean),
    address: d.address,
    city: d.city,
    state: d.state,
    pincode: d.pincode,
    latitude: d.latitude,
    longitude: d.longitude,
    serviceArea: d.serviceArea,
    serviceRadiusKm: d.serviceRadiusKm != null ? Number(d.serviceRadiusKm) : 15,
    supportedCities: d.supportedCities || [],
    available24x7: Boolean(d.available24x7),
    emergencyAvailable: d.emergencyAvailable !== false,
    operatingHoursStart: d.operatingHoursStart || '00:00',
    operatingHoursEnd: d.operatingHoursEnd || '23:59',
    cashPaymentEnabled: d.cashPaymentEnabled !== false,
    isDisabled: Boolean(d.isDisabled),
    isSuspended: Boolean(d.isSuspended),
    ratingAverage: Number(d.ratingAverage || 0),
    reviewCount: Number(d.reviewCount || 0),
    serviceLicenseUrl: d.serviceLicenseUrl,
    companyRegistrationUrl: d.companyRegistrationUrl,
    gstCertificateUrl: d.gstCertificateUrl,
    fleetInsuranceUrl: d.fleetInsuranceUrl,
    bankAccountHolderName: d.bankAccountHolderName,
    bankAccountNumber: d.bankAccountNumber,
    ifscCode: d.ifscCode,
    bankName: d.bankName,
    cancelledChequeUrl: d.cancelledChequeUrl,
    verificationStatus: normalizeVerificationStatus(d.verificationStatus),
    rejectionReason: d.rejectionReason,
    isApproved: Boolean(d.isApproved),
    approvalNotes: d.approvalNotes,
    createdAt: d.createdAt,
    updatedAt: d.updatedAt,
  };
}

function toAmbulancePublic(doc) {
  const full = toAmbulance(doc);
  if (!full) return null;
  return {
    ...full,
    drivers: (full.drivers || []).map((driver) => ({
      id: driver.id,
      fullName: driver.fullName,
      photoUrl: driver.photoUrl,
      verificationStatus: driver.verificationStatus,
      status: driver.status,
    })),
    bankAccountNumber: undefined,
    ifscCode: undefined,
    cancelledChequeUrl: undefined,
  };
}

function toAmbulanceBooking(doc) {
  if (!doc) return null;
  const d = doc.toObject ? doc.toObject() : doc;
  const status = d.status;
  return {
    id: d.id,
    ambulanceId: d.ambulanceId || null,
    ambulanceServiceName: d.ambulanceServiceName,
    patientId: d.patientId,
    patientName: d.patientName,
    patientMobile: d.patientMobile,
    patientEmail: d.patientEmail,
    patientAge: d.patientAge ?? null,
    patientGender: d.patientGender || null,
    patientCondition: d.patientCondition || null,
    consciousState: d.consciousState || 'unknown',
    emergencyCategory: d.emergencyCategory || null,
    contactPerson: d.contactPerson || null,
    contactPhone: d.contactPhone || null,
    pickupAddress: d.pickupAddress,
    pickupCity: d.pickupCity,
    pickupPincode: d.pickupPincode,
    pickupLatitude: d.pickupLatitude != null ? Number(d.pickupLatitude) : null,
    pickupLongitude: d.pickupLongitude != null ? Number(d.pickupLongitude) : null,
    dropAddress: d.dropAddress,
    dropCity: d.dropCity || null,
    dropLatitude: d.dropLatitude != null ? Number(d.dropLatitude) : null,
    dropLongitude: d.dropLongitude != null ? Number(d.dropLongitude) : null,
    destinationType: d.destinationType || 'other',
    destinationHospitalName: d.destinationHospitalName || null,
    destinationHospitalId: d.destinationHospitalId || null,
    notes: d.notes,
    vehicleTypeRequested: d.vehicleTypeRequested,
    requirements: d.requirements || {},
    bookingKind: d.bookingKind || (d.isEmergency === false ? 'scheduled' : 'emergency'),
    scheduledAt: d.scheduledAt || null,
    isEmergency: d.isEmergency !== false,
    status,
    canonicalStatus: canonicalStatus(status),
    statusLabel: userFacingLabel(status),
    rejectionReason: d.rejectionReason,
    cancelReason: d.cancelReason || null,
    cancelledBy: d.cancelledBy || null,
    estimatedArrivalMinutes: d.estimatedArrivalMinutes,
    assignedVehicleId: d.assignedVehicleId || null,
    assignedDriverId: d.assignedDriverId || null,
    assignedDriverName: d.assignedDriverName || null,
    assignedVehicleRegistration: d.assignedVehicleRegistration || null,
    assignedVehicleType: d.assignedVehicleType || null,
    currentDispatchId: d.currentDispatchId || null,
    dispatchRound: d.dispatchRound || 0,
    searchRadiusKm: d.searchRadiusKm || null,
    liveLatitude: d.liveLatitude != null ? Number(d.liveLatitude) : null,
    liveLongitude: d.liveLongitude != null ? Number(d.liveLongitude) : null,
    liveAccuracy: d.liveAccuracy != null ? Number(d.liveAccuracy) : null,
    liveHeading: d.liveHeading != null ? Number(d.liveHeading) : null,
    liveSpeed: d.liveSpeed != null ? Number(d.liveSpeed) : null,
    liveLocationUpdatedAt: d.liveLocationUpdatedAt || null,
    locationUnavailable: Boolean(d.locationUnavailable),
    pickupTime: d.pickupTime || null,
    patientPickedUpAt: d.patientPickedUpAt || null,
    destinationArrivalAt: d.destinationArrivalAt || null,
    completedAt: d.completedAt || null,
    tripDistanceKm: d.tripDistanceKm != null ? Number(d.tripDistanceKm) : null,
    tripDurationMinutes: d.tripDurationMinutes != null ? Number(d.tripDurationMinutes) : null,
    tripNotes: d.tripNotes || null,
    fare: d.fare || null,
    paymentStatus: d.paymentStatus || 'unpaid',
    paymentMethod: d.paymentMethod || 'online',
    paymentPolicy: d.paymentPolicy || null,
    timeline: timelineFor(status),
    createdAt: d.createdAt,
    updatedAt: d.updatedAt,
  };
}

module.exports = { toAmbulance, toAmbulancePublic, toVehicle, toDriver, toAmbulanceBooking };
