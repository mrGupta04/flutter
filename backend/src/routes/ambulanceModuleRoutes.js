const express = require('express');
const bcrypt = require('bcryptjs');
const { sendSuccess, sendError } = require('../utils/response');
const { adminRequired, signToken, authRequired } = require('../middleware/auth');
const {
  ambulanceRequired,
  ambulanceProviderRequired,
  ambulanceDriverRequired,
  patientRequired,
  actorFromAuth,
} = require('../middleware/ambulanceAuth');
const { catalogPayload } = require('../db/ambulanceConstants');
const {
  createAmbulanceBooking,
  findAmbulanceBookingById,
  listIncomingAmbulanceRequests,
  listAmbulanceBookingsForPatient,
  listAllAmbulanceBookings,
  cancelAmbulanceBooking,
  updateAmbulanceLiveLocation,
  submitAmbulanceReview,
} = require('../db/ambulanceBookingRepositories');
const { listAmbulanceStatusHistory, listAmbulanceAuditLogs } = require('../db/ambulanceAuditRepositories');
const {
  upsertVehicle,
  upsertDriver,
  setVehicleStatus,
  setDriverPresence,
  findDriverByMobile,
  updateOperationsSettings,
  assignVehicleToDriver,
} = require('../db/ambulanceFleetRepositories');
const {
  startDispatch,
  acceptDispatch,
  acceptDirectAssignment,
  rejectDispatch,
  acceptScheduledBooking,
  rejectScheduledBooking,
  advanceTrip,
  reassignBooking,
  nearbyAmbulances,
  estimateForRequest,
} = require('../services/ambulanceDispatchService');
const {
  createAmbulancePaymentOrder,
  confirmAmbulancePayment,
  markCashPayment,
  refundAmbulancePayment,
} = require('../db/ambulancePaymentRepositories');
const {
  getProviderDashboard,
  getProviderAnalytics,
  getAdminAmbulanceOverview,
  getAdminAnalytics,
  getLiveOperations,
  listPublicProviders,
  getPublicProvider,
  setProviderAccess,
} = require('../db/ambulanceOpsRepositories');
const { getFareRules, upsertFareRules } = require('../services/ambulanceFareService');
const { locationFreshness } = require('../services/ambulanceLocationService');
const { emitAmbulanceEvent } = require('../services/ambulanceRealtime');
const { registerDeviceToken } = require('../db/notificationRepositories');
const { notifyAmbulanceStatus } = require('../services/ambulanceNotificationService');
const { parseRequirements } = require('../db/ambulanceBookingRepositories');
const Ambulance = require('../db/models/Ambulance');
const Doctor = require('../db/models/Doctor');

const router = express.Router();

function handle(res, err, fallback) {
  console.error(err);
  return sendError(res, err.message || fallback, err.statusCode || 500);
}

router.get('/catalog', (_req, res) => {
  return sendSuccess(res, { data: catalogPayload() });
});

router.get('/providers', async (req, res) => {
  try {
    const data = await listPublicProviders({
      page: Math.max(1, parseInt(req.query.page || '1', 10)),
      pageSize: Math.min(50, parseInt(req.query.pageSize || '20', 10)),
      city: req.query.city,
      vehicleType: req.query.vehicleType,
    });
    return sendSuccess(res, { data: data.providers, pagination: data.pagination });
  } catch (err) {
    return handle(res, err, 'Failed to list ambulance providers');
  }
});

router.get('/providers/:id', async (req, res) => {
  try {
    const data = await getPublicProvider(req.params.id);
    return sendSuccess(res, { data });
  } catch (err) {
    return handle(res, err, 'Failed to load provider');
  }
});

router.get('/hospitals', async (req, res) => {
  try {
    const lat = Number(req.query.latitude);
    const lng = Number(req.query.longitude);
    const docs = await Doctor.find({
      verificationStatus: 'verified',
      clinicName: { $exists: true, $ne: '' },
    })
      .select('id clinicName address city state latitude longitude mobileNumber')
      .limit(80)
      .lean();
    const { distanceKm } = require('../utils/geoDistance');
    const hospitals = docs.map((doc) => ({
      id: doc.id,
      name: doc.clinicName,
      address: [doc.address, doc.city, doc.state].filter(Boolean).join(', '),
      city: doc.city,
      latitude: doc.latitude,
      longitude: doc.longitude,
      contact: doc.mobileNumber,
      distanceKm:
        Number.isFinite(lat) && Number.isFinite(doc.latitude)
          ? distanceKm(lat, lng, doc.latitude, doc.longitude)
          : null,
      emergencyDepartmentAvailable: null,
    }));
    hospitals.sort((a, b) => (a.distanceKm ?? 999) - (b.distanceKm ?? 999));
    return sendSuccess(res, {
      data: hospitals,
      message:
        'Hospital list is based on verified clinics on this platform. Emergency department capacity is not claimed unless verified in real time.',
    });
  } catch (err) {
    return handle(res, err, 'Failed to list hospitals');
  }
});

router.get('/nearby', authRequired, async (req, res) => {
  try {
    const matches = await nearbyAmbulances({
      latitude: req.query.latitude,
      longitude: req.query.longitude,
      vehicleType: req.query.vehicleType,
      emergency: req.query.emergency !== 'false',
      radiusKm: req.query.radiusKm,
      requirements: parseRequirements(req.query),
    });
    return sendSuccess(res, { data: matches });
  } catch (err) {
    return handle(res, err, 'Failed to find nearby ambulances');
  }
});

router.post('/fare/estimate', async (req, res) => {
  try {
    const estimate = await estimateForRequest({
      ...req.body,
      requirements: parseRequirements(req.body || {}),
    });
    return sendSuccess(res, { data: estimate });
  } catch (err) {
    return handle(res, err, 'Failed to estimate fare');
  }
});

router.post('/emergency', patientRequired, async (req, res) => {
  try {
    const booking = await createAmbulanceBooking({
      ...req.body,
      patientId: req.auth.patientId,
      patientEmail: req.body?.patientEmail || req.auth.email,
      bookingKind: 'emergency',
      isEmergency: true,
      ambulanceId: req.body?.ambulanceId,
    });
    emitAmbulanceEvent('ambulance_request_created', {
      bookingId: booking.id,
      patientId: booking.patientId,
    });
    await notifyAmbulanceStatus(booking, {
      patientBody: 'Searching for a nearby ambulance. This is a transportation request, not medical advice.',
      patientType: 'ambulance_emergency',
    });
    const dispatch = await startDispatch(booking.id, {
      actor: actorFromAuth(req.auth),
      preferredAmbulanceId: booking.ambulanceId,
    });
    return sendSuccess(res, {
      statusCode: 201,
      message: 'Emergency ambulance request created. Searching for a suitable ambulance.',
      data: { booking: dispatch?.booking || booking, offered: dispatch?.offered || [] },
    });
  } catch (err) {
    return handle(res, err, 'Failed to create emergency request');
  }
});

router.post('/scheduled', patientRequired, async (req, res) => {
  try {
    const booking = await createAmbulanceBooking({
      ...req.body,
      patientId: req.auth.patientId,
      patientEmail: req.body?.patientEmail || req.auth.email,
      bookingKind: 'scheduled',
      isEmergency: false,
    });
    if (booking.ambulanceId) {
      emitAmbulanceEvent('ambulance_request_created', {
        bookingId: booking.id,
        patientId: booking.patientId,
        ambulanceId: booking.ambulanceId,
      });
    }
    return sendSuccess(res, {
      statusCode: 201,
      message: 'Scheduled ambulance request submitted',
      data: booking,
    });
  } catch (err) {
    return handle(res, err, 'Failed to create scheduled booking');
  }
});

router.get('/my-bookings', patientRequired, async (req, res) => {
  try {
    const bookings = await listAmbulanceBookingsForPatient({
      patientId: req.auth.patientId,
      patientEmail: req.auth.email,
      statusGroup: req.query.group,
    });
    return sendSuccess(res, { data: bookings });
  } catch (err) {
    return handle(res, err, 'Failed to load bookings');
  }
});

router.get('/my-bookings/:id', patientRequired, async (req, res) => {
  try {
    const booking = await findAmbulanceBookingById(req.params.id);
    if (!booking) return sendError(res, 'Booking not found', 404);
    if (booking.patientId && booking.patientId !== req.auth.patientId) {
      return sendError(res, 'Not authorized to view this booking', 403);
    }
    const history = await listAmbulanceStatusHistory(booking.id);
    const freshness = locationFreshness(booking.liveLocationUpdatedAt);
    return sendSuccess(res, { data: { ...booking, history, location: freshness } });
  } catch (err) {
    return handle(res, err, 'Failed to load booking');
  }
});

router.get('/my-bookings/:id/location', patientRequired, async (req, res) => {
  try {
    const booking = await findAmbulanceBookingById(req.params.id);
    if (!booking) return sendError(res, 'Booking not found', 404);
    if (booking.patientId && booking.patientId !== req.auth.patientId) {
      return sendError(res, 'Not authorized to view this location', 403);
    }
    const terminal = ['trip_completed', 'completed', 'cancelled', 'expired', 'failed', 'no_answer'].includes(
      booking.status,
    );
    if (terminal) {
      return sendSuccess(res, {
        data: {
          available: false,
          message: 'Live tracking is only available during an active trip.',
        },
      });
    }
    return sendSuccess(res, {
      data: {
        available: Boolean(booking.liveLatitude),
        latitude: booking.liveLatitude,
        longitude: booking.liveLongitude,
        heading: booking.liveHeading,
        speed: booking.liveSpeed,
        updatedAt: booking.liveLocationUpdatedAt,
        location: locationFreshness(booking.liveLocationUpdatedAt),
      },
    });
  } catch (err) {
    return handle(res, err, 'Failed to load location');
  }
});

router.post('/my-bookings/:id/cancel', patientRequired, async (req, res) => {
  try {
    const existing = await findAmbulanceBookingById(req.params.id);
    if (!existing) return sendError(res, 'Booking not found', 404);
    if (existing.patientId && existing.patientId !== req.auth.patientId) {
      return sendError(res, 'Not authorized', 403);
    }
    const booking = await cancelAmbulanceBooking({
      bookingId: req.params.id,
      actor: actorFromAuth(req.auth),
      reason: req.body?.reason,
      asUser: true,
    });
    emitAmbulanceEvent('ambulance_request_cancelled', {
      bookingId: booking.id,
      patientId: booking.patientId,
      ambulanceId: booking.ambulanceId,
    });
    return sendSuccess(res, { message: 'Booking cancelled', data: booking });
  } catch (err) {
    return handle(res, err, 'Failed to cancel booking');
  }
});

router.post('/my-bookings/:id/retry-dispatch', patientRequired, async (req, res) => {
  try {
    const existing = await findAmbulanceBookingById(req.params.id);
    if (!existing || existing.patientId !== req.auth.patientId) {
      return sendError(res, 'Booking not found', 404);
    }
    const result = await startDispatch(existing.id, { actor: actorFromAuth(req.auth) });
    return sendSuccess(res, { data: result, message: 'Search expanded. Looking for more ambulances.' });
  } catch (err) {
    return handle(res, err, 'Failed to retry dispatch');
  }
});

router.post('/my-bookings/:id/review', patientRequired, async (req, res) => {
  try {
    const review = await submitAmbulanceReview({
      bookingId: req.params.id,
      patientId: req.auth.patientId,
      ...req.body,
    });
    return sendSuccess(res, { message: 'Review submitted', data: review });
  } catch (err) {
    return handle(res, err, 'Failed to submit review');
  }
});

router.post('/payments/create-order', patientRequired, async (req, res) => {
  try {
    const data = await createAmbulancePaymentOrder(
      req.body?.bookingId,
      req.auth.patientId,
    );
    return sendSuccess(res, { data });
  } catch (err) {
    return handle(res, err, 'Failed to create payment order');
  }
});

router.post('/payments/verify', patientRequired, async (req, res) => {
  try {
    const booking = await confirmAmbulancePayment({
      bookingId: req.body?.bookingId,
      razorpayOrderId: req.body?.razorpayOrderId,
      razorpayPaymentId: req.body?.razorpayPaymentId,
      razorpaySignature: req.body?.razorpaySignature,
      actor: actorFromAuth(req.auth),
    });
    return sendSuccess(res, { message: 'Payment verified', data: booking });
  } catch (err) {
    return handle(res, err, 'Payment verification failed');
  }
});

router.post('/device-token', ambulanceRequired, async (req, res) => {
  try {
    const data = await registerDeviceToken(
      req.ambulanceId,
      'ambulance',
      req.body?.token || req.body?.deviceToken,
    );
    return sendSuccess(res, { data });
  } catch (err) {
    return handle(res, err, 'Failed to register device token');
  }
});

router.post('/driver/login', async (req, res) => {
  try {
    const found = await findDriverByMobile(req.body?.mobileNumber);
    if (!found?.driver?.pinHash) {
      return sendError(res, 'Invalid driver credentials', 401);
    }
    if (!bcrypt.compareSync(String(req.body?.pin || ''), found.driver.pinHash)) {
      return sendError(res, 'Invalid driver credentials', 401);
    }
    if (found.driver.status === 'SUSPENDED') {
      return sendError(res, 'Driver account is suspended', 403);
    }
    const token = signToken(
      {
        type: 'ambulance_driver',
        ambulanceId: found.provider.id,
        driverId: found.driver.id,
        mobileNumber: found.driver.mobileNumber,
      },
      '30d',
    );
    return sendSuccess(res, {
      message: 'Driver login successful',
      token,
      data: {
        driver: { ...found.driver, pinHash: undefined },
        provider: {
          id: found.provider.id,
          serviceName: found.provider.serviceName,
        },
      },
    });
  } catch (err) {
    return handle(res, err, 'Driver login failed');
  }
});

router.get('/dashboard', ambulanceRequired, async (req, res) => {
  try {
    const data = await getProviderDashboard(req.ambulanceId);
    return sendSuccess(res, { data });
  } catch (err) {
    return handle(res, err, 'Failed to load dashboard');
  }
});

router.get('/analytics', ambulanceRequired, async (req, res) => {
  try {
    const data = await getProviderAnalytics(req.ambulanceId);
    return sendSuccess(res, { data });
  } catch (err) {
    return handle(res, err, 'Failed to load analytics');
  }
});

router.put('/operations', ambulanceProviderRequired, async (req, res) => {
  try {
    const data = await updateOperationsSettings(
      req.ambulanceId,
      req.body || {},
      actorFromAuth(req.auth),
    );
    return sendSuccess(res, { message: 'Operations updated', data });
  } catch (err) {
    return handle(res, err, 'Failed to update operations');
  }
});

router.get('/fleet', ambulanceRequired, async (req, res) => {
  try {
    const provider = await Ambulance.findOne({ id: req.ambulanceId }).lean();
    if (!provider) return sendError(res, 'Provider not found', 404);
    return sendSuccess(res, {
      data: {
        vehicles: provider.vehicles || [],
        drivers: (provider.drivers || []).map((d) => ({ ...d, pinHash: undefined })),
      },
    });
  } catch (err) {
    return handle(res, err, 'Failed to load fleet');
  }
});

router.post('/fleet/vehicles', ambulanceProviderRequired, async (req, res) => {
  try {
    const vehicle = await upsertVehicle(
      req.ambulanceId,
      req.body || {},
      actorFromAuth(req.auth),
    );
    return sendSuccess(res, { message: 'Ambulance saved', data: vehicle });
  } catch (err) {
    return handle(res, err, 'Failed to save ambulance');
  }
});

router.patch('/fleet/vehicles/:id', ambulanceProviderRequired, async (req, res) => {
  try {
    const vehicle = await upsertVehicle(
      req.ambulanceId,
      { ...req.body, id: req.params.id },
      actorFromAuth(req.auth),
    );
    return sendSuccess(res, { message: 'Ambulance updated', data: vehicle });
  } catch (err) {
    return handle(res, err, 'Failed to update ambulance');
  }
});

router.post('/fleet/vehicles/:id/status', ambulanceProviderRequired, async (req, res) => {
  try {
    const vehicle = await setVehicleStatus(
      req.ambulanceId,
      req.params.id,
      req.body?.status,
      actorFromAuth(req.auth),
    );
    return sendSuccess(res, { data: vehicle });
  } catch (err) {
    return handle(res, err, 'Failed to update ambulance status');
  }
});

router.post('/fleet/drivers', ambulanceProviderRequired, async (req, res) => {
  try {
    const driver = await upsertDriver(
      req.ambulanceId,
      req.body || {},
      actorFromAuth(req.auth),
    );
    return sendSuccess(res, { message: 'Driver saved', data: driver });
  } catch (err) {
    return handle(res, err, 'Failed to save driver');
  }
});

router.patch('/fleet/drivers/:id', ambulanceProviderRequired, async (req, res) => {
  try {
    const driver = await upsertDriver(
      req.ambulanceId,
      { ...req.body, id: req.params.id },
      actorFromAuth(req.auth),
    );
    return sendSuccess(res, { message: 'Driver updated', data: driver });
  } catch (err) {
    return handle(res, err, 'Failed to update driver');
  }
});

router.post('/fleet/assign', ambulanceProviderRequired, async (req, res) => {
  try {
    const data = await assignVehicleToDriver(
      req.ambulanceId,
      req.body?.vehicleId,
      req.body?.driverId,
      actorFromAuth(req.auth),
    );
    return sendSuccess(res, { data });
  } catch (err) {
    return handle(res, err, 'Failed to assign driver');
  }
});

router.post('/driver/presence', ambulanceRequired, async (req, res) => {
  try {
    const driverId = req.driverId || req.body?.driverId;
    if (!driverId) return sendError(res, 'driverId is required', 400);
    const driver = await setDriverPresence({
      ambulanceId: req.ambulanceId,
      driverId,
      online: req.body?.online,
      status: req.body?.status,
      latitude: req.body?.latitude,
      longitude: req.body?.longitude,
    });
    return sendSuccess(res, { data: driver });
  } catch (err) {
    return handle(res, err, 'Failed to update driver presence');
  }
});

router.get('/requests', ambulanceRequired, async (req, res) => {
  try {
    const bookings = await listIncomingAmbulanceRequests(req.ambulanceId, {
      status: req.query.status,
      kind: req.query.kind,
    });
    return sendSuccess(res, { data: bookings });
  } catch (err) {
    return handle(res, err, 'Failed to load requests');
  }
});

router.post('/requests/:id/accept', ambulanceRequired, async (req, res) => {
  try {
    const existing = await findAmbulanceBookingById(req.params.id);
    if (!existing) return sendError(res, 'Request not found', 404);
    const actor = actorFromAuth(req.auth);
    let booking;
    if (existing.bookingKind === 'scheduled' && existing.status === 'requested') {
      booking = await acceptScheduledBooking({
        bookingId: req.params.id,
        ambulanceId: req.ambulanceId,
        vehicleId: req.body?.vehicleId,
        driverId: req.driverId || req.body?.driverId,
        actor,
      });
    } else {
      try {
        booking = await acceptDispatch({
          bookingId: req.params.id,
          ambulanceId: req.ambulanceId,
          vehicleId: req.body?.vehicleId,
          driverId: req.driverId || req.body?.driverId,
          dispatchId: req.body?.dispatchId,
          actor,
        });
      } catch (err) {
        if (err.code !== 'DISPATCH_UNAVAILABLE') throw err;
        booking = await acceptDirectAssignment({
          bookingId: req.params.id,
          ambulanceId: req.ambulanceId,
          vehicleId: req.body?.vehicleId,
          driverId: req.driverId || req.body?.driverId,
          actor,
        });
      }
    }
    return sendSuccess(res, { message: 'Request accepted', data: booking });
  } catch (err) {
    return handle(res, err, 'Failed to accept request');
  }
});

router.post('/requests/:id/reject', ambulanceRequired, async (req, res) => {
  try {
    const existing = await findAmbulanceBookingById(req.params.id);
    if (!existing) return sendError(res, 'Request not found', 404);
    const actor = actorFromAuth(req.auth);
    if (existing.bookingKind === 'scheduled' && existing.status === 'requested') {
      const booking = await rejectScheduledBooking({
        bookingId: req.params.id,
        ambulanceId: req.ambulanceId,
        reason: req.body?.reason,
        actor,
      });
      return sendSuccess(res, { message: 'Request rejected', data: booking });
    }
    await rejectDispatch({
      bookingId: req.params.id,
      ambulanceId: req.ambulanceId,
      dispatchId: req.body?.dispatchId,
      reason: req.body?.reason,
      actor,
    });
    return sendSuccess(res, { message: 'Request rejected' });
  } catch (err) {
    return handle(res, err, 'Failed to reject request');
  }
});

const tripActions = [
  ['start', 'start'],
  ['arrived', 'arrived'],
  ['pickup', 'pickup'],
  ['enroute', 'enroute'],
  ['destination', 'destination'],
  ['complete', 'complete'],
];

for (const [path, action] of tripActions) {
  router.post(`/trips/:id/${path}`, ambulanceRequired, async (req, res) => {
    try {
      const booking = await advanceTrip({
        bookingId: req.params.id,
        ambulanceId: req.ambulanceId,
        action,
        actor: actorFromAuth(req.auth),
        extra: req.body || {},
      });
      return sendSuccess(res, { data: booking });
    } catch (err) {
      return handle(res, err, `Failed to ${action} trip`);
    }
  });
}

router.post('/trips/:id/location', ambulanceRequired, async (req, res) => {
  try {
    const result = await updateAmbulanceLiveLocation({
      bookingId: req.params.id,
      ambulanceId: req.ambulanceId,
      latitude: req.body?.latitude,
      longitude: req.body?.longitude,
      accuracy: req.body?.accuracy,
      heading: req.body?.heading,
      speed: req.body?.speed,
      vehicleId: req.body?.vehicleId,
      driverId: req.driverId || req.body?.driverId,
    });
    if (!result.throttled) {
      emitAmbulanceEvent('ambulance_location_updated', {
        bookingId: req.params.id,
        patientId: result.booking.patientId,
        ambulanceId: req.ambulanceId,
        latitude: result.booking.liveLatitude,
        longitude: result.booking.liveLongitude,
        heading: result.booking.liveHeading,
        updatedAt: result.booking.liveLocationUpdatedAt,
      });
    }
    return sendSuccess(res, { data: result.booking, message: result.throttled ? 'Throttled' : 'Updated' });
  } catch (err) {
    return handle(res, err, 'Failed to update location');
  }
});

router.post('/trips/:id/cancel', ambulanceRequired, async (req, res) => {
  try {
    const booking = await cancelAmbulanceBooking({
      bookingId: req.params.id,
      actor: actorFromAuth(req.auth),
      reason: req.body?.reason,
      asUser: false,
    });
    emitAmbulanceEvent('ambulance_request_cancelled', {
      bookingId: booking.id,
      patientId: booking.patientId,
      ambulanceId: booking.ambulanceId,
    });
    return sendSuccess(res, { data: booking });
  } catch (err) {
    return handle(res, err, 'Failed to cancel trip');
  }
});

router.post('/trips/:id/cash', ambulanceProviderRequired, async (req, res) => {
  try {
    const booking = await markCashPayment(
      req.params.id,
      req.ambulanceId,
      actorFromAuth(req.auth),
    );
    return sendSuccess(res, { message: 'Cash payment recorded', data: booking });
  } catch (err) {
    return handle(res, err, 'Failed to record cash payment');
  }
});

router.get('/admin/overview', adminRequired, async (_req, res) => {
  try {
    const data = await getAdminAmbulanceOverview();
    return sendSuccess(res, { data });
  } catch (err) {
    return handle(res, err, 'Failed to load ambulance overview');
  }
});

router.get('/admin/analytics', adminRequired, async (_req, res) => {
  try {
    const data = await getAdminAnalytics();
    return sendSuccess(res, { data });
  } catch (err) {
    return handle(res, err, 'Failed to load analytics');
  }
});

router.get('/admin/bookings', adminRequired, async (req, res) => {
  try {
    const data = await listAllAmbulanceBookings({
      status: req.query.status,
      kind: req.query.kind,
      ambulanceId: req.query.ambulanceId,
      page: Math.max(1, parseInt(req.query.page || '1', 10)),
      pageSize: Math.min(50, parseInt(req.query.pageSize || '20', 10)),
    });
    return sendSuccess(res, { data: data.bookings, pagination: data.pagination });
  } catch (err) {
    return handle(res, err, 'Failed to list bookings');
  }
});

router.get('/admin/live', adminRequired, async (_req, res) => {
  try {
    const data = await getLiveOperations();
    return sendSuccess(res, { data });
  } catch (err) {
    return handle(res, err, 'Failed to load live operations');
  }
});

router.get('/admin/audit', adminRequired, async (req, res) => {
  try {
    const data = await listAmbulanceAuditLogs({
      ambulanceId: req.query.ambulanceId,
      action: req.query.action,
      page: Math.max(1, parseInt(req.query.page || '1', 10)),
    });
    return sendSuccess(res, { data: data.logs, pagination: data.pagination });
  } catch (err) {
    return handle(res, err, 'Failed to load audit logs');
  }
});

router.post('/admin/providers/:id/suspend', adminRequired, async (req, res) => {
  try {
    const data = await setProviderAccess(
      req.params.id,
      { suspended: true },
      actorFromAuth(req.auth),
    );
    return sendSuccess(res, { message: 'Provider suspended', data });
  } catch (err) {
    return handle(res, err, 'Failed to suspend provider');
  }
});

router.post('/admin/providers/:id/enable', adminRequired, async (req, res) => {
  try {
    const data = await setProviderAccess(
      req.params.id,
      { suspended: false, disabled: false },
      actorFromAuth(req.auth),
    );
    return sendSuccess(res, { message: 'Provider enabled', data });
  } catch (err) {
    return handle(res, err, 'Failed to enable provider');
  }
});

router.post('/admin/dispatch/:id/reassign', adminRequired, async (req, res) => {
  try {
    const data = await reassignBooking({
      bookingId: req.params.id,
      actor: actorFromAuth(req.auth),
      reason: req.body?.reason || 'admin_override',
    });
    return sendSuccess(res, { message: 'Dispatch reassigned', data });
  } catch (err) {
    return handle(res, err, 'Failed to reassign dispatch');
  }
});

router.post('/admin/bookings/:id/cancel', adminRequired, async (req, res) => {
  try {
    const booking = await cancelAmbulanceBooking({
      bookingId: req.params.id,
      actor: actorFromAuth(req.auth),
      reason: req.body?.reason || 'admin_override',
      asUser: false,
    });
    return sendSuccess(res, { message: 'Booking cancelled', data: booking });
  } catch (err) {
    return handle(res, err, 'Failed to cancel booking');
  }
});

router.post('/admin/bookings/:id/refund', adminRequired, async (req, res) => {
  try {
    const booking = await refundAmbulancePayment(req.params.id, actorFromAuth(req.auth));
    return sendSuccess(res, { message: 'Refund processed', data: booking });
  } catch (err) {
    return handle(res, err, 'Failed to refund');
  }
});

router.get('/admin/pricing', adminRequired, async (_req, res) => {
  try {
    const rules = await getFareRules();
    return sendSuccess(res, { data: rules });
  } catch (err) {
    return handle(res, err, 'Failed to load pricing');
  }
});

router.put('/admin/pricing', adminRequired, async (req, res) => {
  try {
    const rules = await upsertFareRules(req.body?.rules || req.body, req.auth?.adminId || 'admin');
    return sendSuccess(res, { message: 'Pricing updated', data: rules });
  } catch (err) {
    return handle(res, err, 'Failed to update pricing');
  }
});

module.exports = router;
