const { v4: uuidv4 } = require('uuid');
const LabBooking = require('./models/LabBooking');
const { findLabById } = require('./labRepositories');
const { normalizeMobile, validateMobile } = require('../utils/mobile');
const {
  createOrder: createRazorpayOrder,
  verifyPaymentSignature,
  isMockMode,
} = require('../services/razorpayService');

const PAYMENT_HOLD_MINUTES = parseInt(process.env.PAYMENT_HOLD_MINUTES || '15', 10);

function toLabBooking(doc) {
  if (!doc) return null;
  const d = doc.toObject ? doc.toObject() : doc;
  return {
    id: d.id,
    labId: d.labId,
    labName: d.labName,
    patientId: d.patientId,
    patientName: d.patientName,
    patientMobile: d.patientMobile,
    patientEmail: d.patientEmail,
    familyMemberId: d.familyMemberId,
    familyMemberName: d.familyMemberName,
    collectionType: d.collectionType,
    collectionAddress: d.collectionAddress,
    collectionCity: d.collectionCity,
    collectionPincode: d.collectionPincode,
    scheduledDate: d.scheduledDate,
    timeSlot: d.timeSlot,
    items: d.items || [],
    subtotal: d.subtotal || 0,
    totalAmount: d.totalAmount || 0,
    paymentStatus: d.paymentStatus,
    status: d.status,
    notes: d.notes,
    rejectionReason: d.rejectionReason,
    reportUrl: d.reportUrl,
    reportFileName: d.reportFileName,
    createdAt: d.createdAt,
    updatedAt: d.updatedAt,
  };
}

async function createLabBooking(input) {
  const labId = String(input.labId || '').trim();
  if (!labId) {
    const err = new Error('labId is required');
    err.statusCode = 400;
    throw err;
  }

  const lab = await findLabById(labId);
  if (!lab || (lab.verificationStatus !== 'verified' && !lab.isApproved)) {
    const err = new Error('Lab not found or not verified');
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

  const collectionType = String(input.collectionType || '').trim();
  if (!['home_collection', 'lab_visit'].includes(collectionType)) {
    const err = new Error('collectionType must be home_collection or lab_visit');
    err.statusCode = 400;
    throw err;
  }

  if (collectionType === 'home_collection') {
    const address = String(input.collectionAddress || '').trim();
    if (address.length < 5) {
      const err = new Error('Collection address is required for home collection');
      err.statusCode = 400;
      throw err;
    }
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

  const items = Array.isArray(input.items)
    ? input.items
        .map((item) => ({
          testId: item.testId ? String(item.testId) : undefined,
          testName: String(item.testName || item.name || '').trim(),
          price: Number(item.price) || 0,
        }))
        .filter((item) => item.testName)
    : [];

  if (items.length === 0) {
    const err = new Error('At least one lab test is required');
    err.statusCode = 400;
    throw err;
  }

  const subtotal = items.reduce((sum, item) => sum + (item.price || 0), 0);
  const totalAmount =
    input.totalAmount != null ? Number(input.totalAmount) : subtotal;

  const booking = await LabBooking.create({
    id: uuidv4(),
    labId,
    labName: lab.labName || lab.name || 'Lab',
    patientId: input.patientId || undefined,
    patientName,
    patientMobile: mobileCheck.mobile,
    patientEmail: input.patientEmail
      ? String(input.patientEmail).trim().toLowerCase()
      : undefined,
    collectionType,
    collectionAddress: input.collectionAddress
      ? String(input.collectionAddress).trim()
      : undefined,
    collectionCity: input.collectionCity
      ? String(input.collectionCity).trim()
      : undefined,
    collectionPincode: input.collectionPincode
      ? String(input.collectionPincode).trim()
      : undefined,
    scheduledDate,
    timeSlot,
    items,
    subtotal,
    totalAmount,
    paymentStatus: input.paymentStatus || 'pending',
    status: 'requested',
    notes: input.notes ? String(input.notes).trim() : undefined,
  });

  return toLabBooking(booking);
}

async function listLabBookingsForLab(labId) {
  const docs = await LabBooking.find({ labId })
    .sort({ createdAt: -1 })
    .limit(100)
    .lean();
  return docs.map(toLabBooking);
}

async function listLabBookingsForPatient({
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

  const docs = await LabBooking.find({ $or: orConditions })
    .sort({ createdAt: -1 })
    .limit(50)
    .lean();
  return docs.map(toLabBooking);
}

async function updateLabBookingStatus({
  bookingId,
  labId,
  status,
  rejectionReason,
  reportUrl,
  reportFileName,
}) {
  const allowed = [
    'confirmed',
    'sample_collected',
    'processing',
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

  const booking = await LabBooking.findOne({ id: bookingId, labId });
  if (!booking) {
    const err = new Error('Booking not found');
    err.statusCode = 404;
    throw err;
  }

  booking.status = status;
  if (rejectionReason) booking.rejectionReason = String(rejectionReason).trim();
  if (reportUrl) {
    booking.reportUrl = reportUrl;
    booking.reportFileName = reportFileName || booking.reportFileName;
  }
  await booking.save();
  return toLabBooking(booking);
}

async function createPaymentOrderForLabBooking(bookingId) {
  const booking = await LabBooking.findOne({ id: bookingId });
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
  if (!['confirmed', 'requested'].includes(booking.status)) {
    const err = new Error('Booking is not payable in its current status');
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
    notes: { labBookingId: booking.id, type: 'lab_booking' },
  });

  booking.razorpayOrderId = razorpayOrder.id;
  booking.paymentExpiresAt = new Date(
    Date.now() + PAYMENT_HOLD_MINUTES * 60 * 1000,
  );
  await booking.save();

  return {
    booking: toLabBooking(booking),
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

async function confirmLabBookingAfterPayment({
  bookingId,
  razorpayOrderId,
  razorpayPaymentId,
  razorpaySignature,
}) {
  const booking = await LabBooking.findOne({ id: bookingId });
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
  return toLabBooking(booking);
}

function toPatientBookingShape(booking) {
  const scheduled = booking.scheduledDate
    ? new Date(booking.scheduledDate)
    : new Date();
  const slotEnd = new Date(scheduled.getTime() + 2 * 60 * 60 * 1000);
  const activeStatuses = [
    'requested',
    'confirmed',
    'sample_collected',
    'processing',
    'report_ready',
  ];
  const testNames = (booking.items || []).map((i) => i.testName).join(', ');

  return {
    id: booking.id,
    doctorId: booking.labId,
    doctorName: booking.labName || 'Lab',
    serviceType: 'lab',
    consultationType: 'lab',
    typeLabel:
      booking.collectionType === 'home_collection'
        ? 'Lab home collection'
        : 'Lab visit',
    patientName: booking.patientName,
    patientMobile: booking.patientMobile,
    patientEmail: booking.patientEmail,
    patientAddress: booking.collectionAddress,
    patientCity: booking.collectionCity,
    patientNotes: booking.notes,
    slotStart: scheduled,
    slotEnd,
    label: `${testNames || 'Lab tests'} · ${booking.timeSlot}`,
    consultationFee: booking.totalAmount,
    status: booking.status === 'requested' ? 'pending' : booking.status,
    paymentStatus: booking.paymentStatus,
    clinicName: booking.labName,
    clinicAddress: booking.collectionAddress,
    createdAt: booking.createdAt,
    isUpcoming: activeStatuses.includes(booking.status) && slotEnd >= new Date(),
    timeline: [
      {
        key: 'requested',
        label: 'Request submitted',
        done: true,
        at: booking.createdAt,
      },
      {
        key: 'confirmed',
        label: 'Lab confirmed',
        done: [
          'confirmed',
          'sample_collected',
          'processing',
          'report_ready',
          'completed',
        ].includes(booking.status),
      },
      {
        key: 'sample',
        label: 'Sample collected',
        done: ['sample_collected', 'processing', 'report_ready', 'completed'].includes(
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
  createLabBooking,
  listLabBookingsForLab,
  listLabBookingsForPatient,
  updateLabBookingStatus,
  createPaymentOrderForLabBooking,
  confirmLabBookingAfterPayment,
  toLabBooking,
  toPatientBookingShape,
};
