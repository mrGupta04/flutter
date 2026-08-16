const ConsultationBooking = require('./models/ConsultationBooking');
const Doctor = require('./models/Doctor');
const Nurse = require('./models/Nurse');
const { assertBookingActor } = require('./bookingLifecycleRepositories');
const { appendStatusHistory } = require('./bookingLifecycleHelpers');
const {
  setLiveLocation,
  getLiveLocation,
  clearLiveLocation,
  shouldPersist,
  markPersisted,
} = require('../services/liveLocationStore');
const { getRouteForBooking, clearRoute } = require('../services/routingService');

const TERMINAL_PROGRESS = new Set(['arrived', 'visit_started', 'completed']);

function resolveTrackingStatus(booking) {
  if (!booking) return 'idle';
  if (booking.status === 'cancelled') return 'cancelled';
  if (booking.visitProgress === 'completed') return 'completed';
  if (booking.visitProgress === 'visit_started') return 'in_service';
  if (booking.visitProgress === 'arrived') return 'arrived';
  if (booking.visitProgress === 'en_route' || booking.trackingStartedAt) {
    return 'on_the_way';
  }
  if (booking.status === 'confirmed') return 'accepted';
  return 'idle';
}

function isTrackingActive(booking) {
  const status = resolveTrackingStatus(booking);
  return status === 'on_the_way' && !booking.trackingStoppedAt;
}

function assertHomeVisitConfirmed(booking) {
  if (!booking) {
    const err = new Error('Booking not found');
    err.statusCode = 404;
    err.code = 'INVALID_BOOKING';
    throw err;
  }
  if (booking.consultationType !== 'book_home') {
    const err = new Error('Live tracking applies to home visits only');
    err.statusCode = 400;
    err.code = 'INVALID_BOOKING';
    throw err;
  }
  if (booking.status === 'cancelled') {
    const err = new Error('This booking was cancelled');
    err.statusCode = 409;
    err.code = 'BOOKING_CANCELLED';
    throw err;
  }
  if (booking.status !== 'confirmed') {
    const err = new Error('Visit must be confirmed before tracking');
    err.statusCode = 409;
    err.code = 'INVALID_BOOKING';
    throw err;
  }
}

async function loadAuthorizedBooking(bookingId, auth) {
  const booking = await ConsultationBooking.findOne({ id: bookingId });
  if (!booking) {
    const err = new Error('Booking not found');
    err.statusCode = 404;
    err.code = 'INVALID_BOOKING';
    throw err;
  }
  await assertBookingActor(booking, auth);
  return booking;
}

async function assertProviderOwnsBooking(booking, auth) {
  const { isDoctor, isNurse } = await assertBookingActor(booking, auth);
  if (!isDoctor && !isNurse) {
    const err = new Error('Only the assigned doctor or nurse can share location');
    err.statusCode = 403;
    err.code = 'UNAUTHORIZED';
    throw err;
  }
  return { isDoctor, isNurse };
}

async function loadProviderPublic(booking) {
  if (booking.nurseId) {
    const nurse = await Nurse.findOne({ id: booking.nurseId })
      .select('firstName lastName mobileNumber')
      .lean();
    const name = `${nurse?.firstName || ''} ${nurse?.lastName || ''}`.trim();
    return {
      providerType: 'nurse',
      providerId: booking.nurseId,
      providerName: name || 'Nurse',
      providerMobile: nurse?.mobileNumber || null,
    };
  }
  const doctor = await Doctor.findOne({ id: booking.doctorId })
    .select('firstName lastName mobileNumber')
    .lean();
  const name = `${doctor?.firstName || ''} ${doctor?.lastName || ''}`.trim();
  return {
    providerType: 'doctor',
    providerId: booking.doctorId,
    providerName: name || 'Doctor',
    providerMobile: doctor?.mobileNumber || null,
  };
}

function mergeLiveOntoBooking(booking) {
  const live = getLiveLocation(booking.id);
  if (!live) return booking;
  return {
    ...booking,
    currentLatitude: live.latitude,
    currentLongitude: live.longitude,
    currentHeading: live.heading,
    currentSpeed: live.speed,
    liveLocationUpdatedAt: new Date(live.timestamp),
  };
}

async function buildTrackingSnapshot(bookingDoc, { includeRoute = false } = {}) {
  const booking = mergeLiveOntoBooking(
    typeof bookingDoc.toObject === 'function' ? bookingDoc.toObject() : bookingDoc,
  );
  const provider = await loadProviderPublic(booking);
  const trackingStatus = resolveTrackingStatus(booking);
  const live = getLiveLocation(booking.id);

  const originLat = live?.latitude ?? booking.currentLatitude;
  const originLng = live?.longitude ?? booking.currentLongitude;

  let route = null;
  if (
    includeRoute &&
    Number.isFinite(originLat) &&
    Number.isFinite(originLng) &&
    Number.isFinite(booking.patientLatitude) &&
    Number.isFinite(booking.patientLongitude)
  ) {
    try {
      route = await getRouteForBooking({
        bookingId: booking.id,
        origin: { latitude: originLat, longitude: originLng },
        destination: {
          latitude: booking.patientLatitude,
          longitude: booking.patientLongitude,
        },
      });
    } catch {
      route = null;
    }
  }

  return {
    bookingId: booking.id,
    trackingStatus,
    visitProgress: booking.visitProgress || null,
    bookingStatus: booking.status,
    providerType: provider.providerType,
    providerId: provider.providerId,
    providerName: provider.providerName,
    providerMobile: provider.providerMobile,
    patientName: booking.patientName || null,
    patientAddress: booking.patientAddress || null,
    patientCity: booking.patientCity || null,
    patientLatitude: booking.patientLatitude ?? null,
    patientLongitude: booking.patientLongitude ?? null,
    currentLatitude: originLat ?? null,
    currentLongitude: originLng ?? null,
    heading: live?.heading ?? booking.currentHeading ?? null,
    speed: live?.speed ?? booking.currentSpeed ?? null,
    lastUpdatedAt: live?.timestamp
      ? new Date(live.timestamp).toISOString()
      : booking.liveLocationUpdatedAt
        ? new Date(booking.liveLocationUpdatedAt).toISOString()
        : null,
    trackingStartedAt: booking.trackingStartedAt || null,
    trackingStoppedAt: booking.trackingStoppedAt || null,
    isTracking: isTrackingActive(booking) && Boolean(live || booking.currentLatitude),
    distanceText: route?.distanceText || null,
    etaMinutes: route?.etaMinutes ?? null,
    durationText: route?.durationText || null,
    polyline: route?.polyline || null,
    routeSource: route?.source || null,
    routeWarning: route?.warning || null,
  };
}

async function startTracking(bookingId, auth) {
  const booking = await loadAuthorizedBooking(bookingId, auth);
  await assertProviderOwnsBooking(booking, auth);
  assertHomeVisitConfirmed(booking);

  if (TERMINAL_PROGRESS.has(booking.visitProgress)) {
    const err = new Error('Tracking already stopped for this visit');
    err.statusCode = 409;
    err.code = 'TRACKING_ALREADY_STOPPED';
    throw err;
  }

  const alreadyStarted =
    booking.visitProgress === 'en_route' &&
    booking.trackingStartedAt &&
    !booking.trackingStoppedAt;

  if (!alreadyStarted) {
    booking.visitProgress = 'en_route';
    booking.trackingStartedAt = booking.trackingStartedAt || new Date();
    booking.trackingStoppedAt = undefined;
    appendStatusHistory(booking, 'en_route', auth.type);
    await booking.save();
    if (booking.patientId) {
      try {
        const { createAndPushNotification } = require('./notificationRepositories');
        await createAndPushNotification({
          userId: booking.patientId,
          userType: 'patient',
          title: booking.nurseId ? 'Nurse on the way' : 'Doctor on the way',
          body: 'Your home visit provider is on the way. Open live tracking to follow them.',
          type: 'en_route',
          data: { bookingId: booking.id },
        });
      } catch (err) {
        console.error('[Tracking] en_route notify failed:', err.message);
      }
    }
  }

  return {
    alreadyStarted,
    snapshot: await buildTrackingSnapshot(booking, { includeRoute: false }),
  };
}

async function stopTracking(bookingId, auth, { progress } = {}) {
  const booking = await loadAuthorizedBooking(bookingId, auth);
  await assertProviderOwnsBooking(booking, auth);
  assertHomeVisitConfirmed(booking);

  if (booking.trackingStoppedAt && !progress) {
    return {
      alreadyStopped: true,
      snapshot: await buildTrackingSnapshot(booking, { includeRoute: false }),
    };
  }

  await stopTrackingInternal(booking, { progress, actor: auth.type });
  return {
    alreadyStopped: false,
    snapshot: await buildTrackingSnapshot(booking, { includeRoute: false }),
  };
}

async function stopTrackingInternal(booking, { progress, actor } = {}) {
  const live = getLiveLocation(booking.id);
  if (live) {
    booking.currentLatitude = live.latitude;
    booking.currentLongitude = live.longitude;
    booking.currentHeading = live.heading;
    booking.currentSpeed = live.speed;
    booking.liveLocationUpdatedAt = new Date(live.timestamp);
  }
  booking.trackingStoppedAt = new Date();
  if (progress && ['arrived', 'visit_started', 'completed'].includes(progress)) {
    booking.visitProgress = progress;
    if (progress === 'visit_started' && !booking.visitStartedAt) {
      booking.visitStartedAt = new Date();
    }
    if (progress === 'completed' && !booking.visitCompletedAt) {
      booking.visitCompletedAt = new Date();
    }
    appendStatusHistory(booking, progress, actor || 'system');
  }
  await booking.save();
  clearLiveLocation(booking.id);
  clearRoute(booking.id);
  return booking;
}

async function applyLocationUpdate(bookingId, auth, payload) {
  const booking = await loadAuthorizedBooking(bookingId, auth);
  await assertProviderOwnsBooking(booking, auth);
  assertHomeVisitConfirmed(booking);

  if (booking.status === 'cancelled') {
    const err = new Error('This booking was cancelled');
    err.statusCode = 409;
    err.code = 'BOOKING_CANCELLED';
    throw err;
  }
  if (TERMINAL_PROGRESS.has(booking.visitProgress) || booking.trackingStoppedAt) {
    const err = new Error('Tracking is not active for this booking');
    err.statusCode = 409;
    err.code = 'TRACKING_ALREADY_STOPPED';
    throw err;
  }

  const latitude = Number(payload.latitude);
  const longitude = Number(payload.longitude);
  if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) {
    const err = new Error('Valid latitude and longitude are required');
    err.statusCode = 400;
    throw err;
  }
  if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
    const err = new Error('Coordinates are out of range');
    err.statusCode = 400;
    throw err;
  }

  const providerId = auth.doctorId || auth.nurseId;
  const live = setLiveLocation(bookingId, {
    providerId,
    providerType: auth.type,
    latitude,
    longitude,
    heading: Number.isFinite(Number(payload.heading)) ? Number(payload.heading) : null,
    speed: Number.isFinite(Number(payload.speed)) ? Number(payload.speed) : null,
    timestamp: Number(payload.timestamp) || Date.now(),
  });

  if (shouldPersist(bookingId)) {
    await ConsultationBooking.updateOne(
      { id: bookingId },
      {
        $set: {
          currentLatitude: live.latitude,
          currentLongitude: live.longitude,
          currentHeading: live.heading,
          currentSpeed: live.speed,
          liveLocationUpdatedAt: new Date(live.timestamp),
        },
      },
    );
    markPersisted(bookingId);
  }

  return {
    bookingId,
    providerId,
    providerType: auth.type,
    latitude: live.latitude,
    longitude: live.longitude,
    heading: live.heading,
    speed: live.speed,
    timestamp: live.timestamp,
  };
}

async function getTrackingSnapshot(bookingId, auth, { includeRoute = true } = {}) {
  const booking = await loadAuthorizedBooking(bookingId, auth);
  assertHomeVisitConfirmed(booking);
  return buildTrackingSnapshot(booking, { includeRoute });
}

async function getTrackingRoute(bookingId, auth) {
  const snapshot = await getTrackingSnapshot(bookingId, auth, { includeRoute: true });
  return {
    bookingId: snapshot.bookingId,
    distanceText: snapshot.distanceText,
    durationText: snapshot.durationText,
    etaMinutes: snapshot.etaMinutes,
    polyline: snapshot.polyline,
    source: snapshot.routeSource,
    warning: snapshot.routeWarning,
    currentLatitude: snapshot.currentLatitude,
    currentLongitude: snapshot.currentLongitude,
    patientLatitude: snapshot.patientLatitude,
    patientLongitude: snapshot.patientLongitude,
  };
}

module.exports = {
  resolveTrackingStatus,
  isTrackingActive,
  startTracking,
  stopTracking,
  stopTrackingInternal,
  applyLocationUpdate,
  getTrackingSnapshot,
  getTrackingRoute,
  buildTrackingSnapshot,
  loadAuthorizedBooking,
};
