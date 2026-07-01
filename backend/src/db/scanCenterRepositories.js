const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const ScanCenter = require('./models/ScanCenter');
const { toScanCenter } = require('./scanCenterMappers');

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

async function findScanCenterById(id) {
  const doc = await ScanCenter.findOne({ id });
  return toScanCenter(doc);
}

async function findScanCenterByEmail(email, excludeId = '') {
  const query = { email };
  if (excludeId) query.id = { $ne: excludeId };
  return ScanCenter.findOne(query);
}

async function ensureScanCenterStub(centerId, mobileNumber) {
  const existing = await ScanCenter.findOne({ id: centerId });
  if (existing) return toScanCenter(existing);

  const doc = await ScanCenter.create({
    id: centerId,
    mobileNumber: mobileNumber || null,
    verificationStatus: 'pending',
  });
  return toScanCenter(doc);
}

async function updateScanCenterProfilePicture(id, profilePicture) {
  await ScanCenter.updateOne({ id }, { $set: { profilePicture } });
  return findScanCenterById(id);
}

async function addScanCenterDocument(id, document) {
  const existing = await ScanCenter.findOne({ id });
  if (!existing) return null;
  const docs = [...(existing.documents || [])];
  const idx = docs.findIndex((d) => d.id === document.id);
  if (idx >= 0) docs[idx] = { ...docs[idx], ...document };
  else docs.push(document);
  await ScanCenter.updateOne({ id }, { $set: { documents: docs } });
  return findScanCenterById(id);
}

async function addScanCenterImage(id, imageUrl) {
  const existing = await ScanCenter.findOne({ id });
  if (!existing) return null;
  const images = [...(existing.centerImages || []), imageUrl];
  await ScanCenter.updateOne({ id }, { $set: { centerImages: images } });
  return findScanCenterById(id);
}

async function upsertScanCenter(data) {
  const id = data.id || uuidv4();
  const existing = await ScanCenter.findOne({ id });

  let passwordHash = existing?.passwordHash;
  if (data.password) {
    passwordHash = bcrypt.hashSync(data.password, 10);
  }

  const payload = {
    id,
    passwordHash,
    centerName: data.centerName ?? existing?.centerName,
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
    operatingHours: data.operatingHours ?? existing?.operatingHours,
    homeVisitAvailable:
      data.homeVisitAvailable ?? existing?.homeVisitAvailable ?? false,
    available24x7: data.available24x7 ?? existing?.available24x7 ?? false,
    cashPaymentEnabled:
      data.cashPaymentEnabled ?? existing?.cashPaymentEnabled ?? true,
    offeredScans: data.offeredScans ?? existing?.offeredScans ?? [],
    offers: data.offers ?? existing?.offers ?? [],
    appointmentSlots: data.appointmentSlots ?? existing?.appointmentSlots ?? [],
    centerImages: data.centerImages ?? existing?.centerImages ?? [],
    documents: data.documents ?? existing?.documents ?? [],
    verificationStatus: (() => {
      const current = existing?.verificationStatus || 'pending';
      if (['verified', 'rejected', 'suspended'].includes(current)) return current;
      if (current === 'verifier_approved') return 'under_review';
      const isComplete =
        (data.centerName ?? existing?.centerName) &&
        (data.email ?? existing?.email) &&
        (data.licenseNumber ?? existing?.licenseNumber);
      if (isComplete && current === 'pending') return 'under_review';
      return current;
    })(),
  };

  if (existing) {
    await ScanCenter.updateOne({ id }, { $set: payload });
  } else {
    await ScanCenter.create(payload);
  }

  return findScanCenterById(id);
}

async function listScanCenters({
  status,
  page = 1,
  pageSize = 20,
  search,
  city,
  scanId,
  categoryId,
  homeVisit,
  hasOffer,
  minPrice,
  maxPrice,
  openNow,
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
  if (scanId?.trim()) {
    filter.offeredScans = {
      $elemMatch: {
        scanId: scanId.trim(),
        enabled: { $ne: false },
      },
    };
  }
  if (categoryId?.trim()) {
    filter.offeredScans = {
      $elemMatch: {
        categoryId: categoryId.trim(),
        enabled: { $ne: false },
      },
    };
  }
  if (homeVisit === true || homeVisit === 'true') {
    filter.homeVisitAvailable = true;
  }
  if (hasOffer === true || hasOffer === 'true') {
    filter.offers = {
      $elemMatch: {
        offerAvailable: true,
        active: { $ne: false },
      },
    };
  }
  if (search?.trim()) {
    const regex = new RegExp(escapeRegex(search.trim()), 'i');
    filter.$or = [
      { centerName: regex },
      { ownerName: regex },
      { email: regex },
      { mobileNumber: regex },
      { city: regex },
      { state: regex },
      { pincode: regex },
      { address: regex },
      { licenseNumber: regex },
      { 'offeredScans.scanName': regex },
    ];
  }

  const totalCount = await ScanCenter.countDocuments(filter);
  const totalPages = Math.max(1, Math.ceil(totalCount / pageSize));
  const skip = (page - 1) * pageSize;

  const docs = await ScanCenter.find(filter)
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(pageSize);

  let centers = docs.map(toScanCenter);

  if (minPrice != null || maxPrice != null) {
    const min = parseInt(minPrice, 10);
    const max = parseInt(maxPrice, 10);
    centers = centers.filter((center) => {
      const prices = (center.offeredScans || [])
        .filter((s) => s.enabled !== false)
        .map((s) => s.discountedPriceInr ?? s.priceInr ?? 0)
        .filter((p) => p > 0);
      if (!prices.length) return false;
      const lowest = Math.min(...prices);
      if (!Number.isNaN(min) && lowest < min) return false;
      if (!Number.isNaN(max) && lowest > max) return false;
      return true;
    });
  }

  if (openNow === true || openNow === 'true') {
    centers = centers.filter((center) => center.available24x7 || center.operatingHours);
  }

  const lat = parseFloat(latitude);
  const lng = parseFloat(longitude);
  if (!Number.isNaN(lat) && !Number.isNaN(lng)) {
    centers = centers
      .map((center) => {
        if (center.latitude == null || center.longitude == null) {
          return { ...center, distanceKm: null };
        }
        const distanceKm = haversineKm(
          lat,
          lng,
          center.latitude,
          center.longitude,
        );
        return { ...center, distanceKm: Math.round(distanceKm * 10) / 10 };
      })
      .sort((a, b) => {
        if (a.distanceKm == null) return 1;
        if (b.distanceKm == null) return -1;
        return a.distanceKm - b.distanceKm;
      });
  }

  return {
    scanCenters: centers,
    pagination: {
      currentPage: page,
      totalPages,
      pageSize,
      totalCount,
      hasNextPage: page < totalPages,
    },
  };
}

async function submitScanCenterForReview(id) {
  const existing = await ScanCenter.findOne({ id });
  if (!existing) return null;
  if (['verified', 'rejected'].includes(existing.verificationStatus)) {
    return findScanCenterById(id);
  }

  await ScanCenter.updateOne(
    { id },
    {
      $set: {
        verificationStatus: 'under_review',
        rejectionReason: null,
        documentRequestNote: null,
      },
    },
  );
  return findScanCenterById(id);
}

async function approveScanCenter(id, approvalNotes) {
  const existing = await ScanCenter.findOne({ id });
  if (!existing) return null;
  const approvable = ['pending', 'under_review', 'verifier_approved'];
  if (!approvable.includes(existing.verificationStatus)) {
    const err = new Error(
      `Cannot approve scan center with status "${existing.verificationStatus}"`,
    );
    err.statusCode = 400;
    throw err;
  }

  await ScanCenter.updateOne(
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
  return findScanCenterById(id);
}

async function rejectScanCenter(id, rejectionReason) {
  await ScanCenter.updateOne(
    { id },
    {
      $set: {
        verificationStatus: 'rejected',
        isApproved: false,
        rejectionReason,
      },
    },
  );
  return findScanCenterById(id);
}

async function suspendScanCenter(id, reason) {
  await ScanCenter.updateOne(
    { id },
    {
      $set: {
        verificationStatus: 'suspended',
        isApproved: false,
        rejectionReason: reason || 'Suspended by admin',
      },
    },
  );
  return findScanCenterById(id);
}

async function requestScanCenterDocuments(id, note) {
  await ScanCenter.updateOne(
    { id },
    {
      $set: {
        verificationStatus: 'under_review',
        documentRequestNote: note,
      },
    },
  );
  return findScanCenterById(id);
}

module.exports = {
  toScanCenter,
  findScanCenterById,
  findScanCenterByEmail,
  ensureScanCenterStub,
  updateScanCenterProfilePicture,
  addScanCenterDocument,
  addScanCenterImage,
  upsertScanCenter,
  listScanCenters,
  submitScanCenterForReview,
  approveScanCenter,
  rejectScanCenter,
  suspendScanCenter,
  requestScanCenterDocuments,
};
