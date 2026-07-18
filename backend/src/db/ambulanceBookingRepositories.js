const { v4: uuidv4 } = require('uuid');
const AmbulanceBooking = require('./models/AmbulanceBooking');
const { findAmbulanceById } = require('./ambulanceRepositories');
const { normalizeMobile, validateMobile } = require('../utils/mobile');

function toAmbulanceBooking(doc) {
  if (!doc) return null;
  const d = doc.toObject ? doc.toObject() : doc;
  return {
    id: d.id,
    ambulanceId: d.ambulanceId,
    ambulanceServiceName: d.ambulanceServiceName,
    patientId: d.patientId,
    patientName: d.patientName,
    patientMobile: d.patientMobile,
    patientEmail: d.patientEmail,
    pickupAddress: d.pickupAddress,
    pickupCity: d.pickupCity,
    pickupPincode: d.pickupPincode,
    pickupLatitude: d.pickupLatitude,
    pickupLongitude: d.pickupLongitude,
    dropAddress: d.dropAddress,
    notes: d.notes,
    vehicleTypeRequested: d.vehicleTypeRequested,
    isEmergency: d.isEmergency !== false,
    status: d.status,
    rejectionReason: d.rejectionReason,
    estimatedArrivalMinutes: d.estimatedArrivalMinutes,
    liveLatitude: d.liveLatitude != null ? Number(d.liveLatitude) : null,
    liveLongitude: d.liveLongitude != null ? Number(d.liveLongitude) : null,
    liveLocationUpdatedAt: d.liveLocationUpdatedAt || null,
    createdAt: d.createdAt,
    updatedAt: d.updatedAt,
  };
}

async function findAmbulanceBookingById(bookingId) {
  const doc = await AmbulanceBooking.findOne({ id: bookingId });
  return toAmbulanceBooking(doc);
}

async function createAmbulanceBooking(input) {
  const ambulanceId = String(input.ambulanceId || '').trim();
  if (!ambulanceId) {
    const err = new Error('ambulanceId is required');
    err.statusCode = 400;
    throw err;
  }

  const ambulance = await findAmbulanceById(ambulanceId);
  if (
    !ambulance ||
    (ambulance.verificationStatus !== 'verified' && !ambulance.isApproved)
  ) {
    const err = new Error('Ambulance service not found or not verified');
    err.statusCode = 404;
    throw err;
  }

  const patientName = String(input.patientName || '').trim();
  if (patientName.length < 2) {
    const err = new Error('Patient name is required');
    err.statusCode = 400;
    throw err;
  }

  const mobileCheck = validateMobile(input.patientMobile, {
    countryCode: input.countryCode || '91',
  });
  if (!mobileCheck.valid) {
    const err = new Error(mobileCheck.error || 'Valid mobile number is required');
    err.statusCode = 400;
    throw err;
  }

  const pickupAddress = String(input.pickupAddress || '').trim();
  if (pickupAddress.length < 5) {
    const err = new Error('Pickup address is required');
    err.statusCode = 400;
    throw err;
  }

  const booking = await AmbulanceBooking.create({
    id: uuidv4(),
    ambulanceId,
    ambulanceServiceName: ambulance.serviceName,
    patientId: input.patientId || undefined,
    patientName,
    patientMobile: mobileCheck.mobile,
    patientEmail: input.patientEmail
      ? String(input.patientEmail).trim().toLowerCase()
      : undefined,
    pickupAddress,
    pickupCity: input.pickupCity ? String(input.pickupCity).trim() : undefined,
    pickupPincode: input.pickupPincode
      ? String(input.pickupPincode).trim()
      : undefined,
    pickupLatitude:
      input.pickupLatitude != null ? Number(input.pickupLatitude) : undefined,
    pickupLongitude:
      input.pickupLongitude != null ? Number(input.pickupLongitude) : undefined,
    dropAddress: input.dropAddress
      ? String(input.dropAddress).trim()
      : undefined,
    notes: input.notes ? String(input.notes).trim() : undefined,
    vehicleTypeRequested: input.vehicleTypeRequested
      ? String(input.vehicleTypeRequested).trim()
      : undefined,
    isEmergency: input.isEmergency !== false,
    status: 'requested',
  });

  return toAmbulanceBooking(booking);
}

async function listAmbulanceBookingsForProvider(ambulanceId) {
  const docs = await AmbulanceBooking.find({ ambulanceId })
    .sort({ createdAt: -1 })
    .limit(100)
    .lean();
  return docs.map(toAmbulanceBooking);
}

async function listAmbulanceBookingsForPatient({
  patientId,
  patientMobile,
  patientEmail,
}) {
  const orConditions = [];
  if (patientId) orConditions.push({ patientId: String(patientId) });
  const mobile = normalizeMobile(patientMobile);
  if (mobile.length === 10) orConditions.push({ patientMobile: mobile });
  const email = String(patientEmail || '').trim().toLowerCase();
  if (email) orConditions.push({ patientEmail: email });
  if (orConditions.length === 0) return [];

  const docs = await AmbulanceBooking.find({ $or: orConditions })
    .sort({ createdAt: -1 })
    .limit(50)
    .lean();
  return docs.map(toAmbulanceBooking);
}

async function updateAmbulanceBookingStatus({
  bookingId,
  ambulanceId,
  status,
  rejectionReason,
  estimatedArrivalMinutes,
}) {
  const allowed = [
    'accepted',
    'dispatched',
    'en_route',
    'arrived',
    'completed',
    'cancelled',
    'rejected',
  ];
  if (!allowed.includes(status)) {
    const err = new Error('Invalid status');
    err.statusCode = 400;
    throw err;
  }

  const booking = await AmbulanceBooking.findOne({ id: bookingId, ambulanceId });
  if (!booking) {
    const err = new Error('Booking not found');
    err.statusCode = 404;
    throw err;
  }

  booking.status = status;
  if (rejectionReason) booking.rejectionReason = String(rejectionReason).trim();
  if (estimatedArrivalMinutes != null) {
    booking.estimatedArrivalMinutes = Number(estimatedArrivalMinutes);
  }
  await booking.save();
  return toAmbulanceBooking(booking);
}

async function updateAmbulanceLiveLocation({
  bookingId,
  ambulanceId,
  latitude,
  longitude,
}) {
  const lat = Number(latitude);
  const lng = Number(longitude);
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
    const err = new Error('Valid latitude and longitude are required');
    err.statusCode = 400;
    throw err;
  }
  if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
    const err = new Error('Latitude/longitude out of range');
    err.statusCode = 400;
    throw err;
  }

  const booking = await AmbulanceBooking.findOne({ id: bookingId, ambulanceId });
  if (!booking) {
    const err = new Error('Booking not found');
    err.statusCode = 404;
    throw err;
  }

  booking.liveLatitude = lat;
  booking.liveLongitude = lng;
  booking.liveLocationUpdatedAt = new Date();
  await booking.save();
  return toAmbulanceBooking(booking);
}

function toPatientBookingShape(booking) {
  const created = booking.createdAt ? new Date(booking.createdAt) : new Date();
  const slotEnd = new Date(created.getTime() + 2 * 60 * 60 * 1000);
  const activeStatuses = [
    'requested',
    'accepted',
    'dispatched',
    'en_route',
    'arrived',
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
    slotStart: created,
    slotEnd,
    label: booking.pickupAddress,
    consultationFee: null,
    status: booking.status === 'requested' ? 'pending' : booking.status,
    paymentStatus: null,
    visitProgress:
      booking.status === 'en_route' || booking.status === 'dispatched'
        ? 'en_route'
        : booking.status === 'arrived'
          ? 'arrived'
          : booking.status === 'completed'
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
    timeline: [
      { key: 'requested', label: 'Request sent', done: true, at: created },
      {
        key: 'accepted',
        label: 'Accepted',
        done: ['accepted', 'dispatched', 'en_route', 'arrived', 'completed'].includes(
          booking.status,
        ),
      },
      {
        key: 'en_route',
        label: 'On the way',
        done: ['dispatched', 'en_route', 'arrived', 'completed'].includes(
          booking.status,
        ),
      },
      {
        key: 'completed',
        label: 'Completed',
        done: booking.status === 'completed',
      },
    ],
  };
}

module.exports = {
  createAmbulanceBooking,
  findAmbulanceBookingById,
  listAmbulanceBookingsForProvider,
  listAmbulanceBookingsForPatient,
  updateAmbulanceBookingStatus,
  updateAmbulanceLiveLocation,
  toAmbulanceBooking,
  toPatientBookingShape,
};
