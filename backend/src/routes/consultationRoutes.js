const express = require('express');
const {
  getVideoSession,
  markVideoCallStarted,
  markVideoCallEnded,
} = require('../services/videoConsultService');
const {
  getPrescriptionContext,
  saveAndFinalizePrescription,
  getPrescription,
} = require('../services/prescriptionService');
const { submitFeedback, dismissFeedback } = require('../services/feedbackService');
const { sendSuccess, sendError } = require('../utils/response');
const { authRequired } = require('../middleware/auth');
const { getPublicBaseUrl } = require('../middleware/multerUpload');

const router = express.Router();

function requireParticipantAuth(req, res) {
  if (
    (req.auth?.type === 'patient' && req.auth?.patientId) ||
    (req.auth?.type === 'doctor' && req.auth?.doctorId)
  ) {
    return true;
  }
  sendError(res, 'Patient or doctor authentication required', 401);
  return false;
}

// GET /consultations/:bookingId/video-session
router.get('/:bookingId/video-session', authRequired, async (req, res) => {
  try {
    if (!requireParticipantAuth(req, res)) return;

    const data = await getVideoSession(req.params.bookingId, req.auth);
    return sendSuccess(res, { data });
  } catch (err) {
    console.error(err);
    const status = err.statusCode || 500;
    return sendError(res, err.message || 'Failed to load video session', status);
  }
});

// POST /consultations/:bookingId/video-session/join
router.post('/:bookingId/video-session/join', authRequired, async (req, res) => {
  try {
    if (!requireParticipantAuth(req, res)) return;

    const data = await markVideoCallStarted(req.params.bookingId, req.auth);
    return sendSuccess(res, {
      message: 'Joined video consultation',
      data,
    });
  } catch (err) {
    console.error(err);
    const status = err.statusCode || 500;
    return sendError(res, err.message || 'Failed to join video session', status);
  }
});

// POST /consultations/:bookingId/video-session/end
router.post('/:bookingId/video-session/end', authRequired, async (req, res) => {
  try {
    if (!requireParticipantAuth(req, res)) return;

    const data = await markVideoCallEnded(req.params.bookingId, req.auth);
    return sendSuccess(res, {
      message: 'Video consultation ended',
      data,
    });
  } catch (err) {
    console.error(err);
    const status = err.statusCode || 500;
    return sendError(res, err.message || 'Failed to end video session', status);
  }
});

// POST /consultations/:bookingId/feedback
router.post('/:bookingId/feedback', authRequired, async (req, res) => {
  try {
    const data = await submitFeedback(req.params.bookingId, req.auth, req.body);
    return sendSuccess(res, {
      message: 'Thank you for your feedback',
      data,
    });
  } catch (err) {
    console.error(err);
    const status = err.statusCode || 500;
    return sendError(res, err.message || 'Failed to submit feedback', status);
  }
});

// POST /consultations/:bookingId/feedback/dismiss
router.post('/:bookingId/feedback/dismiss', authRequired, async (req, res) => {
  try {
    const data = await dismissFeedback(req.params.bookingId, req.auth);
    return sendSuccess(res, {
      message: 'Feedback dismissed',
      data,
    });
  } catch (err) {
    console.error(err);
    const status = err.statusCode || 500;
    return sendError(res, err.message || 'Failed to dismiss feedback', status);
  }
});

// GET /consultations/:bookingId/prescription/context
router.get('/:bookingId/prescription/context', authRequired, async (req, res) => {
  try {
    if (req.auth?.type !== 'doctor' || !req.auth?.doctorId) {
      return sendError(res, 'Doctor authentication required', 401);
    }
    const data = await getPrescriptionContext(req.params.bookingId, req.auth);
    return sendSuccess(res, { data });
  } catch (err) {
    console.error(err);
    const status = err.statusCode || 500;
    return sendError(res, err.message || 'Failed to load prescription context', status);
  }
});

// POST /consultations/:bookingId/prescription
router.post('/:bookingId/prescription', authRequired, async (req, res) => {
  try {
    if (req.auth?.type !== 'doctor' || !req.auth?.doctorId) {
      return sendError(res, 'Doctor authentication required', 401);
    }
    const data = await saveAndFinalizePrescription(
      req.params.bookingId,
      req.auth,
      req.body,
      getPublicBaseUrl(req),
    );
    return sendSuccess(res, {
      message: data.email?.sent
        ? 'Prescription saved and emailed to the patient'
        : 'Prescription saved for the patient',
      data,
    });
  } catch (err) {
    console.error(err);
    const status = err.statusCode || 500;
    return sendError(res, err.message || 'Failed to save prescription', status);
  }
});

// GET /consultations/:bookingId/prescription
router.get('/:bookingId/prescription', authRequired, async (req, res) => {
  try {
    if (!requireParticipantAuth(req, res)) return;
    const data = await getPrescription(req.params.bookingId, req.auth);
    return sendSuccess(res, { data });
  } catch (err) {
    console.error(err);
    const status = err.statusCode || 500;
    return sendError(res, err.message || 'Failed to load prescription', status);
  }
});

module.exports = router;
