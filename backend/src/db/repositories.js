const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const Doctor = require('./models/Doctor');
const { toDoctor } = require('./mappers');
const {
  findDocumentsByDoctorId,
  upsertDocument,
  assertDoctorDocumentsVerified,
  assertDocumentNotVerified,
} = require('./documentVerification');

const DOC_URL_FIELDS = {
  medical_license: 'medicalLicenseUrl',
  government_id: 'governmentIdUrl',
  degree_certificate: 'degreeCertificateUrl',
  clinic_proof: 'clinicProofUrl',
  profile_picture: 'profilePicture',
  cancelled_cheque: 'cancelledChequeUrl',
  aadhaar_card: 'aadhaarCardUrl',
  hospital_photo_1: 'hospitalPhoto1Url',
  hospital_photo_2: 'hospitalPhoto2Url',
  hospital_photo_3: 'hospitalPhoto3Url',
  hospital_photo_4: 'hospitalPhoto4Url',
  hospital_photo_5: 'hospitalPhoto5Url',
};

async function findDoctorById(id) {
  const doc = await Doctor.findOne({ id });
  return toDoctor(doc);
}

async function findDoctorByEmail(email, excludeId = '') {
  const query = { email: String(email || '').trim().toLowerCase() };
  if (excludeId) query.id = { $ne: excludeId };
  return Doctor.findOne(query);
}

async function findDoctorByMobile(mobileNumber, excludeId = '') {
  const mobile = String(mobileNumber || '').replace(/\D/g, '').slice(-10);
  if (!mobile) return null;
  const query = { mobileNumber: mobile };
  if (excludeId) query.id = { $ne: excludeId };
  return Doctor.findOne(query);
}

async function ensureDoctorStub(doctorId, mobileNumber) {
  const existing = await Doctor.findOne({ id: doctorId });
  if (existing) return toDoctor(existing);

  const doc = await Doctor.create({
    id: doctorId,
    mobileNumber: mobileNumber || null,
    verificationStatus: 'pending',
  });
  return toDoctor(doc);
}

async function upsertDoctor(data) {
  const id = data.id || uuidv4();
  const existing = await Doctor.findOne({ id });

  for (const [documentType, field] of Object.entries(DOC_URL_FIELDS)) {
    if (!(field in data) || data[field] == null) continue;
    const newUrl = data[field];
    const oldUrl = existing?.[field];
    if (newUrl && newUrl !== oldUrl) {
      await assertDocumentNotVerified({ doctorId: id, documentType });
    }
  }

  let passwordHash = existing?.passwordHash;
  if (data.password) {
    passwordHash = bcrypt.hashSync(data.password, 10);
  }

  const payload = {
    id,
    firstName: data.firstName ?? existing?.firstName,
    lastName: data.lastName ?? existing?.lastName,
    email: data.email
      ? String(data.email).trim().toLowerCase()
      : existing?.email,
    mobileNumber: data.mobileNumber ?? existing?.mobileNumber,
    countryCode: data.countryCode ?? existing?.countryCode ?? '91',
    passwordHash,
    profilePicture: data.profilePicture ?? existing?.profilePicture,
    gender: data.gender ?? existing?.gender,
    dateOfBirth: data.dateOfBirth ?? existing?.dateOfBirth,
    medicalRegistrationNumber:
      data.medicalRegistrationNumber ?? existing?.medicalRegistrationNumber,
    medicalCouncilName: data.medicalCouncilName ?? existing?.medicalCouncilName,
    specializations: data.specializations ?? existing?.specializations ?? [],
    qualification: data.qualification ?? existing?.qualification,
    yearsOfExperience: data.yearsOfExperience ?? existing?.yearsOfExperience,
    clinicName: data.clinicName ?? existing?.clinicName,
    consultationFee: data.consultationFee ?? existing?.consultationFee,
    onlineConsultFee: data.onlineConsultFee ?? existing?.onlineConsultFee,
    homeVisitFee: data.homeVisitFee ?? existing?.homeVisitFee,
    visitSiteFee: data.visitSiteFee ?? existing?.visitSiteFee,
    offersOnlineConsult:
      data.offersOnlineConsult ?? existing?.offersOnlineConsult ?? false,
    offersBookHome: data.offersBookHome ?? existing?.offersBookHome ?? false,
    offersVisitSite: data.offersVisitSite ?? existing?.offersVisitSite ?? false,
    languagesSpoken: data.languagesSpoken ?? existing?.languagesSpoken ?? [],
    bio: data.bio ?? existing?.bio,
    address: data.address ?? existing?.address,
    city: data.city ?? existing?.city,
    state: data.state ?? existing?.state,
    pincode: data.pincode ?? existing?.pincode,
    latitude: data.latitude ?? existing?.latitude,
    longitude: data.longitude ?? existing?.longitude,
    medicalLicenseUrl: data.medicalLicenseUrl ?? existing?.medicalLicenseUrl,
    governmentIdUrl: data.governmentIdUrl ?? existing?.governmentIdUrl,
    degreeCertificateUrl:
      data.degreeCertificateUrl ?? existing?.degreeCertificateUrl,
    clinicProofUrl: data.clinicProofUrl ?? existing?.clinicProofUrl,
    hospitalPhoto1Url: data.hospitalPhoto1Url ?? existing?.hospitalPhoto1Url,
    hospitalPhoto2Url: data.hospitalPhoto2Url ?? existing?.hospitalPhoto2Url,
    hospitalPhoto3Url: data.hospitalPhoto3Url ?? existing?.hospitalPhoto3Url,
    hospitalPhoto4Url: data.hospitalPhoto4Url ?? existing?.hospitalPhoto4Url,
    hospitalPhoto5Url: data.hospitalPhoto5Url ?? existing?.hospitalPhoto5Url,
    bankAccountNumber: data.bankAccountNumber ?? existing?.bankAccountNumber,
    ifscCode: data.ifscCode ?? existing?.ifscCode,
    cancelledChequeUrl: data.cancelledChequeUrl ?? existing?.cancelledChequeUrl,
    payoutMethod: data.payoutMethod ?? existing?.payoutMethod ?? 'bank',
    upiId: data.upiId ?? existing?.upiId,
    aadhaarLast4: data.aadhaarLast4 ?? existing?.aadhaarLast4,
    aadhaarCardUrl: data.aadhaarCardUrl ?? existing?.aadhaarCardUrl,
    verificationStatus: (() => {
      const current = existing?.verificationStatus || 'pending';
      if (current === 'verified' || current === 'rejected') {
        return current;
      }
      if (current === 'verifier_approved') {
        return 'under_review';
      }
      const isCompleteRegistration =
        (data.firstName ?? existing?.firstName) &&
        (data.email ?? existing?.email) &&
        (data.medicalRegistrationNumber ?? existing?.medicalRegistrationNumber);
      if (isCompleteRegistration && current === 'pending') {
        return 'under_review';
      }
      return current;
    })(),
  };

  if (existing) {
    await Doctor.updateOne({ id }, { $set: payload });
  } else {
    await Doctor.create(payload);
  }

  return findDoctorById(id);
}

async function updateDoctorDocumentUrl(doctorId, documentType, url) {
  const field = DOC_URL_FIELDS[documentType];
  if (!field) return;
  await assertDocumentNotVerified({ doctorId, documentType });
  await Doctor.updateOne({ id: doctorId }, { $set: { [field]: url } });
}

async function createDocument(params) {
  return upsertDocument(params);
}

function escapeRegex(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

const CONSULTATION_TYPE_FIELDS = {
  online_consult: 'offersOnlineConsult',
  book_home: 'offersBookHome',
  visit_site: 'offersVisitSite',
};

const CONSULTATION_TYPE_FEE_FIELDS = {
  online_consult: 'onlineConsultFee',
  book_home: 'homeVisitFee',
  visit_site: 'visitSiteFee',
};

function getConsultationFeeForType(doctor, consultationType) {
  if (!doctor) return null;
  const typeField = CONSULTATION_TYPE_FEE_FIELDS[consultationType];
  if (typeField && doctor[typeField] != null && doctor[typeField] >= 1) {
    return doctor[typeField];
  }
  if (doctor.consultationFee != null && doctor.consultationFee >= 1) {
    return doctor.consultationFee;
  }
  return null;
}

function buildDoctorListFilter({
  status,
  search,
  city,
  specialization,
  consultationType,
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

  if (specialization?.trim()) {
    filter.specializations = new RegExp(escapeRegex(specialization.trim()), 'i');
  }

  const consultField = CONSULTATION_TYPE_FIELDS[consultationType];
  if (consultField) {
    filter[consultField] = true;
  }

  if (search?.trim()) {
    const regex = new RegExp(escapeRegex(search.trim()), 'i');
    filter.$or = [
      { firstName: regex },
      { lastName: regex },
      { city: regex },
      { state: regex },
      { pincode: regex },
      { clinicName: regex },
      { qualification: regex },
      { medicalCouncilName: regex },
      { medicalRegistrationNumber: regex },
      { bio: regex },
      { specializations: regex },
      { languagesSpoken: regex },
    ];
  }

  return filter;
}

async function listDoctors({
  status,
  page = 1,
  pageSize = 20,
  search,
  city,
  specialization,
  consultationType,
}) {
  const filter = buildDoctorListFilter({
    status,
    search,
    city,
    specialization,
    consultationType,
  });
  const totalCount = await Doctor.countDocuments(filter);
  const totalPages = Math.max(1, Math.ceil(totalCount / pageSize));
  const skip = (page - 1) * pageSize;

  const docs = await Doctor.find(filter)
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(pageSize);

  return {
    doctors: docs.map(toDoctor),
    pagination: {
      currentPage: page,
      totalPages,
      pageSize,
      totalCount,
      hasNextPage: page < totalPages,
    },
  };
}

async function updateDoctorEmailVerified({ doctorId, email }) {
  const normalizedEmail = String(email || '').trim().toLowerCase();
  const result = await Doctor.updateOne(
    { id: doctorId },
    {
      $set: {
        email: normalizedEmail,
        emailVerified: true,
        emailVerifiedAt: new Date(),
      },
    },
  );
  if (result.matchedCount === 0) {
    throw new Error('Doctor record not found. Please request a new verification code.');
  }
  return findDoctorById(doctorId);
}

async function updateDoctorAadhaarVerified({
  doctorId,
  aadhaarLast4,
  mobileNumber,
}) {
  await Doctor.updateOne(
    { id: doctorId },
    {
      $set: {
        aadhaarLast4,
        aadhaarVerified: true,
        aadhaarVerifiedAt: new Date(),
        ...(mobileNumber ? { mobileNumber } : {}),
      },
    },
  );
  return findDoctorById(doctorId);
}

async function submitDoctorForReview(id) {
  const existing = await Doctor.findOne({ id });
  if (!existing) return null;
  if (['verified', 'rejected'].includes(existing.verificationStatus)) {
    return findDoctorById(id);
  }

  await Doctor.updateOne(
    { id },
    {
      $set: {
        verificationStatus: 'under_review',
        rejectionReason: null,
      },
    },
  );
  return findDoctorById(id);
}

async function approveDoctor(id, approvalNotes) {
  const existing = await Doctor.findOne({ id });
  if (!existing) return null;
  const approvable = ['pending', 'under_review', 'verifier_approved'];
  if (!approvable.includes(existing.verificationStatus)) {
    const err = new Error(
      `Cannot approve doctor with status "${existing.verificationStatus}"`,
    );
    err.statusCode = 400;
    throw err;
  }

  await assertDoctorDocumentsVerified(toDoctor(existing));

  await Doctor.updateOne(
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
  return findDoctorById(id);
}

async function rejectDoctor(id, rejectionReason) {
  await Doctor.updateOne(
    { id },
    {
      $set: {
        verificationStatus: 'rejected',
        isApproved: false,
        rejectionReason,
      },
    },
  );
  return findDoctorById(id);
}

async function countDoctors() {
  return Doctor.countDocuments();
}

async function touchDoctorPresence(doctorId) {
  if (!doctorId) return null;
  await Doctor.updateOne({ id: doctorId }, { $set: { lastActiveAt: new Date() } });
  return findDoctorById(doctorId);
}

async function clearDoctorPresence(doctorId) {
  if (!doctorId) return null;
  await Doctor.updateOne({ id: doctorId }, { $set: { lastActiveAt: null } });
  return findDoctorById(doctorId);
}

module.exports = {
  toDoctor,
  findDoctorById,
  findDoctorByEmail,
  findDoctorByMobile,
  ensureDoctorStub,
  upsertDoctor,
  updateDoctorDocumentUrl,
  createDocument,
  findDocumentsByDoctorId,
  listDoctors,
  updateDoctorEmailVerified,
  updateDoctorAadhaarVerified,
  submitDoctorForReview,
  approveDoctor,
  rejectDoctor,
  countDoctors,
  touchDoctorPresence,
  clearDoctorPresence,
  getConsultationFeeForType,
};
