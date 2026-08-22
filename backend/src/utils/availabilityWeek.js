/** Sunday (0) through Saturday (6); hourly slots 12 AM–12 AM (hours 0–23). */
const {
  getClinicWeekBounds,
  getClinicActiveWeekBounds,
  sameClinicWeekStart,
} = require('./clinicTime');
const {
  isOnlineConsultType,
  ONLINE_START_MINUTES,
} = require('./slotDateTime');

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

function buildAllSlots(available = false, consultationType) {
  if (isOnlineConsultType(consultationType)) {
    return buildAllOnlineSlots(available);
  }
  const slots = [];
  for (let dayOfWeek = 0; dayOfWeek <= 6; dayOfWeek += 1) {
    for (let startHour = SLOT_START_HOUR; startHour <= SLOT_END_HOUR; startHour += 1) {
      slots.push({ dayOfWeek, startHour, startMinute: 0, available });
    }
  }
  return slots;
}

function buildAllOnlineSlots(available = false) {
  const slots = [];
  for (let dayOfWeek = 0; dayOfWeek <= 6; dayOfWeek += 1) {
    for (let startHour = SLOT_START_HOUR; startHour <= SLOT_END_HOUR; startHour += 1) {
      for (const startMinute of ONLINE_START_MINUTES) {
        slots.push({ dayOfWeek, startHour, startMinute, available });
      }
    }
  }
  return slots;
}

function isValidDayHour(dayOfWeek, startHour) {
  return (
    Number.isInteger(dayOfWeek) &&
    dayOfWeek >= 0 &&
    dayOfWeek <= 6 &&
    Number.isInteger(startHour) &&
    startHour >= SLOT_START_HOUR &&
    startHour <= SLOT_END_HOUR
  );
}

function normalizeSlots(incoming, consultationType) {
  if (isOnlineConsultType(consultationType)) {
    return normalizeOnlineSlots(incoming);
  }

  const map = new Map();
  buildAllSlots(false).forEach((s) => {
    map.set(`${s.dayOfWeek}_${s.startHour}`, { ...s });
  });

  if (Array.isArray(incoming)) {
    incoming.forEach((raw) => {
      const dayOfWeek = Number(raw.dayOfWeek);
      const startHour = Number(raw.startHour);
      if (isValidDayHour(dayOfWeek, startHour)) {
        map.set(`${dayOfWeek}_${startHour}`, {
          dayOfWeek,
          startHour,
          startMinute: 0,
          available: Boolean(raw.available),
        });
      }
    });
  }

  return Array.from(map.values());
}

function normalizeOnlineSlots(incoming) {
  const map = new Map();
  buildAllOnlineSlots(false).forEach((slot) => {
    map.set(`${slot.dayOfWeek}_${slot.startHour}_${slot.startMinute}`, { ...slot });
  });

  const grouped = new Map();
  if (Array.isArray(incoming)) {
    incoming.forEach((raw) => {
      const dayOfWeek = Number(raw.dayOfWeek);
      const startHour = Number(raw.startHour);
      if (!isValidDayHour(dayOfWeek, startHour)) return;
      const hourKey = `${dayOfWeek}_${startHour}`;
      if (!grouped.has(hourKey)) grouped.set(hourKey, []);
      grouped.get(hourKey).push(raw);
    });
  }

  grouped.forEach((group, hourKey) => {
    const [dayOfWeek, startHour] = hourKey.split('_').map(Number);
    const hasExplicitMinutes = group.some((raw) =>
      [20, 40].includes(Number(raw.startMinute)),
    );

    if (hasExplicitMinutes) {
      group.forEach((raw) => {
        const startMinute = Number(raw.startMinute || 0);
        if (!ONLINE_START_MINUTES.includes(startMinute)) return;
        map.set(`${dayOfWeek}_${startHour}_${startMinute}`, {
          dayOfWeek,
          startHour,
          startMinute,
          available: Boolean(raw.available),
        });
      });
      return;
    }

    if (group.some((raw) => raw.available)) {
      ONLINE_START_MINUTES.forEach((startMinute) => {
        map.set(`${dayOfWeek}_${startHour}_${startMinute}`, {
          dayOfWeek,
          startHour,
          startMinute,
          available: true,
        });
      });
    }
  });

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
