const express = require('express');
const { sendSuccess, sendError } = require('../utils/response');
const { signToken, authRequired, receptionistRequired } = require('../middleware/auth');
const { loginReceptionist, getReceptionistById } = require('../db/receptionistRepositories');
const {
  listClinicVisitsForDoctor,
  getClinicVisitForDoctor,
  getClinicOtpStatus,
  verifyClinicVisitOtp,
  regenerateReceptionistClinicOtp,
} = require('../db/clinicVisitVerificationRepositories');

const router = express.Router();

router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body || {};
    const result = await loginReceptionist({ email, password });
    if (!result.ok) {
      return sendError(res, result.error, result.status);
    }
    const token = signToken(result.tokenPayload, '30d');
    return sendSuccess(res, {
      message: 'Login successful',
      data: result.profile,
      token,
    });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Login failed', 500);
  }
});

router.get('/me', authRequired, receptionistRequired, async (req, res) => {
  try {
    const data = await getReceptionistById(req.auth.receptionistId);
    if (!data) {
      return sendError(res, 'Receptionist not found', 404);
    }
    return sendSuccess(res, { data });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to load profile', 500);
  }
});

router.get('/bookings', authRequired, receptionistRequired, async (req, res) => {
  try {
    const filter = String(req.query.filter || 'today').trim();
    const data = await listClinicVisitsForDoctor(req.auth.doctorId, { filter });
    return sendSuccess(res, { data });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to load clinic visits', 500);
  }
});

router.get('/bookings/:bookingId', authRequired, receptionistRequired, async (req, res) => {
  try {
    const data = await getClinicVisitForDoctor(
      req.auth.doctorId,
      req.params.bookingId,
    );
    return sendSuccess(res, { data });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to load booking', err.statusCode || 500);
  }
});

router.get(
  '/bookings/:bookingId/otp-status',
  authRequired,
  receptionistRequired,
  async (req, res) => {
    try {
      const data = await getClinicOtpStatus({
        bookingId: req.params.bookingId,
        doctorId: req.auth.doctorId,
      });
      return sendSuccess(res, { data });
    } catch (err) {
      console.error(err);
      return sendError(
        res,
        err.message || 'Failed to load OTP status',
        err.statusCode || 500,
        err.code,
      );
    }
  },
);

router.post(
  '/bookings/:bookingId/verify',
  authRequired,
  receptionistRequired,
  async (req, res) => {
    try {
      const otp = req.body?.otp || req.body?.code || req.body?.appointmentCode;
      const data = await verifyClinicVisitOtp({
        bookingId: req.params.bookingId,
        otp,
        doctorId: req.auth.doctorId,
        actorType: 'receptionist',
        actorId: req.auth.receptionistId,
        actorName: req.auth.receptionistName,
      });
      return sendSuccess(res, {
        message: 'Patient has been successfully verified and marked as arrived.',
        data,
      });
    } catch (err) {
      console.error(err);
      return sendError(
        res,
        err.message || 'Verification failed',
        err.statusCode || 500,
        err.code,
      );
    }
  },
);

router.post(
  '/bookings/:bookingId/otp/regenerate',
  authRequired,
  receptionistRequired,
  async (req, res) => {
    try {
      const data = await regenerateReceptionistClinicOtp({
        bookingId: req.params.bookingId,
        doctorId: req.auth.doctorId,
      });
      return sendSuccess(res, {
        message: data.message,
        data,
      });
    } catch (err) {
      console.error(err);
      return sendError(
        res,
        err.message || 'Could not generate a new verification code',
        err.statusCode || 500,
        err.code,
      );
    }
  },
);

module.exports = router;
