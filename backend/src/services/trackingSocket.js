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

function emitLocationToRoom(bookingId, location) {
  emitToBooking(bookingId, 'doctor_location_update', location);
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
      if (!['patient', 'doctor', 'nurse'].includes(auth?.type)) {
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
    socket.on('join_booking_room', async (payload = {}, ack) => {
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
        const snapshot = await getTrackingSnapshot(bookingId, socket.data.auth, {
          includeRoute: true,
        });
        const result = { ok: true, bookingId, snapshot };
        socket.emit('tracking_status', {
          bookingId,
          trackingStatus: snapshot.trackingStatus,
          snapshot,
        });
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
    });

    socket.on('start_tracking', async (payload = {}, ack) => {
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
        emitTrackingStatus(bookingId, 'on_the_way');
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
    });

    socket.on('doctor_location_update', async (payload = {}, ack) => {
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
    });

    socket.on('stop_tracking', async (payload = {}, ack) => {
      try {
        const bookingId = String(payload.bookingId || '').trim();
        const progress = payload.progress || payload.visitProgress;
        const { snapshot } = await stopTracking(bookingId, socket.data.auth, {
          progress,
        });
        socket.data.providerBookings.delete(bookingId);
        clearOfflineTimer(bookingId);
        emitTrackingStopped(bookingId, progress || 'stopped');
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
    });

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
  emitTrackingStopped,
  emitTrackingStatus,
  emitLocationToRoom,
  getTrackingIo,
};
