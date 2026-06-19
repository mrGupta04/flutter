const { v4: uuidv4 } = require('uuid');
const ConsultationFeedback = require('./models/ConsultationFeedback');
const ConsultationBooking = require('./models/ConsultationBooking');
const Doctor = require('./models/Doctor');
const Patient = require('./models/Patient');

async function findFeedbackByBookingId(bookingId) {
  return ConsultationFeedback.findOne({ bookingId }).lean();
}

async function findFeedbackByBookingIds(bookingIds) {
  if (!bookingIds.length) return new Map();
  const rows = await ConsultationFeedback.find({
    bookingId: { $in: bookingIds },
  }).lean();
  return new Map(rows.map((row) => [row.bookingId, row]));
}

async function assertBookingForPatient(bookingId, patientId) {
  const booking = await ConsultationBooking.findOne({ id: bookingId }).lean();
  if (!booking) {
    const err = new Error('Booking not found');
    err.statusCode = 404;
    throw err;
  }
  if (booking.patientId !== patientId) {
    const err = new Error('You are not allowed to rate this consultation');
    err.statusCode = 403;
    throw err;
  }
  if (booking.status !== 'confirmed') {
    const err = new Error('Only confirmed consultations can be rated');
    err.statusCode = 400;
    throw err;
  }
  return booking;
}

function isSessionEligibleForFeedback(booking, now = new Date()) {
  const slotEnd = new Date(booking.slotEnd);
  // Online consult: only after the booked slot ends (not when the call is cut early).
  if (booking.consultationType === 'online_consult') {
    return slotEnd <= now;
  }
  if (booking.consultationType === 'visit_site') {
    return Boolean(booking.appointmentVerifiedAt) || slotEnd <= now;
  }
  return slotEnd <= now;
}

function formatPatientDisplayName(patient) {
  if (!patient) return 'Verified patient';
  const first = String(patient.firstName || '').trim();
  const last = String(patient.lastName || '').trim();
  if (first && last) return `${first} ${last.charAt(0).toUpperCase()}.`;
  if (first) return `${first.charAt(0).toUpperCase()}***`;
  return 'Verified patient';
}

async function listPublicDoctorFeedback(doctorId, { limit = 20 } = {}) {
  if (!doctorId) return [];

  const safeLimit = Math.min(50, Math.max(1, Number(limit) || 20));
  const rows = await ConsultationFeedback.find({
    doctorId,
    status: 'submitted',
    rating: { $gte: 1, $lte: 5 },
  })
    .sort({ createdAt: -1 })
    .limit(safeLimit)
    .lean();

  if (!rows.length) return [];

  const patientIds = [...new Set(rows.map((row) => row.patientId).filter(Boolean))];
  const patients = await Patient.find({ id: { $in: patientIds } }).lean();
  const patientMap = new Map(patients.map((p) => [p.id, p]));

  return rows.map((row) => ({
    id: row.id,
    rating: row.rating,
    comment: String(row.comment || '').trim() || `Rated ${row.rating} stars`,
    consultationType: row.consultationType,
    patientDisplayName: formatPatientDisplayName(patientMap.get(row.patientId)),
    createdAt: row.createdAt,
  }));
}

async function updateDoctorRatingAggregate(doctorId) {
  const stats = await ConsultationFeedback.aggregate([
    {
      $match: {
        doctorId,
        status: 'submitted',
        rating: { $gte: 1, $lte: 5 },
      },
    },
    {
      $group: {
        _id: '$doctorId',
        averageRating: { $avg: '$rating' },
        ratingCount: { $sum: 1 },
      },
    },
  ]);

  const row = stats[0];
  await Doctor.updateOne(
    { id: doctorId },
    {
      $set: {
        averageRating: row ? Math.round(row.averageRating * 10) / 10 : null,
        ratingCount: row ? row.ratingCount : 0,
      },
    },
  );
}

async function submitConsultationFeedback({
  bookingId,
  patientId,
  rating,
  comment,
}) {
  const booking = await assertBookingForPatient(bookingId, patientId);
  if (!isSessionEligibleForFeedback(booking)) {
    const err = new Error('Consultation is not finished yet');
    err.statusCode = 400;
    throw err;
  }

  const existing = await findFeedbackByBookingId(bookingId);
  if (existing) {
    const err = new Error('Feedback already submitted for this consultation');
    err.statusCode = 409;
    throw err;
  }

  const feedback = await ConsultationFeedback.create({
    id: uuidv4(),
    bookingId,
    patientId,
    doctorId: booking.doctorId,
    consultationType: booking.consultationType,
    rating,
    comment: comment?.trim() || undefined,
    status: 'submitted',
  });

  await updateDoctorRatingAggregate(booking.doctorId);
  return feedback.toObject();
}

async function dismissConsultationFeedback({ bookingId, patientId }) {
  const booking = await assertBookingForPatient(bookingId, patientId);
  if (!isSessionEligibleForFeedback(booking)) {
    const err = new Error('Consultation is not finished yet');
    err.statusCode = 400;
    throw err;
  }

  const existing = await findFeedbackByBookingId(bookingId);
  if (existing) {
    return existing;
  }

  const feedback = await ConsultationFeedback.create({
    id: uuidv4(),
    bookingId,
    patientId,
    doctorId: booking.doctorId,
    consultationType: booking.consultationType,
    status: 'dismissed',
  });

  return feedback.toObject();
}

function feedbackFieldsForBooking(booking, feedbackMap, now = new Date()) {
  const feedback = feedbackMap.get(booking.id);
  const hasFeedback = Boolean(feedback);
  const sessionEnded = isSessionEligibleForFeedback(booking, now);
  const isUpcoming = new Date(booking.slotStart) >= now;

  return {
    hasFeedback,
    canRequestFeedback: !hasFeedback && !isUpcoming && sessionEnded,
    feedbackStatus: feedback?.status ?? null,
    videoCallEndedAt: booking.videoCallEndedAt ?? null,
  };
}

module.exports = {
  findFeedbackByBookingId,
  findFeedbackByBookingIds,
  listPublicDoctorFeedback,
  submitConsultationFeedback,
  dismissConsultationFeedback,
  feedbackFieldsForBooking,
  isSessionEligibleForFeedback,
};
