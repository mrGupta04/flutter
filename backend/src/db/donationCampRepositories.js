const { v4: uuidv4 } = require('uuid');
const DonationCamp = require('./models/DonationCamp');
const DonationRegistration = require('./models/DonationRegistration');
const { writeAudit } = require('./bloodAuditRepositories');
const { createAndPushNotification } = require('./notificationRepositories');

function fail(message, statusCode = 400) {
  const err = new Error(message);
  err.statusCode = statusCode;
  throw err;
}

function toCamp(doc) {
  if (!doc) return null;
  const d = doc.toObject ? doc.toObject() : doc;
  return {
    id: d.id,
    bloodBankId: d.bloodBankId,
    title: d.title,
    description: d.description,
    organizer: d.organizer,
    contact: d.contact,
    date: d.date,
    startTime: d.startTime,
    endTime: d.endTime,
    address: d.address,
    city: d.city,
    state: d.state,
    pincode: d.pincode,
    latitude: d.latitude,
    longitude: d.longitude,
    capacity: d.capacity || 0,
    registeredCount: d.registeredCount || 0,
    seatsLeft: Math.max(0, (d.capacity || 0) - (d.registeredCount || 0)),
    requiredBloodGroups: d.requiredBloodGroups || [],
    images: d.images || [],
    registrationRequired: d.registrationRequired !== false,
    status: d.status,
    createdAt: d.createdAt,
    updatedAt: d.updatedAt,
  };
}

function toRegistration(doc) {
  if (!doc) return null;
  const d = doc.toObject ? doc.toObject() : doc;
  return {
    id: d.id,
    campId: d.campId,
    bloodBankId: d.bloodBankId,
    userId: d.userId,
    patientName: d.patientName,
    patientMobile: d.patientMobile,
    bloodGroup: d.bloodGroup,
    appointmentTime: d.appointmentTime,
    status: d.status,
    createdAt: d.createdAt,
  };
}

async function listPublicCamps({ city, bloodGroup, page = 1, pageSize = 30 } = {}) {
  const filter = {
    status: 'published',
    date: { $gte: new Date(new Date().setHours(0, 0, 0, 0)) },
  };
  if (city) filter.city = new RegExp(city.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'i');
  if (bloodGroup) filter.requiredBloodGroups = { $in: [bloodGroup, ''] };

  const totalCount = await DonationCamp.countDocuments(filter);
  const docs = await DonationCamp.find(filter)
    .sort({ date: 1 })
    .skip((page - 1) * pageSize)
    .limit(pageSize)
    .lean();
  return {
    camps: docs.map(toCamp),
    pagination: {
      currentPage: page,
      pageSize,
      totalCount,
      totalPages: Math.max(1, Math.ceil(totalCount / pageSize)),
    },
  };
}

async function listCampsByBloodBank(bloodBankId) {
  const docs = await DonationCamp.find({ bloodBankId }).sort({ date: -1 }).lean();
  return docs.map(toCamp);
}

async function findCampById(id) {
  return toCamp(await DonationCamp.findOne({ id }).lean());
}

async function upsertCamp(bloodBankId, data, actorId) {
  const id = data.id || uuidv4();
  const existing = await DonationCamp.findOne({ id });
  if (existing && existing.bloodBankId !== bloodBankId) {
    fail('You can only edit camps for your blood bank', 403);
  }
  if (!data.title || !data.date) fail('Camp title and date are required');

  const payload = {
    id,
    bloodBankId,
    title: String(data.title).trim(),
    description: data.description,
    organizer: data.organizer,
    contact: data.contact,
    date: new Date(data.date),
    startTime: data.startTime,
    endTime: data.endTime,
    address: data.address,
    city: data.city,
    state: data.state,
    pincode: data.pincode,
    latitude: data.latitude,
    longitude: data.longitude,
    capacity: Number(data.capacity) || 50,
    requiredBloodGroups: data.requiredBloodGroups || [],
    images: data.images || [],
    registrationRequired: data.registrationRequired !== false,
    status: data.status || 'published',
  };

  if (existing) {
    await DonationCamp.updateOne({ id }, { $set: payload });
  } else {
    payload.registeredCount = 0;
    await DonationCamp.create(payload);
  }

  await writeAudit({
    actorId: actorId || bloodBankId,
    actorRole: 'bloodbank',
    action: existing ? 'camp.update' : 'camp.create',
    entityType: 'donation_camp',
    entityId: id,
    bloodBankId,
    previousValue: existing ? { title: existing.title } : null,
    newValue: { title: payload.title, date: payload.date },
  });

  return findCampById(id);
}

async function cancelCamp(bloodBankId, campId, actorId) {
  const camp = await DonationCamp.findOne({ id: campId, bloodBankId });
  if (!camp) fail('Camp not found', 404);
  await DonationCamp.updateOne({ id: campId }, { $set: { status: 'cancelled' } });
  await writeAudit({
    actorId: actorId || bloodBankId,
    actorRole: 'bloodbank',
    action: 'camp.cancel',
    entityType: 'donation_camp',
    entityId: campId,
    bloodBankId,
  });
  return findCampById(campId);
}

async function registerForCamp({
  campId,
  userId,
  patientName,
  patientMobile,
  bloodGroup,
  appointmentTime,
}) {
  const camp = await DonationCamp.findOne({ id: campId });
  if (!camp || camp.status !== 'published') fail('Camp is not open for registration', 404);
  if (camp.date < new Date(new Date().setHours(0, 0, 0, 0))) {
    fail('This camp has already ended');
  }
  if ((camp.registeredCount || 0) >= (camp.capacity || 0)) {
    fail('This camp is fully booked');
  }

  const existing = await DonationRegistration.findOne({ campId, userId });
  if (existing && existing.status === 'registered') {
    fail('You are already registered for this camp');
  }

  const registration = existing
    ? await DonationRegistration.findOneAndUpdate(
        { id: existing.id },
        {
          $set: {
            status: 'registered',
            patientName,
            patientMobile,
            bloodGroup,
            appointmentTime,
          },
        },
        { new: true },
      )
    : await DonationRegistration.create({
        id: uuidv4(),
        campId,
        bloodBankId: camp.bloodBankId,
        userId,
        patientName,
        patientMobile,
        bloodGroup,
        appointmentTime,
        status: 'registered',
      });

  if (!existing || existing.status !== 'registered') {
    await DonationCamp.updateOne({ id: campId }, { $inc: { registeredCount: 1 } });
  }

  await createAndPushNotification({
    userType: 'patient',
    userId,
    title: 'Donation camp registered',
    body: `You registered for ${camp.title}. Eligibility is confirmed at the camp.`,
    type: 'general',
    data: { campId, registrationId: registration.id },
  }).catch(() => {});

  return toRegistration(registration);
}

async function cancelRegistration({ campId, userId }) {
  const registration = await DonationRegistration.findOne({ campId, userId });
  if (!registration || registration.status !== 'registered') {
    fail('Registration not found', 404);
  }
  await DonationRegistration.updateOne(
    { id: registration.id },
    { $set: { status: 'cancelled' } },
  );
  await DonationCamp.updateOne(
    { id: campId, registeredCount: { $gt: 0 } },
    { $inc: { registeredCount: -1 } },
  );
  return toRegistration(await DonationRegistration.findOne({ id: registration.id }));
}

async function listMyRegistrations(userId) {
  const docs = await DonationRegistration.find({ userId }).sort({ createdAt: -1 }).lean();
  const campIds = [...new Set(docs.map((d) => d.campId))];
  const camps = await DonationCamp.find({ id: { $in: campIds } }).lean();
  const campMap = new Map(camps.map((c) => [c.id, toCamp(c)]));
  return docs.map((d) => ({ ...toRegistration(d), camp: campMap.get(d.campId) }));
}

module.exports = {
  toCamp,
  listPublicCamps,
  listCampsByBloodBank,
  findCampById,
  upsertCamp,
  cancelCamp,
  registerForCamp,
  cancelRegistration,
  listMyRegistrations,
};
