const { clinicSlotDateTime } = require('./clinicTime');

function slotDateTime(weekStartDate, dayOfWeek, startHour) {
  return clinicSlotDateTime(weekStartDate, dayOfWeek, startHour);
}

function slotEndDateTime(weekStartDate, dayOfWeek, startHour) {
  const end = slotDateTime(weekStartDate, dayOfWeek, startHour);
  return new Date(end.getTime() + 60 * 60 * 1000);
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

module.exports = {
  slotDateTime,
  slotEndDateTime,
  formatSlotLabel,
};
