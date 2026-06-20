const express = require('express');
const {
  ensureDoctorStub,
  updateDoctorEmailVerified,
  findDoctorByEmail,
} = require('../db/repositories');
const { sendSuccess, sendError } = require('../utils/response');
const {
  sendEmailVerificationOtp,
  verifyEmailVerificationOtp,
  normalizeEmail,
  getProviderInfo,
} = require('../services/emailVerificationService');

const router = express.Router();

// GET /doctor/email/config
router.get('/config', (_req, res) => {
  return sendSuccess(res, { data: getProviderInfo() });
});

// POST /doctor/email/send-otp
router.post('/send-otp', async (req, res) => {
  try {
    const { doctorId, email } = req.body;

    if (!doctorId || !email) {
      return sendError(res, 'doctorId and email are required');
    }

    const normalizedEmail = normalizeEmail(email);
    const emailTaken = await findDoctorByEmail(normalizedEmail, doctorId);
    if (emailTaken) {
      return sendError(res, 'Email is already registered', 409);
    }

    await ensureDoctorStub(doctorId);

    const result = await sendEmailVerificationOtp({
      doctorId,
      email: normalizedEmail,
    });

    return sendSuccess(res, {
      message: result.message,
      data: result,
    });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to send verification code', 400);
  }
});

// POST /doctor/email/verify-otp
router.post('/verify-otp', async (req, res) => {
  try {
    const { doctorId, email, otp } = req.body;

    if (!doctorId || !email || !otp) {
      return sendError(res, 'doctorId, email, and otp are required');
    }

    await ensureDoctorStub(doctorId);

    const result = await verifyEmailVerificationOtp({
      doctorId,
      email,
      otp,
    });

    const doctor = await updateDoctorEmailVerified({
      doctorId,
      email: result.email,
    });

    return sendSuccess(res, {
      message: 'Email verified successfully',
      data: {
        ...result,
        doctor,
      },
    });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Email verification failed', 400);
  }
});

module.exports = router;
