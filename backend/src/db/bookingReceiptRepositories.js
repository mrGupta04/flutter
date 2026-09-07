const ConsultationBooking = require('./models/ConsultationBooking');
const LabBooking = require('./models/LabBooking');
const ScanBooking = require('./models/ScanBooking');
const AmbulanceBooking = require('./models/AmbulanceBooking');
const BloodOrder = require('./models/BloodOrder');
const { generateBookingReceiptPdf } = require('../services/bookingReceiptPdfService');
const { paymentFieldsForPatient } = require('../utils/patientBookingList');
const { normalizeUploadUrl } = require('../utils/uploadUrl');

function deny() {
  const err = new Error('Not allowed to view this booking');
  err.statusCode = 403;
  throw err;
}

function missing() {
  const err = new Error('Booking not found');
  err.statusCode = 404;
  throw err;
}

function assertOwned(record, patientId) {
  if (!record) missing();
  if (String(record.patientId || '') !== String(patientId)) deny();
  return record;
}

function receiptPayload(record, extras) {
  const pay = paymentFieldsForPatient(record);
  return {
    bookingId: record.id,
    service: extras.service,
    provider: extras.provider,
    date: extras.date || record.slotStart || record.scheduledDate || record.createdAt,
    patient: record.patientName || extras.patient || 'Patient',
    amount: pay.amountPaid ?? extras.amount ?? record.consultationFee ?? record.totalAmount ?? 0,
    paymentStatus: pay.paymentStatus || record.paymentStatus || 'pending',
    paymentMethod: pay.paymentMethod,
    paymentReference: pay.paymentReference,
    currency: pay.currency,
    invoiceUrl: pay.invoiceUrl,
    canViewReceipt: pay.canViewReceipt,
  };
}

async function findOwnedReceiptSource(bookingId, patientId) {
  const id = String(bookingId || '');
  if (!id) missing();

  const consult = await ConsultationBooking.findOne({ id }).lean();
  if (consult) {
    assertOwned(consult, patientId);
    return receiptPayload(consult, {
      service: consult.nurseId ? 'Nurse home visit' : 'Doctor consultation',
      provider: consult.nurseId ? 'Nurse' : 'Doctor',
      date: consult.slotStart,
      amount: consult.amountPaid ?? consult.consultationFee,
    });
  }

  const lab = await LabBooking.findOne({ id }).lean();
  if (lab) {
    assertOwned(lab, patientId);
    return receiptPayload(lab, {
      service: 'Lab test',
      provider: lab.labName || 'Lab',
      date: lab.scheduledDate,
      amount: lab.totalAmount,
    });
  }

  const scan = await ScanBooking.findOne({ id }).lean();
  if (scan) {
    assertOwned(scan, patientId);
    return receiptPayload(scan, {
      service: 'Scan',
      provider: scan.scanCenterName || 'Scan center',
      date: scan.scheduledDate,
      amount: scan.totalAmount,
    });
  }

  const ambulance = await AmbulanceBooking.findOne({ id }).lean();
  if (ambulance) {
    assertOwned(ambulance, patientId);
    return receiptPayload(ambulance, {
      service: 'Ambulance',
      provider: ambulance.ambulanceServiceName || ambulance.vehicleType || 'Ambulance',
      date: ambulance.createdAt,
      amount: ambulance.fare?.total ?? ambulance.fareBreakdown?.total ?? ambulance.amountPaid,
    });
  }

  const blood = await BloodOrder.findOne({ id }).lean();
  if (blood) {
    assertOwned(blood, patientId);
    return receiptPayload(blood, {
      service: 'Blood bank',
      provider: blood.hospitalName || 'Blood bank',
      date: blood.requiredDate || blood.createdAt,
      amount: blood.totalAmount,
    });
  }

  missing();
}

async function getPatientBookingReceipt(bookingId, patientId) {
  const source = await findOwnedReceiptSource(bookingId, patientId);
  if (!source.canViewReceipt) {
    const err = new Error('A receipt is available after payment is completed');
    err.statusCode = 400;
    throw err;
  }

  if (source.invoiceUrl) {
    return {
      ...source,
      pdfUrl: normalizeUploadUrl(source.invoiceUrl) || source.invoiceUrl,
    };
  }

  const pdf = await generateBookingReceiptPdf(source);
  return {
    ...source,
    pdfUrl: pdf.publicPath,
    fileName: pdf.fileName,
  };
}

module.exports = {
  getPatientBookingReceipt,
  findOwnedReceiptSource,
};
