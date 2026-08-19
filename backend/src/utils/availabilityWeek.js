/** Sunday (0) through Saturday (6); hourly slots 12 AM–12 AM (hours 0–23). */
const {
  getClinicWeekBounds,
  getClinicActiveWeekBounds,
  sameClinicWeekStart,
} = require('./clinicTime');

const SLOT_START_HOUR = 0;
const SLOT_END_HOUR = 23;

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
  const fmt = (h) => {
    const hour24 = ((h % 24) + 24) % 24;
    const suffix = hour24 >= 12 ? 'PM' : 'AM';
    const h12 = hour24 % 12 === 0 ? 12 : hour24 % 12;
    return `${h12}:00 ${suffix}`;
  };
  return `${fmt(hour)} – ${fmt(hour + 1)}`;
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
