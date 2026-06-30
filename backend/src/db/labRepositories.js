const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const Lab = require('./models/Lab');
const { toLab } = require('./labMappers');

function escapeRegex(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function haversineKm(lat1, lon1, lat2, lon2) {
  const toRad = (deg) => (deg * Math.PI) / 180;
  const R = 6371;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

async function findLabById(id) {
  const doc = await Lab.findOne({ id });
  return toLab(doc);
}

async function findLabByEmail(email, excludeId = '') {
  const query = { email };
  if (excludeId) query.id = { $ne: excludeId };
  return Lab.findOne(query);
}

async function ensureLabStub(labId, mobileNumber) {
  const existing = await Lab.findOne({ id: labId });
  if (existing) return toLab(existing);

  const doc = await Lab.create({
    id: labId,
    mobileNumber: mobileNumber || null,
    verificationStatus: 'pending',
  });
  return toLab(doc);
}

async function updateLabProfilePicture(id, profilePicture) {
  await Lab.updateOne({ id }, { $set: { profilePicture } });
  return findLabById(id);
}

async function addLabDocument(id, document) {
  const existing = await Lab.findOne({ id });
  if (!existing) return null;
  const docs = [...(existing.documents || [])];
  const idx = docs.findIndex((d) => d.id === document.id);
  if (idx >= 0) docs[idx] = { ...docs[idx], ...document };
  else docs.push(document);
  await Lab.updateOne({ id }, { $set: { documents: docs } });
  return findLabById(id);
}

async function addLabImage(id, imageUrl) {
  const existing = await Lab.findOne({ id });
  if (!existing) return null;
  const images = [...(existing.labImages || []), imageUrl];
  await Lab.updateOne({ id }, { $set: { labImages: images } });
  return findLabById(id);
}

async function upsertLab(data) {
  const id = data.id || uuidv4();
  const existing = await Lab.findOne({ id });

  let passwordHash = existing?.passwordHash;
  if (data.password) {
    passwordHash = bcrypt.hashSync(data.password, 10);
  }

  const payload = {
    id,
    passwordHash,
    labName: data.labName ?? existing?.labName,
    ownerName: data.ownerName ?? existing?.ownerName,
    email: data.email ?? existing?.email,
    mobileNumber: data.mobileNumber ?? existing?.mobileNumber,
    countryCode: data.countryCode ?? existing?.countryCode ?? '91',
    profilePicture: data.profilePicture ?? existing?.profilePicture,
    address: data.address ?? existing?.address,
    city: data.city ?? existing?.city,
    state: data.state ?? existing?.state,
    pincode: data.pincode ?? existing?.pincode,
    latitude: data.latitude ?? existing?.latitude,
    longitude: data.longitude ?? existing?.longitude,
    gstNumber: data.gstNumber ?? existing?.gstNumber,
    licenseNumber: data.licenseNumber ?? existing?.licenseNumber,
    accreditation: data.accreditation ?? existing?.accreditation,
    operatingHours: data.operatingHours ?? existing?.operatingHours,
    homeCollectionAvailable:
      data.homeCollectionAvailable ?? existing?.homeCollectionAvailable ?? false,
    available24x7: data.available24x7 ?? existing?.available24x7 ?? false,
    offeredTests: data.offeredTests ?? existing?.offeredTests ?? [],
    branches: data.branches ?? existing?.branches ?? [],
    serviceablePincodes:
      data.serviceablePincodes ?? existing?.serviceablePincodes ?? [],
    homeVisitSlots: data.homeVisitSlots ?? existing?.homeVisitSlots ?? [],
    labImages: data.labImages ?? existing?.labImages ?? [],
    documents: data.documents ?? existing?.documents ?? [],
    verificationStatus: (() => {
      const current = existing?.verificationStatus || 'pending';
      if (['verified', 'rejected', 'suspended'].includes(current)) return current;
      if (current === 'verifier_approved') return 'under_review';
      const isComplete =
        (data.labName ?? existing?.labName) &&
        (data.email ?? existing?.email) &&
        (data.licenseNumber ?? existing?.licenseNumber);
      if (isComplete && current === 'pending') return 'under_review';
      return current;
    })(),
  };

  if (existing) {
    await Lab.updateOne({ id }, { $set: payload });
  } else {
    await Lab.create(payload);
  }

  return findLabById(id);
}

async function listLabs({
  status,
  page = 1,
  pageSize = 20,
  search,
  city,
  testId,
  homeCollection,
  latitude,
  longitude,
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
  if (testId?.trim()) {
    filter.offeredTests = {
      $elemMatch: {
        testId: testId.trim(),
        enabled: { $ne: false },
      },
    };
  }
  if (homeCollection === true || homeCollection === 'true') {
    filter.homeCollectionAvailable = true;
  }
  if (search?.trim()) {
    const regex = new RegExp(escapeRegex(search.trim()), 'i');
    filter.$or = [
      { labName: regex },
      { ownerName: regex },
      { email: regex },
      { mobileNumber: regex },
      { city: regex },
      { state: regex },
      { pincode: regex },
      { address: regex },
      { licenseNumber: regex },
      { accreditation: regex },
      { 'offeredTests.testName': regex },
    ];
  }

  const totalCount = await Lab.countDocuments(filter);
  const totalPages = Math.max(1, Math.ceil(totalCount / pageSize));
  const skip = (page - 1) * pageSize;

  const docs = await Lab.find(filter)
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(pageSize);

  let labs = docs.map(toLab);

  const lat = parseFloat(latitude);
  const lng = parseFloat(longitude);
  if (!Number.isNaN(lat) && !Number.isNaN(lng)) {
    labs = labs
      .map((lab) => {
        if (lab.latitude == null || lab.longitude == null) {
          return { ...lab, distanceKm: null };
        }
        const distanceKm = haversineKm(
          lat,
          lng,
          lab.latitude,
          lab.longitude,
        );
        return { ...lab, distanceKm: Math.round(distanceKm * 10) / 10 };
      })
      .sort((a, b) => {
        if (a.distanceKm == null) return 1;
        if (b.distanceKm == null) return -1;
        return a.distanceKm - b.distanceKm;
      });
  }

  return {
    labs,
    pagination: {
      currentPage: page,
      totalPages,
      pageSize,
      totalCount,
      hasNextPage: page < totalPages,
    },
  };
}

async function submitLabForReview(id) {
  const existing = await Lab.findOne({ id });
  if (!existing) return null;
  if (['verified', 'rejected'].includes(existing.verificationStatus)) {
    return findLabById(id);
  }

  await Lab.updateOne(
    { id },
    {
      $set: {
        verificationStatus: 'under_review',
        rejectionReason: null,
        documentRequestNote: null,
      },
    },
  );
  return findLabById(id);
}

async function approveLab(id, approvalNotes) {
  const existing = await Lab.findOne({ id });
  if (!existing) return null;
  const approvable = ['pending', 'under_review', 'verifier_approved'];
  if (!approvable.includes(existing.verificationStatus)) {
    const err = new Error(
      `Cannot approve lab with status "${existing.verificationStatus}"`,
    );
    err.statusCode = 400;
    throw err;
  }

  await Lab.updateOne(
    { id },
    {
      $set: {
        verificationStatus: 'verified',
        isApproved: true,
        approvalNotes: approvalNotes || null,
        rejectionReason: null,
        documentRequestNote: null,
      },
    },
  );
  return findLabById(id);
}

async function rejectLab(id, rejectionReason) {
  await Lab.updateOne(
    { id },
    {
      $set: {
        verificationStatus: 'rejected',
        isApproved: false,
        rejectionReason,
      },
    },
  );
  return findLabById(id);
}

async function suspendLab(id, reason) {
  await Lab.updateOne(
    { id },
    {
      $set: {
        verificationStatus: 'suspended',
        isApproved: false,
        rejectionReason: reason || 'Suspended by admin',
      },
    },
  );
  return findLabById(id);
}

async function requestLabDocuments(id, note) {
  await Lab.updateOne(
    { id },
    {
      $set: {
        verificationStatus: 'under_review',
        documentRequestNote: note,
      },
    },
  );
  return findLabById(id);
}

module.exports = {
  toLab,
  findLabById,
  findLabByEmail,
  ensureLabStub,
  updateLabProfilePicture,
  addLabDocument,
  addLabImage,
  upsertLab,
  listLabs,
  submitLabForReview,
  approveLab,
  rejectLab,
  suspendLab,
  requestLabDocuments,
};
