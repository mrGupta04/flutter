function emitAmbulanceEvent(event, payload = {}) {
  try {
    const { emitToUser, emitToBooking } = require('./trackingSocket');
    const scoped = {
      ...payload,
      event,
      timestamp: Date.now(),
    };

    if (payload.patientId) {
      emitToUser('patient', payload.patientId, event, scoped);
      emitToUser('patient', payload.patientId, 'ambulance_event', scoped);
    }
    if (payload.ambulanceId) {
      emitToUser('ambulance', payload.ambulanceId, event, scoped);
      emitToUser('ambulance', payload.ambulanceId, 'ambulance_event', scoped);
    }
    if (payload.driverId) {
      emitToUser('ambulance_driver', payload.driverId, event, scoped);
    }
    if (payload.adminBroadcast) {
      emitToUser('admin', 'ops', event, scoped);
    }
    const roomId = payload.bookingId || payload.requestId;
    if (roomId) {
      emitToBooking(roomId, event, scoped);
    }
  } catch (err) {
    console.warn('[ambulance-realtime] emit failed:', err.message);
  }
}

module.exports = { emitAmbulanceEvent };
