const { expireDueReservations } = require('../db/bloodReservationRepositories');
const { markExpiredUnits } = require('../db/bloodInventoryUnitRepositories');
const { emitInventoryAlerts } = require('./bloodInventoryAutomationService');

const POLL_MS = Number(process.env.BLOOD_RESERVATION_EXPIRE_POLL_MS || 60_000);

let timer = null;

async function tick() {
  try {
    const [reservations, units] = await Promise.all([
      expireDueReservations(),
      markExpiredUnits(),
    ]);
    if (reservations > 0) {
      console.log(`[BloodReservation] released ${reservations} expired reservation(s)`);
    }
    if (units > 0) {
      console.log(`[BloodInventory] marked ${units} expired unit(s)`);
    }
    await emitInventoryAlerts();
  } catch (err) {
    console.error('[BloodReservation] tick failed:', err.message);
  }
}

function startBloodReservationExpiryScheduler() {
  if (timer) return;
  void tick();
  timer = setInterval(tick, POLL_MS);
  if (typeof timer.unref === 'function') timer.unref();
  console.log(
    `Blood reservation/expiry scheduler started (every ${Math.round(POLL_MS / 1000)}s)`,
  );
}

module.exports = {
  startBloodReservationExpiryScheduler,
};
