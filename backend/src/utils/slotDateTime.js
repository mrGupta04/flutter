const { clinicSlotDateTime, clinicTimeParts } = require('./clinicTime');

const ONLINE_CONSULT_TYPE = 'online_consult';
const ONLINE_SLOT_MINUTES = 20;
const DEFAULT_SLOT_MINUTES = 60;
const ONLINE_START_MINUTES = [0, 20, 40];

function isOnlineConsultType(consultationType) {
  return consultationType === ONLINE_CONSULT_TYPE;
}

function slotDurationMinutes(consultationType) {
  return isOnlineConsultType(consultationType)
    ? ONLINE_SLOT_MINUTES
    : DEFAULT_SLOT_MINUTES;
}

function startMinuteOffsets(consultationType) {
  return isOnlineConsultType(consultationType) ? ONLINE_START_MINUTES : [0];
}

function slotDateTime(weekStartDate, dayOfWeek, startHour, startMinute = 0) {
  return clinicSlotDateTime(weekStartDate, dayOfWeek, startHour, startMinute);
}

function slotEndFromStart(slotStart, consultationType) {
  return new Date(
    slotStart.getTime() + slotDurationMinutes(consultationType) * 60 * 1000,
  );
}

function slotEndDateTime(
  weekStartDate,
  dayOfWeek,
  startHour,
  startMinute = 0,
  consultationType,
) {
  return slotEndFromStart(
    slotDateTime(weekStartDate, dayOfWeek, startHour, startMinute),
    consultationType,
  );
}

function normalizeStartMinute({ startMinute, slotStart, consultationType } = {}) {
  const allowed = startMinuteOffsets(consultationType);
  if (startMinute != null && startMinute !== '') {
    const minute = Number(startMinute);
    if (Number.isInteger(minute) && allowed.includes(minute)) {
      return minute;
    }
    if (isOnlineConsultType(consultationType)) {
      const err = new Error(
        'Online consult slots are 20 minutes and start at :00, :20, or :40',
      );
      err.statusCode = 400;
      throw err;
    }
  }

  if (slotStart instanceof Date && !Number.isNaN(slotStart.getTime())) {
    const { minute } = clinicTimeParts(slotStart);
    if (allowed.includes(minute)) return minute;
    if (isOnlineConsultType(consultationType)) {
      const err = new Error(
        'Online consult slots are 20 minutes and start at :00, :20, or :40',
      );
      err.statusCode = 400;
      throw err;
    }
  }

  return 0;
}

function consultEndFromStart(slotStart, slotEnd, consultationType) {
  const durationEnd = slotEndFromStart(new Date(slotStart), consultationType);
  if (!slotEnd) return durationEnd;
  const storedEnd = new Date(slotEnd);
  if (Number.isNaN(storedEnd.getTime())) return durationEnd;
  if (!isOnlineConsultType(consultationType)) return storedEnd;
  return durationEnd.getTime() <= storedEnd.getTime() ? durationEnd : storedEnd;
}

function formatSlotLabel(slotStart, slotEnd) {
  const tz = { timeZone: 'Asia/Kolkata' };
  const dayOpts = { weekday: 'short', month: 'short', day: 'numeric', ...tz };
  const timeOpts = { hour: 'numeric', minute: '2-digit', hour12: true, ...tz };
  const dayPart = slotStart.toLocaleDateString('en-IN', dayOpts);
  const startPart = slotStart.toLocaleTimeString('en-IN', timeOpts);
  const endPart = slotEnd.toLocaleTimeString('en-IN', timeOpts);
  return `${dayPart} • ${startPart} – ${endPart}`;
}

function usesMinuteWindows(slots, consultationType) {
  if (!isOnlineConsultType(consultationType)) return false;
  return (slots || []).some((slot) =>
    [20, 40].includes(Number(slot.startMinute)),
  );
}

function isAvailabilityWindowOpen(slots, day, hour, minute, consultationType) {
  const list = slots || [];
  if (usesMinuteWindows(list, consultationType)) {
    const match = list.find(
      (slot) =>
        Number(slot.dayOfWeek) === day &&
        Number(slot.startHour) === hour &&
        Number(slot.startMinute || 0) === minute,
    );
    return Boolean(match?.available);
  }
  const hourSlot = list.find(
    (slot) => Number(slot.dayOfWeek) === day && Number(slot.startHour) === hour,
  );
  return Boolean(hourSlot?.available);
}

function listAvailabilityWindows(slots, consultationType) {
  const list = slots || [];
  if (usesMinuteWindows(list, consultationType)) {
    return list
      .filter((slot) => slot.available)
      .map((slot) => ({
        dayOfWeek: Number(slot.dayOfWeek),
        startHour: Number(slot.startHour),
        startMinute: Number(slot.startMinute || 0),
      }));
  }
  const minutes = startMinuteOffsets(consultationType);
  const windows = [];
  for (const slot of list) {
    if (!slot.available) continue;
    for (const minute of minutes) {
      windows.push({
        dayOfWeek: Number(slot.dayOfWeek),
        startHour: Number(slot.startHour),
        startMinute: minute,
      });
    }
  }
  return windows;
}

module.exports = {
  ONLINE_CONSULT_TYPE,
  ONLINE_SLOT_MINUTES,
  DEFAULT_SLOT_MINUTES,
  ONLINE_START_MINUTES,
  isOnlineConsultType,
  slotDurationMinutes,
  startMinuteOffsets,
  slotDateTime,
  slotEndFromStart,
  slotEndDateTime,
  normalizeStartMinute,
  consultEndFromStart,
  formatSlotLabel,
  usesMinuteWindows,
  isAvailabilityWindowOpen,
  listAvailabilityWindows,
};
