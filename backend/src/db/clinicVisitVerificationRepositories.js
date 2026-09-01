const crypto = require('crypto');
const { v4: uuidv4 } = require('uuid');
const ConsultationBooking = require('./models/ConsultationBooking');
const BookingVerificationOtp = require('./models/BookingVerificationOtp');
const Patient = require('./models/Patient');
const { findDoctorById } = require('./repositories');
const { hashPassword, verifyPassword } = require('../utils/providerAuth');
const { clinicParts, clinicDateTime } = require('../utils/clinicTime');
const { formatSlotLabel } = require('../utils/slotDateTime');
const { appendStatusHistory } = require('./bookingLifecycleHelpers');

const MAX_OTP_ATTEMPTS = Number(process.env.CLINIC_OTP_MAX_ATTEMPTS || 5);
const LOCK_MS = Number(process.env.CLINIC_OTP_LOCK_MS || 15 * 60 * 1000);
const REGEN_COOLDOWN_MS = Number(process.env.CLINIC_OTP_REGEN_COOLDOWN_MS || 2 * 60 * 1000);
const VERIFY_WINDOW_BEFORE_MS = 2 * 60 * 60 * 1000;
const VERIFY_WINDOW_AFTER_MS = 4 * 60 * 60 * 1000;

function generateOtpCode() {
  return String(crypto.randomInt(1000, 10000));
}

function isVerified(booking) {
  return (
    booking?.verificationStatus === 'VERIFIED' ||
    Boolean(booking?.appointmentVerifiedAt)
  );
}

function otpExpiresAt(booking, now = new Date()) {
  const slotEnd = booking?.slotEnd ? new Date(booking.slotEnd) : now;
  const fromSlot = new Date(slotEnd.getTime() + VERIFY_WINDOW_AFTER_MS);
  const fromNow = new Date(now.getTime() + 12 * 60 * 60 * 1000);
  return fromSlot > fromNow ? fromSlot : fromNow;
}

function clinicDayBounds(date = new Date()) {
  const { year, month, day } = clinicParts(date);
  return {
    start: clinicDateTime(year, month, day, 0, 0, 0, 0),
    end: clinicDateTime(year, month, day, 23, 59, 59, 999),
  };
}

function clinicVerificationFields(booking, { includeOtp = false } = {}) {
  if (!booking) return {};
  const verified = isVerified(booking);
  const status =
    booking.verificationStatus ||
    (verified ? 'VERIFIED' : booking.appointmentCode ? 'PENDING' : null);
  const fields = {
    verificationStatus: status,
    verifiedBy: booking.verifiedBy || null,
    verifiedByType: booking.verifiedByType || null,
    verifiedByName: booking.verifiedByName || null,
    verifiedAt: booking.verifiedAt || booking.appointmentVerifiedAt || null,
    patientArrivedAt: booking.patientArrivedAt || null,
    appointmentVerifiedAt: booking.appointmentVerifiedAt || null,
    isAppointmentVerified: verified,
  };
  if (includeOtp && !verified && booking.appointmentCode) {
    fields.appointmentCode = booking.appointmentCode;
  }
  return fields;
}

async function generateUniqueAppointmentCode(doctorId) {
  for (let attempt = 0; attempt < 20; attempt += 1) {
    const code = generateOtpCode();
    const existing = await ConsultationBooking.findOne({
      doctorId,
      appointmentCode: code,
      consultationType: 'visit_site',
      status: 'confirmed',
      slotStart: { $gte: new Date() },
    }).lean();
    if (!existing) return code;
  }
  const err = new Error('Could not generate a verification code. Please try again.');
  err.statusCode = 503;
  throw err;
}

async function latestOtpRecord(bookingId) {
  return BookingVerificationOtp.findOne({ bookingId }).sort({ createdAt: -1 });
}

async function persistOtp(booking, code) {
  const now = new Date();
  const hash = hashPassword(code);
  const expiresAt = otpExpiresAt(booking, now);
  let record = await latestOtpRecord(booking.id);
  if (record && !record.isUsed) {
    record.otpHash = hash;
    record.expiresAt = expiresAt;
    record.attemptCount = 0;
    record.lockedUntil = undefined;
    record.lastGeneratedAt = now;
    record.isUsed = false;
    record.verifiedAt = undefined;
    await record.save();
  } else {
    record = await BookingVerificationOtp.create({
      id: uuidv4(),
      bookingId: booking.id,
      otpHash: hash,
      expiresAt,
      attemptCount: 0,
      isUsed: false,
      lastGeneratedAt: now,
    });
  }
  booking.appointmentCode = code;
  booking.verificationStatus = booking.verificationStatus || 'PENDING';
  return { record, expiresAt };
}

async function issueClinicVisitOtp(booking, { regenerate = false } = {}) {
  if (!booking || booking.consultationType !== 'visit_site') {
    const err = new Error('Arrival verification applies to clinic visits only');
    err.statusCode = 400;
    throw err;
  }
  if (booking.status === 'cancelled') {
    const err = new Error('This booking was cancelled');
    err.statusCode = 409;
    throw err;
  }
  if (isVerified(booking)) {
    const err = new Error('Patient is already verified');
    err.statusCode = 409;
    throw err;
  }

  const existing = await latestOtpRecord(booking.id);
  if (existing && !existing.isUsed) {
    const generatedAt = existing.lastGeneratedAt || existing.createdAt;
    const elapsed = Date.now() - new Date(generatedAt).getTime();
    if (regenerate && elapsed < REGEN_COOLDOWN_MS) {
      const waitSec = Math.ceil((REGEN_COOLDOWN_MS - elapsed) / 1000);
      const err = new Error(
        `Please wait ${waitSec} seconds before requesting a new verification code`,
      );
      err.statusCode = 429;
      throw err;
    }
    if (!regenerate && booking.appointmentCode) {
      return {
        code: booking.appointmentCode,
        expiresAt: existing.expiresAt,
        created: false,
      };
    }
  }

  const code = await generateUniqueAppointmentCode(booking.doctorId);
  const { expiresAt } = await persistOtp(booking, code);
  await booking.save();
  return { code, expiresAt, created: true };
}

async function ensureClinicVisitOtp(booking) {
  if (!booking || booking.consultationType !== 'visit_site') return null;
  if (isVerified(booking)) return null;
  if (!booking.appointmentCode) {
    return issueClinicVisitOtp(booking, { regenerate: false });
  }
  const existing = await latestOtpRecord(booking.id);
  if (!existing || existing.isUsed) {
    const { expiresAt } = await persistOtp(booking, booking.appointmentCode);
    if (!booking.verificationStatus) booking.verificationStatus = 'PENDING';
    await booking.save();
    return { code: booking.appointmentCode, expiresAt, created: true };
  }
  return { code: booking.appointmentCode, expiresAt: existing.expiresAt, created: false };
}

function otpStatusError(record, now = new Date()) {
  if (!record) {
    const err = new Error(
      'This verification code has expired. Please generate a new verification code.',
    );
    err.statusCode = 400;
    err.code = 'OTP_MISSING';
    return err;
  }
  if (record.isUsed) {
    const err = new Error('This verification code has already been used');
    err.statusCode = 409;
    err.code = 'OTP_USED';
    return err;
  }
  if (record.lockedUntil && new Date(record.lockedUntil) > now) {
    const err = new Error(
      'Too many incorrect attempts. OTP verification is temporarily locked. Please try again later or request a new code.',
    );
    err.statusCode = 429;
    err.code = 'OTP_LOCKED';
    return err;
  }
  if (new Date(record.expiresAt) <= now) {
    const err = new Error(
      'This verification code has expired. Please generate a new verification code.',
    );
    err.statusCode = 400;
    err.code = 'OTP_EXPIRED';
    return err;
  }
  return null;
}

async function notifyArrivalVerified(booking, receptionistName) {
  try {
    const { createAndPushNotification } = require('./notificationRepositories');
    const { emitBookingStatusUpdate } = require('../services/trackingSocket');
    emitBookingStatusUpdate({
      ...booking.toObject?.() || booking,
      verificationStatus: 'VERIFIED',
    });

    if (booking.patientId) {
      await createAndPushNotification({
        userId: booking.patientId,
        userType: 'patient',
        title: 'Arrival verified',
        body: 'You have been verified by the clinic receptionist.',
        type: 'arrived',
        data: { bookingId: booking.id },
      });
    }
    if (booking.doctorId) {
      const name = booking.patientName || 'A patient';
      const by = receptionistName ? ` by ${receptionistName}` : '';
      await createAndPushNotification({
        userId: booking.doctorId,
        userType: 'doctor',
        title: 'Patient Arrived',
        body: `${name} has arrived at the clinic and has been verified${by}.`,
        type: 'arrived',
        data: { bookingId: booking.id, patientName: name },
      });
    }
  } catch (err) {
    console.error('[clinic-otp] notify failed:', err.message);
  }
}

async function verifyClinicVisitOtp({
  bookingId,
  otp,
  doctorId,
  actorType,
  actorId,
  actorName,
}) {
  const code = String(otp || '').trim();
  if (!/^\d{4}$/.test(code)) {
    const err = new Error('Enter a valid 4-digit verification code');
    err.statusCode = 400;
    throw err;
  }

  const booking = await ConsultationBooking.findOne({ id: bookingId });
  if (!booking) {
    const err = new Error('Invalid booking ID');
    err.statusCode = 404;
    throw err;
  }
  if (booking.consultationType !== 'visit_site') {
    const err = new Error('Arrival verification applies to clinic visits only');
    err.statusCode = 400;
    throw err;
  }
  if (booking.doctorId !== doctorId) {
    const err = new Error('This appointment does not belong to your clinic');
    err.statusCode = 403;
    throw err;
  }
  if (booking.status === 'cancelled') {
    const err = new Error('This booking was cancelled');
    err.statusCode = 409;
    throw err;
  }
  if (booking.status !== 'confirmed') {
    const err = new Error('Only confirmed clinic visits can be verified');
    err.statusCode = 400;
    throw err;
  }
  if (isVerified(booking)) {
    const err = new Error('Patient is already verified');
    err.statusCode = 409;
    throw err;
  }

  const now = new Date();
  const slotStart = new Date(booking.slotStart);
  const windowStart = new Date(slotStart.getTime() - VERIFY_WINDOW_BEFORE_MS);
  const windowEnd = new Date(new Date(booking.slotEnd).getTime() + VERIFY_WINDOW_AFTER_MS);
  if (now < windowStart || now > windowEnd) {
    const err = new Error(
      'This verification code can only be used around the scheduled visit time',
    );
    err.statusCode = 400;
    throw err;
  }

  let record = await latestOtpRecord(booking.id);
  if (!record && booking.appointmentCode) {
    await persistOtp(booking, booking.appointmentCode);
    await booking.save();
    record = await latestOtpRecord(booking.id);
  }

  const statusErr = otpStatusError(record, now);
  if (statusErr) throw statusErr;

  const matchesHash = verifyPassword(code, record.otpHash);
  const matchesPlain =
    booking.appointmentCode && booking.appointmentCode === code;
  if (!matchesHash && !matchesPlain) {
    record.attemptCount = (record.attemptCount || 0) + 1;
    if (record.attemptCount >= MAX_OTP_ATTEMPTS) {
      record.lockedUntil = new Date(now.getTime() + LOCK_MS);
    }
    await record.save();
    if (record.attemptCount >= MAX_OTP_ATTEMPTS) {
      const err = new Error(
        'Too many incorrect attempts. OTP verification is temporarily locked. Request a new code if needed.',
      );
      err.statusCode = 429;
      err.code = 'OTP_LOCKED';
      throw err;
    }
    const remaining = MAX_OTP_ATTEMPTS - record.attemptCount;
    const err = new Error(
      `The verification code is incorrect. Please ask the patient to provide the correct OTP. ${remaining} attempt(s) remaining.`,
    );
    err.statusCode = 400;
    err.code = 'OTP_INVALID';
    throw err;
  }

  record.isUsed = true;
  record.verifiedAt = now;
  record.lockedUntil = undefined;
  await record.save();

  booking.verificationStatus = 'VERIFIED';
  booking.verifiedBy = actorId;
  booking.verifiedByType = actorType;
  booking.verifiedByName = actorName || undefined;
  booking.verifiedAt = now;
  booking.patientArrivedAt = now;
  booking.appointmentVerifiedAt = now;
  booking.visitProgress = 'arrived';
  booking.appointmentCode = undefined;
  appendStatusHistory(booking, 'patient_arrived', actorType);
  await booking.save();

  await notifyArrivalVerified(booking, actorName);

  const doctor = await findDoctorById(booking.doctorId);
  return {
    id: booking.id,
    patientName: booking.patientName,
    patientMobile: booking.patientMobile,
    slotStart: booking.slotStart,
    slotEnd: booking.slotEnd,
    label: formatSlotLabel(new Date(booking.slotStart), new Date(booking.slotEnd)),
    verificationStatus: 'VERIFIED',
    verifiedBy: booking.verifiedBy,
    verifiedByName: booking.verifiedByName || null,
    verifiedAt: booking.verifiedAt,
    patientArrivedAt: booking.patientArrivedAt,
    isAppointmentVerified: true,
    clinicName: doctor?.clinicName,
  };
}

async function getPatientClinicOtp({ bookingId, patientId, mobileNumber }) {
  const { assertPatientCanAccessBooking } = require('./bookingRepositories');
  const booking = await assertPatientCanAccessBooking(
    bookingId,
    patientId,
    mobileNumber,
  );
  if (booking.consultationType !== 'visit_site') {
    const err = new Error('Arrival verification applies to clinic visits only');
    err.statusCode = 400;
    throw err;
  }
  if (isVerified(booking)) {
    return {
      bookingId: booking.id,
      verificationStatus: 'VERIFIED',
      isAppointmentVerified: true,
      verifiedAt: booking.verifiedAt || booking.appointmentVerifiedAt,
      appointmentCode: null,
    };
  }
  const issued = await ensureClinicVisitOtp(booking);
  return {
    bookingId: booking.id,
    verificationStatus: 'PENDING',
    isAppointmentVerified: false,
    appointmentCode: issued?.code || booking.appointmentCode || null,
    otpExpiresAt: issued?.expiresAt || null,
  };
}

async function regeneratePatientClinicOtp({ bookingId, patientId, mobileNumber }) {
  const { assertPatientCanAccessBooking } = require('./bookingRepositories');
  const bookingDoc = await ConsultationBooking.findOne({ id: bookingId });
  if (!bookingDoc) {
    const err = new Error('Booking not found');
    err.statusCode = 404;
    throw err;
  }
  await assertPatientCanAccessBooking(bookingId, patientId, mobileNumber);
  const issued = await issueClinicVisitOtp(bookingDoc, { regenerate: true });
  return {
    bookingId: bookingDoc.id,
    verificationStatus: 'PENDING',
    appointmentCode: issued.code,
    otpExpiresAt: issued.expiresAt,
    message: 'A new verification code has been generated.',
  };
}

async function regenerateReceptionistClinicOtp({ bookingId, doctorId }) {
  const booking = await ConsultationBooking.findOne({ id: bookingId });
  if (!booking) {
    const err = new Error('Invalid booking ID');
    err.statusCode = 404;
    throw err;
  }
  if (booking.doctorId !== doctorId) {
    const err = new Error('This appointment does not belong to your clinic');
    err.statusCode = 403;
    throw err;
  }
  await issueClinicVisitOtp(booking, { regenerate: true });
  try {
    const { createAndPushNotification } = require('./notificationRepositories');
    if (booking.patientId) {
      await createAndPushNotification({
        userId: booking.patientId,
        userType: 'patient',
        title: 'New clinic verification code',
        body: 'Your clinic arrival OTP was refreshed. Open this booking to view the new code.',
        type: 'general',
        data: { bookingId: booking.id },
      });
    }
  } catch (err) {
    console.error('[clinic-otp] regen notify failed:', err.message);
  }
  return {
    bookingId: booking.id,
    message: 'A new verification code was generated for the patient.',
  };
}

function clinicVisitDisplayStatus(booking) {
  if (booking.status === 'cancelled') return 'CANCELLED';
  if (booking.visitProgress === 'completed') return 'COMPLETED';
  if (booking.visitProgress === 'visit_started') return 'CONSULTATION_STARTED';
  if (isVerified(booking)) return 'VERIFIED';
  if (booking.status === 'confirmed') return 'PENDING_VERIFICATION';
  return String(booking.status || '').toUpperCase();
}

async function listClinicVisitsForDoctor(doctorId, { filter = 'today' } = {}) {
  const now = new Date();
  const query = {
    doctorId,
    consultationType: 'visit_site',
  };

  switch (String(filter || 'today')) {
    case 'upcoming':
      query.status = 'confirmed';
      query.slotEnd = { $gte: now };
      break;
    case 'completed':
      query.$or = [
        { visitProgress: 'completed' },
        { verificationStatus: 'VERIFIED', slotEnd: { $lt: now } },
      ];
      break;
    case 'cancelled':
      query.status = 'cancelled';
      break;
    case 'verified':
      query.$or = [
        { verificationStatus: 'VERIFIED' },
        { appointmentVerifiedAt: { $ne: null } },
      ];
      break;
    case 'pending':
      query.status = 'confirmed';
      query.$and = [
        {
          $or: [
            { verificationStatus: { $exists: false } },
            { verificationStatus: null },
            { verificationStatus: 'PENDING' },
          ],
        },
        {
          $or: [
            { appointmentVerifiedAt: { $exists: false } },
            { appointmentVerifiedAt: null },
          ],
        },
      ];
      break;
    case 'today':
    default: {
      const { start, end } = clinicDayBounds(now);
      query.slotStart = { $gte: start, $lte: end };
      query.status = { $in: ['confirmed', 'cancelled'] };
      break;
    }
  }

  const bookings = await ConsultationBooking.find(query)
    .sort({ slotStart: 1 })
    .limit(100)
    .lean();

  const patientIds = [
    ...new Set(bookings.map((b) => b.patientId).filter(Boolean)),
  ];
  const patients = patientIds.length
    ? await Patient.find({ id: { $in: patientIds } })
        .select('id profilePicture')
        .lean()
    : [];
  const photoByPatient = new Map(patients.map((p) => [p.id, p.profilePicture]));

  return bookings.map((b) => {
    const verified = isVerified(b);
    return {
      id: b.id,
      bookingId: b.id,
      patientName: b.patientName,
      patientProfilePicture: photoByPatient.get(b.patientId) || null,
      patientMobile: b.patientMobile,
      visitReason: b.visitReason || b.patientNotes || null,
      slotStart: b.slotStart,
      slotEnd: b.slotEnd,
      label: formatSlotLabel(new Date(b.slotStart), new Date(b.slotEnd)),
      status: b.status,
      visitProgress: b.visitProgress || null,
      displayStatus: clinicVisitDisplayStatus(b),
      ...clinicVerificationFields(b, { includeOtp: false }),
      canVerify: b.status === 'confirmed' && !verified,
    };
  });
}

async function getClinicOtpStatus({ bookingId, doctorId }) {
  const visit = await getClinicVisitForDoctor(doctorId, bookingId);
  const record = await latestOtpRecord(bookingId);
  const now = new Date();
  const lockedUntil = record?.lockedUntil ? new Date(record.lockedUntil) : null;
  return {
    bookingId,
    verificationStatus: visit.verificationStatus,
    displayStatus: visit.displayStatus,
    canVerify: visit.canVerify,
    isAppointmentVerified: visit.isAppointmentVerified,
    otp: {
      hasOtp: Boolean(record),
      isUsed: Boolean(record?.isUsed) || visit.verificationStatus === 'VERIFIED',
      isExpired: record ? new Date(record.expiresAt) <= now : false,
      isLocked: Boolean(lockedUntil && lockedUntil > now),
      lockedUntil: lockedUntil || null,
      attemptCount: record?.attemptCount || 0,
      maxAttempts: MAX_OTP_ATTEMPTS,
      expiresAt: record?.expiresAt || null,
    },
  };
}

async function getClinicVisitForDoctor(doctorId, bookingId) {
  const booking = await ConsultationBooking.findOne({
    id: bookingId,
    doctorId,
    consultationType: 'visit_site',
  }).lean();
  if (!booking) {
    const err = new Error('Invalid booking ID');
    err.statusCode = 404;
    throw err;
  }
  const patient = booking.patientId
    ? await Patient.findOne({ id: booking.patientId })
        .select('id profilePicture')
        .lean()
    : null;
  const verified = isVerified(booking);
  return {
    id: booking.id,
    bookingId: booking.id,
    patientName: booking.patientName,
    patientProfilePicture: patient?.profilePicture || null,
    patientMobile: booking.patientMobile,
    visitReason: booking.visitReason || booking.patientNotes || null,
    slotStart: booking.slotStart,
    slotEnd: booking.slotEnd,
    label: formatSlotLabel(new Date(booking.slotStart), new Date(booking.slotEnd)),
    status: booking.status,
    visitProgress: booking.visitProgress || null,
    displayStatus: clinicVisitDisplayStatus(booking),
    ...clinicVerificationFields(booking, { includeOtp: false }),
    canVerify: booking.status === 'confirmed' && !verified,
  };
}

async function startClinicConsultation({ bookingId, doctorId }) {
  const booking = await ConsultationBooking.findOne({ id: bookingId });
  if (!booking) {
    const err = new Error('Invalid booking ID');
    err.statusCode = 404;
    throw err;
  }
  if (booking.doctorId !== doctorId) {
    const err = new Error('This appointment does not belong to your clinic');
    err.statusCode = 403;
    throw err;
  }
  if (booking.consultationType !== 'visit_site') {
    const err = new Error('This action applies to clinic visits only');
    err.statusCode = 400;
    throw err;
  }
  if (!isVerified(booking)) {
    const err = new Error('Verify the patient arrival before starting consultation');
    err.statusCode = 409;
    throw err;
  }
  if (booking.visitProgress === 'completed') {
    const err = new Error('This consultation is already completed');
    err.statusCode = 409;
    throw err;
  }
  const now = new Date();
  booking.visitProgress = 'visit_started';
  booking.visitStartedAt = booking.visitStartedAt || now;
  appendStatusHistory(booking, 'visit_started', 'doctor');
  await booking.save();
  try {
    const { emitBookingStatusUpdate } = require('../services/trackingSocket');
    emitBookingStatusUpdate(booking);
  } catch (_) {
    /* ignore */
  }
  return getClinicVisitForDoctor(doctorId, booking.id);
}

async function completeClinicConsultation({ bookingId, doctorId }) {
  const booking = await ConsultationBooking.findOne({ id: bookingId });
  if (!booking) {
    const err = new Error('Invalid booking ID');
    err.statusCode = 404;
    throw err;
  }
  if (booking.doctorId !== doctorId) {
    const err = new Error('This appointment does not belong to your clinic');
    err.statusCode = 403;
    throw err;
  }
  if (booking.consultationType !== 'visit_site') {
    const err = new Error('This action applies to clinic visits only');
    err.statusCode = 400;
    throw err;
  }
  if (!isVerified(booking)) {
    const err = new Error('Patient has not been verified yet');
    err.statusCode = 409;
    throw err;
  }
  const now = new Date();
  booking.visitProgress = 'completed';
  booking.visitCompletedAt = now;
  appendStatusHistory(booking, 'completed', 'doctor');
  await booking.save();
  try {
    const { emitBookingStatusUpdate } = require('../services/trackingSocket');
    emitBookingStatusUpdate(booking);
  } catch (_) {
    /* ignore */
  }
  return getClinicVisitForDoctor(doctorId, booking.id);
}

module.exports = {
  MAX_OTP_ATTEMPTS,
  clinicVerificationFields,
  generateUniqueAppointmentCode,
  issueClinicVisitOtp,
  ensureClinicVisitOtp,
  verifyClinicVisitOtp,
  getPatientClinicOtp,
  regeneratePatientClinicOtp,
  regenerateReceptionistClinicOtp,
  listClinicVisitsForDoctor,
  getClinicVisitForDoctor,
  getClinicOtpStatus,
  startClinicConsultation,
  completeClinicConsultation,
  isVerified,
};
