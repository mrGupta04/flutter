const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const Nurse = require('./models/Nurse');
const { toNurse } = require('./nurseMappers');
const {
  findDocumentsByNurseId,
  assertNurseDocumentsVerified,
} = require('./documentVerification');

function escapeRegex(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

async function findNurseById(id) {
  const doc = await Nurse.findOne({ id });
  return toNurse(doc);
}

async function findNurseByEmail(email, excludeId = '') {
  const query = { email };
  if (excludeId) query.id = { $ne: excludeId };
  return Nurse.findOne(query);
}

async function ensureNurseStub(nurseId, mobileNumber) {
  const existing = await Nurse.findOne({ id: nurseId });
  if (existing) return toNurse(existing);

  const doc = await Nurse.create({
    id: nurseId,
    mobileNumber: mobileNumber || null,
    verificationStatus: 'pending',
  });
  return toNurse(doc);
}

async function updateNurseProfilePicture(id, profilePicture) {
  await Nurse.updateOne({ id }, { $set: { profilePicture } });
  return findNurseById(id);
}

async function upsertNurse(data) {
  const id = data.id || uuidv4();
  const existing = await Nurse.findOne({ id });

  let passwordHash = existing?.passwordHash;
  if (data.password) {
    passwordHash = bcrypt.hashSync(data.password, 10);
  }

  const payload = {
    id,
    passwordHash,
    firstName: data.firstName ?? existing?.firstName,
    lastName: data.lastName ?? existing?.lastName,
    email: data.email ?? existing?.email,
    mobileNumber: data.mobileNumber ?? existing?.mobileNumber,
    countryCode: data.countryCode ?? existing?.countryCode ?? '91',
    profilePicture: data.profilePicture ?? existing?.profilePicture,
    qualification: data.qualification ?? existing?.qualification,
    registrationNumber: data.registrationNumber ?? existing?.registrationNumber,
    nursingCouncil: data.nursingCouncil ?? existing?.nursingCouncil,
    yearsOfExperience: data.yearsOfExperience ?? existing?.yearsOfExperience,
    specialization: data.specialization ?? existing?.specialization,
    address: data.address ?? existing?.address,
    city: data.city ?? existing?.city,
    state: data.state ?? existing?.state,
    pincode: data.pincode ?? existing?.pincode,
    latitude: data.latitude ?? existing?.latitude,
    longitude: data.longitude ?? existing?.longitude,
    availableForHomeVisit: data.availableForHomeVisit ?? existing?.availableForHomeVisit ?? true,
    homeVisitFee: data.homeVisitFee ?? existing?.homeVisitFee,
    shiftAvailability: data.shiftAvailability ?? existing?.shiftAvailability,
    bankAccountHolderName: data.bankAccountHolderName ?? existing?.bankAccountHolderName,
    bankAccountNumber: data.bankAccountNumber ?? existing?.bankAccountNumber,
    ifscCode: data.ifscCode ?? existing?.ifscCode,
    bankName: data.bankName ?? existing?.bankName,
    verificationStatus: (() => {
      const current = existing?.verificationStatus || 'pending';
      if (current === 'verified' || current === 'rejected') {
        return current;
      }
      if (current === 'verifier_approved') {
        return 'under_review';
      }
      const isComplete =
        (data.firstName ?? existing?.firstName) &&
        (data.email ?? existing?.email) &&
        (data.qualification ?? existing?.qualification);
      if (isComplete && current === 'pending') {
        return 'under_review';
      }
      return current;
    })(),
  };

  if (existing) {
    await Nurse.updateOne({ id }, { $set: payload });
  } else {
    await Nurse.create(payload);
  }

  return findNurseById(id);
}

async function listNurses({
  status,
  page = 1,
  pageSize = 20,
  search,
  city,
  specialization,
  homeVisit,
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
    filter.specialization = new RegExp(escapeRegex(specialization.trim()), 'i');
  }
  if (homeVisit === true || homeVisit === 'true') {
    filter.availableForHomeVisit = true;
  }
  if (search?.trim()) {
    const regex = new RegExp(escapeRegex(search.trim()), 'i');
    filter.$or = [
      { firstName: regex },
      { lastName: regex },
      { email: regex },
      { mobileNumber: regex },
      { city: regex },
      { state: regex },
      { pincode: regex },
      { address: regex },
      { qualification: regex },
      { specialization: regex },
      { nursingCouncil: regex },
      { registrationNumber: regex },
      { shiftAvailability: regex },
    ];
  }

  const totalCount = await Nurse.countDocuments(filter);
  const totalPages = Math.max(1, Math.ceil(totalCount / pageSize));
  const skip = (page - 1) * pageSize;

  const docs = await Nurse.find(filter)
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(pageSize);

  return {
    nurses: docs.map(toNurse),
    pagination: {
      currentPage: page,
      totalPages,
      pageSize,
      totalCount,
      hasNextPage: page < totalPages,
    },
  };
}

async function submitNurseForReview(id) {
  const existing = await Nurse.findOne({ id });
  if (!existing) return null;
  if (['verified', 'rejected'].includes(existing.verificationStatus)) {
    return findNurseById(id);
  }

  await Nurse.updateOne(
    { id },
    {
      $set: {
        verificationStatus: 'under_review',
        rejectionReason: null,
      },
    },
  );
  return findNurseById(id);
}

async function approveNurse(id, approvalNotes) {
  const existing = await Nurse.findOne({ id });
  if (!existing) return null;
  const approvable = ['pending', 'under_review', 'verifier_approved'];
  if (!approvable.includes(existing.verificationStatus)) {
    const err = new Error(
      `Cannot approve nurse with status "${existing.verificationStatus}"`,
    );
    err.statusCode = 400;
    throw err;
  }

  await assertNurseDocumentsVerified(toNurse(existing));

  await Nurse.updateOne(
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
  return findNurseById(id);
}

async function rejectNurse(id, rejectionReason) {
  await Nurse.updateOne(
    { id },
    {
      $set: {
        verificationStatus: 'rejected',
        isApproved: false,
        rejectionReason,
      },
    },
  );
  return findNurseById(id);
}

module.exports = {
  toNurse,
  findNurseById,
  findNurseByEmail,
  ensureNurseStub,
  updateNurseProfilePicture,
  upsertNurse,
  listNurses,
  submitNurseForReview,
  approveNurse,
  rejectNurse,
  findDocumentsByNurseId,
};
