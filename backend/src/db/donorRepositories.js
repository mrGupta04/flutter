const { v4: uuidv4 } = require('uuid');
const DonorProfile = require('./models/DonorProfile');
const DonorRequest = require('./models/DonorRequest');
const BloodDonation = require('./models/BloodDonation');
const { writeAudit } = require('./bloodAuditRepositories');
const { getCompatibleDonorGroups } = require('../services/bloodCompatibilityService');

function httpError(message, statusCode = 400) {
  const err = new Error(message);
  err.statusCode = statusCode;
  return err;
}

function toDonorPublic(doc, { includeContact = false } = {}) {
  if (!doc) return null;
  const d = doc.toObject ? doc.toObject() : doc;
  return {
    id: d.id,
    patientId: includeContact ? d.patientId : undefined,
    displayName: d.displayName,
    bloodGroup: d.bloodGroup,
    dateOfBirth: d.dateOfBirth,
    gender: d.gender,
    city: d.city,
    state: d.state,
    pincode: includeContact ? d.pincode : undefined,
    contactPreference: d.contactPreference,
    lastDonationDate: d.lastDonationDate,
    nextEligibleDate: d.nextEligibleDate,
    eligibilityStatus: d.eligibilityStatus,
    preferredRadiusKm: d.preferredRadiusKm,
    availableForEmergency: Boolean(d.availableForEmergency),
    consentToShareMaskedContact: Boolean(d.consentToShareMaskedContact),
    availabilityNotes: d.availabilityNotes,
    active: d.active !== false,
    createdAt: d.createdAt,
    updatedAt: d.updatedAt,
  };
}

function toDonorMasked(doc) {
  if (!doc) return null;
  const d = doc.toObject ? doc.toObject() : doc;
  return {
    id: d.id,
    bloodGroup: d.bloodGroup,
    city: d.city,
    eligibilityStatus: d.eligibilityStatus,
    availableForEmergency: Boolean(d.availableForEmergency),
    preferredRadiusKm: d.preferredRadiusKm,
  };
}

async function findDonorByPatientId(patientId) {
  const doc = await DonorProfile.findOne({ patientId });
  return toDonorPublic(doc, { includeContact: true });
}

async function upsertDonorProfile(patientId, data) {
  if (!patientId) throw httpError('Authentication required', 401);
  const bloodGroup = String(data.bloodGroup || '').trim().toUpperCase();
  if (!bloodGroup) throw httpError('Invalid blood group');

  const existing = await DonorProfile.findOne({ patientId });
  const payload = {
    id: existing?.id || uuidv4(),
    patientId,
    displayName: data.displayName ?? existing?.displayName,
    bloodGroup,
    dateOfBirth: data.dateOfBirth ? new Date(data.dateOfBirth) : existing?.dateOfBirth,
    gender: data.gender ?? existing?.gender,
    city: data.city ?? existing?.city,
    state: data.state ?? existing?.state,
    pincode: data.pincode ?? existing?.pincode,
    latitude: data.latitude ?? existing?.latitude,
    longitude: data.longitude ?? existing?.longitude,
    contactPreference: data.contactPreference ?? existing?.contactPreference ?? 'in_app',
    lastDonationDate: data.lastDonationDate
      ? new Date(data.lastDonationDate)
      : existing?.lastDonationDate,
    nextEligibleDate: data.nextEligibleDate
      ? new Date(data.nextEligibleDate)
      : existing?.nextEligibleDate,
    eligibilityStatus: data.eligibilityStatus || existing?.eligibilityStatus || 'pending_screening',
    preferredRadiusKm: data.preferredRadiusKm ?? existing?.preferredRadiusKm ?? 15,
    availableForEmergency: data.availableForEmergency ?? existing?.availableForEmergency ?? false,
    emergencyConsentAt:
      data.availableForEmergency === true
        ? new Date()
        : existing?.emergencyConsentAt,
    consentToShareMaskedContact:
      data.consentToShareMaskedContact ?? existing?.consentToShareMaskedContact ?? false,
    availabilityNotes: data.availabilityNotes ?? existing?.availabilityNotes,
    active: data.active !== false,
  };

  if (existing) {
    await DonorProfile.updateOne({ id: existing.id }, { $set: payload });
  } else {
    await DonorProfile.create(payload);
  }
  return findDonorByPatientId(patientId);
}

function haversineKm(lat1, lon1, lat2, lon2) {
  if ([lat1, lon1, lat2, lon2].some((v) => v == null)) return null;
  const R = 6371;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLng = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLng / 2) ** 2;
  return Math.round(R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a)) * 10) / 10;
}

async function findEligibleDonors({
  bloodGroup,
  city,
  latitude,
  longitude,
  componentType,
  limit = 20,
}) {
  const compatible = await getCompatibleDonorGroups(bloodGroup);
  const filter = {
    active: true,
    availableForEmergency: true,
    eligibilityStatus: { $in: ['opted_in', 'pending_screening'] },
    bloodGroup: { $in: compatible },
  };
  if (city) filter.city = new RegExp(city.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'i');

  const docs = await DonorProfile.find(filter).limit(80).lean();
  const now = new Date();
  return docs
    .filter((d) => !d.nextEligibleDate || new Date(d.nextEligibleDate) <= now)
    .map((d) => {
      const distanceKm = haversineKm(latitude, longitude, d.latitude, d.longitude);
      return { ...toDonorMasked(d), distanceKm, componentType };
    })
    .filter((d) => d.distanceKm == null || d.distanceKm <= (d.preferredRadiusKm || 15))
    .sort((a, b) => (a.distanceKm ?? 999) - (b.distanceKm ?? 999))
    .slice(0, limit);
}

async function createDonorRequests({
  donors,
  emergencyRequestId,
  bloodRequestId,
  bloodBankId,
  payload,
}) {
  const created = [];
  for (const donor of donors) {
    const existing = await DonorRequest.findOne({
      donorProfileId: donor.id,
      emergencyRequestId,
    });
    if (existing) continue;
    const request = await DonorRequest.create({
      id: uuidv4(),
      donorProfileId: donor.id,
      patientId: payload.patientId,
      bloodRequestId,
      emergencyRequestId,
      bloodBankId,
      bloodGroup: payload.bloodGroup,
      componentType: payload.componentType,
      units: payload.units,
      hospitalName: payload.hospitalName,
      hospitalAddress: payload.hospitalAddress,
      city: payload.city,
      latitude: payload.latitude,
      longitude: payload.longitude,
      distanceKm: donor.distanceKm,
      status: 'notified',
      expiresAt: new Date(Date.now() + 6 * 60 * 60 * 1000),
    });
    created.push(request.toObject());
  }
  return created;
}

async function listDonorRequestsForPatient(patientId) {
  const profile = await DonorProfile.findOne({ patientId }).lean();
  if (!profile) return [];
  return DonorRequest.find({ donorProfileId: profile.id }).sort({ createdAt: -1 }).limit(50).lean();
}

async function respondToDonorRequest(requestId, patientId, { accept, notes }) {
  const profile = await DonorProfile.findOne({ patientId }).lean();
  if (!profile) throw httpError('Donor profile not found', 404);

  const request = await DonorRequest.findOne({
    id: requestId,
    donorProfileId: profile.id,
    status: 'notified',
  });
  if (!request) throw httpError('Donor request not found or already handled', 404);

  request.status = accept ? 'accepted' : 'declined';
  request.donorResponseAt = new Date();
  request.donorNotes = notes || null;
  await request.save();
  return request.toObject();
}

async function recordDonation(data, { actorId, actorRole } = {}) {
  if (!data.bloodBankId || !data.bloodGroup || !data.componentType || !data.units) {
    throw httpError('Blood bank, blood group, component, and units are required');
  }
  const donation = await BloodDonation.create({
    id: uuidv4(),
    bloodBankId: data.bloodBankId,
    donorProfileId: data.donorProfileId,
    patientId: data.patientId,
    donorRequestId: data.donorRequestId,
    donorDisplayName: data.donorDisplayName,
    bloodGroup: data.bloodGroup,
    componentType: data.componentType,
    units: Number(data.units),
    donationDate: data.donationDate ? new Date(data.donationDate) : new Date(),
    status: data.status || 'collected',
    nextEligibleDate: data.nextEligibleDate ? new Date(data.nextEligibleDate) : null,
    screeningNotes: data.screeningNotes,
    recordedBy: actorId,
    recordedByRole: actorRole,
  });

  if (data.donorProfileId) {
    await DonorProfile.updateOne(
      { id: data.donorProfileId },
      {
        $set: {
          lastDonationDate: donation.donationDate,
          nextEligibleDate: donation.nextEligibleDate || null,
        },
      },
    );
  }
  if (data.donorRequestId) {
    await DonorRequest.updateOne(
      { id: data.donorRequestId },
      { $set: { status: 'completed', bloodBankConfirmedAt: new Date() } },
    );
  }

  await writeAudit({
    actorId: actorId || 'system',
    actorRole: actorRole || 'blood_bank',
    action: 'donation_recorded',
    entityType: 'BloodDonation',
    entityId: donation.id,
    bloodBankId: data.bloodBankId,
    newValue: { bloodGroup: data.bloodGroup, units: data.units },
  });

  return donation.toObject();
}

async function listDonationsByPatient(patientId) {
  return BloodDonation.find({ patientId }).sort({ donationDate: -1 }).lean();
}

async function listDonationsByBloodBank(bloodBankId, { page = 1, pageSize = 20 } = {}) {
  const filter = { bloodBankId };
  const totalCount = await BloodDonation.countDocuments(filter);
  const totalPages = Math.max(1, Math.ceil(totalCount / pageSize));
  const donations = await BloodDonation.find(filter)
    .sort({ donationDate: -1 })
    .skip((page - 1) * pageSize)
    .limit(pageSize)
    .lean();
  return {
    donations,
    pagination: {
      currentPage: page,
      totalPages,
      pageSize,
      totalCount,
      hasNextPage: page < totalPages,
    },
  };
}

async function listDonorsForBloodBank({ bloodGroup, city, page = 1, pageSize = 20 } = {}) {
  const filter = { active: true };
  if (bloodGroup) filter.bloodGroup = bloodGroup;
  if (city) filter.city = new RegExp(city.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'i');
  const totalCount = await DonorProfile.countDocuments(filter);
  const totalPages = Math.max(1, Math.ceil(totalCount / pageSize));
  const donors = await DonorProfile.find(filter)
    .sort({ updatedAt: -1 })
    .skip((page - 1) * pageSize)
    .limit(pageSize);
  return {
    donors: donors.map((d) => toDonorMasked(d)),
    pagination: {
      currentPage: page,
      totalPages,
      pageSize,
      totalCount,
      hasNextPage: page < totalPages,
    },
  };
}

async function listAllDonors({ page = 1, pageSize = 20, bloodGroup, status } = {}) {
  const filter = {};
  if (bloodGroup) filter.bloodGroup = bloodGroup;
  if (status) filter.eligibilityStatus = status;
  const totalCount = await DonorProfile.countDocuments(filter);
  const totalPages = Math.max(1, Math.ceil(totalCount / pageSize));
  const donors = await DonorProfile.find(filter)
    .sort({ createdAt: -1 })
    .skip((page - 1) * pageSize)
    .limit(pageSize);
  return {
    donors: donors.map((d) => toDonorPublic(d, { includeContact: true })),
    pagination: {
      currentPage: page,
      totalPages,
      pageSize,
      totalCount,
      hasNextPage: page < totalPages,
    },
  };
}

module.exports = {
  findDonorByPatientId,
  upsertDonorProfile,
  findEligibleDonors,
  createDonorRequests,
  listDonorRequestsForPatient,
  respondToDonorRequest,
  recordDonation,
  listDonationsByPatient,
  listDonationsByBloodBank,
  listDonorsForBloodBank,
  listAllDonors,
  toDonorPublic,
  toDonorMasked,
};
