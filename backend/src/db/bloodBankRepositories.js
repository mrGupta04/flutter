const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const BloodBank = require('./models/BloodBank');
const { toBloodBank } = require('./bloodBankMappers');

const DEFAULT_BLOOD_GROUPS = [
  'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'Bombay', 'Rare',
];

const DEFAULT_BLOOD_COMPONENTS = [
  { componentId: 'whole_blood', componentName: 'Whole Blood' },
  { componentId: 'packed_rbc', componentName: 'Packed RBC' },
  { componentId: 'platelets', componentName: 'Platelets' },
  { componentId: 'plasma', componentName: 'Plasma' },
  { componentId: 'cryoprecipitate', componentName: 'Cryoprecipitate' },
];

function escapeRegex(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function isOpenNow(bank) {
  if (bank.available24x7) return true;
  if (!bank.openingTime || !bank.closingTime) return true;
  const now = new Date();
  const dayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  const today = dayNames[now.getDay()];
  const workingDay = (bank.workingDays || []).find((d) => d.day === today);
  if (workingDay && workingDay.open === false) return false;
  const [oh, om] = bank.openingTime.split(':').map(Number);
  const [ch, cm] = bank.closingTime.split(':').map(Number);
  const mins = now.getHours() * 60 + now.getMinutes();
  const openMins = oh * 60 + (om || 0);
  const closeMins = ch * 60 + (cm || 0);
  return mins >= openMins && mins <= closeMins;
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

async function updateBloodBankLogo(id, logoUrl) {
  await BloodBank.updateOne({ id }, { $set: { logoUrl } });
  return findBloodBankById(id);
}

async function addBloodBankGalleryImage(id, imageUrl) {
  await BloodBank.updateOne({ id }, { $push: { galleryImages: imageUrl } });
  return findBloodBankById(id);
}

async function addBloodBankDocument(id, document) {
  await BloodBank.updateOne({ id }, { $push: { documents: document } });
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
    ownerName: data.ownerName ?? data.contactPerson ?? existing?.ownerName ?? existing?.contactPerson,
    licenseNumber: data.licenseNumber ?? existing?.licenseNumber,
    governmentRegistrationNumber:
      data.governmentRegistrationNumber ?? existing?.governmentRegistrationNumber,
    gstNumber: data.gstNumber ?? existing?.gstNumber,
    contactPerson: data.contactPerson ?? data.ownerName ?? existing?.contactPerson,
    email: data.email ?? existing?.email,
    mobileNumber: data.mobileNumber ?? existing?.mobileNumber,
    countryCode: data.countryCode ?? existing?.countryCode ?? '91',
    profilePicture: data.profilePicture ?? existing?.profilePicture,
    logoUrl: data.logoUrl ?? existing?.logoUrl,
    description: data.description ?? existing?.description,
    emergencyContact: data.emergencyContact ?? existing?.emergencyContact,
    whatsappNumber: data.whatsappNumber ?? existing?.whatsappNumber,
    landlineNumber: data.landlineNumber ?? existing?.landlineNumber,
    emailSupport: data.emailSupport ?? existing?.emailSupport,
    address: data.address ?? existing?.address,
    city: data.city ?? existing?.city,
    state: data.state ?? existing?.state,
    pincode: data.pincode ?? existing?.pincode,
    latitude: data.latitude ?? existing?.latitude,
    longitude: data.longitude ?? existing?.longitude,
    openingTime: data.openingTime ?? existing?.openingTime,
    closingTime: data.closingTime ?? existing?.closingTime,
    workingDays: data.workingDays ?? existing?.workingDays ?? [],
    available24x7: data.available24x7 ?? existing?.available24x7 ?? false,
    emergencyBloodSupply: data.emergencyBloodSupply ?? existing?.emergencyBloodSupply ?? false,
    facilities: data.facilities ?? existing?.facilities ?? [],
    bloodGroupsAvailable: data.bloodGroupsAvailable ?? existing?.bloodGroupsAvailable ?? [],
    hasApheresis: data.hasApheresis ?? existing?.hasApheresis ?? false,
    hasComponentSeparation: data.hasComponentSeparation ?? existing?.hasComponentSeparation ?? false,
    homeDeliveryAvailable: data.homeDeliveryAvailable ?? existing?.homeDeliveryAvailable ?? false,
    hospitalDeliveryAvailable:
      data.hospitalDeliveryAvailable ?? existing?.hospitalDeliveryAvailable ?? false,
    cashPaymentEnabled: data.cashPaymentEnabled ?? existing?.cashPaymentEnabled ?? true,
    bloodComponents: data.bloodComponents ?? existing?.bloodComponents ?? [],
    offers: data.offers ?? existing?.offers ?? [],
    galleryImages: data.galleryImages ?? existing?.galleryImages ?? [],
    documents: data.documents ?? existing?.documents ?? [],
    verificationStatus: (() => {
      const current = existing?.verificationStatus || 'pending';
      if (current === 'verified' || current === 'rejected' || current === 'suspended') {
        return current;
      }
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
  pincode,
  area,
  available24x7,
  bloodGroup,
  hasApheresis,
  emergencySupply,
  homeDelivery,
  openNow,
  componentType,
  hasDiscount,
  minRating,
  maxPrice,
  latitude,
  longitude,
  maxDistanceKm,
}) {
  const filter = {};
  if (status === 'awaiting_review') {
    filter.verificationStatus = {
      $in: ['pending', 'under_review', 'verifier_approved'],
    };
  } else if (status) {
    filter.verificationStatus = status;
  }
  if (status === 'verified') {
    filter.isSuspended = { $ne: true };
  }
  if (city?.trim()) {
    filter.city = new RegExp(escapeRegex(city.trim()), 'i');
  }
  if (pincode?.trim()) {
    filter.pincode = new RegExp(escapeRegex(pincode.trim()), 'i');
  }
  if (area?.trim()) {
    filter.address = new RegExp(escapeRegex(area.trim()), 'i');
  }
  if (available24x7 === true || available24x7 === 'true') {
    filter.available24x7 = true;
  }
  if (emergencySupply === true || emergencySupply === 'true') {
    filter.emergencyBloodSupply = true;
  }
  if (homeDelivery === true || homeDelivery === 'true') {
    filter.homeDeliveryAvailable = true;
  }
  if (bloodGroup?.trim()) {
    const group = bloodGroup.trim().toUpperCase();
    filter.bloodGroupsAvailable = new RegExp(escapeRegex(group), 'i');
  }
  if (hasApheresis === true || hasApheresis === 'true') {
    filter.hasApheresis = true;
  }
  if (componentType?.trim()) {
    filter['bloodComponents.componentId'] = componentType.trim();
    filter['bloodComponents.availabilityStatus'] = 'available';
  }
  if (hasDiscount === true || hasDiscount === 'true') {
    filter['offers.offerAvailable'] = true;
    filter['offers.active'] = true;
  }
  if (minRating) {
    filter.averageRating = { $gte: parseFloat(minRating) };
  }
  if (search?.trim()) {
    const regex = new RegExp(escapeRegex(search.trim()), 'i');
    filter.$or = [
      { institutionName: regex },
      { contactPerson: regex },
      { ownerName: regex },
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

  let docs = await BloodBank.find(filter)
    .sort({ averageRating: -1, createdAt: -1 })
    .skip(skip)
    .limit(pageSize);

  let bloodBanks = docs.map(toBloodBank);

  if (openNow === true || openNow === 'true') {
    bloodBanks = bloodBanks.filter(isOpenNow);
  }

  if (latitude && longitude) {
    const lat = parseFloat(latitude);
    const lng = parseFloat(longitude);
    bloodBanks = bloodBanks.map((bank) => {
      let distanceKm = null;
      if (bank.latitude != null && bank.longitude != null) {
        const R = 6371;
        const dLat = ((bank.latitude - lat) * Math.PI) / 180;
        const dLng = ((bank.longitude - lng) * Math.PI) / 180;
        const a =
          Math.sin(dLat / 2) ** 2 +
          Math.cos((lat * Math.PI) / 180) *
            Math.cos((bank.latitude * Math.PI) / 180) *
            Math.sin(dLng / 2) ** 2;
        distanceKm = R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        distanceKm = Math.round(distanceKm * 10) / 10;
      }
      return { ...bank, distanceKm };
    });
    if (maxDistanceKm) {
      const max = parseFloat(maxDistanceKm);
      bloodBanks = bloodBanks.filter((b) => b.distanceKm == null || b.distanceKm <= max);
    }
    bloodBanks.sort((a, b) => (a.distanceKm ?? 999) - (b.distanceKm ?? 999));
  }

  if (maxPrice) {
    const max = parseFloat(maxPrice);
    bloodBanks = bloodBanks.filter((bank) => {
      const prices = (bank.bloodComponents || [])
        .filter((c) => c.enabled !== false && c.availabilityStatus === 'available')
        .map((c) => c.discountPriceInr ?? c.priceInr ?? Infinity);
      const minPrice = prices.length ? Math.min(...prices) : Infinity;
      return minPrice <= max;
    });
  }

  return {
    bloodBanks,
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
        isSuspended: false,
        suspensionReason: null,
      },
    },
  );

  const { initializeBloodBankInventory } = require('./bloodInventoryRepositories');
  await initializeBloodBankInventory(id);

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

async function suspendBloodBank(id, reason) {
  await BloodBank.updateOne(
    { id },
    {
      $set: {
        verificationStatus: 'suspended',
        isSuspended: true,
        suspensionReason: reason || null,
      },
    },
  );
  return findBloodBankById(id);
}

async function requestBloodBankDocuments(id, note) {
  await BloodBank.updateOne(
    { id },
    { $set: { documentRequestNote: note, verificationStatus: 'under_review' } },
  );
  return findBloodBankById(id);
}

async function getBloodBankDashboardStats(bloodBankId) {
  const BloodOrder = require('./models/BloodOrder');
  const EmergencyBloodRequest = require('./models/EmergencyBloodRequest');

  const [total, pending, completed, emergency, todayOrders, revenueAgg] = await Promise.all([
    BloodOrder.countDocuments({ bloodBankId }),
    BloodOrder.countDocuments({ bloodBankId, status: 'pending' }),
    BloodOrder.countDocuments({ bloodBankId, status: 'delivered' }),
    BloodOrder.countDocuments({ bloodBankId, isEmergency: true }),
    BloodOrder.countDocuments({
      bloodBankId,
      createdAt: { $gte: new Date(new Date().setHours(0, 0, 0, 0)) },
    }),
    BloodOrder.aggregate([
      { $match: { bloodBankId, status: 'delivered' } },
      { $group: { _id: null, total: { $sum: '$totalAmount' } } },
    ]),
  ]);

  const bank = await findBloodBankById(bloodBankId);
  const activeOffers = (bank?.offers || []).filter(
    (o) => o.offerAvailable && o.active,
  ).length;

  return {
    totalOrders: total,
    pendingOrders: pending,
    completedOrders: completed,
    emergencyRequests: emergency,
    todayOrders,
    revenue: revenueAgg[0]?.total ?? 0,
    activeOffers,
    averageRating: bank?.averageRating ?? 4.5,
    reviewCount: bank?.reviewCount ?? 0,
  };
}

module.exports = {
  toBloodBank,
  findBloodBankById,
  findBloodBankByEmail,
  ensureBloodBankStub,
  updateBloodBankProfilePicture,
  updateBloodBankLogo,
  addBloodBankGalleryImage,
  addBloodBankDocument,
  upsertBloodBank,
  listBloodBanks,
  submitBloodBankForReview,
  approveBloodBank,
  rejectBloodBank,
  suspendBloodBank,
  requestBloodBankDocuments,
  getBloodBankDashboardStats,
  DEFAULT_BLOOD_GROUPS,
  DEFAULT_BLOOD_COMPONENTS,
  isOpenNow,
};
