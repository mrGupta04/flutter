const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const BloodBank = require('./models/BloodBank');
const { toBloodBank } = require('./bloodBankMappers');

function escapeRegex(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

async function findBloodBankById(id) {
  const doc = await BloodBank.findOne({ id });
  return toBloodBank(doc);
}

async function findBloodBankByEmail(email, excludeId = '') {
  const query = { email };
  if (excludeId) query.id = { $ne: excludeId };
  return BloodBank.findOne(query);
}

async function ensureBloodBankStub(bloodBankId, mobileNumber) {
  const existing = await BloodBank.findOne({ id: bloodBankId });
  if (existing) return toBloodBank(existing);

  const doc = await BloodBank.create({
    id: bloodBankId,
    mobileNumber: mobileNumber || null,
    verificationStatus: 'pending',
  });
  return toBloodBank(doc);
}

async function updateBloodBankProfilePicture(id, profilePicture) {
  await BloodBank.updateOne({ id }, { $set: { profilePicture } });
  return findBloodBankById(id);
}

async function upsertBloodBank(data) {
  const id = data.id || uuidv4();
  const existing = await BloodBank.findOne({ id });

  let passwordHash = existing?.passwordHash;
  if (data.password) {
    passwordHash = bcrypt.hashSync(data.password, 10);
  }

  const payload = {
    id,
    passwordHash,
    institutionName: data.institutionName ?? existing?.institutionName,
    licenseNumber: data.licenseNumber ?? existing?.licenseNumber,
    contactPerson: data.contactPerson ?? existing?.contactPerson,
    email: data.email ?? existing?.email,
    mobileNumber: data.mobileNumber ?? existing?.mobileNumber,
    countryCode: data.countryCode ?? existing?.countryCode ?? '91',
    profilePicture: data.profilePicture ?? existing?.profilePicture,
    emergencyContact: data.emergencyContact ?? existing?.emergencyContact,
    address: data.address ?? existing?.address,
    city: data.city ?? existing?.city,
    state: data.state ?? existing?.state,
    pincode: data.pincode ?? existing?.pincode,
    latitude: data.latitude ?? existing?.latitude,
    longitude: data.longitude ?? existing?.longitude,
    bloodGroupsAvailable: data.bloodGroupsAvailable ?? existing?.bloodGroupsAvailable ?? [],
    hasApheresis: data.hasApheresis ?? existing?.hasApheresis ?? false,
    hasComponentSeparation: data.hasComponentSeparation ?? existing?.hasComponentSeparation ?? false,
    available24x7: data.available24x7 ?? existing?.available24x7 ?? false,
    verificationStatus: (() => {
      const current = existing?.verificationStatus || 'pending';
      if (current === 'verified' || current === 'rejected') return current;
      if (current === 'verifier_approved') return 'under_review';
      const isComplete =
        (data.institutionName ?? existing?.institutionName) &&
        (data.email ?? existing?.email) &&
        (data.licenseNumber ?? existing?.licenseNumber);
      if (isComplete && current === 'pending') return 'under_review';
      return current;
    })(),
  };

  if (existing) {
    await BloodBank.updateOne({ id }, { $set: payload });
  } else {
    await BloodBank.create(payload);
  }

  return findBloodBankById(id);
}

async function listBloodBanks({
  status,
  page = 1,
  pageSize = 20,
  search,
  city,
  available24x7,
  bloodGroup,
  hasApheresis,
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
  if (bloodGroup?.trim()) {
    const group = bloodGroup.trim().toUpperCase();
    filter.bloodGroupsAvailable = new RegExp(escapeRegex(group), 'i');
  }
  if (hasApheresis === true || hasApheresis === 'true') {
    filter.hasApheresis = true;
  }
  if (search?.trim()) {
    const regex = new RegExp(escapeRegex(search.trim()), 'i');
    filter.$or = [
      { institutionName: regex },
      { contactPerson: regex },
      { email: regex },
      { mobileNumber: regex },
      { city: regex },
      { state: regex },
      { pincode: regex },
      { address: regex },
      { licenseNumber: regex },
      { bloodGroupsAvailable: regex },
    ];
  }

  const totalCount = await BloodBank.countDocuments(filter);
  const totalPages = Math.max(1, Math.ceil(totalCount / pageSize));
  const skip = (page - 1) * pageSize;

  const docs = await BloodBank.find(filter)
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(pageSize);

  return {
    bloodBanks: docs.map(toBloodBank),
    pagination: {
      currentPage: page,
      totalPages,
      pageSize,
      totalCount,
      hasNextPage: page < totalPages,
    },
  };
}

async function submitBloodBankForReview(id) {
  const existing = await BloodBank.findOne({ id });
  if (!existing) return null;
  if (['verified', 'rejected'].includes(existing.verificationStatus)) {
    return findBloodBankById(id);
  }

  await BloodBank.updateOne(
    { id },
    { $set: { verificationStatus: 'under_review', rejectionReason: null } },
  );
  return findBloodBankById(id);
}

async function approveBloodBank(id, approvalNotes) {
  const existing = await BloodBank.findOne({ id });
  if (!existing) return null;
  const approvable = ['pending', 'under_review', 'verifier_approved'];
  if (!approvable.includes(existing.verificationStatus)) {
    const err = new Error(
      `Cannot approve blood bank with status "${existing.verificationStatus}"`,
    );
    err.statusCode = 400;
    throw err;
  }

  await BloodBank.updateOne(
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
  return findBloodBankById(id);
}

async function rejectBloodBank(id, rejectionReason) {
  await BloodBank.updateOne(
    { id },
    {
      $set: {
        verificationStatus: 'rejected',
        isApproved: false,
        rejectionReason,
      },
    },
  );
  return findBloodBankById(id);
}

module.exports = {
  toBloodBank,
  findBloodBankById,
  findBloodBankByEmail,
  ensureBloodBankStub,
  updateBloodBankProfilePicture,
  upsertBloodBank,
  listBloodBanks,
  submitBloodBankForReview,
  approveBloodBank,
  rejectBloodBank,
};
