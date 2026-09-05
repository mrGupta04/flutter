const { processDispatchTimeouts } = require('./ambulanceDispatchService');

let timer = null;

function startAmbulanceDispatchScheduler() {
  const pollMs = Number(process.env.AMBULANCE_DISPATCH_POLL_MS || 5000);
  if (timer) clearInterval(timer);
  timer = setInterval(() => {
    processDispatchTimeouts().catch((err) =>
      console.warn('[ambulance-dispatch] timeout sweep failed:', err.message),
    );
  }, pollMs);
  if (typeof timer.unref === 'function') timer.unref();
}

module.exports = { startAmbulanceDispatchScheduler };
