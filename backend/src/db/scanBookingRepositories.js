const { v4: uuidv4 } = require('uuid');
const ScanBooking = require('./models/ScanBooking');
const { findScanCenterById } = require('./scanCenterRepositories');
const { normalizeMobile, validateMobile } = require('../utils/mobile');
const {
  createOrder: createRazorpayOrder,
  verifyPaymentSignature,
  isMockMode,
} = require('../services/razorpayService');

const PAYMENT_HOLD_MINUTES = parseInt(process.env.PAYMENT_HOLD_MINUTES || '15', 10);

function toScanBooking(doc) {
  if (!doc) return null;
  const d = doc.toObject ? doc.toObject() : doc;
  return {
    id: d.id,
    scanCenterId: d.scanCenterId,
    scanCenterName: d.scanCenterName,
    patientId: d.patientId,
    patientName: d.patientName,
    patientMobile: d.patientMobile,
    patientEmail: d.patientEmail,
    familyMemberId: d.familyMemberId,
    familyMemberName: d.familyMemberName,
    scanId: d.scanId,
    scanName: d.scanName,
    categoryId: d.categoryId,
    contrastRequired: Boolean(d.contrastRequired),
    preparationNotes: d.preparationNotes,
    prescriptionUrl: d.prescriptionUrl,
    prescriptionFileName: d.prescriptionFileName,
    scheduledDate: d.scheduledDate,
    timeSlot: d.timeSlot,
    totalAmount: d.totalAmount || 0,
    paymentStatus: d.paymentStatus,
    status: d.status,
    notes: d.notes,
    rejectionReason: d.rejectionReason,
    reportUrl: d.reportUrl,
    createdAt: d.createdAt,
    updatedAt: d.updatedAt,
  };
}

async function createScanBooking(input) {
  const scanCenterId = String(input.scanCenterId || '').trim();
  if (!scanCenterId) {
    const err = new Error('scanCenterId is required');
    err.statusCode = 400;
    throw err;
  }

  const center = await findScanCenterById(scanCenterId);
  if (!center || (center.verificationStatus !== 'verified' && !center.isApproved)) {
    const err = new Error('Scan center not found or not verified');
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

  const scanName = String(input.scanName || '').trim();
  if (!scanName) {
    const err = new Error('Scan name is required');
    err.statusCode = 400;
    throw err;
  }

  const timeSlot = String(input.timeSlot || '').trim();
  if (!timeSlot) {
    const err = new Error('Time slot is required');
    err.statusCode = 400;
    throw err;
  }

  const scheduledDate = new Date(input.scheduledDate);
  if (Number.isNaN(scheduledDate.getTime())) {
    const err = new Error('Valid scheduled date is required');
    err.statusCode = 400;
    throw err;
  }

  const paymentStatus =
    input.paymentMethod === 'pay_at_center' ? 'pay_at_center' : 'pending';

  const booking = await ScanBooking.create({
    id: uuidv4(),
    scanCenterId,
    scanCenterName: center.centerName || center.displayName || center.name || 'Scan center',
    patientId: input.patientId || undefined,
    patientName,
    patientMobile: mobileCheck.mobile,
    patientEmail: input.patientEmail
      ? String(input.patientEmail).trim().toLowerCase()
      : undefined,
    familyMemberId: input.familyMemberId,
    familyMemberName: input.familyMemberName,
    scanId: input.scanId,
    scanName,
    categoryId: input.categoryId,
    contrastRequired: Boolean(input.contrastRequired),
    preparationNotes: input.preparationNotes,
    prescriptionUrl: input.prescriptionUrl,
    prescriptionFileName: input.prescriptionFileName,
    scheduledDate,
    timeSlot,
    totalAmount: Number(input.totalAmount) || 0,
    paymentStatus,
    status: 'requested',
    notes: input.notes ? String(input.notes).trim() : undefined,
  });

  return toScanBooking(booking);
}

async function listScanBookingsForCenter(scanCenterId) {
  const docs = await ScanBooking.find({ scanCenterId })
    .sort({ createdAt: -1 })
    .limit(100)
    .lean();
  return docs.map(toScanBooking);
}

async function listScanBookingsForPatient({
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

  const docs = await ScanBooking.find({ $or: orConditions })
    .sort({ createdAt: -1 })
    .limit(50)
    .lean();
  return docs.map(toScanBooking);
}

async function updateScanBookingStatus({
  bookingId,
  scanCenterId,
  status,
  rejectionReason,
  reportUrl,
}) {
  const allowed = [
    'confirmed',
    'in_progress',
    'report_ready',
    'completed',
    'cancelled',
    'rejected',
  ];
  if (!allowed.includes(status)) {
    const err = new Error('Invalid status');
    err.statusCode = 400;
    throw err;
  }

  const booking = await ScanBooking.findOne({ id: bookingId, scanCenterId });
  if (!booking) {
    const err = new Error('Booking not found');
    err.statusCode = 404;
    throw err;
  }

  booking.status = status;
  if (rejectionReason) booking.rejectionReason = String(rejectionReason).trim();
  if (reportUrl) booking.reportUrl = reportUrl;
  await booking.save();
  return toScanBooking(booking);
}

async function createPaymentOrderForScanBooking(bookingId) {
  const booking = await ScanBooking.findOne({ id: bookingId });
  if (!booking) {
    const err = new Error('Booking not found');
    err.statusCode = 404;
    throw err;
  }
  if (booking.paymentStatus === 'paid') {
    const err = new Error('Already paid');
    err.statusCode = 400;
    throw err;
  }
  if (booking.paymentStatus === 'pay_at_center') {
    const err = new Error('This booking is set to pay at center');
    err.statusCode = 400;
    throw err;
  }

  const amountInPaise = Math.round((booking.totalAmount || 0) * 100);
  if (amountInPaise < 100) {
    const err = new Error('Amount must be at least ₹1');
    err.statusCode = 400;
    throw err;
  }

  const razorpayOrder = await createRazorpayOrder({
    amountInPaise,
    receipt: booking.id.slice(0, 40),
    notes: { scanBookingId: booking.id, type: 'scan_booking' },
  });

  booking.razorpayOrderId = razorpayOrder.id;
  booking.paymentExpiresAt = new Date(
    Date.now() + PAYMENT_HOLD_MINUTES * 60 * 1000,
  );
  await booking.save();

  return {
    booking: toScanBooking(booking),
    razorpayOrder,
    amountInPaise,
    keyId: isMockMode() ? null : process.env.RAZORPAY_KEY_ID,
    mock: isMockMode(),
    prefill: {
      name: booking.patientName,
      email: booking.patientEmail || undefined,
      contact: booking.patientMobile,
    },
  };
}

async function confirmScanBookingAfterPayment({
  bookingId,
  razorpayOrderId,
  razorpayPaymentId,
  razorpaySignature,
}) {
  const booking = await ScanBooking.findOne({ id: bookingId });
  if (!booking) {
    const err = new Error('Booking not found');
    err.statusCode = 404;
    throw err;
  }

  if (!isMockMode()) {
    const valid = verifyPaymentSignature({
      orderId: razorpayOrderId,
      paymentId: razorpayPaymentId,
      signature: razorpaySignature,
    });
    if (!valid) {
      const err = new Error('Invalid payment signature');
      err.statusCode = 400;
      throw err;
    }
  }

  booking.paymentStatus = 'paid';
  booking.razorpayPaymentId = razorpayPaymentId;
  booking.razorpayOrderId = razorpayOrderId;
  if (booking.status === 'requested') booking.status = 'confirmed';
  await booking.save();
  return toScanBooking(booking);
}

function toPatientBookingShape(booking) {
  const scheduled = booking.scheduledDate
    ? new Date(booking.scheduledDate)
    : new Date();
  const slotEnd = new Date(scheduled.getTime() + 2 * 60 * 60 * 1000);
  const activeStatuses = [
    'requested',
    'confirmed',
    'in_progress',
    'report_ready',
  ];

  return {
    id: booking.id,
    doctorId: booking.scanCenterId,
    doctorName: booking.scanCenterName || 'Scan center',
    serviceType: 'scan',
    consultationType: 'scan',
    typeLabel: 'Scan',
    patientName: booking.patientName,
    patientMobile: booking.patientMobile,
    patientEmail: booking.patientEmail,
    patientNotes: booking.notes,
    slotStart: scheduled,
    slotEnd,
    label: `${booking.scanName} · ${booking.timeSlot}`,
    consultationFee: booking.totalAmount,
    status: booking.status === 'requested' ? 'pending' : booking.status,
    paymentStatus: booking.paymentStatus,
    clinicName: booking.scanCenterName,
    createdAt: booking.createdAt,
    isUpcoming: activeStatuses.includes(booking.status) && slotEnd >= new Date(),
    timeline: [
      { key: 'requested', label: 'Request submitted', done: true, at: booking.createdAt },
      {
        key: 'confirmed',
        label: 'Center confirmed',
        done: ['confirmed', 'in_progress', 'report_ready', 'completed'].includes(
          booking.status,
        ),
      },
      {
        key: 'report',
        label: 'Report ready',
        done: ['report_ready', 'completed'].includes(booking.status),
      },
    ],
  };
}

module.exports = {
  createScanBooking,
  listScanBookingsForCenter,
  listScanBookingsForPatient,
  updateScanBookingStatus,
  createPaymentOrderForScanBooking,
  confirmScanBookingAfterPayment,
  toScanBooking,
  toPatientBookingShape,
};
