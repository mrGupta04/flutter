/** India clinic timezone — all availability weeks/slots use this, not server local TZ. */
const CLINIC_TZ = process.env.CLINIC_TIMEZONE || 'Asia/Kolkata';

const WEEKDAY_INDEX = {
  Sun: 0,
  Mon: 1,
  Tue: 2,
  Wed: 3,
  Thu: 4,
  Fri: 5,
  Sat: 6,
};

function clinicParts(date = new Date()) {
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone: CLINIC_TZ,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).formatToParts(date);

  const pick = (type) => parts.find((p) => p.type === type)?.value;
  return {
    year: Number(pick('year')),
    month: Number(pick('month')),
    day: Number(pick('day')),
  };
}

function clinicDayOfWeek(date = new Date()) {
  const weekday = new Intl.DateTimeFormat('en-US', {
    timeZone: CLINIC_TZ,
    weekday: 'short',
  }).format(date);
  return WEEKDAY_INDEX[weekday];
}

function pad2(n) {
  return String(n).padStart(2, '0');
}

/** Calendar date + time in clinic TZ as a UTC Date instant. */
function clinicDateTime(year, month, day, hour = 0, minute = 0, second = 0, ms = 0) {
  return new Date(
    `${year}-${pad2(month)}-${pad2(day)}T${pad2(hour)}:${pad2(minute)}:${pad2(second)}.${String(ms).padStart(3, '0')}+05:30`,
  );
}

function addClinicDays(year, month, day, deltaDays) {
  const shifted = new Date(clinicDateTime(year, month, day).getTime() + deltaDays * 86400000);
  return clinicParts(shifted);
}

function getClinicWeekBounds(referenceDate = new Date()) {
  const { year, month, day } = clinicParts(referenceDate);
  const dow = clinicDayOfWeek(referenceDate);
  const sunday = addClinicDays(year, month, day, -dow);
  const saturday = addClinicDays(sunday.year, sunday.month, sunday.day, 6);
  const weekStart = clinicDateTime(sunday.year, sunday.month, sunday.day, 0, 0, 0, 0);
  const weekEnd = clinicDateTime(saturday.year, saturday.month, saturday.day, 23, 59, 59, 999);
  return { weekStart, weekEnd };
}

function getClinicActiveWeekBounds(referenceDate = new Date()) {
  const now = new Date();
  let { weekStart, weekEnd } = getClinicWeekBounds(referenceDate);
  if (now > weekEnd) {
    const nextSunday = addClinicDays(
      clinicParts(weekStart).year,
      clinicParts(weekStart).month,
      clinicParts(weekStart).day,
      7,
    );
    ({ weekStart, weekEnd } = getClinicWeekBounds(clinicDateTime(nextSunday.year, nextSunday.month, nextSunday.day)));
  }
  return { weekStart, weekEnd };
}

function clinicSlotDateTime(weekStartDate, dayOfWeek, startHour) {
  const { year, month, day } = clinicParts(weekStartDate);
  const slotDay = addClinicDays(year, month, day, dayOfWeek);
  return clinicDateTime(slotDay.year, slotDay.month, slotDay.day, startHour, 0, 0, 0);
}

function sameClinicWeekStart(a, b) {
  if (!a || !b) return false;
  return getClinicWeekBounds(a).weekStart.getTime() === getClinicWeekBounds(b).weekStart.getTime();
}

module.exports = {
  CLINIC_TZ,
  clinicParts,
  clinicDayOfWeek,
  clinicDateTime,
  getClinicWeekBounds,
  getClinicActiveWeekBounds,
  clinicSlotDateTime,
  sameClinicWeekStart,
};
