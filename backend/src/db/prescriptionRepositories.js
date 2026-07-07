const { v4: uuidv4 } = require('uuid');
const Prescription = require('./models/Prescription');
const ConsultationBooking = require('./models/ConsultationBooking');
const Doctor = require('./models/Doctor');

function bookingSymptoms(booking) {
  const notes = String(booking.patientNotes || '').trim();
  const reason = String(booking.visitReason || '').trim();
  if (notes && reason) return `${notes}\n${reason}`;
  return notes || reason || '';
}

async function findPrescriptionByBookingId(bookingId) {
  return Prescription.findOne({ bookingId }).lean();
}

async function findPrescriptionsByBookingIds(bookingIds) {
  if (!bookingIds.length) return new Map();
  const rows = await Prescription.find({
    bookingId: { $in: bookingIds },
    status: 'finalized',
  }).lean();
  return new Map(rows.map((row) => [row.bookingId, row]));
}

function isPrescriptionEligibleConsultation(consultationType) {
  return consultationType === 'online_consult' || consultationType === 'book_home';
}

async function findBookingsDueForAutoPrescription() {
  const now = new Date();
  const bookings = await ConsultationBooking.find({
    consultationType: { $in: ['online_consult', 'book_home'] },
    status: 'confirmed',
    slotEnd: { $lte: now },
  }).lean();

  if (!bookings.length) return [];

  const bookingIds = bookings.map((b) => b.id);
  const finalized = await Prescription.find({
    bookingId: { $in: bookingIds },
    status: 'finalized',
  })
    .select('bookingId')
    .lean();

  const finalizedIds = new Set(finalized.map((row) => row.bookingId));
  return bookings.filter((b) => !finalizedIds.has(b.id));
}

async function assertBookingForDoctor(bookingId, doctorId) {
  const booking = await ConsultationBooking.findOne({ id: bookingId }).lean();
  if (!booking) {
    const err = new Error('Booking not found');
    err.statusCode = 404;
    throw err;
  }
  if (booking.doctorId !== doctorId) {
    const err = new Error('You are not allowed to manage prescriptions for this booking');
    err.statusCode = 403;
    throw err;
  }
  if (booking.status !== 'confirmed') {
    const err = new Error('Prescriptions can only be written for confirmed consultations');
    err.statusCode = 400;
    throw err;
  }
  return booking;
}

function normalizeMedicines(items) {
  if (!Array.isArray(items)) return [];
  return items
    .map((item) => ({
      name: String(item?.name || '').trim(),
      dosage: String(item?.dosage || '').trim() || undefined,
      frequency: String(item?.frequency || '').trim() || undefined,
      duration: String(item?.duration || '').trim() || undefined,
      instructions: String(item?.instructions || '').trim() || undefined,
    }))
    .filter((item) => item.name.length > 0)
    .slice(0, 30);
}

function normalizeTests(items) {
  if (!Array.isArray(items)) return [];
  return items
    .map((item) => ({
      name: String(item?.name || '').trim(),
      notes: String(item?.notes || '').trim() || undefined,
    }))
    .filter((item) => item.name.length > 0)
    .slice(0, 20);
}

async function upsertPrescriptionDraft({
  bookingId,
  doctorId,
  diagnosis,
  medicines,
  tests,
  advice,
}) {
  const booking = await assertBookingForDoctor(bookingId, doctorId);
  const doctor = await Doctor.findOne({ id: doctorId }).lean();
  const doctorName = doctor
    ? `${doctor.firstName || ''} ${doctor.lastName || ''}`.trim()
    : 'Doctor';

  const payload = {
    doctorId,
    patientId: booking.patientId || undefined,
    patientName: booking.patientName,
    patientEmail: booking.patientEmail || undefined,
    symptoms: bookingSymptoms(booking),
    diagnosis: String(diagnosis || '').trim() || undefined,
    medicines: normalizeMedicines(medicines),
    tests: normalizeTests(tests),
    advice: String(advice || '').trim() || undefined,
    status: 'draft',
  };

  const existing = await Prescription.findOne({ bookingId }).lean();
  if (existing) {
    await Prescription.updateOne({ bookingId }, { $set: payload });
    return {
      ...(await Prescription.findOne({ bookingId }).lean()),
      doctorName,
    };
  }

  const created = await Prescription.create({
    id: uuidv4(),
    bookingId,
    ...payload,
  });
  return { ...created.toObject(), doctorName };
}

async function finalizePrescription({ bookingId, pdfUrl, pdfFileName }) {
  await Prescription.updateOne(
    { bookingId },
    {
      $set: {
        pdfUrl,
        pdfFileName,
        status: 'finalized',
        emailedAt: new Date(),
      },
    },
  );
  return Prescription.findOne({ bookingId }).lean();
}

function prescriptionFieldsForBooking(booking, prescription, now = new Date()) {
  const eligible = isPrescriptionEligibleConsultation(booking?.consultationType);
  const finalized = prescription?.status === 'finalized';
  const slotStart = booking?.slotStart ? new Date(booking.slotStart) : null;
  const slotEnd = booking?.slotEnd ? new Date(booking.slotEnd) : null;
  const slotStarted = Boolean(slotStart && slotStart <= now);
  const slotEnded = Boolean(slotEnd && slotEnd <= now);
  const prescriptionPending = Boolean(
    eligible && !finalized && slotStarted,
  );
  const prescriptionProcessing = Boolean(prescriptionPending && slotEnded);

  if (!finalized) {
    return {
      hasPrescription: false,
      prescriptionPdfUrl: null,
      prescriptionFileName: null,
      prescriptionCreatedAt: null,
      prescriptionPending,
      prescriptionProcessing,
    };
  }

  return {
    hasPrescription: true,
    prescriptionPdfUrl: prescription.pdfUrl,
    prescriptionFileName: prescription.pdfFileName,
    prescriptionCreatedAt: prescription.updatedAt || prescription.createdAt,
    prescriptionPending: false,
    prescriptionProcessing: false,
  };
}

module.exports = {
  bookingSymptoms,
  findPrescriptionByBookingId,
  findPrescriptionsByBookingIds,
  findBookingsDueForAutoPrescription,
  assertBookingForDoctor,
  upsertPrescriptionDraft,
  finalizePrescription,
  prescriptionFieldsForBooking,
};
