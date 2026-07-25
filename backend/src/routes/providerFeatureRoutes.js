const express = require('express');
const {
  listNotifications,
  markNotificationRead,
  markAllNotificationsRead,
  registerDeviceToken,
} = require('../db/notificationRepositories');
const {
  cancelBooking,
  updateVisitProgress,
  getBookingTimeline,
  markNoShow,
} = require('../db/bookingLifecycleRepositories');
const { getProviderEarnings } = require('../db/earningsRepositories');
const { listChatMessages, sendChatMessage } = require('../db/chatRepositories');
const {
  saveNurseVisitNote,
  getNurseVisitNote,
} = require('../db/nurseVisitNoteRepositories');
const {
  startNurseVisit,
  saveNurseVisitReportDraft,
  submitNurseVisitReport,
  requestVisitCompletionOtp,
  verifyVisitCompletionOtp,
} = require('../db/nurseVisitWorkflowRepositories');
const { listPublicNurseFeedback } = require('../db/feedbackRepositories');
const Nurse = require('../db/models/Nurse');
const { sendSuccess, sendError } = require('../utils/response');
const { authRequired } = require('../middleware/auth');

/**
 * Attach shared provider feature routes.
 * @param {import('express').Router} router
 * @param {'doctor'|'nurse'} providerType
 */
function attachProviderFeatureRoutes(router, providerType) {
  function requireProvider(req, res) {
    if (providerType === 'doctor') {
      if (req.auth?.type !== 'doctor' || !req.auth?.doctorId) {
        sendError(res, 'Doctor authentication required', 401);
        return null;
      }
      return { id: req.auth.doctorId, type: 'doctor' };
    }
    if (req.auth?.type !== 'nurse' || !req.auth?.nurseId) {
      sendError(res, 'Nurse authentication required', 401);
      return null;
    }
    return { id: req.auth.nurseId, type: 'nurse' };
  }

  router.get('/notifications', authRequired, async (req, res) => {
    try {
      const provider = requireProvider(req, res);
      if (!provider) return;
      const data = await listNotifications(provider.id, provider.type, {
        limit: req.query.limit,
        unreadOnly: req.query.unreadOnly === 'true',
      });
      return sendSuccess(res, { data });
    } catch (err) {
      return sendError(res, err.message || 'Failed to load notifications', 500);
    }
  });

  router.post('/notifications/:id/read', authRequired, async (req, res) => {
    try {
      const provider = requireProvider(req, res);
      if (!provider) return;
      const data = await markNotificationRead(req.params.id, provider.id);
      return sendSuccess(res, { data });
    } catch (err) {
      const status = err.statusCode || 500;
      return sendError(res, err.message || 'Failed to mark read', status);
    }
  });

  router.post('/notifications/read-all', authRequired, async (req, res) => {
    try {
      const provider = requireProvider(req, res);
      if (!provider) return;
      const data = await markAllNotificationsRead(provider.id, provider.type);
      return sendSuccess(res, { data });
    } catch (err) {
      return sendError(res, err.message || 'Failed to mark all read', 500);
    }
  });

  router.post('/device-token', authRequired, async (req, res) => {
    try {
      const provider = requireProvider(req, res);
      if (!provider) return;
      const data = await registerDeviceToken(
        provider.id,
        provider.type,
        req.body?.token || req.body?.deviceToken,
      );
      return sendSuccess(res, { message: 'Device token registered', data });
    } catch (err) {
      const status = err.statusCode || 500;
      return sendError(res, err.message || 'Failed to register token', status);
    }
  });

  router.get('/earnings', authRequired, async (req, res) => {
    try {
      const provider = requireProvider(req, res);
      if (!provider) return;
      const data = await getProviderEarnings({
        doctorId: provider.type === 'doctor' ? provider.id : undefined,
        nurseId: provider.type === 'nurse' ? provider.id : undefined,
        from: req.query.from,
        to: req.query.to,
      });
      return sendSuccess(res, { data });
    } catch (err) {
      console.error(err);
      return sendError(res, err.message || 'Failed to load earnings', 500);
    }
  });

  router.get('/bookings/:bookingId/timeline', authRequired, async (req, res) => {
    try {
      if (!requireProvider(req, res)) return;
      const data = await getBookingTimeline(req.params.bookingId, req.auth);
      return sendSuccess(res, { data });
    } catch (err) {
      const status = err.statusCode || 500;
      return sendError(res, err.message || 'Failed to load timeline', status);
    }
  });

  router.post('/bookings/:bookingId/visit-progress', authRequired, async (req, res) => {
    try {
      if (!requireProvider(req, res)) return;
      const data = await updateVisitProgress(
        req.params.bookingId,
        req.auth,
        req.body?.progress || req.body?.visitProgress,
      );
      return sendSuccess(res, { message: 'Visit progress updated', data });
    } catch (err) {
      const status = err.statusCode || 500;
      return sendError(res, err.message || 'Failed to update progress', status);
    }
  });

  router.post('/bookings/:bookingId/cancel', authRequired, async (req, res) => {
    try {
      if (!requireProvider(req, res)) return;
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

  router.post('/bookings/:bookingId/no-show', authRequired, async (req, res) => {
    try {
      if (!requireProvider(req, res)) return;
      const data = await markNoShow(req.params.bookingId, req.auth);
      return sendSuccess(res, { message: 'Marked as no-show', data });
    } catch (err) {
      const status = err.statusCode || 500;
      return sendError(res, err.message || 'Failed to mark no-show', status);
    }
  });

  router.get('/bookings/:bookingId/chat', authRequired, async (req, res) => {
    try {
      if (!requireProvider(req, res)) return;
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
      if (!requireProvider(req, res)) return;
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

  if (providerType === 'nurse') {
    router.post('/bookings/:bookingId/visit-note', authRequired, async (req, res) => {
      try {
        const provider = requireProvider(req, res);
        if (!provider) return;
        const data = await saveNurseVisitNote({
          bookingId: req.params.bookingId,
          nurseId: provider.id,
          careSummary: req.body?.careSummary,
          vitals: req.body?.vitals,
          proceduresDone: req.body?.proceduresDone,
          advice: req.body?.advice,
          followUpNeeded: req.body?.followUpNeeded,
        });
        return sendSuccess(res, { message: 'Care summary saved', data });
      } catch (err) {
        const status = err.statusCode || 500;
        return sendError(res, err.message || 'Failed to save visit note', status);
      }
    });

    router.get('/bookings/:bookingId/visit-note', authRequired, async (req, res) => {
      try {
        if (!requireProvider(req, res)) return;
        const data = await getNurseVisitNote(req.params.bookingId, req.auth);
        return sendSuccess(res, { data });
      } catch (err) {
        const status = err.statusCode || 500;
        return sendError(res, err.message || 'Failed to load visit note', status);
      }
    });

    router.post('/bookings/:bookingId/visit-start', authRequired, async (req, res) => {
      try {
        const provider = requireProvider(req, res);
        if (!provider) return;
        const data = await startNurseVisit({
          bookingId: req.params.bookingId,
          nurseId: provider.id,
        });
        return sendSuccess(res, { message: 'Visit started', data });
      } catch (err) {
        const status = err.statusCode || 500;
        return sendError(res, err.message || 'Failed to start visit', status);
      }
    });

    router.put('/bookings/:bookingId/visit-report', authRequired, async (req, res) => {
      try {
        const provider = requireProvider(req, res);
        if (!provider) return;
        const data = await saveNurseVisitReportDraft({
          bookingId: req.params.bookingId,
          nurseId: provider.id,
          payload: req.body,
        });
        return sendSuccess(res, { message: 'Draft saved', data });
      } catch (err) {
        const status = err.statusCode || 500;
        return sendError(res, err.message || 'Failed to save draft', status);
      }
    });

    router.post('/bookings/:bookingId/visit-report/submit', authRequired, async (req, res) => {
      try {
        const provider = requireProvider(req, res);
        if (!provider) return;
        const data = await submitNurseVisitReport({
          bookingId: req.params.bookingId,
          nurseId: provider.id,
          payload: req.body,
        });
        return sendSuccess(res, { message: 'Report submitted and PDF generated', data });
      } catch (err) {
        const status = err.statusCode || 500;
        return sendError(res, err.message || 'Failed to submit report', status);
      }
    });

    router.post('/bookings/:bookingId/visit-complete/request-otp', authRequired, async (req, res) => {
      try {
        const provider = requireProvider(req, res);
        if (!provider) return;
        const data = await requestVisitCompletionOtp({
          bookingId: req.params.bookingId,
          nurseId: provider.id,
        });
        return sendSuccess(res, { message: 'OTP sent to patient', data });
      } catch (err) {
        const status = err.statusCode || 500;
        return sendError(res, err.message || 'Failed to generate OTP', status);
      }
    });

    router.post('/bookings/:bookingId/visit-complete/verify-otp', authRequired, async (req, res) => {
      try {
        const provider = requireProvider(req, res);
        if (!provider) return;
        const data = await verifyVisitCompletionOtp({
          bookingId: req.params.bookingId,
          nurseId: provider.id,
          otp: req.body?.otp,
        });
        return sendSuccess(res, { message: 'Visit completed successfully', data });
      } catch (err) {
        const status = err.statusCode || 500;
        return sendError(res, err.message || 'OTP verification failed', status);
      }
    });

    // Public nurse feedback
    router.get('/feedback', async (req, res) => {
      try {
        const nurseId = req.query.nurseId;
        if (!nurseId) return sendError(res, 'nurseId is required', 400);
        const nurse = await Nurse.findOne({ id: nurseId }).lean();
        if (!nurse) return sendError(res, 'Nurse not found', 404);
        const reviews = await listPublicNurseFeedback(nurseId, {
          limit: req.query.limit,
        });
        return sendSuccess(res, {
          data: {
            averageRating: nurse.averageRating ?? null,
            ratingCount: nurse.ratingCount ?? 0,
            reviews,
          },
        });
      } catch (err) {
        return sendError(res, err.message || 'Failed to load feedback', 500);
      }
    });
  }
}

module.exports = { attachProviderFeatureRoutes };
