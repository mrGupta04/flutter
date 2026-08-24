/**
 * In-memory live GPS for home-visit tracking.
 *
 * Redis is not part of this project (MongoDB + single Node process). High-frequency
 * points stay here; MongoDB is updated on a throttle so we never insert a document
 * per GPS ping.
 */

const locations = new Map();
const lastPersistAt = new Map();

const PERSIST_INTERVAL_MS = Number(process.env.TRACKING_PERSIST_MS || 5000);

function setLiveLocation(bookingId, payload) {
  if (!bookingId) return null;
  const next = {
    bookingId,
    providerId: payload.providerId,
    providerType: payload.providerType,
    latitude: payload.latitude,
    longitude: payload.longitude,
    heading: payload.heading ?? null,
    speed: payload.speed ?? null,
    timestamp: payload.timestamp || Date.now(),
  };
  locations.set(bookingId, next);
  return next;
}

function getLiveLocation(bookingId) {
  return locations.get(bookingId) || null;
}

function clearLiveLocation(bookingId) {
  locations.delete(bookingId);
  lastPersistAt.delete(bookingId);
}

function shouldPersist(bookingId) {
  const last = lastPersistAt.get(bookingId) || 0;
  return Date.now() - last >= PERSIST_INTERVAL_MS;
}

function markPersisted(bookingId) {
  lastPersistAt.set(bookingId, Date.now());
}

module.exports = {
  setLiveLocation,
  getLiveLocation,
  clearLiveLocation,
  shouldPersist,
  markPersisted,
  PERSIST_INTERVAL_MS,
};
