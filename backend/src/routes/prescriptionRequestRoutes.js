const express = require('express');
const path = require('path');
const { sendSuccess, sendError } = require('../utils/response');
const { authRequired } = require('../middleware/auth');
const { upload, filePublicUrl } = require('../middleware/multerUpload');
const {
  MAX_LABS_PER_REQUEST,
  assertAllowedFileType,
  normalizeFileType,
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
} = require('../db/prescriptionRequestRepositories');
const { listChatMessages, sendChatMessage } = require('../db/chatRepositories');

const router = express.Router();

function requirePatient(req, res) {
  if (req.auth?.type !== 'patient' || !req.auth?.patientId) {
    sendError(res, 'Patient authentication required', 401);
    return null;
  }
  return req.auth.patientId;
}

function requireLabOrScan(req, res) {
  if (req.auth?.type === 'lab' && req.auth?.labId) {
    return { labId: req.auth.labId, providerType: 'lab' };
  }
  if (req.auth?.type === 'scan_center' && req.auth?.scanCenterId) {
    return { labId: req.auth.scanCenterId, providerType: 'scan_center' };
  }
  sendError(res, 'Lab or scan center authentication required', 401);
  return null;
}

function handleErr(res, err, fallback) {
  console.error(err);
  return sendError(
    res,
    err.message || fallback,
    err.statusCode || 500,
  );
}

router.post(
  '/upload',
  authRequired,
  upload.single('prescription'),
  async (req, res) => {
    try {
      const patientId = requirePatient(req, res);
      if (!patientId) return;

      if (!req.file) {
        return sendError(res, 'Prescription file is required', 400);
      }

      const ext = normalizeFileType(
        path.extname(req.file.originalname || '') ||
          req.file.mimetype ||
          '',
      );
      try {
        assertAllowedFileType(ext);
      } catch (err) {
        return sendError(res, err.message, err.statusCode || 400);
      }

      if (!req.file.size || req.file.size <= 0) {
        return sendError(res, 'Uploaded prescription file is empty', 400);
      }

      const url = await filePublicUrl(req, req.file);
      return sendSuccess(res, {
        message: 'Prescription uploaded',
        data: {
          prescriptionFileUrl: url,
          prescriptionFileType: ext,
          prescriptionFileName: req.file.originalname,
          size: req.file.size,
        },
      });
    } catch (err) {
      return handleErr(res, err, 'Failed to upload prescription');
    }
  },
);

router.post('/request', authRequired, async (req, res) => {
  try {
    const patientId = requirePatient(req, res);
    if (!patientId) return;

    const body = req.body || {};
    const data = await createPrescriptionRequest({
      userId: patientId,
      prescriptionFileUrl: body.prescriptionFileUrl,
      prescriptionFileType: body.prescriptionFileType,
      prescriptionFileName: body.prescriptionFileName,
      labIds: body.labIds,
      requestedTests: body.requestedTests,
      notes: body.notes,
      patientName: body.patientName,
      patientMobile: body.patientMobile,
      patientEmail: body.patientEmail,
      distanceByLabId: body.distanceByLabId || {},
    });

    return sendSuccess(res, {
      message: 'Prescription request submitted',
      data,
      statusCode: 201,
    });
  } catch (err) {
    return handleErr(res, err, 'Failed to create prescription request');
  }
});

router.get('/my-requests', authRequired, async (req, res) => {
  try {
    const patientId = requirePatient(req, res);
    if (!patientId) return;
    const data = await listMyPrescriptionRequests(patientId);
    return sendSuccess(res, { data });
  } catch (err) {
    return handleErr(res, err, 'Failed to list prescription requests');
  }
});

router.get('/meta/limits', (_req, res) => {
  return sendSuccess(res, {
    data: {
      maxLabsPerRequest: MAX_LABS_PER_REQUEST,
      allowedFileTypes: ['jpg', 'jpeg', 'png', 'pdf'],
      maxFileSizeBytes: 10 * 1024 * 1024,
    },
  });
});
router.get('/lab/inbox', authRequired, async (req, res) => {
  try {
    const provider = requireLabOrScan(req, res);
    if (!provider) return;
    const data = await listPrescriptionRequestsForLab(provider.labId);
    return sendSuccess(res, { data });
  } catch (err) {
    return handleErr(res, err, 'Failed to list lab prescription requests');
  }
});

router.get('/:id', authRequired, async (req, res) => {
  try {
    if (req.auth?.type === 'patient' && req.auth?.patientId) {
      const data = await getPrescriptionRequestForUser(
        req.params.id,
        req.auth.patientId,
      );
      return sendSuccess(res, { data });
    }
    const provider = requireLabOrScan(req, res);
    if (!provider) return;
    const data = await getPrescriptionRequestForLab(
      req.params.id,
      provider.labId,
    );
    return sendSuccess(res, { data });
  } catch (err) {
    return handleErr(res, err, 'Failed to load prescription request');
  }
});

router.get('/:id/quotations', authRequired, async (req, res) => {
  try {
    const patientId = requirePatient(req, res);
    if (!patientId) return;
    const data = await getPrescriptionRequestForUser(req.params.id, patientId);
    return sendSuccess(res, { data: data.quotations || [] });
  } catch (err) {
    return handleErr(res, err, 'Failed to load quotations');
  }
});

router.post('/:id/quotations', authRequired, async (req, res) => {
  try {
    const provider = requireLabOrScan(req, res);
    if (!provider) return;
    const body = req.body || {};
    const data = await submitQuotation({
      requestId: req.params.id,
      labId: provider.labId,
      quotedAmount: body.quotedAmount ?? body.totalPrice,
      estimatedCompletionTime: body.estimatedCompletionTime,
      availableServices: body.availableServices,
      labNotes: body.labNotes || body.notes,
    });
    return sendSuccess(res, {
      message: 'Quotation submitted',
      data,
    });
  } catch (err) {
    return handleErr(res, err, 'Failed to submit quotation');
  }
});

router.post('/:id/quotations/reject', authRequired, async (req, res) => {
  try {
    const provider = requireLabOrScan(req, res);
    if (!provider) return;
    const data = await rejectQuotation({
      requestId: req.params.id,
      labId: provider.labId,
      reason: req.body?.reason,
    });
    return sendSuccess(res, {
      message: 'Quotation rejected',
      data,
    });
  } catch (err) {
    return handleErr(res, err, 'Failed to reject quotation');
  }
});

router.post('/:id/select-lab', authRequired, async (req, res) => {
  try {
    const patientId = requirePatient(req, res);
    if (!patientId) return;
    const quotationId = req.body?.quotationId;
    if (!quotationId) {
      return sendError(res, 'quotationId is required', 400);
    }
    const data = await selectLabQuotation({
      requestId: req.params.id,
      userId: patientId,
      quotationId,
    });
    return sendSuccess(res, {
      message: 'Lab selected',
      data,
    });
  } catch (err) {
    return handleErr(res, err, 'Failed to select lab');
  }
});

router.post('/:id/payments/create-order', authRequired, async (req, res) => {
  try {
    const patientId = requirePatient(req, res);
    if (!patientId) return;
    const result = await createPaymentOrderForPrescriptionRequest(
      req.params.id,
      patientId,
    );
    return sendSuccess(res, {
      message: 'Payment order created',
      data: {
        prescriptionRequestId: req.params.id,
        razorpayOrderId: result.razorpayOrder.id,
        amount: result.amountInPaise,
        currency: 'INR',
        keyId: result.keyId,
        mock: result.mock,
        prefillName: result.prefill.name,
        prefillEmail: result.prefill.email,
        prefillContact: result.prefill.contact,
        prescriptionRequest: result.prescriptionRequest,
      },
    });
  } catch (err) {
    return handleErr(res, err, 'Failed to create payment order');
  }
});

router.post('/:id/payments/verify', authRequired, async (req, res) => {
  try {
    const patientId = requirePatient(req, res);
    if (!patientId) return;
    const body = req.body || {};
    const data = await confirmPrescriptionPayment({
      requestId: req.params.id,
      userId: patientId,
      razorpayOrderId: body.razorpayOrderId || body.orderId,
      razorpayPaymentId: body.razorpayPaymentId || body.paymentId,
      razorpaySignature: body.razorpaySignature || body.signature,
    });
    return sendSuccess(res, {
      message: 'Payment verified. Booking confirmed and chat enabled.',
      data,
    });
  } catch (err) {
    return handleErr(res, err, 'Payment verification failed');
  }
});

router.post('/:id/payments/failed', authRequired, async (req, res) => {
  try {
    const patientId = requirePatient(req, res);
    if (!patientId) return;
    const data = await markPrescriptionPaymentFailed(req.params.id, patientId);
    return sendSuccess(res, {
      message: 'Payment marked as failed',
      data,
    });
  } catch (err) {
    return handleErr(res, err, 'Failed to update payment status');
  }
});

router.get('/:id/chat', authRequired, async (req, res) => {
  try {
    const messages = await listChatMessages(req.params.id, req.auth, {
      after: req.query.after,
    });
    return sendSuccess(res, { data: messages });
  } catch (err) {
    return handleErr(res, err, 'Failed to load chat');
  }
});

router.post('/:id/chat', authRequired, async (req, res) => {
  try {
    const message = await sendChatMessage(
      req.params.id,
      req.auth,
      req.body?.body ?? req.body?.message,
    );
    return sendSuccess(res, {
      message: 'Message sent',
      data: message,
      statusCode: 201,
    });
  } catch (err) {
    return handleErr(res, err, 'Failed to send message');
  }
});


module.exports = router;

