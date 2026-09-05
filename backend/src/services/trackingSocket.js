const { Server } = require('socket.io');
const { verifyToken } = require('../middleware/auth');
const {
  startTracking,
  stopTracking,
  applyLocationUpdate,
  loadAuthorizedBooking,
  getTrackingSnapshot,
} = require('../db/trackingRepositories');

let io = null;

const providerOfflineTimers = new Map();
const lastLocationAt = new Map();
const MIN_LOCATION_INTERVAL_MS = Number(process.env.TRACKING_MIN_INTERVAL_MS || 2000);
const OFFLINE_GRACE_MS = Number(process.env.TRACKING_OFFLINE_GRACE_MS || 20000);

function bookingRoom(bookingId) {
  return `booking_${bookingId}`;
}

function userRoom(userType, userId) {
  return `${userType}_${userId}`;
}

function emitToUser(userType, userId, event, payload) {
  if (!io || !userType || !userId) return;
  io.to(userRoom(userType, userId)).emit(event, payload);
}

function safeAck(ack, payload) {
  if (typeof ack === 'function') {
    ack(payload);
  }
}

function emitToBooking(bookingId, event, payload) {
  if (!io || !bookingId) return;
  io.to(bookingRoom(bookingId)).emit(event, payload);
}

function emitTrackingStopped(bookingId, reason) {
  emitToBooking(bookingId, 'tracking_stopped', {
    bookingId,
    reason,
    trackingStatus:
      reason === 'cancelled'
        ? 'cancelled'
        : reason === 'completed'
          ? 'completed'
          : reason === 'visit_started'
            ? 'in_service'
            : reason === 'arrived'
              ? 'arrived'
              : 'accepted',
    timestamp: Date.now(),
  });
  emitToBooking(bookingId, 'tracking_status', {
    bookingId,
    trackingStatus:
      reason === 'cancelled'
        ? 'cancelled'
        : reason === 'completed'
          ? 'completed'
          : reason === 'visit_started'
            ? 'in_service'
            : reason === 'arrived'
              ? 'arrived'
              : 'accepted',
  });
}

function emitTrackingStatus(bookingId, trackingStatus) {
  emitToBooking(bookingId, 'tracking_status', {
    bookingId,
    trackingStatus,
    timestamp: Date.now(),
  });
}

function emitBookingStatusUpdate(booking) {
  if (!booking) return;
  let payload;
  try {
    const {
      workflowStatus,
      remainingPaymentSeconds,
      isPaymentPendingStatus,
    } = require('../db/nurseBookingStatus');
    payload = {
      bookingId: booking.id,
      status: booking.status,
      workflowStatus: workflowStatus(booking),
      paymentStatus: booking.paymentStatus,
      visitProgress: booking.visitProgress || null,
      verificationStatus: booking.verificationStatus || null,
      paymentExpiresAt: booking.paymentExpiresAt || null,
      remainingPaymentSeconds: isPaymentPendingStatus(booking.status)
        ? remainingPaymentSeconds(booking)
        : 0,
      lastNurseLatitude: booking.currentLatitude ?? null,
      lastNurseLongitude: booking.currentLongitude ?? null,
      lastNurseHeading: booking.currentHeading ?? null,
      lastLocationUpdatedAt: booking.liveLocationUpdatedAt || null,
      serverTime: new Date().toISOString(),
    };
  } catch {
    payload = {
      bookingId: booking.id,
      status: booking.status,
      paymentStatus: booking.paymentStatus,
      visitProgress: booking.visitProgress || null,
      verificationStatus: booking.verificationStatus || null,
      timestamp: Date.now(),
    };
  }
  emitToBooking(booking.id, 'booking-status-update', payload);
  emitToBooking(booking.id, 'booking_status_update', payload);
  if (booking.patientId) {
    emitToUser('patient', booking.patientId, 'booking-status-update', payload);
    emitToUser('patient', booking.patientId, 'booking_status_update', payload);
  }
  if (booking.nurseId) {
    emitToUser('nurse', booking.nurseId, 'booking-status-update', payload);
    emitToUser('nurse', booking.nurseId, 'booking_status_update', payload);
  }
  if (booking.doctorId) {
    emitToUser('doctor', booking.doctorId, 'booking-status-update', payload);
  }
}

function emitLocationToRoom(bookingId, location) {
  emitToBooking(bookingId, 'doctor_location_update', location);
  emitToBooking(bookingId, 'nurse-location-update', location);
  emitToBooking(bookingId, 'nurse_location_update', location);
}

function clearOfflineTimer(bookingId) {
  const timer = providerOfflineTimers.get(bookingId);
  if (timer) {
    clearTimeout(timer);
    providerOfflineTimers.delete(bookingId);
  }
}

function scheduleProviderOffline(bookingId) {
  clearOfflineTimer(bookingId);
  const timer = setTimeout(() => {
    providerOfflineTimers.delete(bookingId);
    emitToBooking(bookingId, 'provider_offline', {
      bookingId,
      message: 'Doctor/nurse phone appears offline. Showing last known location.',
      timestamp: Date.now(),
    });
  }, OFFLINE_GRACE_MS);
  providerOfflineTimers.set(bookingId, timer);
}

function attachTrackingSocket(httpServer) {
  const corsOriginRaw = (process.env.CORS_ORIGIN || '').trim();
  const corsOrigin =
    !corsOriginRaw || corsOriginRaw === '*'
      ? true
      : corsOriginRaw.split(',').map((o) => o.trim()).filter(Boolean);

  io = new Server(httpServer, {
    cors: {
      origin: corsOrigin,
      credentials: true,
    },
    path: '/socket.io',
    pingInterval: 20000,
    pingTimeout: 20000,
  });

  io.use((socket, next) => {
    const header = socket.handshake.headers?.authorization;
    const queryToken = socket.handshake.query?.token;
    const token =
      socket.handshake.auth?.token ||
      (Array.isArray(queryToken) ? queryToken[0] : queryToken) ||
      (typeof header === 'string' && header.startsWith('Bearer ')
        ? header.slice(7)
        : null);
    if (!token) {
      return next(new Error('Authentication required'));
    }
    try {
      const auth = verifyToken(token);
      if (!['patient', 'doctor', 'nurse', 'bloodbank', 'blood_bank_staff', 'ambulance', 'ambulance_driver', 'admin'].includes(auth?.type)) {
        return next(new Error('Invalid tracking identity'));
      }
      socket.data.auth = auth;
      socket.data.rooms = new Set();
      socket.data.providerBookings = new Set();
      next();
    } catch {
      next(new Error('Invalid or expired token'));
    }
  });

  io.on('connection', (socket) => {
    const auth = socket.data.auth || {};
    if (auth.type === 'patient' && auth.patientId) {
      socket.join(userRoom('patient', auth.patientId));
    } else if (auth.type === 'doctor' && auth.doctorId) {
      socket.join(userRoom('doctor', auth.doctorId));
    } else if (auth.type === 'nurse' && auth.nurseId) {
      socket.join(userRoom('nurse', auth.nurseId));
    } else if ((auth.type === 'bloodbank' || auth.type === 'blood_bank_staff') && auth.bloodBankId) {
      socket.join(userRoom('bloodbank', auth.bloodBankId));
    } else if ((auth.type === 'ambulance' || auth.type === 'ambulance_driver') && auth.ambulanceId) {
      socket.join(userRoom('ambulance', auth.ambulanceId));
      if (auth.driverId) socket.join(userRoom('ambulance_driver', auth.driverId));
    } else if (auth.type === 'admin') {
      socket.join(userRoom('admin', 'ops'));
    }

    socket.on('join_booking_room', onJoin);
    socket.on('join-booking-room', onJoin);

    async function onJoin(payload = {}, ack) {
      try {
        const bookingId = String(payload.bookingId || '').trim();
        if (!bookingId) {
          const err = { ok: false, code: 'INVALID_BOOKING', message: 'bookingId is required' };
          socket.emit('tracking_error', err);
          return safeAck(ack, err);
        }
        const booking = await loadAuthorizedBooking(bookingId, socket.data.auth);
        const room = bookingRoom(bookingId);
        await socket.join(room);
        socket.data.rooms.add(bookingId);
        const isProvider =
          (socket.data.auth.type === 'doctor' &&
            booking.doctorId === socket.data.auth.doctorId) ||
          (socket.data.auth.type === 'nurse' &&
            booking.nurseId === socket.data.auth.nurseId);
        if (isProvider) {
          socket.data.providerBookings.add(bookingId);
          clearOfflineTimer(bookingId);
        }
        let snapshot = null;
        try {
          if (booking.status === 'confirmed' && booking.consultationType === 'book_home') {
            snapshot = await getTrackingSnapshot(bookingId, socket.data.auth, {
              includeRoute: true,
            });
            socket.emit('tracking_status', {
              bookingId,
              trackingStatus: snapshot.trackingStatus,
              snapshot,
            });
          }
        } catch {
          snapshot = null;
        }
        const result = { ok: true, bookingId, snapshot };
        safeAck(ack, result);
      } catch (err) {
        const payloadErr = {
          ok: false,
          code: err.code || 'JOIN_FAILED',
          message: err.message || 'Unable to join booking room',
        };
        socket.emit('tracking_error', payloadErr);
        safeAck(ack, payloadErr);
      }
    }

    socket.on('leave_booking_room', (payload = {}) => {
      const bookingId = String(payload.bookingId || '').trim();
      if (bookingId) {
        socket.leave(bookingRoom(bookingId));
        socket.data.rooms.delete(bookingId);
      }
    });
    socket.on('leave-booking-room', (payload = {}) => {
      const bookingId = String(payload.bookingId || '').trim();
      if (bookingId) {
        socket.leave(bookingRoom(bookingId));
        socket.data.rooms.delete(bookingId);
      }
    });

    socket.on('start_tracking', onStartTracking);
    socket.on('nurse-started-trip', onStartTracking);

    async function onStartTracking(payload = {}, ack) {
      try {
        const bookingId = String(payload.bookingId || '').trim();
        const { alreadyStarted, snapshot } = await startTracking(
          bookingId,
          socket.data.auth,
        );
        socket.data.providerBookings.add(bookingId);
        await socket.join(bookingRoom(bookingId));
        socket.data.rooms.add(bookingId);
        clearOfflineTimer(bookingId);
        emitToBooking(bookingId, 'tracking_started', {
          bookingId,
          alreadyStarted,
          trackingStatus: 'on_the_way',
          timestamp: Date.now(),
        });
        emitToBooking(bookingId, 'nurse-started-trip', {
          bookingId,
          alreadyStarted,
          trackingStatus: 'on_the_way',
          timestamp: Date.now(),
        });
        emitTrackingStatus(bookingId, 'on_the_way');
        try {
          emitBookingStatusUpdate({
            id: bookingId,
            status: 'confirmed',
            visitProgress: 'en_route',
            nurseId: socket.data.auth.nurseId,
            doctorId: socket.data.auth.doctorId,
            patientId: snapshot?.patientId,
          });
        } catch {
          // snapshot may not include patientId
        }
        safeAck(ack, { ok: true, alreadyStarted, snapshot });
      } catch (err) {
        const payloadErr = {
          ok: false,
          code: err.code || 'START_FAILED',
          message: err.message || 'Unable to start tracking',
        };
        socket.emit('tracking_error', payloadErr);
        safeAck(ack, payloadErr);
      }
    }

    socket.on('doctor_location_update', onLocation);
    socket.on('nurse-location-update', onLocation);
    socket.on('nurse_location_update', onLocation);

    async function onLocation(payload = {}, ack) {
      try {
        const now = Date.now();
        const last = lastLocationAt.get(socket.id) || 0;
        if (now - last < MIN_LOCATION_INTERVAL_MS) {
          return safeAck(ack, { ok: true, throttled: true });
        }
        lastLocationAt.set(socket.id, now);

        const bookingId = String(payload.bookingId || '').trim();
        const location = await applyLocationUpdate(bookingId, socket.data.auth, payload);
        clearOfflineTimer(bookingId);
        emitLocationToRoom(bookingId, location);
        safeAck(ack, { ok: true, location });
      } catch (err) {
        const payloadErr = {
          ok: false,
          code: err.code || 'LOCATION_FAILED',
          message: err.message || 'Unable to update location',
        };
        socket.emit('tracking_error', payloadErr);
        safeAck(ack, payloadErr);
      }
    }

    socket.on('stop_tracking', onStopTracking);
    socket.on('nurse-arrived', (payload = {}, ack) =>
      onStopTracking({ ...payload, progress: payload.progress || 'arrived' }, ack),
    );

    async function onStopTracking(payload = {}, ack) {
      try {
        const bookingId = String(payload.bookingId || '').trim();
        const progress = payload.progress || payload.visitProgress;
        const { snapshot } = await stopTracking(bookingId, socket.data.auth, {
          progress,
        });
        socket.data.providerBookings.delete(bookingId);
        clearOfflineTimer(bookingId);
        emitTrackingStopped(bookingId, progress || 'stopped');
        if (progress === 'arrived') {
          emitToBooking(bookingId, 'nurse-arrived', {
            bookingId,
            trackingStatus: 'arrived',
            timestamp: Date.now(),
          });
        }
        safeAck(ack, { ok: true, snapshot });
      } catch (err) {
        const payloadErr = {
          ok: false,
          code: err.code || 'STOP_FAILED',
          message: err.message || 'Unable to stop tracking',
        };
        socket.emit('tracking_error', payloadErr);
        safeAck(ack, payloadErr);
      }
    }

    socket.on('disconnect', () => {
      lastLocationAt.delete(socket.id);
      for (const bookingId of socket.data.providerBookings || []) {
        scheduleProviderOffline(bookingId);
      }
    });
  });

  return io;
}

function getTrackingIo() {
  return io;
}

module.exports = {
  attachTrackingSocket,
  emitToBooking,
  emitToUser,
  emitTrackingStopped,
  emitTrackingStatus,
  emitLocationToRoom,
  emitBookingStatusUpdate,
  getTrackingIo,
};
