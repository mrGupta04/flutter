const express = require('express');
const {
  listNotifications,
  markNotificationRead,
  markAllNotificationsRead,
  registerDeviceToken,
} = require('../db/notificationRepositories');
const {
  addFavorite,
  removeFavorite,
  listFavorites,
  isFavorite,
} = require('../db/favoriteRepositories');
const {
  cancelBooking,
  rescheduleBooking,
  getBookingTimeline,
  getCancellationPolicy,
} = require('../db/bookingLifecycleRepositories');
const ConsultationBooking = require('../db/models/ConsultationBooking');
const { listChatMessages, sendChatMessage } = require('../db/chatRepositories');
const { getNurseVisitNote } = require('../db/nurseVisitNoteRepositories');
const { sendSuccess, sendError } = require('../utils/response');
const { authRequired } = require('../middleware/auth');

const router = express.Router();

function requirePatientAuth(req, res) {
  if (req.auth?.type !== 'patient' || !req.auth?.patientId) {
    sendError(res, 'Patient authentication required', 401);
    return null;
  }
  return req.auth.patientId;
}

// --- Notifications ---
router.get('/notifications', authRequired, async (req, res) => {
  try {
    const patientId = requirePatientAuth(req, res);
    if (!patientId) return;
    const data = await listNotifications(patientId, 'patient', {
      limit: req.query.limit,
      unreadOnly: req.query.unreadOnly === 'true',
    });
    return sendSuccess(res, { data });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to load notifications', 500);
  }
});

router.post('/notifications/:id/read', authRequired, async (req, res) => {
  try {
    const patientId = requirePatientAuth(req, res);
    if (!patientId) return;
    const data = await markNotificationRead(req.params.id, patientId);
    return sendSuccess(res, { data });
  } catch (err) {
    const status = err.statusCode || 500;
    return sendError(res, err.message || 'Failed to mark read', status);
  }
});

router.post('/notifications/read-all', authRequired, async (req, res) => {
  try {
    const patientId = requirePatientAuth(req, res);
    if (!patientId) return;
    const data = await markAllNotificationsRead(patientId, 'patient');
    return sendSuccess(res, { data });
  } catch (err) {
    return sendError(res, err.message || 'Failed to mark all read', 500);
  }
});

router.post('/device-token', authRequired, async (req, res) => {
  try {
    const patientId = requirePatientAuth(req, res);
    if (!patientId) return;
    const data = await registerDeviceToken(
      patientId,
      'patient',
      req.body?.token || req.body?.deviceToken,
    );
    return sendSuccess(res, { message: 'Device token registered', data });
  } catch (err) {
    const status = err.statusCode || 500;
    return sendError(res, err.message || 'Failed to register token', status);
  }
});

// --- Favorites ---
router.get('/favorites', authRequired, async (req, res) => {
  try {
    const patientId = requirePatientAuth(req, res);
    if (!patientId) return;
    const data = await listFavorites(patientId);
    return sendSuccess(res, { data });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to load favorites', 500);
  }
});

router.post('/favorites', authRequired, async (req, res) => {
  try {
    const patientId = requirePatientAuth(req, res);
    if (!patientId) return;
    const { providerType, providerId } = req.body || {};
    const data = await addFavorite(patientId, providerType, providerId);
    return sendSuccess(res, { message: 'Added to favorites', data });
  } catch (err) {
    const status = err.statusCode || 500;
    return sendError(res, err.message || 'Failed to add favorite', status);
  }
});

router.delete('/favorites/:providerType/:providerId', authRequired, async (req, res) => {
  try {
    const patientId = requirePatientAuth(req, res);
    if (!patientId) return;
    const data = await removeFavorite(
      patientId,
      req.params.providerType,
      req.params.providerId,
    );
    return sendSuccess(res, { message: 'Removed from favorites', data });
  } catch (err) {
    const status = err.statusCode || 500;
    return sendError(res, err.message || 'Failed to remove favorite', status);
  }
});

router.get('/favorites/check/:providerType/:providerId', authRequired, async (req, res) => {
  try {
    const patientId = requirePatientAuth(req, res);
    if (!patientId) return;
    const favored = await isFavorite(
      patientId,
      req.params.providerType,
      req.params.providerId,
    );
    return sendSuccess(res, { data: { isFavorite: favored } });
  } catch (err) {
    return sendError(res, err.message || 'Failed to check favorite', 500);
  }
});

// --- Booking lifecycle (patient) ---
router.get('/bookings/:bookingId/timeline', authRequired, async (req, res) => {
  try {
    const patientId = requirePatientAuth(req, res);
    if (!patientId) return;
    const data = await getBookingTimeline(req.params.bookingId, req.auth);
    return sendSuccess(res, { data });
  } catch (err) {
    const status = err.statusCode || 500;
    return sendError(res, err.message || 'Failed to load timeline', status);
  }
});

router.get('/bookings/:bookingId/cancellation-policy', authRequired, async (req, res) => {
  try {
    const patientId = requirePatientAuth(req, res);
    if (!patientId) return;
    const booking = await ConsultationBooking.findOne({
      id: req.params.bookingId,
    }).lean();
    if (!booking || booking.patientId !== patientId) {
      return sendError(res, 'Booking not found', 404);
    }
    return sendSuccess(res, { data: getCancellationPolicy(booking) });
  } catch (err) {
    return sendError(res, err.message || 'Failed to load policy', 500);
  }
});

router.post('/bookings/:bookingId/cancel', authRequired, async (req, res) => {
  try {
    const patientId = requirePatientAuth(req, res);
    if (!patientId) return;
    const data = await cancelBooking(
      req.params.bookingId,
      req.auth,
      req.body?.reason,
    );
    return sendSuccess(res, { message: 'Booking cancelled', data });
  } catch (err) {
    const status = err.statusCode || 500;
    return sendError(res, err.message || 'Failed to cancel', status);
  }
});

router.post('/bookings/:bookingId/reschedule', authRequired, async (req, res) => {
  try {
    const patientId = requirePatientAuth(req, res);
    if (!patientId) return;
    const data = await rescheduleBooking(req.params.bookingId, req.auth, req.body || {});
    return sendSuccess(res, { message: 'Booking rescheduled', data });
  } catch (err) {
    const status = err.statusCode || 500;
    return sendError(res, err.message || 'Failed to reschedule', status);
  }
});

// --- Chat ---
router.get('/bookings/:bookingId/chat', authRequired, async (req, res) => {
  try {
    const patientId = requirePatientAuth(req, res);
    if (!patientId) return;
    const data = await listChatMessages(req.params.bookingId, req.auth, {
      after: req.query.after,
    });
    return sendSuccess(res, { data });
  } catch (err) {
    const status = err.statusCode || 500;
    return sendError(res, err.message || 'Failed to load chat', status);
  }
});

router.post('/bookings/:bookingId/chat', authRequired, async (req, res) => {
  try {
    const patientId = requirePatientAuth(req, res);
    if (!patientId) return;
    const data = await sendChatMessage(
      req.params.bookingId,
      req.auth,
      req.body?.body || req.body?.message,
    );
    return sendSuccess(res, { message: 'Message sent', data });
  } catch (err) {
    const status = err.statusCode || 500;
    return sendError(res, err.message || 'Failed to send message', status);
  }
});

// --- Nurse visit notes ---
router.get('/bookings/:bookingId/visit-note', authRequired, async (req, res) => {
  try {
    const patientId = requirePatientAuth(req, res);
    if (!patientId) return;
    const data = await getNurseVisitNote(req.params.bookingId, req.auth);
    return sendSuccess(res, { data });
  } catch (err) {
    const status = err.statusCode || 500;
    return sendError(res, err.message || 'Failed to load visit note', status);
  }
});

module.exports = router;
