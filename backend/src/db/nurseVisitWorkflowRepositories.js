const crypto = require('crypto');
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const ConsultationBooking = require('./models/ConsultationBooking');
const NurseVisitNote = require('./models/NurseVisitNote');
const Nurse = require('./models/Nurse');
const { appendStatusHistory } = require('./bookingLifecycleHelpers');
const { createAndPushNotification, notifyPatient } = require('./notificationRepositories');
const { generateNurseVisitNotePdf } = require('../services/nurseVisitNotePdfService');
const { sendTransactionalEmail } = require('../services/emailProviders/smtpProvider');

const OTP_EXPIRY_MS = 5 * 60 * 1000;
const MAX_OTP_ATTEMPTS = 5;

function computeBmi(heightCm, weightKg) {
  if (!heightCm || !weightKg || heightCm <= 0) return null;
  const heightM = heightCm / 100;
  const bmi = weightKg / (heightM * heightM);
  return Math.round(bmi * 10) / 10;
}

function generateOtp() {
  return String(crypto.randomInt(100000, 999999));
}

async function assertNurseBooking(bookingId, nurseId) {
  const booking = await ConsultationBooking.findOne({ id: bookingId });
  if (!booking) {
    const err = new Error('Booking not found');
    err.statusCode = 404;
    throw err;
  }
  if (booking.nurseId !== nurseId) {
    const err = new Error('You are not assigned to this visit');
    err.statusCode = 403;
    throw err;
  }
  if (booking.status !== 'confirmed') {
    const err = new Error('Visit must be confirmed');
    err.statusCode = 409;
    throw err;
  }
  if (booking.consultationType !== 'book_home') {
    const err = new Error('Only home visits support this workflow');
    err.statusCode = 400;
    throw err;
  }
  return booking;
}

async function startNurseVisit({ bookingId, nurseId }) {
  const booking = await assertNurseBooking(bookingId, nurseId);
  if (!['arrived', 'visit_started'].includes(booking.visitProgress || '')) {
    const err = new Error('Mark arrival before starting the visit');
    err.statusCode = 400;
    throw err;
  }

  const now = new Date();
  booking.visitProgress = 'visit_started';
  booking.visitStartedAt = booking.visitStartedAt || now;
  booking.trackingStoppedAt = booking.trackingStoppedAt || now;
  appendStatusHistory(booking, 'visit_started', 'nurse');
  await booking.save();

  try {
    const { stopTrackingInternal } = require('./trackingRepositories');
    await stopTrackingInternal(booking, { actor: 'nurse' });
    const { emitTrackingStopped } = require('../services/trackingSocket');
    emitTrackingStopped(booking.id, 'visit_started');
  } catch (err) {
    console.error('[NurseVisit] stop tracking failed:', err.message);
  }

  let note = await NurseVisitNote.findOne({ bookingId });
  if (!note) {
    note = await NurseVisitNote.create({
      id: uuidv4(),
      bookingId,
      nurseId,
      patientId: booking.patientId,
      patientName: booking.patientName,
      visitStartedAt: now,
      status: 'draft',
    });
  } else if (!note.visitStartedAt) {
    note.visitStartedAt = now;
    note.status = note.status === 'locked' ? note.status : 'draft';
    await note.save();
  }

  try {
    await notifyPatient(booking, {
      title: 'Nurse visit started',
      body: 'Your nurse has started today\'s home visit.',
      type: 'visit_started',
    });
  } catch (err) {
    console.error('[NurseVisit] start notify failed:', err.message);
  }

  return { booking: booking.toObject(), note: note.toObject() };
}

function normalizeReportPayload(body = {}) {
  const vitalsData = body.vitalsData || body.vitals || {};
  if (vitalsData.heightCm && vitalsData.weightKg && !vitalsData.bmi) {
    vitalsData.bmi = computeBmi(vitalsData.heightCm, vitalsData.weightKg);
  }

  return {
    vitalsData,
    generalAssessment: body.generalAssessment || {},
    symptoms: Array.isArray(body.symptoms) ? body.symptoms : [],
    symptomsOther: body.symptomsOther?.trim() || undefined,
    proceduresPerformed: Array.isArray(body.proceduresPerformed)
      ? body.proceduresPerformed
      : [],
    proceduresOther: body.proceduresOther?.trim() || undefined,
    medicinesAdministered: Array.isArray(body.medicinesAdministered)
      ? body.medicinesAdministered
      : [],
    nurseNotes: body.nurseNotes?.trim() || body.careSummary?.trim() || undefined,
    followUpRecommendation: body.followUpRecommendation || undefined,
    attachments: Array.isArray(body.attachments) ? body.attachments : undefined,
    careSummary: body.careSummary?.trim() || body.nurseNotes?.trim() || undefined,
  };
}

async function saveNurseVisitReportDraft({ bookingId, nurseId, payload }) {
  const booking = await assertNurseBooking(bookingId, nurseId);
  const data = normalizeReportPayload(payload);

  let note = await NurseVisitNote.findOne({ bookingId });
  if (note?.status === 'locked') {
    const err = new Error('Report is locked after completion');
    err.statusCode = 409;
    throw err;
  }

  if (!note) {
    note = await NurseVisitNote.create({
      id: uuidv4(),
      bookingId,
      nurseId,
      patientId: booking.patientId,
      patientName: booking.patientName,
      visitStartedAt: booking.visitStartedAt,
      status: 'draft',
      ...data,
    });
  } else {
    Object.assign(note, data);
    if (note.status !== 'submitted' && note.status !== 'finalized') {
      note.status = 'draft';
    }
    await note.save();
  }

  return note.toObject();
}

async function submitNurseVisitReport({ bookingId, nurseId, payload }) {
  const booking = await assertNurseBooking(bookingId, nurseId);
  const data = normalizeReportPayload(payload);

  if (!data.nurseNotes && !data.careSummary) {
    const err = new Error('Nurse notes are required');
    err.statusCode = 400;
    throw err;
  }

  let note = await NurseVisitNote.findOne({ bookingId });
  if (note?.status === 'locked') {
    const err = new Error('Report is locked after completion');
    err.statusCode = 409;
    throw err;
  }

  const nurse = await Nurse.findOne({ id: nurseId }).lean();
  const now = new Date();
  const visitEndedAt = now;
  const startedAt = note?.visitStartedAt || booking.visitStartedAt || now;
  const durationMinutes = Math.max(
    1,
    Math.round((visitEndedAt - new Date(startedAt)) / 60000),
  );

  if (!note) {
    note = await NurseVisitNote.create({
      id: uuidv4(),
      bookingId,
      nurseId,
      patientId: booking.patientId,
      patientName: booking.patientName,
      visitStartedAt: startedAt,
      visitEndedAt,
      visitDurationMinutes: durationMinutes,
      verificationCode: uuidv4().slice(0, 8).toUpperCase(),
      status: 'submitted',
      submittedAt: now,
      ...data,
    });
  } else {
    Object.assign(note, data);
    note.visitEndedAt = visitEndedAt;
    note.visitDurationMinutes = durationMinutes;
    note.verificationCode = note.verificationCode || uuidv4().slice(0, 8).toUpperCase();
    note.status = 'submitted';
    note.submittedAt = now;
    await note.save();
  }

  const pdf = await generateNurseVisitNotePdf({
    note: note.toObject(),
    nurseName: nurse?.fullName || 'Nurse',
    nurseQualification: nurse?.qualification,
    bookingId: booking.id,
    slotStart: booking.slotStart,
    patientMobile: booking.patientMobile,
    patientAddress: [
      booking.patientAddress,
      booking.patientCity,
      booking.patientState,
      booking.patientPincode,
    ]
      .filter(Boolean)
      .join(', '),
  });

  note.pdfUrl = pdf.publicPath;
  note.pdfGeneratedAt = now;
  note.status = 'finalized';
  await note.save();

  appendStatusHistory(booking, 'report_submitted', 'nurse');
  await booking.save();

  try {
    await notifyPatient(booking, {
      title: 'Nursing report ready',
      body: 'Your nurse has submitted the visit report. PDF is available in Medical Records.',
      type: 'nursing_report_ready',
      data: { bookingId, pdfUrl: note.pdfUrl },
    });
  } catch (err) {
    console.error('[NurseVisit] report notify failed:', err.message);
  }

  return note.toObject();
}

async function requestVisitCompletionOtp({ bookingId, nurseId }) {
  const booking = await assertNurseBooking(bookingId, nurseId);
  const note = await NurseVisitNote.findOne({ bookingId });
  if (!note || !['submitted', 'finalized'].includes(note.status)) {
    const err = new Error('Submit the nursing report before completing the visit');
    err.statusCode = 400;
    throw err;
  }
  if (note.status === 'locked') {
    const err = new Error('Visit already completed');
    err.statusCode = 409;
    throw err;
  }

  const otp = generateOtp();
  const hash = await bcrypt.hash(otp, 8);
  const expiresAt = new Date(Date.now() + OTP_EXPIRY_MS);

  booking.completionOtpHash = hash;
  booking.completionOtpExpiresAt = expiresAt;
  booking.completionOtpAttempts = 0;
  appendStatusHistory(booking, 'otp_generated', 'nurse');
  await booking.save();

  const message =
    `Your nurse has completed today's visit. Share this OTP with the nurse to verify successful completion. OTP: ${otp}`;

  try {
    await notifyPatient(booking, {
      title: 'Visit completion OTP',
      body: message,
      type: 'visit_completion_otp',
      data: { bookingId, otp, otpExpiresAt: expiresAt.toISOString() },
    });
  } catch (err) {
    console.error('[NurseVisit] OTP push failed:', err.message);
  }

  if (booking.patientEmail) {
    try {
      await sendTransactionalEmail({
        to: booking.patientEmail,
        subject: 'Nurse visit completion OTP',
        text: message,
        html: `<p>${message}</p><p>This OTP expires in 5 minutes.</p>`,
      });
    } catch (err) {
      console.error('[NurseVisit] OTP email failed:', err.message);
    }
  }

  return {
    bookingId,
    otpExpiresAt: expiresAt,
    message: 'OTP sent to patient',
  };
}

async function verifyVisitCompletionOtp({ bookingId, nurseId, otp }) {
  const booking = await assertNurseBooking(bookingId, nurseId);
  const note = await NurseVisitNote.findOne({ bookingId });

  if (!note || !['submitted', 'finalized', 'locked'].includes(note.status)) {
    const err = new Error('Nursing report not found');
    err.statusCode = 404;
    throw err;
  }
  if (note.status === 'locked' && booking.visitProgress === 'completed') {
    return { booking: booking.toObject(), note: note.toObject(), alreadyCompleted: true };
  }
  if (!booking.completionOtpHash || !booking.completionOtpExpiresAt) {
    const err = new Error('Generate OTP before verification');
    err.statusCode = 400;
    throw err;
  }
  if (new Date() > booking.completionOtpExpiresAt) {
    const err = new Error('OTP has expired. Request a new OTP.');
    err.statusCode = 400;
    throw err;
  }
  if ((booking.completionOtpAttempts || 0) >= MAX_OTP_ATTEMPTS) {
    const err = new Error('Too many failed attempts. Request a new OTP.');
    err.statusCode = 429;
    throw err;
  }

  const match = await bcrypt.compare(String(otp || '').trim(), booking.completionOtpHash);
  if (!match) {
    booking.completionOtpAttempts = (booking.completionOtpAttempts || 0) + 1;
    await booking.save();
    const err = new Error('Invalid OTP. Please try again.');
    err.statusCode = 400;
    throw err;
  }

  const now = new Date();
  booking.completionOtpVerifiedAt = now;
  booking.completionOtpHash = undefined;
  booking.completionOtpExpiresAt = undefined;
  booking.visitProgress = 'completed';
  booking.visitCompletedAt = now;
  booking.trackingStoppedAt = booking.trackingStoppedAt || now;
  appendStatusHistory(booking, 'otp_verified', 'nurse');
  appendStatusHistory(booking, 'completed', 'nurse');
  await booking.save();

  try {
    const { stopTrackingInternal } = require('./trackingRepositories');
    await stopTrackingInternal(booking, { actor: 'nurse' });
    const { emitTrackingStopped } = require('../services/trackingSocket');
    emitTrackingStopped(booking.id, 'completed');
  } catch (err) {
    console.error('[NurseVisit] stop tracking on complete failed:', err.message);
  }

  note.status = 'locked';
  note.lockedAt = now;
  await note.save();

  try {
    await notifyPatient(booking, {
      title: 'Visit completed',
      body: 'Your nurse home visit has been successfully completed.',
      type: 'visit_completed',
    });
  } catch (err) {
    console.error('[NurseVisit] complete notify failed:', err.message);
  }

  try {
    await createAndPushNotification({
      userId: nurseId,
      userType: 'nurse',
      title: 'Visit completed',
      body: 'OTP verified. The home visit is marked complete.',
      type: 'visit_completed',
      data: { bookingId },
    });
  } catch (err) {
    console.error('[NurseVisit] nurse complete notify failed:', err.message);
  }

  return { booking: booking.toObject(), note: note.toObject() };
}

async function listPatientNursingReports(patientId) {
  const notes = await NurseVisitNote.find({
    patientId,
    status: { $in: ['finalized', 'locked'] },
    pdfUrl: { $exists: true, $ne: null },
  })
    .sort({ createdAt: -1 })
    .lean();

  const bookingIds = notes.map((n) => n.bookingId);
  const bookings = await ConsultationBooking.find({ id: { $in: bookingIds } }).lean();
  const bookingMap = new Map(bookings.map((b) => [b.id, b]));

  return notes.map((note) => {
    const booking = bookingMap.get(note.bookingId);
    return {
      ...note,
      slotStart: booking?.slotStart,
      nurseId: note.nurseId,
    };
  });
}

async function getNurseVisitReportForBooking(bookingId, auth) {
  const booking = await ConsultationBooking.findOne({ id: bookingId }).lean();
  if (!booking) {
    const err = new Error('Booking not found');
    err.statusCode = 404;
    throw err;
  }

  const allowed =
    (auth?.type === 'patient' && auth.patientId === booking.patientId) ||
    (auth?.type === 'nurse' && auth.nurseId === booking.nurseId) ||
    (auth?.type === 'doctor' && booking.patientId);
  if (!allowed) {
    const err = new Error('Not allowed to view this report');
    err.statusCode = 403;
    throw err;
  }

  const note = await NurseVisitNote.findOne({ bookingId }).lean();
  if (!note) {
    const err = new Error('Nursing report not found');
    err.statusCode = 404;
    throw err;
  }
  return { note, booking };
}

module.exports = {
  startNurseVisit,
  saveNurseVisitReportDraft,
  submitNurseVisitReport,
  requestVisitCompletionOtp,
  verifyVisitCompletionOtp,
  listPatientNursingReports,
  getNurseVisitReportForBooking,
  computeBmi,
};
