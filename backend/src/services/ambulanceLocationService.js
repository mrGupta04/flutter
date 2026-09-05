const { v4: uuidv4 } = require('uuid');
const AmbulanceLocation = require('../db/models/AmbulanceLocation');
const Ambulance = require('../db/models/Ambulance');

const MIN_DISTANCE_M = Number(process.env.AMBULANCE_LOCATION_MIN_DISTANCE_M || 20);

function haversineMeters(a, b) {
  if (!a || !b) return Infinity;
  const toRad = (d) => (d * Math.PI) / 180;
  const R = 6371000;
  const dLat = toRad(b.latitude - a.latitude);
  const dLon = toRad(b.longitude - a.longitude);
  const x =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(a.latitude)) * Math.cos(toRad(b.latitude)) * Math.sin(dLon / 2) ** 2;
  return 2 * R * Math.asin(Math.min(1, Math.sqrt(x)));
}

async function persistAmbulanceLocation(input) {
  const last = await AmbulanceLocation.findOne({
    bookingId: input.bookingId,
  })
    .sort({ recordedAt: -1 })
    .lean();

  if (
    last &&
    haversineMeters(
      { latitude: last.latitude, longitude: last.longitude },
      { latitude: input.latitude, longitude: input.longitude },
    ) < MIN_DISTANCE_M
  ) {
    return last;
  }

  const doc = await AmbulanceLocation.create({
    id: uuidv4(),
    bookingId: input.bookingId,
    ambulanceId: input.ambulanceId,
    vehicleId: input.vehicleId,
    driverId: input.driverId,
    latitude: input.latitude,
    longitude: input.longitude,
    accuracy: input.accuracy,
    heading: input.heading,
    speed: input.speed,
    recordedAt: new Date(),
  });

  if (input.ambulanceId && input.vehicleId) {
    await Ambulance.updateOne(
      { id: input.ambulanceId, 'vehicles.id': input.vehicleId },
      {
        $set: {
          'vehicles.$.currentLatitude': input.latitude,
          'vehicles.$.currentLongitude': input.longitude,
          'vehicles.$.lastLocationAt': new Date(),
          'vehicles.$.lastLocationAccuracy': input.accuracy,
          'vehicles.$.lastLocationHeading': input.heading,
          'vehicles.$.lastLocationSpeed': input.speed,
        },
      },
    );
  }

  return doc.toObject();
}

function locationFreshness(updatedAt) {
  if (!updatedAt) {
    return { stale: true, secondsAgo: null, message: 'Ambulance location temporarily unavailable' };
  }
  const secondsAgo = Math.max(0, Math.round((Date.now() - new Date(updatedAt).getTime()) / 1000));
  const staleAfter = Number(process.env.AMBULANCE_LOCATION_STALE_MS || 30000) / 1000;
  return {
    stale: secondsAgo > staleAfter,
    secondsAgo,
    message:
      secondsAgo > staleAfter
        ? 'Ambulance location temporarily unavailable'
        : `Location last updated ${secondsAgo} seconds ago`,
  };
}

module.exports = {
  persistAmbulanceLocation,
  locationFreshness,
  haversineMeters,
};
