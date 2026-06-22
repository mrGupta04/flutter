const { findDoctorById } = require('../db/repositories');
const { findPatientById } = require('../db/patientRepositories');
const ConsultationBooking = require('../db/models/ConsultationBooking');
const {
  bookingSymptoms,
  findPrescriptionByBookingId,
  assertBookingForDoctor,
  upsertPrescriptionDraft,
  finalizePrescription,
} = require('../db/prescriptionRepositories');
const { formatSlotLabel } = require('../utils/slotDateTime');
const { generatePrescriptionPdf } = require('./prescriptionPdfService');
const { sendPrescriptionEmail } = require('./prescriptionNotificationService');

const DEFAULT_AUTO_PRESCRIPTION_ADVICE =
  'Thank you for your consultation. Please follow any instructions discussed during your visit. Contact your doctor or seek urgent care if symptoms worsen.';

function normalizeMobile(mobile) {
  return String(mobile || '').replace(/\D/g, '').slice(-10);
}

async function assertBookingPrescriptionAccess(auth, booking) {
  if (auth?.type === 'doctor' && auth.doctorId === booking.doctorId) {
    return { role: 'doctor' };
  }

  if (auth?.type === 'patient') {
    if (booking.patientId && booking.patientId === auth.patientId) {
      return { role: 'patient' };
    }
    const patient = await findPatientById(auth.patientId);
    const authMobile = normalizeMobile(patient?.mobileNumber);
    const bookingMobile = normalizeMobile(booking.patientMobile);
    if (
      authMobile.length === 10 &&
      bookingMobile.length === 10 &&
      authMobile === bookingMobile
    ) {
      return { role: 'patient' };
    }
  }

  const err = new Error('You are not allowed to access this prescription');
  err.statusCode = 403;
  throw err;
}

async function findBookingForPrescription(bookingId) {
  const booking = await ConsultationBooking.findOne({ id: bookingId }).lean();
  if (!booking) {
    const err = new Error('Booking not found');
    err.statusCode = 404;
    throw err;
  }
  if (booking.consultationType !== 'online_consult') {
    const err = new Error('Prescriptions are available for online consultations');
    err.statusCode = 400;
    throw err;
  }
  if (booking.status !== 'confirmed') {
    const err = new Error('Prescription is only available for confirmed consultations');
    err.statusCode = 400;
    throw err;
  }
  return booking;
}

function formatPrescriptionResponse(prescription, doctor, booking) {
  if (!prescription) return null;
  const doctorName = doctor
    ? `${doctor.firstName || ''} ${doctor.lastName || ''}`.trim()
    : 'Doctor';

  return {
    id: prescription.id,
    bookingId: prescription.bookingId,
    patientName: prescription.patientName,
    patientEmail: prescription.patientEmail,
    symptoms: prescription.symptoms,
    diagnosis: prescription.diagnosis,
    medicines: prescription.medicines || [],
    tests: prescription.tests || [],
    advice: prescription.advice,
    status: prescription.status,
    pdfUrl: prescription.pdfUrl,
    pdfFileName: prescription.pdfFileName,
    emailedAt: prescription.emailedAt,
    createdAt: prescription.createdAt,
    updatedAt: prescription.updatedAt,
    doctorName,
    slotLabel: booking ? formatSlotLabel(booking.slotStart, booking.slotEnd) : null,
  };
}

async function getPrescriptionContext(bookingId, auth) {
  if (auth?.type !== 'doctor' || !auth.doctorId) {
    const err = new Error('Doctor authentication required');
    err.statusCode = 401;
    throw err;
  }

  const booking = await assertBookingForDoctor(bookingId, auth.doctorId);
  const doctor = await findDoctorById(booking.doctorId);
  const existing = await findPrescriptionByBookingId(bookingId);

  return {
    bookingId: booking.id,
    patientName: booking.patientName,
    patientEmail: booking.patientEmail,
    symptoms: bookingSymptoms(booking),
    slotLabel: formatSlotLabel(booking.slotStart, booking.slotEnd),
    doctorName: doctor
      ? `${doctor.firstName || ''} ${doctor.lastName || ''}`.trim()
      : 'Doctor',
    prescription: formatPrescriptionResponse(existing, doctor, booking),
  };
}

function prescriptionHasContent(prescription) {
  return Boolean(
    prescription?.diagnosis ||
      (prescription?.medicines && prescription.medicines.length > 0) ||
      (prescription?.tests && prescription.tests.length > 0) ||
      prescription?.advice,
  );
}

async function finalizeAndDeliverPrescription({
  booking,
  doctor,
  draft,
  publicBaseUrl,
}) {
  const doctorName = doctor
    ? `${doctor.firstName || ''} ${doctor.lastName || ''}`.trim()
    : 'Doctor';

  const pdf = await generatePrescriptionPdf({
    prescription: draft,
    doctorName,
    doctorQualification: doctor?.qualification,
    clinicName: doctor?.clinicName,
    slotStart: booking.slotStart,
  });

  const pdfUrl = `${String(publicBaseUrl || '').replace(/\/$/, '')}${pdf.publicPath}`;
  const finalized = await finalizePrescription({
    bookingId: booking.id,
    pdfUrl,
    pdfFileName: pdf.fileName,
  });

  let emailResult = { sent: false, reason: 'Patient email not provided' };
  if (booking.patientEmail) {
    try {
      emailResult = await sendPrescriptionEmail({
        to: booking.patientEmail,
        patientName: booking.patientName,
        doctorName,
        slotLabel: formatSlotLabel(booking.slotStart, booking.slotEnd),
        pdfPath: pdf.filePath,
        pdfFileName: pdf.fileName,
        pdfUrl,
      });
    } catch (emailErr) {
      console.error('[prescription] Email failed:', emailErr.message);
      emailResult = { sent: false, reason: emailErr.message };
    }
  }

  return {
    prescription: formatPrescriptionResponse(finalized, doctor, booking),
    email: emailResult,
  };
}

async function saveAndFinalizePrescription(bookingId, auth, body, publicBaseUrl) {
  if (auth?.type !== 'doctor' || !auth.doctorId) {
    const err = new Error('Doctor authentication required');
    err.statusCode = 401;
    throw err;
  }

  const booking = await assertBookingForDoctor(bookingId, auth.doctorId);
  const doctor = await findDoctorById(booking.doctorId);

  const draft = await upsertPrescriptionDraft({
    bookingId,
    doctorId: auth.doctorId,
    diagnosis: body?.diagnosis,
    medicines: body?.medicines,
    tests: body?.tests,
    advice: body?.advice,
  });

  if (!prescriptionHasContent(draft)) {
    const err = new Error(
      'Add at least a diagnosis, medicine, test, or advice before saving the prescription',
    );
    err.statusCode = 400;
    throw err;
  }

  return finalizeAndDeliverPrescription({
    booking,
    doctor,
    draft,
    publicBaseUrl,
  });
}

async function autoFinalizePrescriptionForBooking(bookingId, publicBaseUrl) {
  const booking = await ConsultationBooking.findOne({ id: bookingId }).lean();
  if (!booking) return null;
  if (booking.consultationType !== 'online_consult') return null;
  if (booking.status !== 'confirmed') return null;
  if (new Date(booking.slotEnd) > new Date()) return null;

  const existing = await findPrescriptionByBookingId(bookingId);
  if (existing?.status === 'finalized') return null;

  const doctor = await findDoctorById(booking.doctorId);
  let draft = existing;

  if (!prescriptionHasContent(draft)) {
    draft = await upsertPrescriptionDraft({
      bookingId,
      doctorId: booking.doctorId,
      diagnosis: draft?.diagnosis,
      medicines: draft?.medicines || [],
      tests: draft?.tests || [],
      advice: draft?.advice || DEFAULT_AUTO_PRESCRIPTION_ADVICE,
    });
  }

  return finalizeAndDeliverPrescription({
    booking,
    doctor,
    draft,
    publicBaseUrl,
  });
}

async function getPrescription(bookingId, auth) {
  const booking = await findBookingForPrescription(bookingId);
  await assertBookingPrescriptionAccess(auth, booking);

  const prescription = await findPrescriptionByBookingId(bookingId);
  if (!prescription || prescription.status !== 'finalized') {
    const err = new Error('Prescription not available yet');
    err.statusCode = 404;
    throw err;
  }

  const doctor = await findDoctorById(booking.doctorId);
  return formatPrescriptionResponse(prescription, doctor, booking);
}

module.exports = {
  getPrescriptionContext,
  saveAndFinalizePrescription,
  autoFinalizePrescriptionForBooking,
  getPrescription,
};
