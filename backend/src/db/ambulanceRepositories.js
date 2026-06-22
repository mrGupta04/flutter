const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const Ambulance = require('./models/Ambulance');
const { toAmbulance } = require('./ambulanceMappers');
const {
  findDocumentsByAmbulanceId,
  assertAmbulanceDocumentsVerified,
} = require('./documentVerification');

function escapeRegex(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

async function findAmbulanceById(id) {
  const doc = await Ambulance.findOne({ id });
  return toAmbulance(doc);
}

async function findAmbulanceByEmail(email, excludeId = '') {
  const query = { email };
  if (excludeId) query.id = { $ne: excludeId };
  return Ambulance.findOne(query);
}

async function ensureAmbulanceStub(ambulanceId, mobileNumber) {
  const existing = await Ambulance.findOne({ id: ambulanceId });
  if (existing) return toAmbulance(existing);

  const doc = await Ambulance.create({
    id: ambulanceId,
    mobileNumber: mobileNumber || null,
    verificationStatus: 'pending',
  });
  return toAmbulance(doc);
}

async function updateAmbulanceProfilePicture(id, profilePicture) {
  await Ambulance.updateOne({ id }, { $set: { profilePicture } });
  return findAmbulanceById(id);
}

async function upsertAmbulance(data) {
  const id = data.id || uuidv4();
  const existing = await Ambulance.findOne({ id });

  let passwordHash = existing?.passwordHash;
  if (data.password) {
    passwordHash = bcrypt.hashSync(data.password, 10);
  }

  const vehicles = data.vehicles ?? existing?.vehicles ?? [];
  const drivers = data.drivers ?? existing?.drivers ?? [];
  const derivedVehicleTypes = vehicles.length
    ? [...new Set(vehicles.map((v) => v.vehicleType).filter(Boolean))]
    : data.vehicleTypes ?? existing?.vehicleTypes ?? [];

  const payload = {
    id,
    passwordHash,
    serviceName: data.serviceName ?? existing?.serviceName,
    ownerName: data.ownerName ?? existing?.ownerName,
    email: data.email ?? existing?.email,
    mobileNumber: data.mobileNumber ?? existing?.mobileNumber,
    countryCode: data.countryCode ?? existing?.countryCode ?? '91',
    profilePicture: data.profilePicture ?? existing?.profilePicture,
    emergencyContact: data.emergencyContact ?? existing?.emergencyContact,
    licenseNumber: data.licenseNumber ?? existing?.licenseNumber,
    registrationNumber: data.registrationNumber ?? existing?.registrationNumber,
    panNumber: data.panNumber ?? existing?.panNumber,
    gstNumber: data.gstNumber ?? existing?.gstNumber,
    companyRegistrationNumber:
      data.companyRegistrationNumber ?? existing?.companyRegistrationNumber,
    vehicleCount:
      (vehicles.length || data.vehicleCount) ?? existing?.vehicleCount,
    vehicleTypes: derivedVehicleTypes,
    vehicles,
    drivers,
    address: data.address ?? existing?.address,
    city: data.city ?? existing?.city,
    state: data.state ?? existing?.state,
    pincode: data.pincode ?? existing?.pincode,
    latitude: data.latitude ?? existing?.latitude,
    longitude: data.longitude ?? existing?.longitude,
    serviceArea: data.serviceArea ?? existing?.serviceArea,
    available24x7: data.available24x7 ?? existing?.available24x7 ?? false,
    serviceLicenseUrl: data.serviceLicenseUrl ?? existing?.serviceLicenseUrl,
    companyRegistrationUrl:
      data.companyRegistrationUrl ?? existing?.companyRegistrationUrl,
    gstCertificateUrl: data.gstCertificateUrl ?? existing?.gstCertificateUrl,
    fleetInsuranceUrl: data.fleetInsuranceUrl ?? existing?.fleetInsuranceUrl,
    bankAccountHolderName:
      data.bankAccountHolderName ?? existing?.bankAccountHolderName,
    bankAccountNumber: data.bankAccountNumber ?? existing?.bankAccountNumber,
    ifscCode: data.ifscCode ?? existing?.ifscCode,
    bankName: data.bankName ?? existing?.bankName,
    cancelledChequeUrl: data.cancelledChequeUrl ?? existing?.cancelledChequeUrl,
    verificationStatus: (() => {
      const current = existing?.verificationStatus || 'pending';
      if (current === 'verified' || current === 'rejected') return current;
      if (current === 'verifier_approved') return 'under_review';
      const isComplete =
        (data.serviceName ?? existing?.serviceName) &&
        (data.email ?? existing?.email) &&
        (data.licenseNumber ?? existing?.licenseNumber);
      if (isComplete && current === 'pending') return 'under_review';
      return current;
    })(),
  };

  if (existing) {
    await Ambulance.updateOne({ id }, { $set: payload });
  } else {
    await Ambulance.create(payload);
  }

  return findAmbulanceById(id);
}

async function listAmbulances({
  status,
  page = 1,
  pageSize = 20,
  search,
  city,
  available24x7,
  vehicleType,
}) {
  const filter = {};
  if (status === 'awaiting_review') {
    filter.verificationStatus = {
      $in: ['pending', 'under_review', 'verifier_approved'],
    };
  } else if (status) {
    filter.verificationStatus = status;
  }
  if (city?.trim()) {
    filter.city = new RegExp(escapeRegex(city.trim()), 'i');
  }
  if (available24x7 === true || available24x7 === 'true') {
    filter.available24x7 = true;
  }
  if (vehicleType?.trim()) {
    filter.vehicleTypes = new RegExp(escapeRegex(vehicleType.trim()), 'i');
  }
  if (search?.trim()) {
    const regex = new RegExp(escapeRegex(search.trim()), 'i');
    filter.$or = [
      { serviceName: regex },
      { ownerName: regex },
      { email: regex },
      { mobileNumber: regex },
      { city: regex },
      { state: regex },
      { pincode: regex },
      { address: regex },
      { serviceArea: regex },
      { licenseNumber: regex },
      { registrationNumber: regex },
      { vehicleTypes: regex },
    ];
  }

  const totalCount = await Ambulance.countDocuments(filter);
  const totalPages = Math.max(1, Math.ceil(totalCount / pageSize));
  const skip = (page - 1) * pageSize;

  const docs = await Ambulance.find(filter)
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(pageSize);

  return {
    ambulances: docs.map(toAmbulance),
    pagination: {
      currentPage: page,
      totalPages,
      pageSize,
      totalCount,
      hasNextPage: page < totalPages,
    },
  };
}

async function submitAmbulanceForReview(id) {
  const existing = await Ambulance.findOne({ id });
  if (!existing) return null;
  if (['verified', 'rejected'].includes(existing.verificationStatus)) {
    return findAmbulanceById(id);
  }

  await Ambulance.updateOne(
    { id },
    { $set: { verificationStatus: 'under_review', rejectionReason: null } },
  );
  return findAmbulanceById(id);
}

async function approveAmbulance(id, approvalNotes) {
  const existing = await Ambulance.findOne({ id });
  if (!existing) return null;
  const approvable = ['pending', 'under_review', 'verifier_approved'];
  if (!approvable.includes(existing.verificationStatus)) {
    const err = new Error(
      `Cannot approve ambulance with status "${existing.verificationStatus}"`,
    );
    err.statusCode = 400;
    throw err;
  }

  await assertAmbulanceDocumentsVerified(toAmbulance(existing));

  await Ambulance.updateOne(
    { id },
    {
      $set: {
        verificationStatus: 'verified',
        isApproved: true,
        approvalNotes: approvalNotes || null,
        rejectionReason: null,
      },
    },
  );
  return findAmbulanceById(id);
}

const SERVICE_DOC_FIELDS = {
  serviceLicense: 'serviceLicenseUrl',
  companyRegistration: 'companyRegistrationUrl',
  gstCertificate: 'gstCertificateUrl',
  fleetInsurance: 'fleetInsuranceUrl',
  cancelledCheque: 'cancelledChequeUrl',
};

const VEHICLE_DOC_FIELDS = {
  rcBook: 'rcBookUrl',
  insurance: 'insuranceUrl',
  fitnessCertificate: 'fitnessCertificateUrl',
  pollutionCertificate: 'pollutionCertificateUrl',
  photoFront: 'photoFrontUrl',
  photoBack: 'photoBackUrl',
  photoInterior: 'photoInteriorUrl',
};

const DRIVER_DOC_FIELDS = {
  governmentId: 'governmentIdUrl',
  drivingLicense: 'drivingLicenseUrl',
  emtCertificate: 'emtCertificateUrl',
  photo: 'photoUrl',
};

async function updateAmbulanceDocumentUrl(ambulanceId, documentType, fileUrl) {
  const field = SERVICE_DOC_FIELDS[documentType];
  if (!field) return null;
  await Ambulance.updateOne({ id: ambulanceId }, { $set: { [field]: fileUrl } });
  return findAmbulanceById(ambulanceId);
}

async function updateVehicleDocumentUrl(
  ambulanceId,
  vehicleId,
  documentType,
  fileUrl,
) {
  const field = VEHICLE_DOC_FIELDS[documentType];
  if (!field) return null;

  const doc = await Ambulance.findOne({ id: ambulanceId });
  if (!doc) return null;

  const vehicles = (doc.vehicles || []).map((v) => {
    const vehicle = v.toObject ? v.toObject() : v;
    if (vehicle.id !== vehicleId) return vehicle;
    return { ...vehicle, [field]: fileUrl };
  });

  await Ambulance.updateOne({ id: ambulanceId }, { $set: { vehicles } });
  return findAmbulanceById(ambulanceId);
}

async function updateDriverDocumentUrl(
  ambulanceId,
  driverId,
  documentType,
  fileUrl,
) {
  const field = DRIVER_DOC_FIELDS[documentType];
  if (!field) return null;

  const doc = await Ambulance.findOne({ id: ambulanceId });
  if (!doc) return null;

  const drivers = (doc.drivers || []).map((d) => {
    const driver = d.toObject ? d.toObject() : d;
    if (driver.id !== driverId) return driver;
    return { ...driver, [field]: fileUrl };
  });

  await Ambulance.updateOne({ id: ambulanceId }, { $set: { drivers } });
  return findAmbulanceById(ambulanceId);
}

async function rejectAmbulance(id, rejectionReason) {
  await Ambulance.updateOne(
    { id },
    {
      $set: {
        verificationStatus: 'rejected',
        isApproved: false,
        rejectionReason,
      },
    },
  );
  return findAmbulanceById(id);
}

module.exports = {
  toAmbulance,
  findAmbulanceById,
  findAmbulanceByEmail,
  ensureAmbulanceStub,
  updateAmbulanceProfilePicture,
  updateAmbulanceDocumentUrl,
  updateVehicleDocumentUrl,
  updateDriverDocumentUrl,
  upsertAmbulance,
  listAmbulances,
  submitAmbulanceForReview,
  approveAmbulance,
  rejectAmbulance,
  findDocumentsByAmbulanceId,
};
