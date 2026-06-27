const NurseAvailability = require('./models/NurseAvailability');
const { findNurseById } = require('./nurseRepositories');
const {
  getActiveWeekBounds,
  getWeekBounds,
  normalizeSlots,
  isWeekExpired,
  sameWeekStart,
  buildAllSlots,
} = require('../utils/availabilityWeek');

const CONSULTATION_TYPE = 'book_home';

function toAvailabilityPayload(doc, extras = {}) {
  if (!doc) return null;
  const d = doc.toObject ? doc.toObject() : doc;
  const availableCount = (d.slots || []).filter((s) => s.available).length;
  return {
    nurseId: d.nurseId,
    consultationType: d.consultationType || CONSULTATION_TYPE,
    weekStartDate: d.weekStartDate,
    weekEndDate: d.weekEndDate,
    slots: d.slots || [],
    availableSlotCount: availableCount,
    ...extras,
  };
}

async function findAvailabilityForActiveWeek(nurseId) {
  const { weekStart } = getActiveWeekBounds();

  let doc = await NurseAvailability.findOne({
    nurseId,
    weekStartDate: weekStart,
    consultationType: CONSULTATION_TYPE,
  });
  if (doc) return doc;

  const docs = await NurseAvailability.find({
    nurseId,
    consultationType: CONSULTATION_TYPE,
  }).sort({ weekStartDate: -1 });

  for (const candidate of docs) {
    if (sameWeekStart(candidate.weekStartDate, weekStart)) return candidate;
  }

  return null;
}

async function getTypeAvailabilityStatus(nurseId) {
  const { weekStart, weekEnd } = getActiveWeekBounds();
  const weekDoc = await findAvailabilityForActiveWeek(nurseId);

  if (!weekDoc) {
    return {
      consultationType: CONSULTATION_TYPE,
      availability: null,
      needsUpdate: true,
      reminderMessage:
        'Set your weekly home visit slots (Sunday–Saturday, 8 AM–6 PM).',
      suggestedWeekStart: weekStart,
      suggestedWeekEnd: weekEnd,
    };
  }

  const expired = isWeekExpired(weekDoc.weekEndDate);

  return {
    consultationType: CONSULTATION_TYPE,
    availability: toAvailabilityPayload(weekDoc),
    needsUpdate: expired,
    reminderMessage: expired
      ? 'Your home visit schedule expired. Update your weekly slots.'
      : null,
    suggestedWeekStart: weekStart,
    suggestedWeekEnd: weekEnd,
  };
}

async function getNurseAvailabilityStatus(nurseId) {
  const status = await getTypeAvailabilityStatus(nurseId);
  return {
    availability: status.availability,
    needsUpdate: status.needsUpdate,
    reminderMessage: status.reminderMessage,
    suggestedWeekStart: status.suggestedWeekStart,
    suggestedWeekEnd: status.suggestedWeekEnd,
    byType: { [CONSULTATION_TYPE]: status },
  };
}

async function getNurseAvailability(nurseId, { forWeekStart } = {}) {
  if (forWeekStart) {
    const { weekStart, weekEnd } = getWeekBounds(new Date(forWeekStart));
    const doc = await NurseAvailability.findOne({
      nurseId,
      weekStartDate: weekStart,
      consultationType: CONSULTATION_TYPE,
    });
    return toAvailabilityPayload(doc, {
      consultationType: CONSULTATION_TYPE,
      needsUpdate: doc ? isWeekExpired(doc.weekEndDate) : true,
    });
  }

  const status = await getTypeAvailabilityStatus(nurseId);
  if (status.availability) {
    return {
      ...status.availability,
      consultationType: CONSULTATION_TYPE,
      needsUpdate: status.needsUpdate,
      reminderMessage: status.reminderMessage,
    };
  }

  return {
    nurseId,
    consultationType: CONSULTATION_TYPE,
    weekStartDate: status.suggestedWeekStart,
    weekEndDate: status.suggestedWeekEnd,
    slots: buildAllSlots(false),
    availableSlotCount: 0,
    needsUpdate: status.needsUpdate,
    reminderMessage: status.reminderMessage,
  };
}

async function saveNurseAvailability(nurseId, { slots, weekStartDate } = {}) {
  const nurse = await findNurseById(nurseId);
  if (!nurse) {
    const err = new Error('Nurse not found');
    err.statusCode = 404;
    throw err;
  }

  const normalized = normalizeSlots(slots);
  const availableCount = normalized.filter((s) => s.available).length;
  if (availableCount === 0) {
    const err = new Error('Select at least one available time slot');
    err.statusCode = 400;
    throw err;
  }

  const { weekStart, weekEnd } = weekStartDate
    ? getWeekBounds(new Date(weekStartDate))
    : getActiveWeekBounds();

  const payload = {
    nurseId,
    consultationType: CONSULTATION_TYPE,
    weekStartDate: weekStart,
    weekEndDate: weekEnd,
    slots: normalized,
  };

  const existing = await NurseAvailability.findOne({
    nurseId,
    weekStartDate: weekStart,
    consultationType: CONSULTATION_TYPE,
  });

  let doc;
  if (existing) {
    doc = await NurseAvailability.findOneAndUpdate(
      { _id: existing._id },
      { $set: payload },
      { new: true },
    );
  } else {
    doc = await NurseAvailability.create(payload);
  }

  return toAvailabilityPayload(doc, { needsUpdate: false });
}

module.exports = {
  CONSULTATION_TYPE,
  findAvailabilityForActiveWeek,
  getNurseAvailability,
  getNurseAvailabilityStatus,
  saveNurseAvailability,
};
