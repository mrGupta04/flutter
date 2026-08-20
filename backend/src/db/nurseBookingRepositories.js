const { v4: uuidv4 } = require('uuid');
const mongoose = require('mongoose');
const ConsultationBooking = require('./models/ConsultationBooking');
const { findNurseById } = require('./nurseRepositories');
const { findAvailabilityForActiveWeek } = require('./nurseAvailabilityRepositories');
const {
  isWeekExpired,
  SLOT_START_HOUR,
  SLOT_END_HOUR,
} = require('../utils/availabilityWeek');
const {
  slotDateTime,
  slotEndDateTime,
  formatSlotLabel,
} = require('../utils/slotDateTime');
const { distanceKm } = require('../utils/geoDistance');
const {
  NURSE_PAYMENT_MINUTES,
  CONSULTATION_TYPE,
  STATUS,
  ACTIVE_SLOT_STATUSES,
  PAYMENT_PENDING_STATUSES,
  APPROVAL_PENDING_STATUSES,
  isPaymentPendingStatus,
  isApprovalPendingStatus,
  isActiveSlotStatus,
  remainingPaymentSeconds,
  workflowStatus,
  overlapFilter,
  paymentWindowExpiresAt,
} = require('./nurseBookingStatus');

const HOME_VISIT_APPROVAL_HOURS = parseInt(
  process.env.HOME_VISIT_APPROVAL_HOURS || '48',
  10,
);
const SLOT_HOLD_MINUTES = parseInt(process.env.SLOT_HOLD_MINUTES || '10', 10);

function normalizeMobile(mobile) {
  return String(mobile || '').replace(/\D/g, '').slice(-10);
}

function isSlotReserved(booking, now = new Date()) {
  if (!booking) return false;
  if (!isActiveSlotStatus(booking.status)) return false;
  if (booking.status === STATUS.HELD) {
    return !booking.paymentExpiresAt || booking.paymentExpiresAt > now;
  }
  if (isPaymentPendingStatus(booking.status)) {
    return !booking.paymentExpiresAt || booking.paymentExpiresAt > now;
  }
  return true;
}

async function notifyNursePaymentExpired(booking) {
  try {
    const { notifyPatient } = require('./notificationRepositories');
    await notifyPatient(booking, {
      title: 'Payment window expired',
      body: 'Your booking expired because payment was not completed within 10 minutes.',
      type: 'payment_expired',
    });
  } catch (err) {
    console.error('[NurseExpire] notify failed:', err.message);
  }
  emitNurseBookingStatus(booking);
}

function emitNurseBookingStatus(booking) {
  try {
    const { emitBookingStatusUpdate } = require('../services/trackingSocket');
    emitBookingStatusUpdate(booking);
  } catch (err) {
    console.warn('[NurseBooking] status emit failed:', err.message);
  }
}

async function expireDuePaymentBookings(filter = {}) {
  const now = new Date();
  const due = await ConsultationBooking.find({
    ...filter,
    nurseId: filter.nurseId || { $exists: true, $nin: [null, ''] },
    consultationType: CONSULTATION_TYPE,
    status: { $in: PAYMENT_PENDING_STATUSES },
    paymentExpiresAt: { $lte: now },
  });

  for (const booking of due) {
    booking.status = STATUS.PAYMENT_EXPIRED;
    booking.paymentStatus = 'expired';
    booking.cancelledAt = now;
    booking.cancelledBy = 'system';
    booking.cancellationReason = 'Payment window expired';
    const { appendStatusHistory } = require('./bookingLifecycleHelpers');
    appendStatusHistory(booking, STATUS.PAYMENT_EXPIRED, 'system');
    await booking.save();
    await notifyNursePaymentExpired(booking);
  }
  return due.length;
}

async function expirePendingNurseBookings(nurseId) {
  const now = new Date();
  await ConsultationBooking.updateMany(
    {
      nurseId,
      status: STATUS.HELD,
      paymentExpiresAt: { $lte: now },
    },
    { $set: { status: STATUS.CANCELLED, paymentStatus: 'failed' } },
  );
  await ConsultationBooking.updateMany(
    {
      nurseId,
      status: { $in: APPROVAL_PENDING_STATUSES },
      approvalExpiresAt: { $lte: now },
    },
    {
      $set: {
        status: STATUS.CANCELLED,
        paymentStatus: 'failed',
        cancelledAt: now,
        cancelledBy: 'system',
        cancellationReason: 'Nurse approval window expired',
      },
    },
  );
  await expireDuePaymentBookings({ nurseId });
}

async function expireAllNursePaymentWindows() {
  return expireDuePaymentBookings();
}

async function findOverlappingNurseBooking(
  nurseId,
  slotStart,
  slotEnd,
  { excludeId, session } = {},
) {
  const query = ConsultationBooking.findOne(
    overlapFilter(nurseId, slotStart, slotEnd, { excludeId }),
  );
  if (session) query.session(session);
  const existing = await query;
  if (existing && isSlotReserved(existing)) return existing;
  return null;
}

async function withMongoTransaction(work) {
  const session = await mongoose.startSession();
  try {
    session.startTransaction();
    const result = await work(session);
    await session.commitTransaction();
    return result;
  } catch (err) {
    try {
      await session.abortTransaction();
    } catch {
      // ignore abort errors
    }
    if (
      err.code === 11000 ||
      String(err.message || '').includes('duplicate key')
    ) {
      const conflict = new Error(
        'This slot was just booked. Please choose another time.',
      );
      conflict.statusCode = 409;
      throw conflict;
    }
    const msg = String(err.message || '');
    if (
      msg.includes('Transaction numbers are only allowed') ||
      msg.includes('replica set')
    ) {
      return work(null);
    }
    throw err;
  } finally {
    session.endSession();
  }
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
  const regular = Number(nurse?.homeVisitFee);
  const offer = Number(nurse?.homeVisitOfferFee);
  const regularFee = Number.isFinite(regular) && regular >= 1 ? regular : null;
  const offerFee = Number.isFinite(offer) && offer >= 1 ? offer : null;
  if (offerFee != null && (regularFee == null || offerFee < regularFee)) {
    return offerFee;
  }
  return regularFee;
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
  const nurseName = `${nurse?.firstName || ''} ${nurse?.lastName || ''}`.trim() || 'Nurse';
  const now = new Date();
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
    amount: booking.consultationFee,
    status: booking.status,
    workflowStatus: workflowStatus(booking),
    visitProgress: booking.visitProgress || null,
    paymentStatus: booking.paymentStatus,
    paymentMethod: booking.paymentMethod || booking.paymentProvider || null,
    mockTransactionId: booking.mockTransactionId || null,
    paymentExpiresAt: booking.paymentExpiresAt || null,
    remainingPaymentSeconds: isPaymentPendingStatus(booking.status)
      ? remainingPaymentSeconds(booking, now)
      : 0,
    serverTime: now.toISOString(),
    lastNurseLatitude: booking.currentLatitude ?? null,
    lastNurseLongitude: booking.currentLongitude ?? null,
    lastNurseHeading: booking.currentHeading ?? null,
    lastLocationUpdatedAt: booking.liveLocationUpdatedAt || null,
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
    status: { $in: ACTIVE_SLOT_STATUSES },
    slotStart: { $lte: weekEnd },
    slotEnd: { $gte: weekStart },
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
    for (let hour = SLOT_START_HOUR; hour <= SLOT_END_HOUR; hour += 1) {
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

  const overlapping = await findOverlappingNurseBooking(
    nurseId,
    slotStart,
    slotEnd,
  );

  if (overlapping && isSlotReserved(overlapping)) {
    if (
      overlapping.status === STATUS.HELD &&
      patientId &&
      overlapping.patientId === patientId
    ) {
      overlapping.paymentExpiresAt = new Date(
        Date.now() + holdMinutes * 60 * 1000,
      );
      await overlapping.save();
      return {
        holdId: overlapping.id,
        expiresAt: overlapping.paymentExpiresAt,
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
        status: STATUS.HELD,
      },
      { $set: { status: STATUS.CANCELLED, paymentStatus: 'failed' } },
    );
  }

  const paymentExpiresAt = new Date(Date.now() + holdMinutes * 60 * 1000);
  const fee = getNurseHomeVisitFee(nurse);

  try {
    const booking = await withMongoTransaction(async (session) => {
      const raced = await findOverlappingNurseBooking(
        nurseId,
        slotStart,
        slotEnd,
        { session },
      );
      if (raced && isSlotReserved(raced)) {
        const err = new Error(
          'This slot was just booked. Please choose another time.',
        );
        err.statusCode = 409;
        throw err;
      }
      const [created] = await ConsultationBooking.create(
        [
          {
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
            status: STATUS.HELD,
            paymentStatus: 'pending',
            paymentProvider: 'mock',
            paymentMethod: 'MOCK',
            currency: 'INR',
            paymentExpiresAt,
          },
        ],
        session ? { session } : undefined,
      );
      return created;
    });
    return { holdId: booking.id, expiresAt: paymentExpiresAt };
  } catch (err) {
    if (err.statusCode === 409) throw err;
    const raced = await findOverlappingNurseBooking(nurseId, slotStart, slotEnd);
    if (raced && isSlotReserved(raced)) {
      const conflict = new Error(
        'This slot was just booked. Please choose another time.',
      );
      conflict.statusCode = 409;
      throw conflict;
    }
    throw err;
  }
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
  booking.status = STATUS.CANCELLED;
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
    patientId: payloadPatientId,
    patientEmail,
    patientNotes,
    patientAddress,
    patientCity,
    patientState,
    patientPincode,
    visitReason,
    fee,
  } = validated;

  const { resolvePatientId } = require('./notificationRepositories');
  const patientId =
    (payloadPatientId && String(payloadPatientId)) ||
    (await resolvePatientId({
      patientMobile: mobile,
      patientEmail,
    }));

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
    status: STATUS.HELD,
    paymentExpiresAt: { $gt: new Date() },
  });

  if (existingHold) {
    if (patientId && existingHold.patientId && existingHold.patientId !== patientId) {
      const err = new Error('This slot was just booked. Please choose another time.');
      err.statusCode = 409;
      throw err;
    }
    const overlap = await findOverlappingNurseBooking(
      payload.nurseId,
      slotStart,
      slotEnd,
      { excludeId: existingHold.id },
    );
    if (overlap && isSlotReserved(overlap)) {
      const err = new Error('This slot was just booked. Please choose another time.');
      err.statusCode = 409;
      throw err;
    }
    existingHold.status = STATUS.PENDING_NURSE_APPROVAL;
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
    existingHold.paymentProvider = 'mock';
    existingHold.paymentMethod = 'MOCK';
    if (payload.couponCode) {
      existingHold.couponCode = String(payload.couponCode).trim().toUpperCase();
    }
    const { appendStatusHistory } = require('./bookingLifecycleHelpers');
    appendStatusHistory(existingHold, STATUS.PENDING_NURSE_APPROVAL, 'patient');
    await existingHold.save();
    await notifyNurseOfHomeVisitRequest(existingHold, nurse);
    emitNurseBookingStatus(existingHold);
    return formatNurseBookingResponse(existingHold, nurse);
  }

  const overlap = await findOverlappingNurseBooking(
    payload.nurseId,
    slotStart,
    slotEnd,
  );
  if (overlap && isSlotReserved(overlap)) {
    const err = new Error('This slot was just booked. Please choose another time.');
    err.statusCode = 409;
    throw err;
  }

  const bookingDoc = {
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
    status: STATUS.PENDING_NURSE_APPROVAL,
    paymentStatus: 'pending',
    paymentProvider: 'mock',
    paymentMethod: 'MOCK',
    currency: 'INR',
    approvalExpiresAt,
    statusHistory: [
      {
        status: STATUS.PENDING_NURSE_APPROVAL,
        at: new Date(),
        by: 'patient',
      },
    ],
  };

  let booking;
  try {
    booking = await withMongoTransaction(async (session) => {
      const raced = await findOverlappingNurseBooking(
        payload.nurseId,
        slotStart,
        slotEnd,
        { session },
      );
      if (raced && isSlotReserved(raced)) {
        const err = new Error(
          'This slot was just booked. Please choose another time.',
        );
        err.statusCode = 409;
        throw err;
      }
      const [created] = await ConsultationBooking.create(
        [bookingDoc],
        session ? { session } : undefined,
      );
      return created;
    });
  } catch (err) {
    if (err.statusCode === 409) throw err;
    const raced = await findOverlappingNurseBooking(
      payload.nurseId,
      slotStart,
      slotEnd,
    );
    if (raced && isSlotReserved(raced)) {
      const conflict = new Error(
        'This slot was just booked. Please choose another time.',
      );
      conflict.statusCode = 409;
      throw conflict;
    }
    throw err;
  }

  await notifyNurseOfHomeVisitRequest(booking, nurse);
  emitNurseBookingStatus(booking);
  return formatNurseBookingResponse(booking, nurse);
}

async function notifyNurseOfHomeVisitRequest(booking, nurse) {
  try {
    const { createAndPushNotification } = require('./notificationRepositories');
    if (!booking.nurseId) return;
    const slotLabel = formatSlotLabel(booking.slotStart, booking.slotEnd);
    const location = [booking.patientAddress, booking.patientCity]
      .filter(Boolean)
      .join(', ');
    const nurseName = nurse
      ? `${nurse.firstName || ''} ${nurse.lastName || ''}`.trim()
      : 'Nurse';
    await createAndPushNotification({
      userId: booking.nurseId,
      userType: 'nurse',
      title: 'New Booking Request',
      body:
        `New booking request from ${booking.patientName}. ` +
        `${slotLabel}${location ? ` · ${location}` : ''}. ` +
        'A new user has requested your nursing service.',
      type: 'home_visit_request',
      data: {
        bookingId: booking.id,
        action: 'home_visit_request',
        patientName: booking.patientName,
        date: booking.slotStart,
        time: slotLabel,
        location,
        service: 'Nurse home visit',
        nurseName,
      },
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
  if (!isApprovalPendingStatus(booking.status)) {
    const err = new Error('This request is no longer awaiting approval');
    err.statusCode = 409;
    throw err;
  }
  if (
    booking.approvalExpiresAt &&
    new Date(booking.approvalExpiresAt) <= new Date()
  ) {
    booking.status = STATUS.CANCELLED;
    booking.cancelledAt = new Date();
    booking.cancelledBy = 'system';
    await booking.save();
    const err = new Error('This request has expired');
    err.statusCode = 410;
    throw err;
  }

  const now = new Date();
  booking.status = STATUS.PAYMENT_PENDING;
  booking.doctorApprovedAt = now;
  booking.paymentExpiresAt = paymentWindowExpiresAt(now);
  booking.paymentStatus = 'pending';
  booking.paymentProvider = 'mock';
  booking.paymentMethod = 'MOCK';
  const { appendStatusHistory } = require('./bookingLifecycleHelpers');
  appendStatusHistory(booking, 'nurse_verified', 'nurse');
  appendStatusHistory(booking, STATUS.PAYMENT_PENDING, 'nurse');
  await booking.save();

  try {
    const { notifyPatient } = require('./notificationRepositories');
    const nurse = await findNurseById(nurseId);
    const nurseName = `${nurse?.firstName || ''} ${nurse?.lastName || ''}`.trim() || 'your nurse';
    await notifyPatient(booking, {
      title: 'Nurse Verified',
      body: `Nurse ${nurseName} has verified your booking. Please complete payment within ${NURSE_PAYMENT_MINUTES} minutes.`,
      type: 'payment_due',
      data: {
        paymentExpiresAt: booking.paymentExpiresAt,
        remainingPaymentSeconds: remainingPaymentSeconds(booking),
      },
    });
  } catch (err) {
    console.error('[NurseApprove] notify failed:', err.message);
  }

  emitNurseBookingStatus(booking);
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
  if (!isApprovalPendingStatus(booking.status)) {
    const err = new Error('This request is no longer awaiting approval');
    err.statusCode = 409;
    throw err;
  }

  booking.status = STATUS.NURSE_REJECTED;
  booking.paymentStatus = 'failed';
  booking.doctorRejectedAt = new Date();
  booking.cancelledAt = new Date();
  booking.cancelledBy = 'nurse';
  const { appendStatusHistory } = require('./bookingLifecycleHelpers');
  appendStatusHistory(booking, STATUS.NURSE_REJECTED, 'nurse');
  await booking.save();

  try {
    const { notifyPatient } = require('./notificationRepositories');
    await notifyPatient(booking, {
      title: 'Nurse visit declined',
      body: 'Your nurse could not accept this home visit request. The time slot is available again.',
      type: 'booking_rejected',
    });
  } catch (err) {
    console.error('[NurseReject] notify failed:', err.message);
  }

  emitNurseBookingStatus(booking);
  const nurse = await findNurseById(nurseId);
  return formatNurseBookingResponse(booking, nurse);
}

function mapNurseBookingListItem(b, now = new Date()) {
  const slotStart = new Date(b.slotStart);
  const slotEnd = new Date(b.slotEnd);
  const slotLabel = formatSlotLabel(slotStart, slotEnd);
  const activeProgress = ['en_route', 'arrived', 'visit_started'].includes(
    b.visitProgress,
  );
  return {
    id: b.id,
    title: `Home visit — ${b.patientName}`,
    subtitle: slotLabel,
    status: b.status,
    workflowStatus: workflowStatus(b),
    paymentStatus: b.paymentStatus,
    visitProgress: b.visitProgress || null,
    paymentExpiresAt: b.paymentExpiresAt || null,
    remainingPaymentSeconds: isPaymentPendingStatus(b.status)
      ? remainingPaymentSeconds(b, now)
      : 0,
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
    consultationType: b.consultationType || 'book_home',
    typeLabel: 'Home visit',
    consultationFee: b.consultationFee,
    isUpcoming:
      (slotEnd >= now && b.visitProgress !== 'completed') ||
      activeProgress ||
      isApprovalPendingStatus(b.status) ||
      isPaymentPendingStatus(b.status),
    patientLatitude: b.patientLatitude ?? null,
    patientLongitude: b.patientLongitude ?? null,
    distanceKm: b.distanceKm ?? null,
    doctorApprovedAt: b.doctorApprovedAt ?? null,
    createdAt: b.createdAt,
  };
}

async function listNurseBookings(nurseId) {
  await expirePendingNurseBookings(nurseId);
  const bookings = await ConsultationBooking.find({
    nurseId,
    status: {
      $in: [
        STATUS.CONFIRMED,
        STATUS.PENDING_NURSE_APPROVAL,
        STATUS.LEGACY_AWAITING_APPROVAL,
        STATUS.PAYMENT_PENDING,
        STATUS.LEGACY_APPROVED_PENDING_PAYMENT,
        STATUS.NURSE_REJECTED,
        STATUS.PAYMENT_EXPIRED,
        'pending',
        STATUS.CANCELLED,
      ],
    },
  })
    .sort({ slotStart: -1 })
    .limit(200)
    .lean();

  const now = new Date();
  return bookings.map((b) => mapNurseBookingListItem(b, now));
}

async function getNurseBookingById(bookingId, auth) {
  const booking = await ConsultationBooking.findOne({ id: bookingId });
  if (!booking) {
    const err = new Error('Booking not found');
    err.statusCode = 404;
    throw err;
  }
  if (booking.consultationType !== CONSULTATION_TYPE || !booking.nurseId) {
    const err = new Error('Not a nurse home visit booking');
    err.statusCode = 400;
    throw err;
  }

  const isNurse = auth?.type === 'nurse' && auth.nurseId === booking.nurseId;
  const isPatient =
    auth?.type === 'patient' &&
    booking.patientId &&
    auth.patientId === booking.patientId;
  if (!isNurse && !isPatient) {
    const err = new Error('Not allowed to view this booking');
    err.statusCode = 403;
    throw err;
  }

  if (booking.nurseId) {
    await expirePendingNurseBookings(booking.nurseId);
    const fresh = await ConsultationBooking.findOne({ id: bookingId });
    const nurse = await findNurseById(booking.nurseId);
    return formatNurseBookingResponse(fresh || booking, nurse);
  }

  const err = new Error('Nurse not found');
  err.statusCode = 404;
  throw err;
}

module.exports = {
  getNurseBookableSlots,
  holdNurseSlot,
  releaseNurseSlotHold,
  createNurseHomeVisitRequest,
  approveNurseHomeVisitRequest,
  rejectNurseHomeVisitRequest,
  listNurseBookings,
  getNurseBookingById,
  expireAllNursePaymentWindows,
  expirePendingNurseBookings,
  formatNurseBookingResponse,
  isPaymentPendingStatus,
  remainingPaymentSeconds,
  workflowStatus,
};
