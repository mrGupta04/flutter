/** Minutes without a heartbeat before a doctor is no longer "live". */
const LIVE_THRESHOLD_MS =
  parseInt(process.env.DOCTOR_LIVE_THRESHOLD_MS || '300000', 10) || 300000;

function isDoctorLiveNow(lastActiveAt) {
  if (!lastActiveAt) return false;
  const ts = lastActiveAt instanceof Date ? lastActiveAt.getTime() : new Date(lastActiveAt).getTime();
  if (Number.isNaN(ts)) return false;
  return Date.now() - ts <= LIVE_THRESHOLD_MS;
}

module.exports = { LIVE_THRESHOLD_MS, isDoctorLiveNow };
