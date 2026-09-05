function emitBloodEvent(event, payload = {}) {
  try {
    const { emitToUser, emitToBooking } = require('./trackingSocket');
    const scoped = {
      ...payload,
      event,
      timestamp: Date.now(),
    };

    if (payload.patientId) {
      emitToUser('patient', payload.patientId, event, scoped);
      emitToUser('patient', payload.patientId, 'blood_event', scoped);
    }
    if (payload.bloodBankId) {
      emitToUser('bloodbank', payload.bloodBankId, event, scoped);
      emitToUser('bloodbank', payload.bloodBankId, 'blood_event', scoped);
    }
    if (payload.donorPatientId) {
      emitToUser('patient', payload.donorPatientId, event, scoped);
      emitToUser('donor', payload.donorPatientId, event, scoped);
    }
    const roomId = payload.requestId || payload.orderId || payload.bookingId;
    if (roomId) {
      emitToBooking(roomId, event, scoped);
    }
  } catch (err) {
    console.warn('[blood-realtime] emit failed:', err.message);
  }
}

module.exports = { emitBloodEvent };
