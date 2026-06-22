const { findBookingsDueForAutoPrescription } = require('../db/prescriptionRepositories');
const { autoFinalizePrescriptionForBooking } = require('./prescriptionService');

const POLL_MS = 60 * 1000;
let timer = null;

function resolvePublicBaseUrl() {
  const configured = process.env.PUBLIC_BASE_URL;
  if (configured && String(configured).trim()) {
    return String(configured).trim().replace(/\/$/, '');
  }
  const port = process.env.PORT || '3000';
  return `http://localhost:${port}`;
}

async function processDuePrescriptions() {
  const due = await findBookingsDueForAutoPrescription();
  if (!due.length) return { processed: 0, sent: 0 };

  const publicBaseUrl = resolvePublicBaseUrl();
  let sent = 0;

  for (const booking of due) {
    try {
      const result = await autoFinalizePrescriptionForBooking(
        booking.id,
        publicBaseUrl,
      );
      if (result) {
        sent += 1;
        console.log(
          `[prescription-auto] Sent prescription for booking ${booking.id}`,
        );
      }
    } catch (err) {
      console.error(
        `[prescription-auto] Failed for booking ${booking.id}:`,
        err.message,
      );
    }
  }

  return { processed: due.length, sent };
}

function startPrescriptionAutoSendScheduler() {
  if (timer) return;

  timer = setInterval(() => {
    void processDuePrescriptions();
  }, POLL_MS);

  setTimeout(() => {
    void processDuePrescriptions();
  }, 5000);
}

module.exports = {
  startPrescriptionAutoSendScheduler,
  processDuePrescriptions,
};
