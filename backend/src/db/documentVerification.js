const { v4: uuidv4 } = require('uuid');
const Document = require('./models/Document');
const { toDocument } = require('./mappers');

const DOCTOR_DOC_URL_FIELDS = {
  medical_license: 'medicalLicenseUrl',
  government_id: 'governmentIdUrl',
  degree_certificate: 'degreeCertificateUrl',
  clinic_proof: 'clinicProofUrl',
  cancelled_cheque: 'cancelledChequeUrl',
  aadhaar_card: 'aadhaarCardUrl',
};

const REQUIRED_DOCTOR_DOC_TYPES = [
  'medical_license',
  'aadhaar_card',
  'degree_certificate',
  'clinic_proof',
];

const AMBULANCE_SERVICE_DOC_FIELDS = {
  serviceLicense: 'serviceLicenseUrl',
  companyRegistration: 'companyRegistrationUrl',
  gstCertificate: 'gstCertificateUrl',
  fleetInsurance: 'fleetInsuranceUrl',
  cancelledCheque: 'cancelledChequeUrl',
};

const AMBULANCE_VEHICLE_DOC_FIELDS = {
  rcBook: 'rcBookUrl',
  insurance: 'insuranceUrl',
  fitnessCertificate: 'fitnessCertificateUrl',
  pollutionCertificate: 'pollutionCertificateUrl',
  photoFront: 'photoFrontUrl',
  photoBack: 'photoBackUrl',
  photoInterior: 'photoInteriorUrl',
};

const AMBULANCE_DRIVER_DOC_FIELDS = {
  governmentId: 'governmentIdUrl',
  drivingLicense: 'drivingLicenseUrl',
  emtCertificate: 'emtCertificateUrl',
  photo: 'photoUrl',
};

function latestByKey(documents, keyFn) {
  const map = new Map();
  for (const doc of documents) {
    const key = keyFn(doc);
    const existing = map.get(key);
    if (!existing || new Date(doc.uploadedAt) > new Date(existing.uploadedAt)) {
      map.set(key, doc);
    }
  }
  return [...map.values()];
}

async function findDocumentById(documentId) {
  const doc = await Document.findOne({ id: documentId });
  return toDocument(doc);
}

async function findDocumentsByDoctorId(doctorId) {
  const docs = await Document.find({ doctorId }).sort({ uploadedAt: -1 });
  return docs.map(toDocument);
}

async function findDocumentsByNurseId(nurseId) {
  const docs = await Document.find({ nurseId }).sort({ uploadedAt: -1 });
  return docs.map(toDocument);
}

async function findDocumentsByAmbulanceId(ambulanceId) {
  const docs = await Document.find({ ambulanceId }).sort({ uploadedAt: -1 });
  return docs.map(toDocument);
}

async function upsertDocument({
  doctorId,
  nurseId,
  ambulanceId,
  vehicleId,
  driverId,
  documentType,
  fileUrl,
  fileName,
  fileSize,
  mimeType,
}) {
  const query = { documentType };
  if (doctorId) query.doctorId = doctorId;
  if (nurseId) query.nurseId = nurseId;
  if (ambulanceId) {
    query.ambulanceId = ambulanceId;
    query.vehicleId = vehicleId || null;
    query.driverId = driverId || null;
  }

  const existing = await Document.findOne(query).sort({ uploadedAt: -1 });
  if (existing) {
    await Document.updateOne(
      { id: existing.id },
      {
        $set: {
          fileUrl,
          fileName,
          fileSize,
          mimeType,
          status: 'pending',
          rejectionReason: null,
          verifiedAt: null,
          verifiedBy: null,
          uploadedAt: new Date(),
        },
      },
    );
    return findDocumentById(existing.id);
  }

  const doc = await Document.create({
    id: uuidv4(),
    doctorId: doctorId || undefined,
    nurseId: nurseId || undefined,
    ambulanceId: ambulanceId || undefined,
    vehicleId: vehicleId || undefined,
    driverId: driverId || undefined,
    documentType,
    fileUrl,
    fileName,
    fileSize,
    mimeType,
    status: 'pending',
  });
  return toDocument(doc);
}

async function verifyDocument(documentId, verifiedBy) {
  const existing = await Document.findOne({ id: documentId });
  if (!existing) {
    const err = new Error('Document not found');
    err.statusCode = 404;
    throw err;
  }

  await Document.updateOne(
    { id: documentId },
    {
      $set: {
        status: 'verified',
        verifiedAt: new Date(),
        verifiedBy: verifiedBy || null,
        rejectionReason: null,
      },
    },
  );
  return findDocumentById(documentId);
}

async function rejectDocument(documentId, rejectionReason, _rejectedBy) {
  const existing = await Document.findOne({ id: documentId });
  if (!existing) {
    const err = new Error('Document not found');
    err.statusCode = 404;
    throw err;
  }

  await Document.updateOne(
    { id: documentId },
    {
      $set: {
        status: 'rejected',
        rejectionReason,
        verifiedAt: null,
        verifiedBy: null,
      },
    },
  );
  return findDocumentById(documentId);
}

function mergeDoctorDocuments(doctor, apiDocs) {
  const byType = new Map();
  for (const doc of apiDocs) {
    if (doc.documentType && doc.fileUrl) {
      byType.set(doc.documentType, doc);
    }
  }

  for (const [type, field] of Object.entries(DOCTOR_DOC_URL_FIELDS)) {
    const url = doctor[field];
    if (url && !byType.has(type)) {
      byType.set(type, {
        doctorId: doctor.id,
        documentType: type,
        fileUrl: url,
        fileName: url.split('/').pop(),
        status: 'pending',
      });
    }
  }

  return [...byType.values()];
}

function collectAmbulanceDocuments(ambulance, apiDocs) {
  const results = [...apiDocs];
  const keyOf = (type, vehicleId, driverId) =>
    `${type}:${vehicleId || ''}:${driverId || ''}`;

  const existingKeys = new Set(
    apiDocs.map((d) => keyOf(d.documentType, d.vehicleId, d.driverId)),
  );

  const addSynthetic = (documentType, fileUrl, vehicleId, driverId) => {
    if (!fileUrl) return;
    const key = keyOf(documentType, vehicleId, driverId);
    if (existingKeys.has(key)) return;
    existingKeys.add(key);
    results.push({
      ambulanceId: ambulance.id,
      documentType,
      fileUrl,
      fileName: fileUrl.split('/').pop(),
      vehicleId: vehicleId || null,
      driverId: driverId || null,
      status: 'pending',
    });
  };

  for (const [type, field] of Object.entries(AMBULANCE_SERVICE_DOC_FIELDS)) {
    addSynthetic(type, ambulance[field]);
  }

  for (const vehicle of ambulance.vehicles || []) {
    for (const [type, field] of Object.entries(AMBULANCE_VEHICLE_DOC_FIELDS)) {
      addSynthetic(type, vehicle[field], vehicle.id);
    }
  }

  for (const driver of ambulance.drivers || []) {
    for (const [type, field] of Object.entries(AMBULANCE_DRIVER_DOC_FIELDS)) {
      addSynthetic(type, driver[field], null, driver.id);
    }
  }

  return results;
}

function validateAllDocumentsVerified(documents, label = 'document') {
  const pending = documents.filter(
    (d) => d.fileUrl && d.status !== 'verified',
  );
  if (pending.length === 0 && documents.length === 0) {
    const err = new Error(`No ${label}s uploaded yet`);
    err.statusCode = 400;
    throw err;
  }
  if (pending.length > 0) {
    const names = pending
      .map((d) => d.documentType)
      .filter(Boolean)
      .join(', ');
    const err = new Error(
      `All documents must be verified before approval. Pending: ${names}`,
    );
    err.statusCode = 400;
    throw err;
  }
}

async function ensureDoctorDocumentsFromProfile(doctor) {
  if (!doctor?.id) return [];
  const existing = await findDocumentsByDoctorId(doctor.id);
  const byType = new Map(
    existing.filter((d) => d.documentType).map((d) => [d.documentType, d]),
  );

  for (const [type, field] of Object.entries(DOCTOR_DOC_URL_FIELDS)) {
    const url = doctor[field];
    if (!url || byType.has(type)) continue;
    const created = await upsertDocument({
      doctorId: doctor.id,
      documentType: type,
      fileUrl: url,
      fileName: url.split('/').pop(),
    });
    byType.set(type, created);
  }

  return [...byType.values()];
}

async function ensureAmbulanceDocumentsFromProfile(ambulance) {
  if (!ambulance?.id) return [];
  const existing = await findDocumentsByAmbulanceId(ambulance.id);
  const merged = collectAmbulanceDocuments(ambulance, existing);
  const results = [...existing];

  for (const item of merged) {
    if (item.id) continue;
    if (!item.fileUrl) continue;
    const created = await upsertDocument({
      ambulanceId: ambulance.id,
      vehicleId: item.vehicleId,
      driverId: item.driverId,
      documentType: item.documentType,
      fileUrl: item.fileUrl,
      fileName: item.fileName,
    });
    results.push(created);
  }

  return results;
}

async function ensureNurseDocumentsFromProfile(nurse) {
  if (!nurse?.id || !nurse.profilePicture) {
    return findDocumentsByNurseId(nurse?.id);
  }
  const existing = await findDocumentsByNurseId(nurse.id);
  if (existing.some((d) => d.documentType === 'profile_picture')) {
    return existing;
  }
  const created = await upsertDocument({
    nurseId: nurse.id,
    documentType: 'profile_picture',
    fileUrl: nurse.profilePicture,
    fileName: nurse.profilePicture.split('/').pop(),
  });
  return [...existing, created];
}

async function assertDoctorDocumentsVerified(doctor) {
  const apiDocs = await findDocumentsByDoctorId(doctor.id);
  const merged = mergeDoctorDocuments(doctor, apiDocs);
  const required = merged.filter((d) =>
    REQUIRED_DOCTOR_DOC_TYPES.includes(d.documentType),
  );
  validateAllDocumentsVerified(required, 'required document');
}

async function assertNurseDocumentsVerified(nurse) {
  const apiDocs = await findDocumentsByNurseId(nurse.id);
  const merged = latestByKey(apiDocs, (d) => d.documentType);
  if (!nurse.profilePicture && merged.length === 0) {
    const err = new Error('Profile picture must be uploaded before approval');
    err.statusCode = 400;
    throw err;
  }
  if (merged.length === 0 && nurse.profilePicture) {
    merged.push({
      nurseId: nurse.id,
      documentType: 'profile_picture',
      fileUrl: nurse.profilePicture,
      status: 'pending',
    });
  }
  validateAllDocumentsVerified(merged, 'profile document');
}

async function assertAmbulanceDocumentsVerified(ambulance) {
  const apiDocs = await findDocumentsByAmbulanceId(ambulance.id);
  const merged = collectAmbulanceDocuments(ambulance, apiDocs);
  const uploaded = merged.filter((d) => d.fileUrl);
  validateAllDocumentsVerified(uploaded, 'ambulance document');
}

module.exports = {
  DOCTOR_DOC_URL_FIELDS,
  REQUIRED_DOCTOR_DOC_TYPES,
  findDocumentById,
  findDocumentsByDoctorId,
  findDocumentsByNurseId,
  findDocumentsByAmbulanceId,
  upsertDocument,
  verifyDocument,
  rejectDocument,
  mergeDoctorDocuments,
  collectAmbulanceDocuments,
  ensureDoctorDocumentsFromProfile,
  ensureAmbulanceDocumentsFromProfile,
  ensureNurseDocumentsFromProfile,
  assertDoctorDocumentsVerified,
  assertNurseDocumentsVerified,
  assertAmbulanceDocumentsVerified,
};
