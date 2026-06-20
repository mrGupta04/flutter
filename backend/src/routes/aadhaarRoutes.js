const express = require('express');
const { ensureDoctorStub, updateDoctorAadhaarVerified } = require('../db/repositories');
const { sendSuccess, sendError } = require('../utils/response');
const {
  normalizeAadhaar,
  getProviderInfo,
} = require('../services/aadhaarOtpService');

const router = express.Router();

// GET /doctor/aadhaar/config
router.get('/config', (_req, res) => {
  return sendSuccess(res, { data: getProviderInfo() });
});

// POST /doctor/aadhaar/send-otp
router.post('/send-otp', async (req, res) => {
  try {
    const { doctorId, aadhaarNumber, mobileNumber } = req.body;

    if (!doctorId || !aadhaarNumber || !mobileNumber) {
      return sendError(
        res,
        'doctorId, aadhaarNumber, and mobileNumber are required',
      );
    }

    await ensureDoctorStub(doctorId, mobileNumber);

    const normalizedAadhaar = normalizeAadhaar(aadhaarNumber);
    const result = {
      aadhaarLast4: normalizedAadhaar.slice(-4),
      mobileNumber,
    };
    // Temporary bypass: skip Aadhaar OTP send/verify until Render OTP stability is resolved.
    const doctor = await updateDoctorAadhaarVerified({
      doctorId,
      aadhaarLast4: result.aadhaarLast4,
      mobileNumber: result.mobileNumber,
    });

    return sendSuccess(res, {
      message: 'Aadhaar verification temporarily bypassed',
      data: {
        provider: 'bypass',
        bypassed: true,
        verified: true,
        ...result,
        doctor,
      },
    });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to send OTP', 400);
  }
});

// POST /doctor/aadhaar/verify-otp
router.post('/verify-otp', async (req, res) => {
  try {
    const { doctorId, aadhaarNumber } = req.body;

    if (!doctorId || !aadhaarNumber) {
      return sendError(res, 'doctorId and aadhaarNumber are required');
    }

    const aadhaar = normalizeAadhaar(aadhaarNumber);
    const doctor = await updateDoctorAadhaarVerified({
      doctorId,
      aadhaarLast4: aadhaar.slice(-4),
    });

    return sendSuccess(res, {
      message: 'Aadhaar verification temporarily bypassed',
      data: {
        provider: 'bypass',
        bypassed: true,
        verified: true,
        aadhaarLast4: aadhaar.slice(-4),
        doctor,
      },
    });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'OTP verification failed', 400);
  }
});

module.exports = router;
