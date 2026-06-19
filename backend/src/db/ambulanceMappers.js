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
    rcBookUrl: v.rcBookUrl,
    insuranceUrl: v.insuranceUrl,
    fitnessCertificateUrl: v.fitnessCertificateUrl,
    pollutionCertificateUrl: v.pollutionCertificateUrl,
    photoFrontUrl: v.photoFrontUrl,
    photoBackUrl: v.photoBackUrl,
    photoInteriorUrl: v.photoInteriorUrl,
  };
}

function toDriver(d) {
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
  };
}

function toAmbulance(doc) {
  if (!doc) return null;
  const d = doc.toObject ? doc.toObject() : doc;
  return {
    id: d.id,
    serviceName: d.serviceName,
    ownerName: d.ownerName,
    email: d.email,
    mobileNumber: d.mobileNumber,
    profilePicture: d.profilePicture,
    emergencyContact: d.emergencyContact,
    licenseNumber: d.licenseNumber,
    registrationNumber: d.registrationNumber,
    panNumber: d.panNumber,
    gstNumber: d.gstNumber,
    companyRegistrationNumber: d.companyRegistrationNumber,
    vehicleCount: d.vehicleCount,
    vehicleTypes: d.vehicleTypes || [],
    vehicles: (d.vehicles || []).map(toVehicle).filter(Boolean),
    drivers: (d.drivers || []).map(toDriver).filter(Boolean),
    address: d.address,
    city: d.city,
    state: d.state,
    pincode: d.pincode,
    latitude: d.latitude,
    longitude: d.longitude,
    serviceArea: d.serviceArea,
    available24x7: Boolean(d.available24x7),
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

module.exports = { toAmbulance, toVehicle, toDriver };
