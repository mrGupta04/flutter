const EARLY_MS =
  parseInt(process.env.VIDEO_JOIN_EARLY_MINUTES || '10', 10) * 60 * 1000;
const GRACE_MS =
  parseInt(process.env.VIDEO_JOIN_GRACE_MINUTES || '5', 10) * 60 * 1000;

function getVideoJoinWindow(slotStart, slotEnd, now = new Date()) {
  const start = new Date(slotStart);
  const end = new Date(slotEnd);
  const windowStart = new Date(start.getTime() - EARLY_MS);
  const windowEnd = new Date(end.getTime() + GRACE_MS);
  const nowMs = now.getTime();

  return {
    windowStart,
    windowEnd,
    slotStart: start,
    slotEnd: end,
    canJoin: nowMs >= windowStart.getTime() && nowMs <= windowEnd.getTime(),
    isBeforeWindow: nowMs < windowStart.getTime(),
    isAfterWindow: nowMs > windowEnd.getTime(),
    startsInMs: Math.max(0, windowStart.getTime() - nowMs),
    endsInMs: Math.max(0, windowEnd.getTime() - nowMs),
  };
}

function videoJoinFields(booking, now = new Date()) {
  if (!booking || booking.consultationType !== 'online_consult') {
    return {};
  }
  if (booking.status !== 'confirmed') {
    return {
      canJoinVideo: false,
      videoJoinWindowStart: null,
      videoJoinWindowEnd: null,
    };
  }

  const window = getVideoJoinWindow(booking.slotStart, booking.slotEnd, now);
  return {
    canJoinVideo: window.canJoin,
    videoJoinWindowStart: window.windowStart.toISOString(),
    videoJoinWindowEnd: window.windowEnd.toISOString(),
    videoStartsInMinutes: window.isBeforeWindow
      ? Math.ceil(window.startsInMs / 60000)
      : null,
  };
}

module.exports = {
  getVideoJoinWindow,
  videoJoinFields,
};
