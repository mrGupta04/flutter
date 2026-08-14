const { v4: uuidv4 } = require('uuid');
const PrescriptionRequest = require('./models/PrescriptionRequest');
const PrescriptionQuotation = require('./models/PrescriptionQuotation');
const Lab = require('./models/Lab');
const ScanCenter = require('./models/ScanCenter');
const LabBooking = require('./models/LabBooking');
const ScanBooking = require('./models/ScanBooking');
const Patient = require('./models/Patient');
const { createAndPushNotification } = require('./notificationRepositories');
const {
  createOrder: createRazorpayOrder,
  verifyPaymentSignature,
  isMockMode,
} = require('../services/razorpayService');

const MAX_LABS_PER_REQUEST = 4;
const PAYMENT_HOLD_MINUTES = 30;
const ALLOWED_FILE_TYPES = new Set(['jpg', 'jpeg', 'png', 'pdf']);

function httpError(message, statusCode = 400) {
  const err = new Error(message);
  err.statusCode = statusCode;
  return err;
}

function normalizeFileType(raw) {
  const value = String(raw || '')
    .toLowerCase()
    .replace(/^\./, '')
    .trim();
  if (value === 'image/jpeg' || value === 'image/jpg') return 'jpg';
  if (value === 'image/png') return 'png';
  if (value === 'application/pdf') return 'pdf';
  return value;
}

function assertAllowedFileType(fileType) {
  const normalized = normalizeFileType(fileType);
  if (!ALLOWED_FILE_TYPES.has(normalized)) {
    throw httpError(
      'Invalid prescription format. Allowed: JPG, JPEG, PNG, PDF.',
      400,
    );
  }
  return normalized;
}

function toPrescriptionRequest(doc, quotations = undefined) {
  if (!doc) return null;
  const obj = doc.toObject ? doc.toObject() : doc;
  const result = {
    id: obj.id,
    userId: obj.userId,
    patientName: obj.patientName,
    patientMobile: obj.patientMobile,
    patientEmail: obj.patientEmail,
    prescriptionFileUrl: obj.prescriptionFileUrl,
    prescriptionFileType: obj.prescriptionFileType,
    prescriptionFileName: obj.prescriptionFileName,
    requestedTests: obj.requestedTests || [],
    notes: obj.notes || null,
    status: obj.status,
    selectedLabId: obj.selectedLabId || null,
    selectedQuotationId: obj.selectedQuotationId || null,
    paymentStatus: obj.paymentStatus,
    chatEnabled: Boolean(obj.chatEnabled && obj.paymentStatus === 'PAID'),
    bookingId: obj.bookingId || null,
    expiresAt: obj.expiresAt || null,
    createdAt: obj.createdAt,
    updatedAt: obj.updatedAt,
  };
  if (quotations !== undefined) {
    result.quotations = quotations;
  }
  return result;
}

function toQuotation(doc) {
  if (!doc) return null;
  const obj = doc.toObject ? doc.toObject() : doc;
  return {
    id: obj.id,
    prescriptionRequestId: obj.prescriptionRequestId,
    labId: obj.labId,
    labName: obj.labName,
    providerType: obj.providerType || 'lab',
    quotedAmount: obj.quotedAmount,
    estimatedCompletionTime: obj.estimatedCompletionTime || null,
    availableServices: obj.availableServices || [],
    labNotes: obj.labNotes || null,
    rating: obj.rating,
    distanceKm: obj.distanceKm,
    status: obj.status,
    paymentStatus: obj.paymentStatus,
    submittedAt: obj.submittedAt || null,
    rejectionReason: obj.rejectionReason || null,
    createdAt: obj.createdAt,
    updatedAt: obj.updatedAt,
  };
}

function normalizeRequestedTests(raw) {
  if (!raw) return [];
  let list = raw;
  if (typeof raw === 'string') {
    try {
      list = JSON.parse(raw);
    } catch {
      list = raw
        .split(/[\n,]/)
        .map((s) => s.trim())
        .filter(Boolean)
        .map((name) => ({ name }));
    }
  }
  if (!Array.isArray(list)) return [];
  return list
    .map((item) => {
      if (typeof item === 'string') {
        const name = item.trim();
        return name ? { name } : null;
      }
      const name = String(item?.name || '').trim();
      if (!name) return null;
      const notes = item?.notes ? String(item.notes).trim() : undefined;
      return notes ? { name, notes } : { name };
    })
    .filter(Boolean)
    .slice(0, 50);
}

function normalizeLabIds(raw) {
  if (!raw) return [];
  let list = raw;
  if (typeof raw === 'string') {
    try {
      list = JSON.parse(raw);
    } catch {
      list = raw.split(',').map((s) => s.trim());
    }
  }
  if (!Array.isArray(list)) return [];
  const unique = [];
  const seen = new Set();
  for (const item of list) {
    const id = String(item || '').trim();
    if (!id || seen.has(id)) continue;
    seen.add(id);
    unique.push(id);
  }
  return unique;
}

async function resolveProvider(labId) {
  const lab = await Lab.findOne({ id: labId }).lean();
  if (lab) {
    return {
      providerType: 'lab',
      labId: lab.id,
      labName: lab.labName || lab.name || 'Lab',
      rating: lab.averageRating ?? 4.5,
      status: lab.verificationStatus || lab.status,
      verified:
        lab.verificationStatus === 'verified' ||
        lab.status === 'verified' ||
        lab.isApproved === true,
    };
  }
  const scan = await ScanCenter.findOne({ id: labId }).lean();
  if (scan) {
    return {
      providerType: 'scan_center',
      labId: scan.id,
      labName: scan.centerName || scan.name || 'Scan Center',
      rating: scan.averageRating ?? 4.5,
      status: scan.verificationStatus || scan.status,
      verified:
        scan.verificationStatus === 'verified' ||
        scan.status === 'verified' ||
        scan.isApproved === true,
    };
  }
  return null;
}

async function createPrescriptionRequest({
  userId,
  prescriptionFileUrl,
  prescriptionFileType,
  prescriptionFileName,
  labIds,
  requestedTests,
  notes,
  patientName,
  patientMobile,
  patientEmail,
  distanceByLabId = {},
}) {
  if (!userId) throw httpError('Authentication required', 401);
  if (!prescriptionFileUrl) {
    throw httpError('Prescription file is required', 400);
  }
  const fileType = assertAllowedFileType(prescriptionFileType);

  const ids = normalizeLabIds(labIds);
  if (ids.length === 0) {
    throw httpError('Select at least one lab or diagnostic center', 400);
  }
  if (ids.length > MAX_LABS_PER_REQUEST) {
    throw httpError(
      'You can send a prescription request to a maximum of 4 labs.',
      400,
    );
  }

  const providers = [];
  for (const id of ids) {
    const provider = await resolveProvider(id);
    if (!provider) {
      throw httpError(`Lab/diagnostic center not found: ${id}`, 404);
    }
    if (!provider.verified) {
      throw httpError(
        `${provider.labName} is not available for prescription quotes`,
        400,
      );
    }
    providers.push({
      ...provider,
      distanceKm:
        typeof distanceByLabId[id] === 'number' ? distanceByLabId[id] : null,
    });
  }

  let patient = null;
  try {
    patient = await Patient.findOne({ id: userId }).lean();
  } catch (_) {}

  const requestId = uuidv4();
  const request = await PrescriptionRequest.create({
    id: requestId,
    userId,
    patientName:
      patientName ||
      patient?.name ||
      [patient?.firstName, patient?.lastName].filter(Boolean).join(' ') ||
      'Patient',
    patientMobile: patientMobile || patient?.mobileNumber || patient?.mobile,
    patientEmail: patientEmail || patient?.email,
    prescriptionFileUrl,
    prescriptionFileType: fileType,
    prescriptionFileName: prescriptionFileName || null,
    requestedTests: normalizeRequestedTests(requestedTests),
    notes: notes ? String(notes).trim().slice(0, 2000) : undefined,
    status: 'SENT_TO_LABS',
    paymentStatus: 'PENDING',
    chatEnabled: false,
    expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
  });

  const quotations = [];
  for (const provider of providers) {
    const quotation = await PrescriptionQuotation.create({
      id: uuidv4(),
      prescriptionRequestId: requestId,
      labId: provider.labId,
      labName: provider.labName,
      providerType: provider.providerType,
      status: 'PENDING',
      paymentStatus: 'PENDING',
      rating: provider.rating,
      distanceKm: provider.distanceKm,
    });
    quotations.push(toQuotation(quotation));

    try {
      await createAndPushNotification({
        userId: provider.labId,
        userType: provider.providerType === 'scan_center' ? 'scan_center' : 'lab',
        title: 'New Prescription Request',
        body: `${request.patientName} sent a prescription for price quotation.`,
        type: 'prescription_request',
        data: {
          prescriptionRequestId: requestId,
          quotationId: quotation.id,
        },
      });
    } catch (err) {
      console.error('[PrescriptionRequest] lab notify failed:', err.message);
    }
  }

  try {
    await createAndPushNotification({
      userId,
      userType: 'patient',
      title: 'Prescription request submitted',
      body: `Your prescription was sent to ${providers.length} lab(s) for quotation.`,
      type: 'prescription_request',
      data: { prescriptionRequestId: requestId },
    });
  } catch (err) {
    console.error('[PrescriptionRequest] patient notify failed:', err.message);
  }

  return toPrescriptionRequest(request, quotations);
}

async function listMyPrescriptionRequests(userId) {
  const docs = await PrescriptionRequest.find({ userId })
    .sort({ createdAt: -1 })
    .limit(100)
    .lean();
  const ids = docs.map((d) => d.id);
  const quotations = await PrescriptionQuotation.find({
    prescriptionRequestId: { $in: ids },
  }).lean();
  const byRequest = new Map();
  for (const q of quotations) {
    if (!byRequest.has(q.prescriptionRequestId)) {
      byRequest.set(q.prescriptionRequestId, []);
    }
    byRequest.get(q.prescriptionRequestId).push(toQuotation(q));
  }
  return docs.map((d) => toPrescriptionRequest(d, byRequest.get(d.id) || []));
}

async function getPrescriptionRequestForUser(requestId, userId) {
  const doc = await PrescriptionRequest.findOne({ id: requestId }).lean();
  if (!doc) throw httpError('Prescription request not found', 404);
  if (doc.userId !== userId) throw httpError('Access denied', 403);
  const quotations = await PrescriptionQuotation.find({
    prescriptionRequestId: requestId,
  })
    .sort({ quotedAmount: 1, createdAt: 1 })
    .lean();
  return toPrescriptionRequest(doc, quotations.map(toQuotation));
}

async function getPrescriptionRequestForLab(requestId, labId) {
  const quotation = await PrescriptionQuotation.findOne({
    prescriptionRequestId: requestId,
    labId,
  }).lean();
  if (!quotation) throw httpError('Prescription request not found', 404);
  const doc = await PrescriptionRequest.findOne({ id: requestId }).lean();
  if (!doc) throw httpError('Prescription request not found', 404);
  return {
    ...toPrescriptionRequest(doc),
    myQuotation: toQuotation(quotation),
  };
}

async function listPrescriptionRequestsForLab(labId) {
  const quotations = await PrescriptionQuotation.find({ labId })
    .sort({ createdAt: -1 })
    .limit(100)
    .lean();
  if (quotations.length === 0) return [];

  const requestIds = quotations.map((q) => q.prescriptionRequestId);
  const requests = await PrescriptionRequest.find({
    id: { $in: requestIds },
  }).lean();
  const requestMap = new Map(requests.map((r) => [r.id, r]));

  return quotations
    .map((q) => {
      const req = requestMap.get(q.prescriptionRequestId);
      if (!req) return null;
      return {
        ...toPrescriptionRequest(req),
        myQuotation: toQuotation(q),
      };
    })
    .filter(Boolean);
}

async function submitQuotation({
  requestId,
  labId,
  quotedAmount,
  estimatedCompletionTime,
  availableServices,
  labNotes,
}) {
  const quotation = await PrescriptionQuotation.findOne({
    prescriptionRequestId: requestId,
    labId,
  });
  if (!quotation) throw httpError('Quotation not found for this lab', 404);

  const request = await PrescriptionRequest.findOne({ id: requestId });
  if (!request) throw httpError('Prescription request not found', 404);

  if (['CANCELLED', 'EXPIRED', 'COMPLETED'].includes(request.status)) {
    throw httpError('This prescription request is no longer open', 400);
  }
  if (request.paymentStatus === 'PAID') {
    throw httpError('Cannot update quotation after payment', 400);
  }
  if (
    request.selectedQuotationId &&
    request.selectedQuotationId !== quotation.id &&
    ['LAB_SELECTED', 'PAYMENT_PENDING', 'PAID', 'BOOKING_CONFIRMED'].includes(
      request.status,
    )
  ) {
    throw httpError('Another lab has already been selected', 400);
  }

  const amount = Number(quotedAmount);
  if (!Number.isFinite(amount) || amount <= 0) {
    throw httpError('Enter a valid total price greater than 0', 400);
  }
  if (amount > 1000000) {
    throw httpError('Quoted amount is too high', 400);
  }

  if (quotation.status === 'REJECTED') {
    throw httpError('This quotation was rejected and cannot be updated', 400);
  }

  quotation.quotedAmount = Math.round(amount);
  quotation.estimatedCompletionTime = estimatedCompletionTime
    ? String(estimatedCompletionTime).trim().slice(0, 120)
    : undefined;
  if (Array.isArray(availableServices)) {
    quotation.availableServices = availableServices
      .map((s) => String(s).trim())
      .filter(Boolean)
      .slice(0, 20);
  }
  quotation.labNotes = labNotes
    ? String(labNotes).trim().slice(0, 2000)
    : undefined;
  quotation.status = 'QUOTED';
  quotation.submittedAt = new Date();
  await quotation.save();

  const quotedCount = await PrescriptionQuotation.countDocuments({
    prescriptionRequestId: requestId,
    status: 'QUOTED',
  });
  if (
    ['SENT_TO_LABS', 'PENDING', 'QUOTATIONS_RECEIVED'].includes(request.status)
  ) {
    request.status = 'QUOTATIONS_RECEIVED';
    await request.save();
  }

  try {
    await createAndPushNotification({
      userId: request.userId,
      userType: 'patient',
      title: 'New quotation received',
      body: `${quotation.labName} quoted ₹${quotation.quotedAmount.toLocaleString('en-IN')}.`,
      type: 'prescription_quotation',
      data: {
        prescriptionRequestId: requestId,
        quotationId: quotation.id,
      },
    });
    if (quotedCount === 1) {
      await createAndPushNotification({
        userId: request.userId,
        userType: 'patient',
        title: 'Quotations available',
        body: 'You can now compare lab prices for your prescription.',
        type: 'prescription_quotation',
        data: { prescriptionRequestId: requestId },
      });
    }
  } catch (err) {
    console.error('[PrescriptionRequest] quote notify failed:', err.message);
  }

  return toQuotation(quotation);
}

async function rejectQuotation({ requestId, labId, reason }) {
  const quotation = await PrescriptionQuotation.findOne({
    prescriptionRequestId: requestId,
    labId,
  });
  if (!quotation) throw httpError('Quotation not found for this lab', 404);

  const request = await PrescriptionRequest.findOne({ id: requestId });
  if (!request) throw httpError('Prescription request not found', 404);
  if (request.paymentStatus === 'PAID') {
    throw httpError('Cannot reject after payment', 400);
  }
  if (request.selectedQuotationId === quotation.id) {
    throw httpError('Cannot reject a selected quotation', 400);
  }

  quotation.status = 'REJECTED';
  quotation.rejectionReason = reason
    ? String(reason).trim().slice(0, 500)
    : 'Unable to provide service';
  quotation.quotedAmount = null;
  await quotation.save();
  return toQuotation(quotation);
}

async function selectLabQuotation({ requestId, userId, quotationId }) {
  const request = await PrescriptionRequest.findOne({ id: requestId });
  if (!request) throw httpError('Prescription request not found', 404);
  if (request.userId !== userId) throw httpError('Access denied', 403);
  if (request.paymentStatus === 'PAID') {
    throw httpError('Lab already selected and paid', 400);
  }
  if (['CANCELLED', 'EXPIRED', 'COMPLETED'].includes(request.status)) {
    throw httpError('This request is no longer active', 400);
  }

  const quotation = await PrescriptionQuotation.findOne({
    id: quotationId,
    prescriptionRequestId: requestId,
  });
  if (!quotation) throw httpError('Quotation not found', 404);
  if (quotation.status !== 'QUOTED' && quotation.status !== 'SELECTED') {
    throw httpError('This quotation is not available for selection', 400);
  }
  if (!quotation.quotedAmount || quotation.quotedAmount <= 0) {
    throw httpError('Quotation has no valid price', 400);
  }

  await PrescriptionQuotation.updateMany(
    {
      prescriptionRequestId: requestId,
      id: { $ne: quotationId },
      status: { $in: ['QUOTED', 'SELECTED', 'PENDING'] },
    },
    { $set: { status: 'REJECTED' } },
  );

  quotation.status = 'SELECTED';
  await quotation.save();

  request.selectedLabId = quotation.labId;
  request.selectedQuotationId = quotation.id;
  request.status = 'PAYMENT_PENDING';
  request.paymentStatus = 'PENDING';
  request.chatEnabled = false;
  await request.save();

  try {
    await createAndPushNotification({
      userId: quotation.labId,
      userType:
        quotation.providerType === 'scan_center' ? 'scan_center' : 'lab',
      title: 'Quotation selected',
      body: `${request.patientName} selected your quotation. Awaiting payment.`,
      type: 'prescription_selected',
      data: {
        prescriptionRequestId: requestId,
        quotationId: quotation.id,
      },
    });
  } catch (err) {
    console.error('[PrescriptionRequest] select notify failed:', err.message);
  }

  const quotations = await PrescriptionQuotation.find({
    prescriptionRequestId: requestId,
  }).lean();
  return toPrescriptionRequest(request, quotations.map(toQuotation));
}

async function createPaymentOrderForPrescriptionRequest(requestId, userId) {
  const request = await PrescriptionRequest.findOne({ id: requestId });
  if (!request) throw httpError('Prescription request not found', 404);
  if (request.userId !== userId) throw httpError('Access denied', 403);
  if (request.paymentStatus === 'PAID') {
    throw httpError('Already paid', 400);
  }
  if (!request.selectedQuotationId || !request.selectedLabId) {
    throw httpError('Select a lab quotation before payment', 400);
  }

  const quotation = await PrescriptionQuotation.findOne({
    id: request.selectedQuotationId,
  });
  if (!quotation || quotation.status !== 'SELECTED') {
    throw httpError('Selected quotation is not available', 400);
  }

  const amountInPaise = Math.round((quotation.quotedAmount || 0) * 100);
  if (amountInPaise < 100) {
    throw httpError('Amount must be at least ₹1', 400);
  }

  const razorpayOrder = await createRazorpayOrder({
    amountInPaise,
    receipt: request.id.slice(0, 40),
    notes: {
      prescriptionRequestId: request.id,
      quotationId: quotation.id,
      type: 'prescription_quote',
    },
  });

  request.razorpayOrderId = razorpayOrder.id;
  request.paymentExpiresAt = new Date(
    Date.now() + PAYMENT_HOLD_MINUTES * 60 * 1000,
  );
  request.status = 'PAYMENT_PENDING';
  request.paymentStatus = 'PENDING';
  request.chatEnabled = false;
  await request.save();

  return {
    prescriptionRequest: toPrescriptionRequest(request),
    razorpayOrder,
    amountInPaise,
    keyId: isMockMode() ? null : process.env.RAZORPAY_KEY_ID,
    mock: isMockMode(),
    prefill: {
      name: request.patientName,
      email: request.patientEmail || undefined,
      contact: request.patientMobile,
    },
  };
}

async function createBookingFromPaidRequest(request, quotation) {
  const bookingId = uuidv4();
  const scheduledDate = new Date();
  scheduledDate.setDate(scheduledDate.getDate() + 1);
  scheduledDate.setHours(10, 0, 0, 0);

  const items = (request.requestedTests || []).map((t) => ({
    testId: undefined,
    testName: t.name,
    price: 0,
  }));
  if (items.length === 0) {
    items.push({
      testName: 'Prescription-based tests',
      price: quotation.quotedAmount,
    });
  } else {
    items[0].price = quotation.quotedAmount;
  }

  if (quotation.providerType === 'scan_center') {
    const scanName =
      (request.requestedTests || []).map((t) => t.name).filter(Boolean).join(', ') ||
      'Prescription-based scan';
    await ScanBooking.create({
      id: bookingId,
      scanCenterId: quotation.labId,
      scanCenterName: quotation.labName,
      patientId: request.userId,
      patientName: request.patientName || 'Patient',
      patientMobile: request.patientMobile || '0000000000',
      patientEmail: request.patientEmail,
      scanName: scanName.slice(0, 200),
      scheduledDate,
      timeSlot: '10:00 AM - 12:00 PM',
      totalAmount: quotation.quotedAmount,
      paymentStatus: 'paid',
      status: 'confirmed',
      notes: `Prescription request ${request.id}`,
      prescriptionUrl: request.prescriptionFileUrl,
      prescriptionFileName: request.prescriptionFileName,
    });
  } else {
    await LabBooking.create({
      id: bookingId,
      labId: quotation.labId,
      labName: quotation.labName,
      patientId: request.userId,
      patientName: request.patientName || 'Patient',
      patientMobile: request.patientMobile || '0000000000',
      patientEmail: request.patientEmail,
      collectionType: 'lab_visit',
      scheduledDate,
      timeSlot: '10:00 AM - 12:00 PM',
      items,
      subtotal: quotation.quotedAmount,
      totalAmount: quotation.quotedAmount,
      paymentStatus: 'paid',
      status: 'confirmed',
      notes: `Prescription request ${request.id}`,
    });
  }

  return bookingId;
}

async function confirmPrescriptionPayment({
  requestId,
  userId,
  razorpayOrderId,
  razorpayPaymentId,
  razorpaySignature,
}) {
  const request = await PrescriptionRequest.findOne({ id: requestId });
  if (!request) throw httpError('Prescription request not found', 404);
  if (request.userId !== userId) throw httpError('Access denied', 403);

  if (request.paymentStatus === 'PAID' && request.chatEnabled) {
    const quotations = await PrescriptionQuotation.find({
      prescriptionRequestId: requestId,
    }).lean();
    return toPrescriptionRequest(request, quotations.map(toQuotation));
  }

  if (!request.selectedQuotationId) {
    throw httpError('No lab selected for payment', 400);
  }

  if (!isMockMode()) {
    const valid = verifyPaymentSignature({
      orderId: razorpayOrderId,
      paymentId: razorpayPaymentId,
      signature: razorpaySignature,
    });
    if (!valid) {
      request.paymentStatus = 'FAILED';
      await request.save();
      throw httpError('Invalid payment signature', 400);
    }
  }

  if (
    request.razorpayOrderId &&
    razorpayOrderId &&
    request.razorpayOrderId !== razorpayOrderId
  ) {
    throw httpError('Payment order mismatch', 400);
  }

  const quotation = await PrescriptionQuotation.findOne({
    id: request.selectedQuotationId,
  });
  if (!quotation) throw httpError('Selected quotation not found', 404);

  let bookingId = request.bookingId;
  if (!bookingId) {
    bookingId = await createBookingFromPaidRequest(request, quotation);
  }

  request.paymentStatus = 'PAID';
  request.status = 'BOOKING_CONFIRMED';
  request.chatEnabled = true;
  request.razorpayOrderId = razorpayOrderId;
  request.razorpayPaymentId = razorpayPaymentId;
  request.bookingId = bookingId;
  await request.save();

  quotation.paymentStatus = 'PAID';
  quotation.status = 'SELECTED';
  await quotation.save();

  try {
    await createAndPushNotification({
      userId: request.userId,
      userType: 'patient',
      title: 'Payment successful',
      body: `Booking confirmed with ${quotation.labName}. Chat is now available.`,
      type: 'prescription_paid',
      data: {
        prescriptionRequestId: requestId,
        bookingId,
      },
    });
    await createAndPushNotification({
      userId: quotation.labId,
      userType:
        quotation.providerType === 'scan_center' ? 'scan_center' : 'lab',
      title: 'Payment completed',
      body: `${request.patientName} paid ₹${quotation.quotedAmount.toLocaleString('en-IN')}. Chat is now available.`,
      type: 'prescription_paid',
      data: {
        prescriptionRequestId: requestId,
        bookingId,
      },
    });
  } catch (err) {
    console.error('[PrescriptionRequest] paid notify failed:', err.message);
  }

  const quotations = await PrescriptionQuotation.find({
    prescriptionRequestId: requestId,
  }).lean();
  return toPrescriptionRequest(request, quotations.map(toQuotation));
}

async function markPrescriptionPaymentFailed(requestId, userId) {
  const request = await PrescriptionRequest.findOne({ id: requestId });
  if (!request) throw httpError('Prescription request not found', 404);
  if (request.userId !== userId) throw httpError('Access denied', 403);
  if (request.paymentStatus === 'PAID') {
    throw httpError('Payment already completed', 400);
  }
  request.paymentStatus = 'FAILED';
  request.chatEnabled = false;
  request.status = 'PAYMENT_PENDING';
  await request.save();
  return toPrescriptionRequest(request);
}

async function findPrescriptionRequestById(requestId) {
  return PrescriptionRequest.findOne({ id: requestId }).lean();
}

module.exports = {
  MAX_LABS_PER_REQUEST,
  ALLOWED_FILE_TYPES,
  assertAllowedFileType,
  normalizeFileType,
  toPrescriptionRequest,
  toQuotation,
  createPrescriptionRequest,
  listMyPrescriptionRequests,
  getPrescriptionRequestForUser,
  getPrescriptionRequestForLab,
  listPrescriptionRequestsForLab,
  submitQuotation,
  rejectQuotation,
  selectLabQuotation,
  createPaymentOrderForPrescriptionRequest,
  confirmPrescriptionPayment,
  markPrescriptionPaymentFailed,
  findPrescriptionRequestById,
};

