const {
  expireAllNursePaymentWindows,
} = require('../db/nurseBookingRepositories');

const POLL_MS = Number(process.env.NURSE_PAYMENT_EXPIRE_POLL_MS || 15_000);

let timer = null;

async function tick() {
  try {
    const expired = await expireAllNursePaymentWindows();
    if (expired > 0) {
      console.log(`[NursePaymentExpire] released ${expired} expired payment window(s)`);
    }
  } catch (err) {
    console.error('[NursePaymentExpire] tick failed:', err.message);
  }
}

function startNursePaymentExpirationScheduler() {
  if (timer) return;
  void tick();
  timer = setInterval(tick, POLL_MS);
  if (typeof timer.unref === 'function') timer.unref();
  console.log(
    `Nurse payment expiration scheduler started (every ${Math.round(POLL_MS / 1000)}s)`,
  );
}

module.exports = {
  startNursePaymentExpirationScheduler,
};
