const { v4: uuidv4 } = require('uuid');
const Ambulance = require('../db/models/Ambulance');
const AmbulanceBooking = require('../db/models/AmbulanceBooking');
const AmbulanceDispatch = require('../db/models/AmbulanceDispatch');
const AmbulanceTrip = require('../db/models/AmbulanceTrip');
const { toAmbulance, toAmbulanceBooking } = require('../db/ambulanceMappers');
const {
  writeAmbulanceAudit,
  appendAmbulanceStatusHistory,
} = require('../db/ambulanceAuditRepositories');
const { releaseFleetAssignment } = require('../db/ambulanceFleetRepositories');
const {
  findMatchingCandidates,
  nextDispatchBatch,
  DEFAULT_RADIUS_KM,
} = require('./ambulanceMatching');
const { emitAmbulanceEvent } = require('./ambulanceRealtime');
const {
  notifyAmbulanceStatus,
  notifyEmergencyOffer,
} = require('./ambulanceNotificationService');
const { estimateFare, calculateFare, getFareRules } = require('./ambulanceFareService');
const { distanceKm } = require('../utils/geoDistance');
const { isActiveTrip } = require('./ambulanceStatus');

const BATCH_SIZE = Number(process.env.AMBULANCE_DISPATCH_BATCH_SIZE || 2);
const OFFER_TIMEOUT_MS = Number(process.env.AMBULANCE_DISPATCH_OFFER_TIMEOUT_MS || 25000);
const MAX_ROUNDS = Number(process.env.AMBULANCE_DISPATCH_MAX_ROUNDS || 5);
const EXPAND_KM = Number(process.env.AMBULANCE_DISPATCH_EXPAND_RADIUS_KM || 5);
const SEARCH_EXPIRE_MS = Number(process.env.AMBULANCE_SEARCH_EXPIRE_MS || 600000);

function fail(message, statusCode = 400, code) {
  const err = new Error(message);
  err.statusCode = statusCode;
  if (code) err.code = code;
  throw err;
}

async function loadVerifiedProviders() {
  const docs = await Ambulance.find({
    $or: [{ verificationStatus: 'verified' }, { isApproved: true }],
    isDisabled: { $ne: true },
    isSuspended: { $ne: true },
  }).lean();
  return docs.map((doc) => toAmbulance(doc));
}

async function startDispatch(bookingId, { actor } = {}) {
  const booking = await AmbulanceBooking.findOne({ id: bookingId });
  if (!booking) fail('Booking not found', 404);
  if (!['requested', 'searching_ambulance'].includes(booking.status)) {
    return toAmbulanceBooking(booking);
  }

  booking.status = 'searching_ambulance';
  booking.searchRadiusKm = booking.searchRadiusKm || DEFAULT_RADIUS_KM;
  booking.dispatchRound = (booking.dispatchRound || 0) + 1;
  booking.lastDispatchAt = new Date();
  booking.dispatchExpiresAt = new Date(Date.now() + OFFER_TIMEOUT_MS);
  await booking.save();

  emitAmbulanceEvent('ambulance_dispatch_started', {
    bookingId: booking.id,
    patientId: booking.patientId,
    ambulanceId: booking.ambulanceId,
  });

  const offered = await offerNextBatch(booking, actor);
  return { booking: toAmbulanceBooking(booking), offered };
}

async function offerNextBatch(booking, actor) {
  if (booking.dispatchRound > MAX_ROUNDS) {
    booking.status = 'no_answer';
    await booking.save();
    await appendAmbulanceStatusHistory({
      bookingId: booking.id,
      fromStatus: 'searching_ambulance',
      toStatus: 'no_answer',
      actorId: actor?.actorId || 'system',
      actorRole: actor?.actorRole || 'system',
      note: 'No ambulance accepted after maximum dispatch rounds',
    });
    await notifyAmbulanceStatus(toAmbulanceBooking(booking), {
      patientBody:
        'No ambulance has accepted your request yet. You can expand the search or contact local emergency services (112 / 108).',
      patientType: 'ambulance_update',
    });
    emitAmbulanceEvent('ambulance_request_cancelled', {
      bookingId: booking.id,
      patientId: booking.patientId,
      reason: 'no_answer',
    });
    return [];
  }

  const providers = await loadVerifiedProviders();
  const candidates = findMatchingCandidates({
    providers,
    pickupLatitude: booking.pickupLatitude,
    pickupLongitude: booking.pickupLongitude,
    requestedType: booking.vehicleTypeRequested,
    requirements: booking.requirements || {},
    emergency: booking.isEmergency !== false,
    radiusKm: booking.searchRadiusKm || DEFAULT_RADIUS_KM,
    excludeVehicleIds: booking.offeredAmbulanceIds || [],
  });

  const batch = nextDispatchBatch(candidates, {
    batchSize: BATCH_SIZE,
    alreadyOffered: booking.offeredAmbulanceIds || [],
  });

  if (batch.length === 0) {
    booking.searchRadiusKm = (booking.searchRadiusKm || DEFAULT_RADIUS_KM) + EXPAND_KM;
    booking.dispatchRound += 1;
    booking.dispatchExpiresAt = new Date(Date.now() + OFFER_TIMEOUT_MS);
    await booking.save();
    if (booking.dispatchRound > MAX_ROUNDS) {
      booking.status = 'no_answer';
      await booking.save();
    }
    return [];
  }

  const created = [];
  for (const candidate of batch) {
    try {
      const dispatch = await AmbulanceDispatch.create({
        id: uuidv4(),
        bookingId: booking.id,
        ambulanceId: candidate.ambulanceId,
        vehicleId: candidate.vehicleId,
        driverId: candidate.driverId,
        round: booking.dispatchRound,
        status: 'offered',
        distanceKm: candidate.distanceKm,
        etaMinutes: candidate.etaMinutes,
        offeredAt: new Date(),
        expiresAt: new Date(Date.now() + OFFER_TIMEOUT_MS),
      });
      booking.offeredAmbulanceIds = [
        ...new Set([...(booking.offeredAmbulanceIds || []), candidate.vehicleId]),
      ];
      const offer = {
        ...candidate,
        dispatchId: dispatch.id,
      };
      created.push(offer);
      emitAmbulanceEvent('ambulance_request_created', {
        bookingId: booking.id,
        ambulanceId: candidate.ambulanceId,
        driverId: candidate.driverId,
        patientId: booking.patientId,
        offer,
      });
      notifyEmergencyOffer(offer, toAmbulanceBooking(booking)).catch((err) =>
        console.warn('[ambulance-dispatch] notify offer failed:', err.message),
      );
    } catch (err) {
      if (err?.code !== 11000) {
        console.warn('[ambulance-dispatch] offer create failed:', err.message);
      }
    }
  }

  booking.currentDispatchId = created[0]?.dispatchId;
  booking.dispatchExpiresAt = new Date(Date.now() + OFFER_TIMEOUT_MS);
  await booking.save();
  return created;
}

async function acceptDispatch({
  bookingId,
  ambulanceId,
  vehicleId,
  driverId,
  dispatchId,
  actor,
}) {
  const offerFilter = {
    bookingId,
    ambulanceId,
    status: 'offered',
  };
  if (dispatchId) offerFilter.id = dispatchId;
  if (vehicleId) offerFilter.vehicleId = vehicleId;

  const offer = await AmbulanceDispatch.findOneAndUpdate(
    offerFilter,
    { $set: { status: 'accepted', respondedAt: new Date() } },
    { new: true },
  );
  if (!offer) {
    fail('This request is no longer available', 409, 'DISPATCH_UNAVAILABLE');
  }

  const lockedBooking = await AmbulanceBooking.findOneAndUpdate(
    {
      id: bookingId,
      status: { $in: ['searching_ambulance', 'requested'] },
      $or: [{ assignedVehicleId: null }, { assignedVehicleId: { $exists: false } }],
    },
    {
      $set: {
        ambulanceId: offer.ambulanceId,
        assignedVehicleId: offer.vehicleId,
        assignedDriverId: offer.driverId || driverId,
        currentDispatchId: offer.id,
        status: 'ambulance_assigned',
        estimatedArrivalMinutes: offer.etaMinutes,
      },
    },
    { new: true },
  );

  if (!lockedBooking) {
    await AmbulanceDispatch.updateOne({ id: offer.id }, { $set: { status: 'superseded' } });
    fail('Another ambulance has already accepted this request', 409, 'ALREADY_ASSIGNED');
  }

  const vehicleLock = await Ambulance.findOneAndUpdate(
    {
      id: offer.ambulanceId,
      vehicles: {
        $elemMatch: {
          id: offer.vehicleId,
          status: { $in: ['AVAILABLE', 'EMERGENCY_ONLY'] },
          $or: [{ currentBookingId: null }, { currentBookingId: { $exists: false } }],
        },
      },
    },
    {
      $set: {
        'vehicles.$[vehicle].status': 'BUSY',
        'vehicles.$[vehicle].currentBookingId': bookingId,
        'drivers.$[driver].status': 'ON_TRIP',
        'drivers.$[driver].currentBookingId': bookingId,
      },
    },
    {
      arrayFilters: [
        { 'vehicle.id': offer.vehicleId },
        { 'driver.id': offer.driverId || driverId || '__none__' },
      ],
      new: true,
    },
  );

  if (!vehicleLock) {
    await AmbulanceBooking.updateOne(
      { id: bookingId },
      {
        $set: {
          status: 'searching_ambulance',
          assignedVehicleId: null,
          assignedDriverId: null,
          ambulanceId: null,
        },
      },
    );
    await AmbulanceDispatch.updateOne({ id: offer.id }, { $set: { status: 'superseded' } });
    fail('This ambulance is no longer available', 409, 'VEHICLE_BUSY');
  }

  const provider = toAmbulance(vehicleLock);
  const vehicle = (provider.vehicles || []).find((item) => item.id === offer.vehicleId);
  const driver = (provider.drivers || []).find(
    (item) => item.id === (offer.driverId || driverId),
  );

  lockedBooking.ambulanceServiceName = provider.serviceName;
  lockedBooking.assignedDriverName = driver?.fullName;
  lockedBooking.assignedVehicleRegistration = vehicle?.registrationNumber;
  lockedBooking.assignedVehicleType = vehicle?.vehicleType;
  lockedBooking.status = 'driver_accepted';
  await lockedBooking.save();

  await AmbulanceDispatch.updateMany(
    { bookingId, id: { $ne: offer.id }, status: 'offered' },
    { $set: { status: 'superseded', respondedAt: new Date() } },
  );

  await appendAmbulanceStatusHistory({
    bookingId,
    fromStatus: 'searching_ambulance',
    toStatus: 'driver_accepted',
    actorId: actor?.actorId,
    actorRole: actor?.actorRole || 'driver',
  });
  await writeAmbulanceAudit({
    actorId: actor?.actorId,
    actorRole: actor?.actorRole,
    action: 'booking_accepted',
    entityType: 'AmbulanceBooking',
    entityId: bookingId,
    ambulanceId: offer.ambulanceId,
    newValue: { vehicleId: offer.vehicleId, driverId: offer.driverId },
  });

  const publicBooking = toAmbulanceBooking(lockedBooking);
  emitAmbulanceEvent('ambulance_assigned', {
    bookingId,
    patientId: lockedBooking.patientId,
    ambulanceId: offer.ambulanceId,
    driverId: offer.driverId,
  });
  emitAmbulanceEvent('ambulance_driver_accepted', {
    bookingId,
    patientId: lockedBooking.patientId,
    ambulanceId: offer.ambulanceId,
    driverId: offer.driverId,
  });
  notifyAmbulanceStatus(publicBooking, {
    patientBody: 'Ambulance confirmed. The driver is preparing to start the trip.',
    patientType: 'ambulance_assigned',
    providerTitle: 'Emergency request accepted',
  }).catch((err) => console.warn('[ambulance-dispatch] notify accept failed:', err.message));

  return publicBooking;
}

async function rejectDispatch({ bookingId, ambulanceId, dispatchId, reason, actor }) {
  const offer = await AmbulanceDispatch.findOneAndUpdate(
    {
      bookingId,
      ambulanceId,
      status: 'offered',
      ...(dispatchId ? { id: dispatchId } : {}),
    },
    {
      $set: {
        status: 'rejected',
        respondedAt: new Date(),
        rejectReason: reason,
      },
    },
    { new: true },
  );
  if (!offer) fail('Dispatch offer not found', 404);

  emitAmbulanceEvent('ambulance_driver_rejected', {
    bookingId,
    ambulanceId,
    driverId: offer.driverId,
  });

  const remaining = await AmbulanceDispatch.countDocuments({ bookingId, status: 'offered' });
  if (remaining === 0) {
    const booking = await AmbulanceBooking.findOne({ id: bookingId });
    if (booking && booking.status === 'searching_ambulance') {
      await offerNextBatch(booking, actor);
    }
  }
  return { ok: true };
}

async function acceptScheduledBooking({ bookingId, ambulanceId, vehicleId, driverId, actor }) {
  const booking = await AmbulanceBooking.findOne({ id: bookingId, ambulanceId });
  if (!booking) fail('Booking not found', 404);
  if (booking.status !== 'requested') fail('Booking cannot be accepted in its current state', 409);

  if (vehicleId) {
    const vehicleLock = await Ambulance.findOneAndUpdate(
      {
        id: ambulanceId,
        vehicles: {
          $elemMatch: {
            id: vehicleId,
            status: { $in: ['AVAILABLE', 'EMERGENCY_ONLY'] },
            $or: [{ currentBookingId: null }, { currentBookingId: { $exists: false } }],
          },
        },
      },
      {
        $set: {
          'vehicles.$[vehicle].currentBookingId': bookingId,
          'drivers.$[driver].currentBookingId': bookingId,
        },
      },
      {
        arrayFilters: [
          { 'vehicle.id': vehicleId },
          { 'driver.id': driverId || '__none__' },
        ],
        new: true,
      },
    );
    if (!vehicleLock) fail('Selected ambulance is not available', 409);
    const provider = toAmbulance(vehicleLock);
    const vehicle = (provider.vehicles || []).find((item) => item.id === vehicleId);
    const driver = (provider.drivers || []).find((item) => item.id === driverId);
    booking.assignedVehicleId = vehicleId;
    booking.assignedDriverId = driverId;
    booking.assignedVehicleRegistration = vehicle?.registrationNumber;
    booking.assignedVehicleType = vehicle?.vehicleType;
    booking.assignedDriverName = driver?.fullName;
  }

  booking.status = 'accepted';
  await booking.save();
  await appendAmbulanceStatusHistory({
    bookingId,
    fromStatus: 'requested',
    toStatus: 'accepted',
    actorId: actor?.actorId,
    actorRole: actor?.actorRole,
  });
  await writeAmbulanceAudit({
    actorId: actor?.actorId,
    actorRole: actor?.actorRole,
    action: 'booking_accepted',
    entityType: 'AmbulanceBooking',
    entityId: bookingId,
    ambulanceId,
  });
  const publicBooking = toAmbulanceBooking(booking);
  emitAmbulanceEvent('ambulance_assigned', {
    bookingId,
    patientId: booking.patientId,
    ambulanceId,
  });
  notifyAmbulanceStatus(publicBooking, {
    patientBody: 'Your scheduled ambulance request has been accepted.',
    patientType: 'booking_approved',
  }).catch(() => {});
  return publicBooking;
}

async function rejectScheduledBooking({ bookingId, ambulanceId, reason, actor }) {
  const booking = await AmbulanceBooking.findOne({ id: bookingId, ambulanceId });
  if (!booking) fail('Booking not found', 404);
  if (booking.status !== 'requested') fail('Booking cannot be rejected in its current state', 409);
  booking.status = 'rejected';
  booking.rejectionReason = reason;
  await booking.save();
  await appendAmbulanceStatusHistory({
    bookingId,
    fromStatus: 'requested',
    toStatus: 'rejected',
    actorId: actor?.actorId,
    actorRole: actor?.actorRole,
    note: reason,
  });
  const publicBooking = toAmbulanceBooking(booking);
  notifyAmbulanceStatus(publicBooking, {
    patientBody: 'The ambulance provider could not accept this scheduled request.',
    patientType: 'booking_rejected',
  }).catch(() => {});
  return publicBooking;
}

async function advanceTrip({ bookingId, ambulanceId, action, actor, extra = {} }) {
  const map = {
    start: { status: 'driver_en_route', event: 'ambulance_driver_en_route' },
    arrived: { status: 'arrived_at_pickup', event: 'ambulance_arrived' },
    pickup: { status: 'patient_picked_up', event: 'patient_picked_up' },
    enroute: { status: 'en_route_to_destination', event: 'ambulance_trip_started' },
    destination: { status: 'arrived_at_destination', event: 'ambulance_destination_reached' },
    complete: { status: 'trip_completed', event: 'ambulance_trip_completed' },
  };
  const step = map[action];
  if (!step) fail('Unknown trip action');

  const { transitionBooking } = require('../db/ambulanceBookingRepositories');
  const extras = { ...extra };
  if (action === 'arrived') extras.pickupTime = extras.pickupTime || new Date();
  if (action === 'pickup') extras.patientPickedUpAt = extras.patientPickedUpAt || new Date();
  if (action === 'destination') extras.destinationArrivalAt = extras.destinationArrivalAt || new Date();
  if (action === 'complete') {
    extras.completedAt = extras.completedAt || new Date();
    const booking = await AmbulanceBooking.findOne({ id: bookingId, ambulanceId });
    if (!booking) fail('Booking not found', 404);
    if (['trip_completed', 'completed'].includes(booking.status)) {
      fail('Trip is already completed', 409, 'ALREADY_COMPLETED');
    }
    const rules = await getFareRules();
    let distanceKmValue = extra.distanceKm;
    if (
      !Number.isFinite(Number(distanceKmValue)) &&
      Number.isFinite(booking.pickupLatitude) &&
      Number.isFinite(booking.dropLatitude)
    ) {
      distanceKmValue = distanceKm(
        booking.pickupLatitude,
        booking.pickupLongitude,
        booking.dropLatitude,
        booking.dropLongitude,
      );
    }
    const durationMinutes = extra.durationMinutes
      || (booking.pickupTime
        ? Math.max(1, Math.round((Date.now() - new Date(booking.pickupTime).getTime()) / 60000))
        : booking.estimatedArrivalMinutes || 0);
    extras.tripDistanceKm = Number(distanceKmValue) || 0;
    extras.tripDurationMinutes = durationMinutes;
    extras.tripNotes = extra.notes;
    extras.fare = calculateFare({
      rules,
      vehicleType: booking.assignedVehicleType || booking.vehicleTypeRequested,
      distanceKm: extras.tripDistanceKm,
      durationMinutes,
      waitingMinutes: extra.waitingMinutes,
      requirements: booking.requirements || {},
      isEmergency: booking.isEmergency !== false,
      estimated: false,
    });
  }

  const publicBooking = await transitionBooking({
    bookingId,
    ambulanceId,
    status: step.status,
    actor,
    extra: extras,
  });

  if (action === 'complete') {
    await AmbulanceTrip.findOneAndUpdate(
      { bookingId },
      {
        $set: {
          id: uuidv4(),
          bookingId,
          ambulanceId,
          vehicleId: publicBooking.assignedVehicleId,
          driverId: publicBooking.assignedDriverId,
          startedAt: publicBooking.pickupTime,
          pickupAt: publicBooking.patientPickedUpAt,
          destinationAt: publicBooking.destinationArrivalAt,
          completedAt: publicBooking.completedAt,
          distanceKm: publicBooking.tripDistanceKm,
          durationMinutes: publicBooking.tripDurationMinutes,
          notes: publicBooking.tripNotes,
          fareTotal: publicBooking.fare?.total,
          paymentStatus: publicBooking.paymentStatus,
        },
      },
      { upsert: true },
    );
    if (publicBooking.assignedVehicleId) {
      await releaseFleetAssignment({
        ambulanceId,
        vehicleId: publicBooking.assignedVehicleId,
        driverId: publicBooking.assignedDriverId,
      });
    }
    await writeAmbulanceAudit({
      actorId: actor?.actorId,
      actorRole: actor?.actorRole,
      action: 'trip_completed',
      entityType: 'AmbulanceBooking',
      entityId: bookingId,
      ambulanceId,
    });
  }

  emitAmbulanceEvent(step.event, {
    bookingId,
    patientId: publicBooking.patientId,
    ambulanceId,
    driverId: publicBooking.assignedDriverId,
    status: publicBooking.status,
  });
  notifyAmbulanceStatus(publicBooking).catch(() => {});
  return publicBooking;
}

async function reassignBooking({ bookingId, actor, reason }) {
  const booking = await AmbulanceBooking.findOne({ id: bookingId });
  if (!booking) fail('Booking not found', 404);
  if (!isActiveTrip(booking.status) && booking.status !== 'requested') {
    fail('Booking cannot be reassigned', 409);
  }

  if (booking.assignedVehicleId && booking.ambulanceId) {
    await releaseFleetAssignment({
      ambulanceId: booking.ambulanceId,
      vehicleId: booking.assignedVehicleId,
      driverId: booking.assignedDriverId,
    });
  }
  await AmbulanceDispatch.updateMany(
    { bookingId, status: 'offered' },
    { $set: { status: 'cancelled' } },
  );

  const previous = {
    ambulanceId: booking.ambulanceId,
    vehicleId: booking.assignedVehicleId,
    driverId: booking.assignedDriverId,
  };
  booking.ambulanceId = undefined;
  booking.assignedVehicleId = undefined;
  booking.assignedDriverId = undefined;
  booking.assignedDriverName = undefined;
  booking.assignedVehicleRegistration = undefined;
  booking.status = 'searching_ambulance';
  booking.offeredAmbulanceIds = [];
  await booking.save();

  await writeAmbulanceAudit({
    actorId: actor?.actorId,
    actorRole: actor?.actorRole,
    action: 'dispatch_reassigned',
    entityType: 'AmbulanceBooking',
    entityId: bookingId,
    previousValue: previous,
    newValue: { reason },
  });
  emitAmbulanceEvent('ambulance_reassigned', {
    bookingId,
    patientId: booking.patientId,
    reason,
  });
  return startDispatch(bookingId, { actor });
}

async function processDispatchTimeouts() {
  const now = new Date();
  const expiredOffers = await AmbulanceDispatch.find({
    status: 'offered',
    expiresAt: { $lte: now },
  }).limit(50);

  for (const offer of expiredOffers) {
    offer.status = 'timeout';
    offer.respondedAt = now;
    await offer.save();
    emitAmbulanceEvent('ambulance_driver_rejected', {
      bookingId: offer.bookingId,
      ambulanceId: offer.ambulanceId,
      reason: 'timeout',
    });
  }

  const searching = await AmbulanceBooking.find({
    status: 'searching_ambulance',
    dispatchExpiresAt: { $lte: now },
  }).limit(30);

  for (const booking of searching) {
    if (Date.now() - new Date(booking.createdAt).getTime() > SEARCH_EXPIRE_MS) {
      booking.status = 'expired';
      await booking.save();
      await notifyAmbulanceStatus(toAmbulanceBooking(booking), {
        patientBody: 'No ambulance has accepted your request yet.',
      });
      continue;
    }
    booking.dispatchRound = (booking.dispatchRound || 0) + 1;
    booking.searchRadiusKm = (booking.searchRadiusKm || DEFAULT_RADIUS_KM) + EXPAND_KM;
    await booking.save();
    await offerNextBatch(booking, { actorId: 'system', actorRole: 'system' });
  }
}

async function nearbyAmbulances(query) {
  const providers = await loadVerifiedProviders();
  return findMatchingCandidates({
    providers,
    pickupLatitude: query.latitude,
    pickupLongitude: query.longitude,
    requestedType: query.vehicleType,
    requirements: query.requirements || {},
    emergency: query.emergency !== false,
    radiusKm: query.radiusKm || DEFAULT_RADIUS_KM,
  });
}

async function estimateForRequest(input) {
  let distance = Number(input.distanceKm);
  if (
    !Number.isFinite(distance) &&
    Number.isFinite(Number(input.pickupLatitude)) &&
    Number.isFinite(Number(input.dropLatitude))
  ) {
    distance = distanceKm(
      Number(input.pickupLatitude),
      Number(input.pickupLongitude),
      Number(input.dropLatitude),
      Number(input.dropLongitude),
    );
  }
  return estimateFare({
    vehicleType: input.vehicleType,
    distanceKm: distance || 8,
    durationMinutes: input.durationMinutes || 20,
    requirements: input.requirements,
    isEmergency: input.isEmergency !== false,
  });
}

module.exports = {
  startDispatch,
  acceptDispatch,
  rejectDispatch,
  acceptScheduledBooking,
  rejectScheduledBooking,
  advanceTrip,
  reassignBooking,
  processDispatchTimeouts,
  nearbyAmbulances,
  estimateForRequest,
  offerNextBatch,
};
