/** Sunday (0) through Saturday (6); hourly slots start at 8, last at 17 (5–6 PM). */
const {
  getClinicWeekBounds,
  getClinicActiveWeekBounds,
  sameClinicWeekStart,
} = require('./clinicTime');

const SLOT_START_HOUR = 8;
const SLOT_END_HOUR = 17;

/** Week bounds for the Sunday–Saturday week containing referenceDate (clinic TZ). */
function getWeekBounds(referenceDate = new Date()) {
  return getClinicWeekBounds(referenceDate);
}

/** If referenceDate is after the current week end, return the next calendar week. */
function getActiveWeekBounds(referenceDate = new Date()) {
  return getClinicActiveWeekBounds(referenceDate);
}

function buildAllSlots(available = false) {
  const slots = [];
  for (let dayOfWeek = 0; dayOfWeek <= 6; dayOfWeek += 1) {
    for (let startHour = SLOT_START_HOUR; startHour <= SLOT_END_HOUR; startHour += 1) {
      slots.push({ dayOfWeek, startHour, available });
    }
  }
  return slots;
}

function normalizeSlots(incoming) {
  const map = new Map();
  buildAllSlots(false).forEach((s) => {
    map.set(`${s.dayOfWeek}_${s.startHour}`, { ...s });
  });

  if (Array.isArray(incoming)) {
    incoming.forEach((raw) => {
      const dayOfWeek = Number(raw.dayOfWeek);
      const startHour = Number(raw.startHour);
      if (
        Number.isInteger(dayOfWeek) &&
        dayOfWeek >= 0 &&
        dayOfWeek <= 6 &&
        Number.isInteger(startHour) &&
        startHour >= SLOT_START_HOUR &&
        startHour <= SLOT_END_HOUR
      ) {
        map.set(`${dayOfWeek}_${startHour}`, {
          dayOfWeek,
          startHour,
          available: Boolean(raw.available),
        });
      }
    });
  }

  return Array.from(map.values());
}

function isWeekExpired(weekEndDate) {
  return new Date() > new Date(weekEndDate);
}

/** True when both dates fall in the same Sunday–Saturday week (clinic TZ). */
function sameWeekStart(a, b) {
  return sameClinicWeekStart(a, b);
}

function formatHourLabel(hour) {
  const suffix = hour >= 12 ? 'PM' : 'AM';
  const h12 = hour % 12 === 0 ? 12 : hour % 12;
  const end = hour + 1;
  const end12 = end % 12 === 0 ? 12 : end % 12;
  const endSuffix = end >= 12 ? 'PM' : 'AM';
  return `${h12}:00 ${suffix} – ${end12}:00 ${endSuffix}`;
}

module.exports = {
  SLOT_START_HOUR,
  SLOT_END_HOUR,
  getWeekBounds,
  getActiveWeekBounds,
  buildAllSlots,
  normalizeSlots,
  isWeekExpired,
  sameWeekStart,
  formatHourLabel,
};
