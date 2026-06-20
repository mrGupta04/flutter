const express = require('express');
const {
  ensureDoctorStub,
  updateDoctorEmailVerified,
  findDoctorByEmail,
} = require('../db/repositories');
const { sendSuccess, sendError } = require('../utils/response');
const {
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

    // Temporary bypass: skip OTP delivery until Render email stability is resolved.
    const doctor = await updateDoctorEmailVerified({
      doctorId,
      email: normalizedEmail,
    });

    return sendSuccess(res, {
      message: 'Email verification temporarily bypassed',
      data: {
        provider: 'bypass',
        bypassed: true,
        verified: true,
        doctor,
      },
    });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to send verification code', 400);
  }
});

// POST /doctor/email/verify-otp
router.post('/verify-otp', async (req, res) => {
  try {
    const { doctorId, email } = req.body;

    if (!doctorId || !email) {
      return sendError(res, 'doctorId and email are required');
    }

    await ensureDoctorStub(doctorId);
    const normalizedEmail = normalizeEmail(email);

    const doctor = await updateDoctorEmailVerified({
      doctorId,
      email: normalizedEmail,
    });

    return sendSuccess(res, {
      message: 'Email verification temporarily bypassed',
      data: {
        provider: 'bypass',
        bypassed: true,
        verified: true,
        email: normalizedEmail,
        doctor,
      },
    });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Email verification failed', 400);
  }
});

module.exports = router;
