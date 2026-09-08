const { createAndPushNotification } = require('../db/notificationRepositories');
const { userFacingLabel } = require('./ambulanceStatus');

const lastAlertAt = new Map();
const ALERT_THROTTLE_MS = Number(process.env.AMBULANCE_ALERT_THROTTLE_MS || 8000);

function throttleKey(userId, type) {
  return `${userId}:${type}`;
}

function shouldNotify(userId, type) {
  const key = throttleKey(userId, type);
  const last = lastAlertAt.get(key) || 0;
  if (Date.now() - last < ALERT_THROTTLE_MS) return false;
  lastAlertAt.set(key, Date.now());
  return true;
}

async function notifyUser(userId, userType, title, body, type, data) {
  if (!userId) return null;
  return createAndPushNotification({
    userId,
    userType,
    title,
    body,
    type,
    data,
  });
}

async function notifyAmbulanceStatus(booking, extra = {}) {
  if (!booking) return;
  const statusLabel = userFacingLabel(booking.status);
  const data = {
    bookingId: booking.id,
    status: booking.status,
    ambulanceId: booking.ambulanceId,
    highPriority: booking.isEmergency,
    ...extra,
  };

  if (booking.patientId) {
    await notifyUser(
      booking.patientId,
      'patient',
      statusLabel,
      extra.patientBody || `${statusLabel} for booking ${booking.id.slice(0, 8)}.`,
      extra.patientType || 'ambulance_update',
      data,
    );
  }

  if (booking.ambulanceId && extra.notifyProvider !== false) {
    await notifyUser(
      booking.ambulanceId,
      'ambulance',
      extra.providerTitle || statusLabel,
      extra.providerBody || statusLabel,
      extra.providerType || 'ambulance_update',
      data,
    );
  }
}

async function notifyEmergencyOffer(offer, booking) {
  if (!offer?.ambulanceId || !shouldNotify(offer.ambulanceId, 'emergency_offer')) {
    return null;
  }
  return notifyUser(
    offer.ambulanceId,
    'ambulance',
    'EMERGENCY AMBULANCE REQUEST',
    [
      `Pickup: ${booking.pickupAddress}`,
      booking.dropAddress ? `Destination: ${booking.dropAddress}` : null,
      offer.etaMinutes ? `Estimated pickup: ${offer.etaMinutes} min` : null,
      booking.vehicleTypeRequested
        ? `Ambulance required: ${booking.vehicleTypeRequested}`
        : null,
    ]
      .filter(Boolean)
      .join(' · '),
    'ambulance_emergency',
    {
      action: 'incoming_booking_request',
      providerRole: 'ambulance',
      bookingId: booking.id,
      dispatchId: offer.dispatchId,
      ambulanceId: offer.ambulanceId,
      vehicleId: offer.vehicleId,
      driverId: offer.driverId,
      patientName: booking.patientName,
      location: booking.pickupAddress,
      service: 'Emergency ambulance',
      status: booking.status || 'searching_ambulance',
      alertSeconds: 25,
      highPriority: true,
      sound: 'emergency',
      vibration: true,
    },
  );
}

module.exports = {
  notifyUser,
  notifyAmbulanceStatus,
  notifyEmergencyOffer,
};
