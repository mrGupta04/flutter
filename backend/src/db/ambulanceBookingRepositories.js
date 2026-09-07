const { v4: uuidv4 } = require('uuid');
const AmbulanceBooking = require('./models/AmbulanceBooking');
const AmbulanceReview = require('./models/AmbulanceReview');
const Ambulance = require('./models/Ambulance');
const { findAmbulanceById } = require('./ambulanceRepositories');
const { toAmbulanceBooking } = require('./ambulanceMappers');
const { normalizeMobile, validateMobile } = require('../utils/mobile');
const { normalizeVehicleType } = require('./ambulanceConstants');
const {
  assertTransition,
  isActiveTrip,
  isTerminal,
  canUserCancel,
  canProviderCancel,
} = require('../services/ambulanceStatus');
const { appendAmbulanceStatusHistory, writeAmbulanceAudit } = require('./ambulanceAuditRepositories');
const { estimateFare } = require('../services/ambulanceFareService');

function fail(message, statusCode = 400, code) {
  const err = new Error(message);
  err.statusCode = statusCode;
  if (code) err.code = code;
  throw err;
}

function parseRequirements(input = {}) {
  const src = input.requirements || input;
  return {
    oxygen: Boolean(src.oxygen || src.requiresOxygen),
    ventilator: Boolean(src.ventilator || src.requiresVentilator),
    cardiacMonitor: Boolean(src.cardiacMonitor || src.requiresCardiacSupport),
    icuSupport: Boolean(src.icuSupport || src.requiresIcu),
    stretcher: src.stretcher !== false,
    wheelchair: Boolean(src.wheelchair),
    neonatal: Boolean(src.neonatal),
    medicalAttendant: Boolean(src.medicalAttendant),
  };
}

async function findAmbulanceBookingById(bookingId) {
  const doc = await AmbulanceBooking.findOne({ id: bookingId });
  return toAmbulanceBooking(doc);
}

async function findAmbulanceBookingDoc(bookingId) {
  return AmbulanceBooking.findOne({ id: bookingId });
}

function buildBookingFields(input, ambulance) {
  const patientName = String(input.patientName || '').trim();
  if (patientName.length < 2) fail('Patient name is required');

  const mobileCheck = validateMobile(input.patientMobile || input.contactPhone, {
    countryCode: input.countryCode || '91',
  });
  if (!mobileCheck.valid) {
    fail(mobileCheck.error || 'Valid mobile number is required');
  }

  const pickupAddress = String(input.pickupAddress || '').trim();
  if (pickupAddress.length < 5) fail('Pickup address is required');

  const isEmergency = input.isEmergency !== false && input.bookingKind !== 'scheduled';
  const bookingKind = input.bookingKind || (isEmergency ? 'emergency' : 'scheduled');
  if (bookingKind === 'scheduled') {
    const scheduledAt = input.scheduledAt ? new Date(input.scheduledAt) : null;
    if (!scheduledAt || Number.isNaN(scheduledAt.getTime())) {
      fail('Scheduled date and time are required');
    }
    if (scheduledAt.getTime() < Date.now() + 20 * 60 * 1000) {
      fail('Scheduled time must be at least 20 minutes from now');
    }
  }

  return {
    ambulanceId: ambulance?.id,
    ambulanceServiceName: ambulance?.serviceName,
    patientId: input.patientId || undefined,
    patientName,
    patientMobile: mobileCheck.mobile,
    patientEmail: input.patientEmail
      ? String(input.patientEmail).trim().toLowerCase()
      : undefined,
    patientAge: input.patientAge != null ? Number(input.patientAge) : undefined,
    patientGender: input.patientGender ? String(input.patientGender).trim() : undefined,
    patientCondition: input.patientCondition
      ? String(input.patientCondition).trim().slice(0, 1000)
      : undefined,
    consciousState: ['conscious', 'unconscious', 'unknown'].includes(input.consciousState)
      ? input.consciousState
      : 'unknown',
    emergencyCategory: input.emergencyCategory
      ? String(input.emergencyCategory).trim()
      : undefined,
    contactPerson: input.contactPerson ? String(input.contactPerson).trim() : undefined,
    contactPhone: input.contactPhone
      ? normalizeMobile(input.contactPhone) || String(input.contactPhone)
      : mobileCheck.mobile,
    pickupAddress,
    pickupCity: input.pickupCity ? String(input.pickupCity).trim() : undefined,
    pickupPincode: input.pickupPincode ? String(input.pickupPincode).trim() : undefined,
    pickupLatitude:
      input.pickupLatitude != null ? Number(input.pickupLatitude) : undefined,
    pickupLongitude:
      input.pickupLongitude != null ? Number(input.pickupLongitude) : undefined,
    dropAddress: input.dropAddress ? String(input.dropAddress).trim() : undefined,
    dropCity: input.dropCity ? String(input.dropCity).trim() : undefined,
    dropLatitude: input.dropLatitude != null ? Number(input.dropLatitude) : undefined,
    dropLongitude: input.dropLongitude != null ? Number(input.dropLongitude) : undefined,
    destinationType: input.destinationType || 'other',
    destinationHospitalName: input.destinationHospitalName
      ? String(input.destinationHospitalName).trim()
      : undefined,
    destinationHospitalId: input.destinationHospitalId || undefined,
    notes: input.notes ? String(input.notes).trim() : undefined,
    vehicleTypeRequested: input.vehicleTypeRequested
      ? String(input.vehicleTypeRequested).trim()
      : undefined,
    requirements: parseRequirements(input),
    bookingKind,
    scheduledAt: input.scheduledAt ? new Date(input.scheduledAt) : undefined,
    isEmergency,
    paymentMethod: input.paymentMethod === 'cash' ? 'cash' : 'online',
    idempotencyKey: input.idempotencyKey || undefined,
  };
}

async function createAmbulanceBooking(input) {
  if (input.idempotencyKey) {
    const existing = await AmbulanceBooking.findOne({
      idempotencyKey: String(input.idempotencyKey),
    });
    if (existing) return toAmbulanceBooking(existing);
  }

  const ambulanceId = String(input.ambulanceId || '').trim();
  let ambulance = null;
  if (ambulanceId) {
    ambulance = await findAmbulanceById(ambulanceId);
    if (
      !ambulance ||
      (ambulance.verificationStatus !== 'verified' && !ambulance.isApproved)
    ) {
      fail('Ambulance service not found or not verified', 404);
    }
    if (ambulance.isDisabled || ambulance.isSuspended) {
      fail('This ambulance provider is currently unavailable', 403);
    }
  }

  const fields = buildBookingFields(input, ambulance);
  const autoDispatch = !ambulanceId && fields.bookingKind === 'emergency';
  const fareEstimate = await estimateFare({
    vehicleType: normalizeVehicleType(fields.vehicleTypeRequested) || 'basic',
    distanceKm: 0,
    durationMinutes: 0,
    requirements: fields.requirements,
    isEmergency: fields.isEmergency,
  });

  const booking = await AmbulanceBooking.create({
    id: uuidv4(),
    ...fields,
    status: autoDispatch
      ? 'searching_ambulance'
      : fields.bookingKind === 'scheduled'
        ? 'requested'
        : 'requested',
    fare: fareEstimate.fare,
    paymentPolicy: fields.isEmergency
      ? fareEstimate.policy.emergencyPayWhen
      : fareEstimate.policy.scheduledPayWhen,
    paymentStatus: fields.paymentMethod === 'cash' ? 'cash' : 'unpaid',
  });

  await appendAmbulanceStatusHistory({
    bookingId: booking.id,
    fromStatus: null,
    toStatus: booking.status,
    actorId: fields.patientId || 'patient',
    actorRole: 'patient',
    note: autoDispatch ? 'Emergency dispatch started' : 'Booking created',
  });

  return toAmbulanceBooking(booking);
}

async function listAmbulanceBookingsForProvider(ambulanceId, { status, kind } = {}) {
  const filter = { ambulanceId };
  if (status) filter.status = status;
  if (kind) filter.bookingKind = kind;
  const docs = await AmbulanceBooking.find(filter).sort({ createdAt: -1 }).limit(200).lean();
  return docs.map(toAmbulanceBooking);
}

async function listAmbulanceBookingsForPatient({
  patientId,
  patientMobile,
  patientEmail,
  statusGroup,
}) {
  const orConditions = [];
  if (patientId) orConditions.push({ patientId: String(patientId) });
  const mobile = normalizeMobile(patientMobile);
  if (mobile.length === 10) orConditions.push({ patientMobile: mobile });
  const email = String(patientEmail || '').trim().toLowerCase();
  if (email) orConditions.push({ patientEmail: email });
  if (orConditions.length === 0) return [];

  const filter = { $or: orConditions };
  if (statusGroup === 'active') {
    filter.status = {
      $in: [
        'requested',
        'searching_ambulance',
        'ambulance_assigned',
        'driver_accepted',
        'accepted',
        'dispatched',
        'driver_en_route',
        'en_route',
        'arrived_at_pickup',
        'arrived',
        'patient_picked_up',
        'en_route_to_destination',
        'arrived_at_destination',
      ],
    };
  } else if (statusGroup === 'upcoming') {
    filter.bookingKind = 'scheduled';
    filter.status = { $in: ['requested', 'accepted', 'ambulance_assigned', 'driver_accepted'] };
  } else if (statusGroup === 'completed') {
    filter.status = { $in: ['trip_completed', 'completed'] };
  }

  const docs = await AmbulanceBooking.find(filter).sort({ createdAt: -1 }).limit(200).lean();
  return docs.map(toAmbulanceBooking);
}

async function listAllAmbulanceBookings({
  status,
  kind,
  ambulanceId,
  page = 1,
  pageSize = 30,
} = {}) {
  const filter = {};
  if (status) filter.status = status;
  if (kind) filter.bookingKind = kind;
  if (ambulanceId) filter.ambulanceId = ambulanceId;
  const totalCount = await AmbulanceBooking.countDocuments(filter);
  const totalPages = Math.max(1, Math.ceil(totalCount / pageSize));
  const docs = await AmbulanceBooking.find(filter)
    .sort({ createdAt: -1 })
    .skip((page - 1) * pageSize)
    .limit(pageSize)
    .lean();
  return {
    bookings: docs.map(toAmbulanceBooking),
    pagination: {
      currentPage: page,
      totalPages,
      pageSize,
      totalCount,
      hasNextPage: page < totalPages,
    },
  };
}

async function transitionBooking({
  bookingId,
  ambulanceId,
  status,
  actor,
  extra = {},
  skipTransitionCheck = false,
}) {
  const booking = await AmbulanceBooking.findOne({ id: bookingId });
  if (!booking) fail('Booking not found', 404);
  if (ambulanceId && booking.ambulanceId && booking.ambulanceId !== ambulanceId) {
    fail('Not authorized for this booking', 403);
  }
  if (isTerminal(booking.status) && booking.status !== status) {
    fail(`Booking is already ${booking.status}`, 409, 'ALREADY_TERMINAL');
  }
  if (!skipTransitionCheck) {
    assertTransition(booking.status, status);
  }
  const fromStatus = booking.status;
  booking.status = status;
  Object.entries(extra).forEach(([key, value]) => {
    if (value !== undefined) booking[key] = value;
  });
  await booking.save();
  await appendAmbulanceStatusHistory({
    bookingId: booking.id,
    fromStatus,
    toStatus: status,
    actorId: actor?.actorId,
    actorRole: actor?.actorRole,
    note: extra.note,
  });
  return toAmbulanceBooking(booking);
}

async function updateAmbulanceBookingStatus({
  bookingId,
  ambulanceId,
  status,
  rejectionReason,
  estimatedArrivalMinutes,
  actor,
}) {
  const allowed = [
    'accepted',
    'dispatched',
    'en_route',
    'arrived',
    'completed',
    'cancelled',
    'rejected',
    'driver_accepted',
    'driver_en_route',
    'arrived_at_pickup',
    'patient_picked_up',
    'en_route_to_destination',
    'arrived_at_destination',
    'trip_completed',
  ];
  if (!allowed.includes(status)) fail('Invalid status');
  return transitionBooking({
    bookingId,
    ambulanceId,
    status,
    actor: actor || { actorId: ambulanceId, actorRole: 'ambulance_provider' },
    extra: {
      rejectionReason,
      estimatedArrivalMinutes,
      completedAt: ['completed', 'trip_completed'].includes(status) ? new Date() : undefined,
    },
    skipTransitionCheck: ['accepted', 'dispatched', 'en_route', 'arrived', 'completed'].includes(
      status,
    ),
  });
}

async function cancelAmbulanceBooking({
  bookingId,
  actor,
  reason,
  asUser,
}) {
  const booking = await AmbulanceBooking.findOne({ id: bookingId });
  if (!booking) fail('Booking not found', 404);
  if (isTerminal(booking.status)) fail('Booking can no longer be cancelled', 409);
  if (asUser && !canUserCancel(booking.status)) {
    fail('Cancellation is no longer available at this stage', 409);
  }
  if (!asUser && !canProviderCancel(booking.status)) {
    fail('Provider cannot cancel at this stage', 409);
  }
  const fromStatus = booking.status;
  booking.status = 'cancelled';
  booking.cancelReason = reason || undefined;
  booking.cancelledBy = actor?.actorRole;
  await booking.save();
  await appendAmbulanceStatusHistory({
    bookingId: booking.id,
    fromStatus,
    toStatus: 'cancelled',
    actorId: actor?.actorId,
    actorRole: actor?.actorRole,
    note: reason,
  });
  await writeAmbulanceAudit({
    actorId: actor?.actorId,
    actorRole: actor?.actorRole,
    action: 'booking_cancelled',
    entityType: 'AmbulanceBooking',
    entityId: booking.id,
    ambulanceId: booking.ambulanceId,
    newValue: { reason },
  });
  return toAmbulanceBooking(booking);
}

async function updateAmbulanceLiveLocation({
  bookingId,
  ambulanceId,
  latitude,
  longitude,
  accuracy,
  heading,
  speed,
  vehicleId,
  driverId,
}) {
  const lat = Number(latitude);
  const lng = Number(longitude);
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
    fail('Valid latitude and longitude are required');
  }
  if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
    fail('Latitude/longitude out of range');
  }

  const booking = await AmbulanceBooking.findOne({ id: bookingId, ambulanceId });
  if (!booking) fail('Booking not found', 404);
  if (!isActiveTrip(booking.status) && booking.status !== 'requested') {
    fail('Location updates are only allowed during an active trip', 409);
  }

  const minInterval = Number(process.env.AMBULANCE_LOCATION_MIN_INTERVAL_MS || 4000);
  if (
    booking.liveLocationUpdatedAt &&
    Date.now() - new Date(booking.liveLocationUpdatedAt).getTime() < minInterval
  ) {
    return { booking: toAmbulanceBooking(booking), throttled: true };
  }

  booking.liveLatitude = lat;
  booking.liveLongitude = lng;
  booking.liveAccuracy = Number.isFinite(Number(accuracy)) ? Number(accuracy) : undefined;
  booking.liveHeading = Number.isFinite(Number(heading)) ? Number(heading) : undefined;
  booking.liveSpeed = Number.isFinite(Number(speed)) ? Number(speed) : undefined;
  booking.liveLocationUpdatedAt = new Date();
  booking.locationUnavailable = false;
  await booking.save();

  const { persistAmbulanceLocation } = require('../services/ambulanceLocationService');
  persistAmbulanceLocation({
    bookingId,
    ambulanceId,
    vehicleId: vehicleId || booking.assignedVehicleId,
    driverId: driverId || booking.assignedDriverId,
    latitude: lat,
    longitude: lng,
    accuracy,
    heading,
    speed,
  }).catch((err) => console.warn('[ambulance-location] persist failed:', err.message));

  return { booking: toAmbulanceBooking(booking), throttled: false };
}

function toPatientBookingShape(booking) {
  const created = booking.createdAt ? new Date(booking.createdAt) : new Date();
  const slotEnd = booking.scheduledAt
    ? new Date(booking.scheduledAt)
    : new Date(created.getTime() + 2 * 60 * 60 * 1000);
  const activeStatuses = [
    'requested',
    'searching_ambulance',
    'ambulance_assigned',
    'driver_accepted',
    'accepted',
    'dispatched',
    'driver_en_route',
    'en_route',
    'arrived_at_pickup',
    'arrived',
    'patient_picked_up',
    'en_route_to_destination',
    'arrived_at_destination',
  ];
  return {
    id: booking.id,
    doctorId: booking.ambulanceId,
    doctorName: booking.ambulanceServiceName || 'Ambulance',
    serviceType: 'ambulance',
    consultationType: 'ambulance',
    typeLabel: booking.isEmergency ? 'Emergency ambulance' : 'Ambulance',
    patientName: booking.patientName,
    patientMobile: booking.patientMobile,
    patientEmail: booking.patientEmail,
    patientAddress: booking.pickupAddress,
    patientCity: booking.pickupCity,
    patientNotes: booking.notes,
    slotStart: booking.scheduledAt || created,
    slotEnd,
    label: booking.pickupAddress,
    consultationFee: booking.fare?.total ?? null,
    status: booking.status === 'requested' ? 'pending' : booking.status,
    ...require('../utils/patientBookingList').paymentFieldsForPatient({
      ...booking,
      amountPaid: booking.amountPaid,
      totalAmount: booking.fare?.total ?? booking.fareBreakdown?.total,
    }),
    visitProgress:
      ['en_route', 'dispatched', 'driver_en_route', 'en_route_to_destination'].includes(
        booking.status,
      )
        ? 'en_route'
        : ['arrived', 'arrived_at_pickup', 'arrived_at_destination'].includes(booking.status)
          ? 'arrived'
          : ['trip_completed', 'completed'].includes(booking.status)
            ? 'completed'
            : null,
    clinicName: booking.ambulanceServiceName,
    clinicAddress: booking.pickupAddress,
    pickupLatitude: booking.pickupLatitude,
    pickupLongitude: booking.pickupLongitude,
    liveLatitude: booking.liveLatitude,
    liveLongitude: booking.liveLongitude,
    liveLocationUpdatedAt: booking.liveLocationUpdatedAt,
    createdAt: booking.createdAt,
    isUpcoming: activeStatuses.includes(booking.status),
    timeline: booking.timeline,
  };
}

async function submitAmbulanceReview({
  bookingId,
  patientId,
  ambulanceRating,
  driverRating,
  providerRating,
  review,
  reportIssue,
}) {
  const booking = await AmbulanceBooking.findOne({ id: bookingId });
  if (!booking) fail('Booking not found', 404);
  if (booking.patientId && booking.patientId !== patientId) {
    fail('Not authorized to review this booking', 403);
  }
  if (!['trip_completed', 'completed'].includes(booking.status)) {
    fail('Reviews are available only after the trip is completed', 409);
  }
  const existing = await AmbulanceReview.findOne({ bookingId });
  if (existing) fail('This trip has already been reviewed', 409);

  const doc = await AmbulanceReview.create({
    id: uuidv4(),
    bookingId,
    patientId,
    ambulanceId: booking.ambulanceId,
    vehicleId: booking.assignedVehicleId,
    driverId: booking.assignedDriverId,
    ambulanceRating,
    driverRating,
    providerRating,
    review: review ? String(review).trim().slice(0, 2000) : undefined,
    reportIssue: reportIssue ? String(reportIssue).trim().slice(0, 2000) : undefined,
  });

  if (booking.ambulanceId && providerRating) {
    const reviews = await AmbulanceReview.find({ ambulanceId: booking.ambulanceId }).lean();
    const avg =
      reviews.reduce((sum, item) => sum + Number(item.providerRating || 0), 0) /
      Math.max(1, reviews.length);
    await Ambulance.updateOne(
      { id: booking.ambulanceId },
      { $set: { ratingAverage: Math.round(avg * 10) / 10, reviewCount: reviews.length } },
    );
  }

  return doc.toObject();
}

module.exports = {
  createAmbulanceBooking,
  findAmbulanceBookingById,
  findAmbulanceBookingDoc,
  listAmbulanceBookingsForProvider,
  listAmbulanceBookingsForPatient,
  listAllAmbulanceBookings,
  updateAmbulanceBookingStatus,
  updateAmbulanceLiveLocation,
  cancelAmbulanceBooking,
  transitionBooking,
  toAmbulanceBooking,
  toPatientBookingShape,
  parseRequirements,
  submitAmbulanceReview,
  fail,
};
