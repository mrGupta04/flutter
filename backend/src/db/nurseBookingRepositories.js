const { v4: uuidv4 } = require('uuid');
const ConsultationBooking = require('./models/ConsultationBooking');
const { findNurseById } = require('./nurseRepositories');
const { findAvailabilityForActiveWeek } = require('./nurseAvailabilityRepositories');
const { isWeekExpired } = require('../utils/availabilityWeek');
const {
  slotDateTime,
  slotEndDateTime,
  formatSlotLabel,
} = require('../utils/slotDateTime');
const { distanceKm } = require('../utils/geoDistance');

const HOME_VISIT_APPROVAL_HOURS = parseInt(
  process.env.HOME_VISIT_APPROVAL_HOURS || '48',
  10,
);
const HOME_VISIT_PAYMENT_HOURS = parseInt(
  process.env.HOME_VISIT_PAYMENT_HOURS || '24',
  10,
);
const SLOT_HOLD_MINUTES = parseInt(process.env.SLOT_HOLD_MINUTES || '10', 10);
const CONSULTATION_TYPE = 'book_home';

function normalizeMobile(mobile) {
  return String(mobile || '').replace(/\D/g, '').slice(-10);
}

function isSlotReserved(booking, now = new Date()) {
  if (!booking) return false;
  if (booking.status === 'held') {
    return !booking.paymentExpiresAt || booking.paymentExpiresAt > now;
  }
  return [
    'confirmed',
    'pending',
    'awaiting_doctor_approval',
    'approved_pending_payment',
  ].includes(booking.status);
}

async function expirePendingNurseBookings(nurseId) {
  const now = new Date();
  await ConsultationBooking.updateMany(
    {
      nurseId,
      status: 'held',
      paymentExpiresAt: { $lte: now },
    },
    { $set: { status: 'cancelled', paymentStatus: 'failed' } },
  );
  await ConsultationBooking.updateMany(
    {
      nurseId,
      status: 'awaiting_doctor_approval',
      approvalExpiresAt: { $lte: now },
    },
    { $set: { status: 'cancelled', paymentStatus: 'failed' } },
  );
}

async function getActiveAvailabilityForBooking(nurseId) {
  const weekDoc = await findAvailabilityForActiveWeek(nurseId);
  if (!weekDoc) {
    return { error: 'Nurse has not set availability yet', status: 404 };
  }
  if (isWeekExpired(weekDoc.weekEndDate)) {
    return {
      error: 'Nurse is updating their schedule. Please try again later.',
      status: 409,
    };
  }
  return { availability: weekDoc };
}

function getNurseHomeVisitFee(nurse) {
  const fee = Number(nurse?.homeVisitFee);
  return Number.isFinite(fee) && fee >= 1 ? fee : null;
}

function resolvePatientDistance(nurse, patientLatitude, patientLongitude) {
  const lat = Number(patientLatitude);
  const lon = Number(patientLongitude);
  const nurseLat = nurse.latitude != null ? Number(nurse.latitude) : null;
  const nurseLon = nurse.longitude != null ? Number(nurse.longitude) : null;
  if (
    !Number.isFinite(lat) ||
    !Number.isFinite(lon) ||
    !Number.isFinite(nurseLat) ||
    !Number.isFinite(nurseLon)
  ) {
    return null;
  }
  return distanceKm(nurseLat, nurseLon, lat, lon);
}

function formatNurseBookingResponse(booking, nurse) {
  const nurseName = `${nurse.firstName || ''} ${nurse.lastName || ''}`.trim();
  return {
    id: booking.id,
    nurseId: booking.nurseId,
    providerType: 'nurse',
    consultationType: booking.consultationType,
    patientName: booking.patientName,
    patientMobile: booking.patientMobile,
    patientEmail: booking.patientEmail,
    patientNotes: booking.patientNotes,
    patientAddress: booking.patientAddress,
    patientCity: booking.patientCity,
    patientState: booking.patientState,
    patientPincode: booking.patientPincode,
    visitReason: booking.visitReason,
    patientLatitude: booking.patientLatitude ?? null,
    patientLongitude: booking.patientLongitude ?? null,
    distanceKm: booking.distanceKm ?? null,
    doctorApprovedAt: booking.doctorApprovedAt ?? null,
    dayOfWeek: booking.dayOfWeek,
    startHour: booking.startHour,
    slotStart: booking.slotStart,
    slotEnd: booking.slotEnd,
    weekStartDate: booking.weekStartDate,
    consultationFee: booking.consultationFee,
    status: booking.status,
    visitProgress: booking.visitProgress || null,
    label: formatSlotLabel(booking.slotStart, booking.slotEnd),
    nurseName,
    createdAt: booking.createdAt,
    timeline: require('./bookingLifecycleHelpers').buildVisitTimeline(booking),
  };
}

async function getNurseBookableSlots(nurseId) {
  const nurse = await findNurseById(nurseId);
  if (!nurse) {
    return { error: 'Nurse not found', status: 404 };
  }
  if (!nurse.availableForHomeVisit) {
    return { error: 'This nurse does not offer home visits', status: 400 };
  }

  const availResult = await getActiveAvailabilityForBooking(nurseId);
  if (availResult.error) {
    return { error: availResult.error, status: availResult.status };
  }

  const availability = availResult.availability;
  const weekStart = availability.weekStartDate;
  const weekEnd = availability.weekEndDate;
  const now = new Date();

  await expirePendingNurseBookings(nurseId);

  const reserved = await ConsultationBooking.find({
    nurseId,
    consultationType: CONSULTATION_TYPE,
    status: {
      $in: [
        'confirmed',
        'pending',
        'held',
        'awaiting_doctor_approval',
        'approved_pending_payment',
      ],
    },
    slotStart: { $gte: weekStart, $lte: weekEnd },
  }).lean();

  const bookedKeys = new Set();
  const bookedSlotStarts = new Set();
  for (const booking of reserved) {
    if (!isSlotReserved(booking, now)) continue;
    bookedKeys.add(`${booking.dayOfWeek}_${booking.startHour}`);
    bookedSlotStarts.add(new Date(booking.slotStart).getTime());
  }

  const slotMap = new Map();
  (availability.slots || []).forEach((s) => {
    slotMap.set(`${s.dayOfWeek}_${s.startHour}`, s);
  });

  const bookable = [];
  for (let day = 0; day <= 6; day += 1) {
    for (let hour = 8; hour <= 17; hour += 1) {
      const key = `${day}_${hour}`;
      const slot = slotMap.get(key) || {
        dayOfWeek: day,
        startHour: hour,
        available: false,
      };
      if (!slot.available || bookedKeys.has(key)) continue;

      const slotStart = slotDateTime(weekStart, day, hour);
      const slotEnd = slotEndDateTime(weekStart, day, hour);
      if (slotStart <= now) continue;
      if (bookedSlotStarts.has(slotStart.getTime())) continue;

      bookable.push({
        dayOfWeek: day,
        startHour: hour,
        slotStart: slotStart.toISOString(),
        slotEnd: slotEnd.toISOString(),
        label: formatSlotLabel(slotStart, slotEnd),
      });
    }
  }

  bookable.sort(
    (a, b) => new Date(a.slotStart).getTime() - new Date(b.slotStart).getTime(),
  );

  return {
    data: {
      nurseId,
      consultationType: CONSULTATION_TYPE,
      weekStartDate: weekStart.toISOString(),
      weekEndDate: weekEnd.toISOString(),
      consultationFee: getNurseHomeVisitFee(nurse),
      slots: bookable,
      totalBookable: bookable.length,
      totalAvailableInWeek: (availability.slots || []).filter((s) => s.available)
        .length,
      message:
        bookable.length === 0
          ? 'No upcoming slots this week. The nurse may need to update their schedule.'
          : null,
    },
  };
}

async function validateNurseBookingPayload(payload) {
  const {
    nurseId,
    patientName,
    patientMobile,
    patientEmail,
    patientNotes,
    dayOfWeek,
    startHour,
    slotStart: slotStartRaw,
    patientId,
    patientAddress,
    patientCity,
    patientState,
    patientPincode,
    visitReason,
  } = payload;

  const nurse = await findNurseById(nurseId);
  if (!nurse) {
    const err = new Error('Nurse not found');
    err.statusCode = 404;
    throw err;
  }
  if (!nurse.availableForHomeVisit) {
    const err = new Error('This nurse does not offer home visits');
    err.statusCode = 400;
    throw err;
  }

  const fee = getNurseHomeVisitFee(nurse);
  if (!fee) {
    const err = new Error('Nurse home visit fee is not set');
    err.statusCode = 400;
    throw err;
  }

  await expirePendingNurseBookings(nurseId);

  const availResult = await getActiveAvailabilityForBooking(nurseId);
  if (availResult.error) {
    const err = new Error(availResult.error);
    err.statusCode = availResult.status;
    throw err;
  }

  const availability = availResult.availability;
  const weekStart = availability.weekStartDate;
  const d = Number(dayOfWeek);
  const h = Number(startHour);
  const slotStart = slotStartRaw
    ? new Date(slotStartRaw)
    : slotDateTime(weekStart, d, h);
  const slotEnd = slotEndDateTime(weekStart, d, h);

  const slotDef = (availability.slots || []).find(
    (s) => s.dayOfWeek === d && s.startHour === h,
  );
  if (!slotDef?.available) {
    const err = new Error('Selected time slot is not available');
    err.statusCode = 409;
    throw err;
  }

  if (slotStart <= new Date()) {
    const err = new Error('Cannot book a past time slot');
    err.statusCode = 400;
    throw err;
  }

  const mobile = normalizeMobile(patientMobile);
  if (mobile.length !== 10) {
    const err = new Error('A valid 10-digit mobile number is required');
    err.statusCode = 400;
    throw err;
  }

  const name = String(patientName || '').trim();
  if (name.length < 2) {
    const err = new Error('Patient name is required');
    err.statusCode = 400;
    throw err;
  }

  const address = String(patientAddress || '').trim();
  const city = String(patientCity || '').trim();
  const pincode = String(patientPincode || '').trim();
  if (address.length < 5) {
    const err = new Error('Patient address is required');
    err.statusCode = 400;
    throw err;
  }
  if (city.length < 2) {
    const err = new Error('City is required');
    err.statusCode = 400;
    throw err;
  }
  if (pincode.length < 6) {
    const err = new Error('A valid 6-digit pincode is required');
    err.statusCode = 400;
    throw err;
  }

  return {
    nurse,
    availability,
    weekStart,
    slotStart,
    slotEnd,
    d,
    h,
    mobile,
    name,
    patientId,
    patientEmail,
    patientNotes,
    patientAddress: address,
    patientCity: city,
    patientState: patientState ? String(patientState).trim() : undefined,
    patientPincode: pincode,
    visitReason: visitReason ? String(visitReason).trim() : undefined,
    fee,
  };
}

async function holdNurseSlot(payload, holdMinutes = SLOT_HOLD_MINUTES) {
  const {
    nurseId,
    dayOfWeek,
    startHour,
    slotStart: slotStartRaw,
    patientId,
    holdId,
  } = payload;

  if (!nurseId) {
    const err = new Error('nurseId is required');
    err.statusCode = 400;
    throw err;
  }

  await expirePendingNurseBookings(nurseId);

  if (holdId) {
    const existing = await ConsultationBooking.findOne({ id: holdId });
    if (
      existing &&
      existing.status === 'held' &&
      (!patientId || !existing.patientId || existing.patientId === patientId)
    ) {
      existing.status = 'cancelled';
      existing.paymentStatus = 'failed';
      await existing.save();
    }
  }

  const nurse = await findNurseById(nurseId);
  if (!nurse) {
    const err = new Error('Nurse not found');
    err.statusCode = 404;
    throw err;
  }

  const availResult = await getActiveAvailabilityForBooking(nurseId);
  if (availResult.error) {
    const err = new Error(availResult.error);
    err.statusCode = availResult.status;
    throw err;
  }

  const availability = availResult.availability;
  const weekStart = availability.weekStartDate;
  const d = Number(dayOfWeek);
  const h = Number(startHour);
  const slotStart = slotStartRaw
    ? new Date(slotStartRaw)
    : slotDateTime(weekStart, d, h);
  const slotEnd = slotEndDateTime(weekStart, d, h);

  const slotDef = (availability.slots || []).find(
    (s) => s.dayOfWeek === d && s.startHour === h,
  );
  if (!slotDef?.available) {
    const err = new Error('Selected time slot is not available');
    err.statusCode = 409;
    throw err;
  }

  if (slotStart <= new Date()) {
    const err = new Error('Cannot hold a past time slot');
    err.statusCode = 400;
    throw err;
  }

  const existing = await ConsultationBooking.findOne({
    nurseId,
    slotStart,
    consultationType: CONSULTATION_TYPE,
    status: {
      $in: [
        'confirmed',
        'pending',
        'held',
        'awaiting_doctor_approval',
        'approved_pending_payment',
      ],
    },
  });

  if (existing && isSlotReserved(existing)) {
    if (
      existing.status === 'held' &&
      patientId &&
      existing.patientId === patientId
    ) {
      existing.paymentExpiresAt = new Date(Date.now() + holdMinutes * 60 * 1000);
      await existing.save();
      return {
        holdId: existing.id,
        expiresAt: existing.paymentExpiresAt,
      };
    }
    const err = new Error('This slot was just booked. Please choose another time.');
    err.statusCode = 409;
    throw err;
  }

  if (patientId) {
    await ConsultationBooking.updateMany(
      {
        nurseId,
        consultationType: CONSULTATION_TYPE,
        patientId,
        status: 'held',
      },
      { $set: { status: 'cancelled', paymentStatus: 'failed' } },
    );
  }

  const paymentExpiresAt = new Date(Date.now() + holdMinutes * 60 * 1000);
  const fee = getNurseHomeVisitFee(nurse);
  const booking = await ConsultationBooking.create({
    id: uuidv4(),
    nurseId,
    providerType: 'nurse',
    patientId: patientId ? String(patientId) : undefined,
    consultationType: CONSULTATION_TYPE,
    patientName: 'Slot hold',
    patientMobile: '0000000000',
    dayOfWeek: d,
    startHour: h,
    slotStart,
    slotEnd,
    weekStartDate: weekStart,
    consultationFee: fee,
    status: 'held',
    paymentStatus: 'pending',
    paymentProvider: 'razorpay',
    currency: 'INR',
    paymentExpiresAt,
  });

  return { holdId: booking.id, expiresAt: paymentExpiresAt };
}

async function releaseNurseSlotHold(holdId, patientId) {
  const booking = await ConsultationBooking.findOne({ id: holdId });
  if (!booking || booking.status !== 'held') {
    return { released: false };
  }
  if (patientId && booking.patientId && booking.patientId !== patientId) {
    const err = new Error('You cannot release this slot hold');
    err.statusCode = 403;
    throw err;
  }
  booking.status = 'cancelled';
  booking.paymentStatus = 'failed';
  await booking.save();
  return { released: true };
}

async function createNurseHomeVisitRequest(payload) {
  const validated = await validateNurseBookingPayload(payload);
  const {
    nurse,
    weekStart,
    slotStart,
    slotEnd,
    d,
    h,
    mobile,
    name,
    patientId,
    patientEmail,
    patientNotes,
    patientAddress,
    patientCity,
    patientState,
    patientPincode,
    visitReason,
    fee,
  } = validated;

  const patientLatitude = payload.patientLatitude;
  const patientLongitude = payload.patientLongitude;
  const distance = resolvePatientDistance(nurse, patientLatitude, patientLongitude);
  const approvalExpiresAt = new Date(
    Date.now() + HOME_VISIT_APPROVAL_HOURS * 60 * 60 * 1000,
  );

  const existingHold = await ConsultationBooking.findOne({
    nurseId: payload.nurseId,
    slotStart,
    consultationType: CONSULTATION_TYPE,
    status: 'held',
    paymentExpiresAt: { $gt: new Date() },
  });

  if (existingHold) {
    if (patientId && existingHold.patientId && existingHold.patientId !== patientId) {
      const err = new Error('This slot was just booked. Please choose another time.');
      err.statusCode = 409;
      throw err;
    }
    existingHold.status = 'awaiting_doctor_approval';
    existingHold.patientId = patientId ? String(patientId) : existingHold.patientId;
    existingHold.patientName = name;
    existingHold.patientMobile = mobile;
    existingHold.patientEmail = patientEmail ? String(patientEmail).trim() : undefined;
    existingHold.patientNotes = patientNotes ? String(patientNotes).trim() : undefined;
    existingHold.patientAddress = patientAddress;
    existingHold.patientCity = patientCity;
    existingHold.patientState = patientState;
    existingHold.patientPincode = patientPincode;
    existingHold.visitReason = visitReason;
    existingHold.patientLatitude = Number.isFinite(Number(patientLatitude))
      ? Number(patientLatitude)
      : undefined;
    existingHold.patientLongitude = Number.isFinite(Number(patientLongitude))
      ? Number(patientLongitude)
      : undefined;
    existingHold.distanceKm = distance ?? undefined;
    existingHold.approvalExpiresAt = approvalExpiresAt;
    existingHold.paymentStatus = 'pending';
    if (payload.couponCode) {
      existingHold.couponCode = String(payload.couponCode).trim().toUpperCase();
    }
    await existingHold.save();
    await notifyNurseOfHomeVisitRequest(existingHold);
    return formatNurseBookingResponse(existingHold, nurse);
  }

  const booking = await ConsultationBooking.create({
    id: uuidv4(),
    nurseId: payload.nurseId,
    providerType: 'nurse',
    patientId: patientId ? String(patientId) : undefined,
    consultationType: CONSULTATION_TYPE,
    patientName: name,
    patientMobile: mobile,
    patientEmail: patientEmail ? String(patientEmail).trim() : undefined,
    patientNotes: patientNotes ? String(patientNotes).trim() : undefined,
    patientAddress,
    patientCity,
    patientState,
    patientPincode,
    visitReason,
    patientLatitude: Number.isFinite(Number(patientLatitude))
      ? Number(patientLatitude)
      : undefined,
    patientLongitude: Number.isFinite(Number(patientLongitude))
      ? Number(patientLongitude)
      : undefined,
    distanceKm: distance ?? undefined,
    dayOfWeek: d,
    startHour: h,
    slotStart,
    slotEnd,
    weekStartDate: weekStart,
    consultationFee: fee,
    couponCode: payload.couponCode
      ? String(payload.couponCode).trim().toUpperCase()
      : undefined,
    status: 'awaiting_doctor_approval',
    paymentStatus: 'pending',
    paymentProvider: 'razorpay',
    currency: 'INR',
    approvalExpiresAt,
  });

  await notifyNurseOfHomeVisitRequest(booking);
  return formatNurseBookingResponse(booking, nurse);
}

async function notifyNurseOfHomeVisitRequest(booking) {
  try {
    const { createAndPushNotification } = require('./notificationRepositories');
    const { formatSlotLabel } = require('../utils/slotDateTime');
    if (!booking.nurseId) return;
    const slotLabel = formatSlotLabel(booking.slotStart, booking.slotEnd);
    await createAndPushNotification({
      userId: booking.nurseId,
      userType: 'nurse',
      title: 'New home visit request',
      body: `${booking.patientName} requested a visit (${slotLabel}). Approve or decline.`,
      type: 'home_visit_request',
      data: { bookingId: booking.id, action: 'home_visit_request' },
    });
  } catch (err) {
    console.error('[NurseHomeVisitRequest] notify failed:', err.message);
  }
}

async function approveNurseHomeVisitRequest(bookingId, nurseId) {
  const booking = await ConsultationBooking.findOne({ id: bookingId });
  if (!booking) {
    const err = new Error('Booking not found');
    err.statusCode = 404;
    throw err;
  }
  if (booking.nurseId !== nurseId) {
    const err = new Error('You are not allowed to approve this booking');
    err.statusCode = 403;
    throw err;
  }
  if (booking.consultationType !== CONSULTATION_TYPE) {
    const err = new Error('Only home visit requests can be approved here');
    err.statusCode = 400;
    throw err;
  }
  if (booking.status !== 'awaiting_doctor_approval') {
    const err = new Error('This request is no longer awaiting approval');
    err.statusCode = 409;
    throw err;
  }

  booking.status = 'approved_pending_payment';
  booking.doctorApprovedAt = new Date();
  booking.paymentExpiresAt = new Date(
    Date.now() + HOME_VISIT_PAYMENT_HOURS * 60 * 60 * 1000,
  );
  const { appendStatusHistory } = require('./bookingLifecycleHelpers');
  appendStatusHistory(booking, 'approved_pending_payment', 'nurse');
  await booking.save();

  if (booking.patientId) {
    try {
      const { createAndPushNotification } = require('./notificationRepositories');
      await createAndPushNotification({
        userId: booking.patientId,
        userType: 'patient',
        title: 'Nurse visit approved',
        body: 'Your nurse approved the visit. Please pay to confirm.',
        type: 'booking_approved',
        data: { bookingId: booking.id },
      });
      await createAndPushNotification({
        userId: booking.patientId,
        userType: 'patient',
        title: 'Payment due',
        body: 'Complete payment to confirm your nurse home visit.',
        type: 'payment_due',
        data: { bookingId: booking.id },
      });
    } catch (err) {
      console.error('[NurseApprove] notify failed:', err.message);
    }
  }

  const nurse = await findNurseById(nurseId);
  return formatNurseBookingResponse(booking, nurse);
}

async function rejectNurseHomeVisitRequest(bookingId, nurseId) {
  const booking = await ConsultationBooking.findOne({ id: bookingId });
  if (!booking) {
    const err = new Error('Booking not found');
    err.statusCode = 404;
    throw err;
  }
  if (booking.nurseId !== nurseId) {
    const err = new Error('You are not allowed to reject this booking');
    err.statusCode = 403;
    throw err;
  }
  if (booking.consultationType !== CONSULTATION_TYPE) {
    const err = new Error('Only home visit requests can be rejected here');
    err.statusCode = 400;
    throw err;
  }
  if (booking.status !== 'awaiting_doctor_approval') {
    const err = new Error('This request is no longer awaiting approval');
    err.statusCode = 409;
    throw err;
  }

  booking.status = 'cancelled';
  booking.paymentStatus = 'failed';
  booking.doctorRejectedAt = new Date();
  booking.cancelledAt = new Date();
  booking.cancelledBy = 'nurse';
  const { appendStatusHistory } = require('./bookingLifecycleHelpers');
  appendStatusHistory(booking, 'cancelled', 'nurse');
  await booking.save();

  if (booking.patientId) {
    try {
      const { createAndPushNotification } = require('./notificationRepositories');
      await createAndPushNotification({
        userId: booking.patientId,
        userType: 'patient',
        title: 'Nurse visit declined',
        body: 'Your nurse could not accept this home visit request.',
        type: 'booking_rejected',
        data: { bookingId: booking.id },
      });
    } catch (err) {
      console.error('[NurseReject] notify failed:', err.message);
    }
  }

  const nurse = await findNurseById(nurseId);
  return formatNurseBookingResponse(booking, nurse);
}

async function listNurseBookings(nurseId) {
  const bookings = await ConsultationBooking.find({
    nurseId,
    status: {
      $in: [
        'confirmed',
        'awaiting_doctor_approval',
        'approved_pending_payment',
        'pending',
      ],
    },
  })
    .sort({ slotStart: 1 })
    .limit(50)
    .lean();

  const now = new Date();

  return bookings.map((b) => {
    const slotStart = new Date(b.slotStart);
    const slotEnd = new Date(b.slotEnd);
    const slotLabel = formatSlotLabel(slotStart, slotEnd);
    return {
      id: b.id,
      title: `Home visit — ${b.patientName}`,
      subtitle: slotLabel,
      status: b.status,
      paymentStatus: b.paymentStatus,
      slotStart: b.slotStart,
      slotEnd: b.slotEnd,
      patientName: b.patientName,
      patientMobile: b.patientMobile,
      patientEmail: b.patientEmail,
      patientNotes: b.patientNotes,
      patientAddress: b.patientAddress,
      patientCity: b.patientCity,
      patientState: b.patientState,
      patientPincode: b.patientPincode,
      visitReason: b.visitReason,
      consultationType: b.consultationType,
      typeLabel: 'Home visit',
      consultationFee: b.consultationFee,
      isUpcoming: slotStart >= now,
      patientLatitude: b.patientLatitude ?? null,
      patientLongitude: b.patientLongitude ?? null,
      distanceKm: b.distanceKm ?? null,
      doctorApprovedAt: b.doctorApprovedAt ?? null,
      createdAt: b.createdAt,
    };
  });
}

module.exports = {
  getNurseBookableSlots,
  holdNurseSlot,
  releaseNurseSlotHold,
  createNurseHomeVisitRequest,
  approveNurseHomeVisitRequest,
  rejectNurseHomeVisitRequest,
  listNurseBookings,
};
