const DoctorAvailability = require('./models/DoctorAvailability');
const { findDoctorById } = require('./repositories');
const {
  getActiveWeekBounds,
  getWeekBounds,
  normalizeSlots,
  isWeekExpired,
  sameWeekStart,
  buildAllSlots,
} = require('../utils/availabilityWeek');

const VALID_CONSULTATION_TYPES = ['online_consult', 'visit_site', 'book_home'];

function normalizeConsultationType(type) {
  const value = String(type || 'online_consult').trim();
  return VALID_CONSULTATION_TYPES.includes(value) ? value : 'online_consult';
}

function requiredAvailabilityTypes(doctor) {
  const types = [];
  if (doctor?.offersOnlineConsult) types.push('online_consult');
  if (doctor?.offersVisitSite) types.push('visit_site');
  if (doctor?.offersBookHome) types.push('book_home');
  return types;
}

function toAvailabilityPayload(doc, extras = {}) {
  if (!doc) return null;
  const d = doc.toObject ? doc.toObject() : doc;
  const availableCount = (d.slots || []).filter((s) => s.available).length;
  return {
    doctorId: d.doctorId,
    consultationType: d.consultationType || 'online_consult',
    weekStartDate: d.weekStartDate,
    weekEndDate: d.weekEndDate,
    slots: d.slots || [],
    availableSlotCount: availableCount,
    ...extras,
  };
}

async function findLatestAvailability(doctorId, consultationType) {
  const type = normalizeConsultationType(consultationType);
  const typed = await DoctorAvailability.findOne({
    doctorId,
    consultationType: type,
  }).sort({ weekStartDate: -1 });
  if (typed) return typed;

  // Legacy records saved before per-type availability
  return DoctorAvailability.findOne({
    doctorId,
    $or: [{ consultationType: { $exists: false } }, { consultationType: null }],
  }).sort({ weekStartDate: -1 });
}

/** Schedule for the current bookable week (not a future week saved early). */
async function findAvailabilityForActiveWeek(doctorId, consultationType) {
  const type = normalizeConsultationType(consultationType);
  const { weekStart } = getActiveWeekBounds();

  let doc = await DoctorAvailability.findOne({
    doctorId,
    weekStartDate: weekStart,
    consultationType: type,
  });
  if (doc) return doc;

  // Legacy records saved before per-type availability
  if (type === 'online_consult') {
    doc = await DoctorAvailability.findOne({
      doctorId,
      weekStartDate: weekStart,
      $or: [{ consultationType: { $exists: false } }, { consultationType: null }],
    });
    if (doc) return doc;
  }

  // weekStartDate may differ by ms from an older save — match same clinic week
  const docs = await DoctorAvailability.find({ doctorId, consultationType: type }).sort({
    weekStartDate: -1,
  });
  for (const candidate of docs) {
    if (sameWeekStart(candidate.weekStartDate, weekStart)) return candidate;
  }

  if (type === 'online_consult') {
    const legacyDocs = await DoctorAvailability.find({
      doctorId,
      $or: [{ consultationType: { $exists: false } }, { consultationType: null }],
    }).sort({ weekStartDate: -1 });
    for (const candidate of legacyDocs) {
      if (sameWeekStart(candidate.weekStartDate, weekStart)) return candidate;
    }
  }

  return null;
}

async function getTypeAvailabilityStatus(doctorId, consultationType) {
  const type = normalizeConsultationType(consultationType);
  const { weekStart, weekEnd } = getActiveWeekBounds();
  const label = type === 'visit_site' ? 'clinic visit' : 'online consult';

  const weekDoc = await findAvailabilityForActiveWeek(doctorId, type);

  if (!weekDoc) {
    return {
      consultationType: type,
      availability: null,
      needsUpdate: true,
      reminderMessage: `Set your weekly ${label} slots (Sunday–Saturday, 8 AM–6 PM).`,
      suggestedWeekStart: weekStart,
      suggestedWeekEnd: weekEnd,
    };
  }

  const expired = isWeekExpired(weekDoc.weekEndDate);

  return {
    consultationType: type,
    availability: toAvailabilityPayload(weekDoc, { isExpired: expired }),
    needsUpdate: expired,
    reminderMessage: expired
      ? `Your ${label} schedule has ended. Update slots for the next week.`
      : null,
    suggestedWeekStart: expired ? weekStart : weekDoc.weekStartDate,
    suggestedWeekEnd: expired ? weekEnd : weekDoc.weekEndDate,
  };
}

async function getDoctorAvailabilityStatus(doctorId, doctor = null) {
  const profile = doctor || (await findDoctorById(doctorId));
  const types = requiredAvailabilityTypes(profile);

  if (types.length === 0) {
    const { weekStart, weekEnd } = getActiveWeekBounds();
    return {
      availability: null,
      needsUpdate: false,
      reminderMessage: null,
      suggestedWeekStart: weekStart,
      suggestedWeekEnd: weekEnd,
      byType: {},
    };
  }

  const byType = {};
  let needsUpdate = false;
  const messages = [];

  for (const type of types) {
    const status = await getTypeAvailabilityStatus(doctorId, type);
    byType[type] = status;
    if (status.needsUpdate) {
      needsUpdate = true;
      if (status.reminderMessage) messages.push(status.reminderMessage);
    }
  }

  const primaryType = types[0];
  const primary = byType[primaryType];

  return {
    availability: primary?.availability ?? null,
    needsUpdate,
    reminderMessage: messages.length > 0 ? messages.join(' ') : null,
    suggestedWeekStart: primary?.suggestedWeekStart,
    suggestedWeekEnd: primary?.suggestedWeekEnd,
    byType,
  };
}

async function getDoctorAvailability(doctorId, { forWeekStart, consultationType } = {}) {
  const type = normalizeConsultationType(consultationType);

  if (forWeekStart) {
    const { weekStart, weekEnd } = getWeekBounds(new Date(forWeekStart));
    let doc = await DoctorAvailability.findOne({
      doctorId,
      weekStartDate: weekStart,
      consultationType: type,
    });
    if (!doc) {
      doc = await DoctorAvailability.findOne({
        doctorId,
        weekStartDate: weekStart,
        $or: [{ consultationType: { $exists: false } }, { consultationType: null }],
      });
    }
    return toAvailabilityPayload(doc, {
      consultationType: type,
      needsUpdate: doc ? isWeekExpired(doc.weekEndDate) : true,
    });
  }

  const status = await getTypeAvailabilityStatus(doctorId, type);
  if (status.availability) {
    return {
      ...status.availability,
      consultationType: type,
      needsUpdate: status.needsUpdate,
      reminderMessage: status.reminderMessage,
    };
  }

  return {
    doctorId,
    consultationType: type,
    weekStartDate: status.suggestedWeekStart,
    weekEndDate: status.suggestedWeekEnd,
    slots: buildAllSlots(false),
    availableSlotCount: 0,
    needsUpdate: status.needsUpdate,
    reminderMessage: status.reminderMessage,
  };
}

function slotKey(dayOfWeek, startHour) {
  return `${dayOfWeek}_${startHour}`;
}

function availableSlotKeys(slots) {
  return new Set(
    (slots || [])
      .filter((s) => s.available)
      .map((s) => slotKey(s.dayOfWeek, s.startHour)),
  );
}

/** Remove slots from other consultation types so the same hour is not bookable twice. */
async function clearConflictingSlotsFromOtherType(doctorId, weekStart, savedType, savedSlots) {
  const savedKeys = availableSlotKeys(savedSlots);
  if (savedKeys.size === 0) return;

  const otherTypes = VALID_CONSULTATION_TYPES.filter((t) => t !== savedType);

  for (const otherType of otherTypes) {
    const otherDoc = await DoctorAvailability.findOne({
      doctorId,
      weekStartDate: weekStart,
      consultationType: otherType,
    });
    if (!otherDoc?.slots?.length) continue;

    let changed = false;
    const updatedSlots = otherDoc.slots.map((slot) => {
      const plain = slot.toObject ? slot.toObject() : slot;
      const key = slotKey(plain.dayOfWeek, plain.startHour);
      if (plain.available && savedKeys.has(key)) {
        changed = true;
        return { ...plain, available: false };
      }
      return plain;
    });

    if (!changed) continue;

    await DoctorAvailability.updateOne(
      { doctorId, weekStartDate: weekStart, consultationType: otherType },
      { $set: { slots: updatedSlots } },
    );
  }
}

async function findAvailabilityDocForSave(doctorId, weekStart, consultationType) {
  const type = normalizeConsultationType(consultationType);
  let doc = await DoctorAvailability.findOne({
    doctorId,
    weekStartDate: weekStart,
    consultationType: type,
  });
  if (doc || type !== 'online_consult') return doc;

  // Legacy rows saved before per-type availability (implicit online consult).
  return DoctorAvailability.findOne({
    doctorId,
    weekStartDate: weekStart,
    $or: [{ consultationType: { $exists: false } }, { consultationType: null }],
  });
}

async function saveDoctorAvailability(
  doctorId,
  { slots, weekStartDate, consultationType } = {},
) {
  const type = normalizeConsultationType(consultationType);
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
    doctorId,
    consultationType: type,
    weekStartDate: weekStart,
    weekEndDate: weekEnd,
    slots: normalized,
  };

  const existing = await findAvailabilityDocForSave(doctorId, weekStart, type);
  let doc;

  if (existing) {
    doc = await DoctorAvailability.findOneAndUpdate(
      { _id: existing._id },
      { $set: payload },
      { new: true },
    );
  } else {
    try {
      doc = await DoctorAvailability.create(payload);
    } catch (err) {
      if (err.code !== 11000) throw err;
      doc = await findAvailabilityDocForSave(doctorId, weekStart, type);
      if (!doc) {
        const dup = new Error(
          'Availability for this week already exists under a legacy database index. Restart the API so index migration can run, then try again.',
        );
        dup.statusCode = 409;
        throw dup;
      }
      doc = await DoctorAvailability.findOneAndUpdate(
        { _id: doc._id },
        { $set: payload },
        { new: true },
      );
    }
  }

  await clearConflictingSlotsFromOtherType(doctorId, weekStart, type, normalized);

  return toAvailabilityPayload(doc, { needsUpdate: false, reminderMessage: null });
}

module.exports = {
  getDoctorAvailability,
  getDoctorAvailabilityStatus,
  saveDoctorAvailability,
  findLatestAvailability,
  findAvailabilityForActiveWeek,
  normalizeConsultationType,
};
