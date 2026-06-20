const express = require('express');
const { ensureDoctorStub, updateDoctorAadhaarVerified } = require('../db/repositories');
const { sendSuccess, sendError } = require('../utils/response');
const {
  sendAadhaarOtp,
  verifyAadhaarOtp,
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

    const result = await sendAadhaarOtp({
      doctorId,
      aadhaarNumber,
      mobileNumber,
    });

    return sendSuccess(res, {
      message: result.message,
      data: result,
    });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to send OTP', 400);
  }
});

// POST /doctor/aadhaar/verify-otp
router.post('/verify-otp', async (req, res) => {
  try {
    const { doctorId, aadhaarNumber, otp } = req.body;

    if (!doctorId || !aadhaarNumber || !otp) {
      return sendError(res, 'doctorId, aadhaarNumber, and otp are required');
    }

    const result = await verifyAadhaarOtp({
      doctorId,
      aadhaarNumber,
      otp,
    });

    const aadhaar = normalizeAadhaar(aadhaarNumber);
    const doctor = await updateDoctorAadhaarVerified({
      doctorId,
      aadhaarLast4: result.aadhaarLast4,
      mobileNumber: result.mobileNumber,
    });

    return sendSuccess(res, {
      message: 'Aadhaar verified successfully',
      data: {
        ...result,
        doctor,
      },
    });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'OTP verification failed', 400);
  }
});

module.exports = router;
