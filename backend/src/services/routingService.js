const axios = require('axios');

/**
 * Google Directions routing with in-memory cache.
 * Recomputes only when the provider has moved far enough or the TTL expires.
 * Falls back to haversine + urban average speed when no API key is configured.
 */

const cache = new Map();

const ROUTE_TTL_MS = Number(process.env.TRACKING_ROUTE_TTL_MS || 45000);
const RECOMPUTE_METERS = Number(process.env.TRACKING_ROUTE_RECOMPUTE_METERS || 250);
const URBAN_KMH = Number(process.env.TRACKING_FALLBACK_KMH || 25);

function haversineMeters(lat1, lon1, lat2, lon2) {
  const toRad = (d) => (d * Math.PI) / 180;
  const R = 6371000;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;
  return 2 * R * Math.asin(Math.min(1, Math.sqrt(a)));
}

function decodePolyline(encoded) {
  if (!encoded || typeof encoded !== 'string') return [];
  const points = [];
  let index = 0;
  let lat = 0;
  let lng = 0;
  while (index < encoded.length) {
    let b;
    let shift = 0;
    let result = 0;
    do {
      b = encoded.charCodeAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    const dlat = result & 1 ? ~(result >> 1) : result >> 1;
    lat += dlat;
    shift = 0;
    result = 0;
    do {
      b = encoded.charCodeAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    const dlng = result & 1 ? ~(result >> 1) : result >> 1;
    lng += dlng;
    points.push({ latitude: lat / 1e5, longitude: lng / 1e5 });
  }
  return points;
}

function fallbackRoute(origin, destination) {
  const meters = haversineMeters(
    origin.latitude,
    origin.longitude,
    destination.latitude,
    destination.longitude,
  );
  const km = Math.round((meters / 1000) * 10) / 10;
  const minutes = Math.max(1, Math.round((km / URBAN_KMH) * 60));
  return {
    distanceMeters: Math.round(meters),
    distanceText: km < 1 ? `${Math.round(meters)} m` : `${km} km`,
    durationSeconds: minutes * 60,
    durationText: minutes === 1 ? '1 min' : `${minutes} min`,
    etaMinutes: minutes,
    polyline: [origin, destination],
    source: 'haversine',
    updatedAt: Date.now(),
  };
}

function cacheKey(bookingId) {
  return `route:${bookingId}`;
}

function getCachedRoute(bookingId, origin) {
  const hit = cache.get(cacheKey(bookingId));
  if (!hit) return null;
  if (Date.now() - hit.updatedAt > ROUTE_TTL_MS) return null;
  const moved = haversineMeters(
    origin.latitude,
    origin.longitude,
    hit.origin.latitude,
    hit.origin.longitude,
  );
  if (moved >= RECOMPUTE_METERS) return null;
  return hit;
}

async function fetchGoogleRoute(origin, destination) {
  const key = (process.env.GOOGLE_MAPS_API_KEY || '').trim();
  if (!key) {
    return fallbackRoute(origin, destination);
  }

  const params = new URLSearchParams({
    origin: `${origin.latitude},${origin.longitude}`,
    destination: `${destination.latitude},${destination.longitude}`,
    mode: 'driving',
    key,
  });

  const url = `https://maps.googleapis.com/maps/api/directions/json?${params}`;
  const { data } = await axios.get(url, { timeout: 8000 });

  if (data.status !== 'OK' || !data.routes?.[0]?.legs?.[0]) {
    const err = new Error(data.error_message || `Directions API: ${data.status}`);
    err.code = 'ROUTING_FAILED';
    throw err;
  }

  const leg = data.routes[0].legs[0];
  const encoded = data.routes[0].overview_polyline?.points || '';
  const minutes = Math.max(1, Math.round((leg.duration?.value || 60) / 60));

  return {
    distanceMeters: leg.distance?.value ?? 0,
    distanceText: leg.distance?.text || '',
    durationSeconds: leg.duration?.value ?? 0,
    durationText: leg.duration?.text || '',
    etaMinutes: minutes,
    polyline: decodePolyline(encoded),
    source: 'google',
    updatedAt: Date.now(),
  };
}

async function getRouteForBooking({ bookingId, origin, destination, force = false }) {
  if (
    !Number.isFinite(origin?.latitude) ||
    !Number.isFinite(origin?.longitude) ||
    !Number.isFinite(destination?.latitude) ||
    !Number.isFinite(destination?.longitude)
  ) {
    const err = new Error('Origin and destination coordinates are required');
    err.statusCode = 400;
    throw err;
  }

  if (!force) {
    const cached = getCachedRoute(bookingId, origin);
    if (cached) return cached;
  }

  let route;
  try {
    route = await fetchGoogleRoute(origin, destination);
  } catch (err) {
    if (err.code === 'ROUTING_FAILED') {
      route = {
        ...fallbackRoute(origin, destination),
        warning: err.message,
      };
    } else {
      route = fallbackRoute(origin, destination);
    }
  }

  const stored = { ...route, origin, destination };
  cache.set(cacheKey(bookingId), stored);
  return stored;
}

function clearRoute(bookingId) {
  cache.delete(cacheKey(bookingId));
}

module.exports = {
  getRouteForBooking,
  clearRoute,
  haversineMeters,
};
