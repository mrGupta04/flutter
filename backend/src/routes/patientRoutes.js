const express = require('express');
const {
  registerPatient,
  loginPatient,
  updatePatient,
  findPatientById,
  upsertFamilyMember,
  deleteFamilyMember,
  upsertSavedAddress,
  deleteSavedAddress,
} = require('../db/patientRepositories');
const { listPatientBookings, addPreviousReportToBooking } = require('../db/bookingRepositories');
const {
  sendPatientPasswordResetOtp,
  resetPatientPassword,
} = require('../services/patientPasswordResetService');
const { sendSuccess, sendError } = require('../utils/response');
const { signToken, authRequired } = require('../middleware/auth');
const { upload, filePublicUrl } = require('../middleware/multerUpload');
const { normalizeUploadUrl } = require('../utils/uploadUrl');

const router = express.Router();

function requirePatientAuth(req, res) {
  if (req.auth?.type !== 'patient' || !req.auth?.patientId) {
    sendError(res, 'Patient authentication required', 401);
    return null;
  }
  return req.auth.patientId;
}

// POST /patient/forgot-password — send OTP (does not reveal if email exists)
router.post('/forgot-password', async (req, res) => {
  try {
    const result = await sendPatientPasswordResetOtp({
      email: req.body?.email,
    });
    return sendSuccess(res, {
      message: result.message,
      data: result,
    });
  } catch (err) {
    console.error(err);
    return sendError(
      res,
      err.message || 'Failed to send reset code',
      err.statusCode || 500,
    );
  }
});

// POST /patient/reset-password — verify OTP and set new password
router.post('/reset-password', async (req, res) => {
  try {
    const result = await resetPatientPassword({
      email: req.body?.email,
      otp: req.body?.otp,
      newPassword: req.body?.newPassword || req.body?.password,
    });
    return sendSuccess(res, {
      message: result.message,
      data: result,
    });
  } catch (err) {
    console.error(err);
    return sendError(
      res,
      err.message || 'Failed to reset password',
      err.statusCode || 500,
    );
  }
});

// POST /patient/register — multipart: profile + Aadhaar card + fields
router.post(
  '/register',
  upload.fields([
    { name: 'profilePicture', maxCount: 1 },
    { name: 'aadhaarCard', maxCount: 1 },
  ]),
  async (req, res) => {
    try {
      const profileFile = req.files?.profilePicture?.[0];
      const aadhaarFile = req.files?.aadhaarCard?.[0];

      if (!profileFile) {
        return sendError(res, 'Profile picture is required', 400);
      }
      if (!aadhaarFile) {
        return sendError(res, 'Aadhaar card image is required', 400);
      }

      const {
        firstName,
        lastName,
        email,
        mobileNumber,
        password,
        age,
        gender,
        aadhaarNumber,
        referralCode,
      } = req.body || {};

      const patient = await registerPatient({
        firstName,
        lastName,
        email,
        mobileNumber,
        password,
        age,
        gender,
        aadhaarNumber,
        referralCode,
        profilePicture: await filePublicUrl(req, profileFile),
        aadhaarCardUrl: await filePublicUrl(req, aadhaarFile),
      });

      const token = signToken(
        {
          patientId: patient.id,
          type: 'patient',
          email: patient.email,
        },
        '30d',
      );

      return res.status(201).json({
        success: true,
        message: 'Account created successfully',
        statusCode: 201,
        data: patient,
        token,
      });
    } catch (err) {
      console.error(err);
      const status = err.statusCode || 500;
      return sendError(res, err.message || 'Registration failed', status);
    }
  },
);

// POST /patient/login
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body || {};
    const patient = await loginPatient(email, password);

    const token = signToken(
      {
        patientId: patient.id,
        type: 'patient',
        email: patient.email,
      },
      '30d',
    );

    return sendSuccess(res, {
      message: 'Login successful',
      data: patient,
      token,
    });
  } catch (err) {
    console.error(err);
    const status = err.statusCode || 500;
    return sendError(res, err.message || 'Login failed', status);
  }
});

// GET /patient/profile
router.get('/profile', authRequired, async (req, res) => {
  try {
    const patientId = requirePatientAuth(req, res);
    if (!patientId) return;

    const patient = await findPatientById(patientId);
    if (!patient) {
      return sendError(res, 'Patient not found', 404);
    }

    return sendSuccess(res, {
      data: {
        ...patient,
        profilePicture: normalizeUploadUrl(patient.profilePicture),
        aadhaarCardUrl: normalizeUploadUrl(patient.aadhaarCardUrl),
      },
    });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to load profile', 500);
  }
});

// PUT /patient/profile — update profile (optional multipart images)
router.put(
  '/profile',
  authRequired,
  upload.fields([
    { name: 'profilePicture', maxCount: 1 },
    { name: 'aadhaarCard', maxCount: 1 },
  ]),
  async (req, res) => {
    try {
      const patientId = requirePatientAuth(req, res);
      if (!patientId) return;

      const profileFile = req.files?.profilePicture?.[0];
      const aadhaarFile = req.files?.aadhaarCard?.[0];
      const body = req.body || {};

      const updateData = { ...body };
      if (typeof updateData.medicalProfile === 'string') {
        try {
          updateData.medicalProfile = JSON.parse(updateData.medicalProfile);
        } catch {
          /* ignore invalid JSON */
        }
      }
      if (profileFile) {
        updateData.profilePicture = await filePublicUrl(req, profileFile);
      }
      if (aadhaarFile) {
        updateData.aadhaarCardUrl = await filePublicUrl(req, aadhaarFile);
      }

      const patient = await updatePatient(patientId, updateData);

      return sendSuccess(res, {
        message: 'Profile updated successfully',
        data: patient,
      });
    } catch (err) {
      console.error(err);
      const status = err.statusCode || 500;
      return sendError(res, err.message || 'Failed to update profile', status);
    }
  },
);

// PUT /patient/medical-profile
router.put('/medical-profile', authRequired, async (req, res) => {
  try {
    const patientId = requirePatientAuth(req, res);
    if (!patientId) return;
    const patient = await updatePatient(patientId, {
      medicalProfile: req.body || {},
    });
    return sendSuccess(res, {
      message: 'Medical profile updated',
      data: patient,
    });
  } catch (err) {
    console.error(err);
    return sendError(
      res,
      err.message || 'Failed to update medical profile',
      err.statusCode || 500,
    );
  }
});

// POST /patient/family-members
router.post('/family-members', authRequired, async (req, res) => {
  try {
    const patientId = requirePatientAuth(req, res);
    if (!patientId) return;
    const patient = await upsertFamilyMember(patientId, req.body || {});
    return sendSuccess(res, {
      message: 'Family member saved',
      data: patient,
    });
  } catch (err) {
    console.error(err);
    return sendError(
      res,
      err.message || 'Failed to save family member',
      err.statusCode || 500,
    );
  }
});

router.put('/family-members/:memberId', authRequired, async (req, res) => {
  try {
    const patientId = requirePatientAuth(req, res);
    if (!patientId) return;
    const patient = await upsertFamilyMember(patientId, {
      ...(req.body || {}),
      id: req.params.memberId,
    });
    return sendSuccess(res, {
      message: 'Family member updated',
      data: patient,
    });
  } catch (err) {
    console.error(err);
    return sendError(
      res,
      err.message || 'Failed to update family member',
      err.statusCode || 500,
    );
  }
});

router.delete('/family-members/:memberId', authRequired, async (req, res) => {
  try {
    const patientId = requirePatientAuth(req, res);
    if (!patientId) return;
    const patient = await deleteFamilyMember(patientId, req.params.memberId);
    return sendSuccess(res, {
      message: 'Family member removed',
      data: patient,
    });
  } catch (err) {
    console.error(err);
    return sendError(
      res,
      err.message || 'Failed to remove family member',
      err.statusCode || 500,
    );
  }
});

router.post('/addresses', authRequired, async (req, res) => {
  try {
    const patientId = requirePatientAuth(req, res);
    if (!patientId) return;
    const patient = await upsertSavedAddress(patientId, req.body || {});
    return sendSuccess(res, {
      message: 'Address saved',
      data: patient,
    });
  } catch (err) {
    console.error(err);
    return sendError(
      res,
      err.message || 'Failed to save address',
      err.statusCode || 500,
    );
  }
});

router.put('/addresses/:addressId', authRequired, async (req, res) => {
  try {
    const patientId = requirePatientAuth(req, res);
    if (!patientId) return;
    const patient = await upsertSavedAddress(patientId, {
      ...(req.body || {}),
      id: req.params.addressId,
    });
    return sendSuccess(res, {
      message: 'Address updated',
      data: patient,
    });
  } catch (err) {
    console.error(err);
    return sendError(
      res,
      err.message || 'Failed to update address',
      err.statusCode || 500,
    );
  }
});

router.delete('/addresses/:addressId', authRequired, async (req, res) => {
  try {
    const patientId = requirePatientAuth(req, res);
    if (!patientId) return;
    const patient = await deleteSavedAddress(patientId, req.params.addressId);
    return sendSuccess(res, {
      message: 'Address removed',
      data: patient,
    });
  } catch (err) {
    console.error(err);
    return sendError(
      res,
      err.message || 'Failed to remove address',
      err.statusCode || 500,
    );
  }
});

// POST /patient/bookings/:bookingId/previous-reports
router.post(
  '/bookings/:bookingId/previous-reports',
  authRequired,
  upload.single('file'),
  async (req, res) => {
    try {
      const patientId = requirePatientAuth(req, res);
      if (!patientId) return;

      if (!req.file) {
        return sendError(res, 'File is required', 400);
      }

      const patient = await findPatientById(patientId);
      if (!patient) {
        return sendError(res, 'Patient not found', 404);
      }

      const report = await addPreviousReportToBooking({
        bookingId: req.params.bookingId,
        patientId,
        mobileNumber: patient.mobileNumber,
        fileUrl: await filePublicUrl(req, req.file),
        fileName: req.file.originalname,
        mimeType: req.file.mimetype,
      });

      return sendSuccess(res, {
        message: 'Report uploaded',
        data: report,
      });
    } catch (err) {
      console.error(err);
      const status = err.statusCode || 500;
      return sendError(res, err.message || 'Failed to upload report', status);
    }
  },
);

// GET /patient/bookings
router.get('/bookings', authRequired, async (req, res) => {
  try {
    const patientId = requirePatientAuth(req, res);
    if (!patientId) return;

    const patient = await findPatientById(patientId);
    if (!patient) {
      return sendError(res, 'Patient not found', 404);
    }

    const bookings = await listPatientBookings(
      patientId,
      patient.mobileNumber,
      patient.email,
    );

    const upcoming = bookings.filter((b) => b.isUpcoming).length;

    return sendSuccess(res, {
      data: {
        bookings,
        stats: {
          total: bookings.length,
          upcoming,
          past: bookings.length - upcoming,
        },
      },
    });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to load bookings', 500);
  }
});

// POST /patient/coupons/validate
router.post('/coupons/validate', authRequired, async (req, res) => {
  try {
    const patientId = requirePatientAuth(req, res);
    if (!patientId) return;
    const { validateCoupon } = require('../db/couponRepositories');
    const result = await validateCoupon({
      code: req.body?.code,
      orderAmountInr: req.body?.orderAmountInr ?? req.body?.amount,
      applicableTo: req.body?.applicableTo || 'consultation',
    });
    return sendSuccess(res, {
      message: 'Coupon applied',
      data: result,
    });
  } catch (err) {
    console.error(err);
    return sendError(
      res,
      err.message || 'Invalid coupon',
      err.statusCode || 500,
    );
  }
});

// Support tickets
router.post('/support-tickets', authRequired, async (req, res) => {
  try {
    const patientId = requirePatientAuth(req, res);
    if (!patientId) return;
    const patient = await findPatientById(patientId);
    const {
      createSupportTicket,
    } = require('../db/supportTicketRepositories');
    const ticket = await createSupportTicket({
      ...(req.body || {}),
      patientId,
      patientName: patient
        ? `${patient.firstName} ${patient.lastName || ''}`.trim()
        : undefined,
      patientEmail: patient?.email,
      patientMobile: patient?.mobileNumber,
    });
    return res.status(201).json({
      success: true,
      message: 'Support ticket created. We will get back to you soon.',
      statusCode: 201,
      data: ticket,
    });
  } catch (err) {
    console.error(err);
    return sendError(
      res,
      err.message || 'Failed to create ticket',
      err.statusCode || 500,
    );
  }
});

router.get('/support-tickets', authRequired, async (req, res) => {
  try {
    const patientId = requirePatientAuth(req, res);
    if (!patientId) return;
    const {
      listTicketsForPatient,
    } = require('../db/supportTicketRepositories');
    const tickets = await listTicketsForPatient(patientId);
    return sendSuccess(res, { data: tickets });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to load tickets', 500);
  }
});

// GET /patient/rewards
router.get('/rewards', authRequired, async (req, res) => {
  try {
    const patientId = requirePatientAuth(req, res);
    if (!patientId) return;
    const { getRewardsSummary } = require('../db/rewardRepositories');
    const summary = await getRewardsSummary(patientId);
    return sendSuccess(res, { data: summary });
  } catch (err) {
    console.error(err);
    return sendError(
      res,
      err.message || 'Failed to load rewards',
      err.statusCode || 500,
    );
  }
});

// POST /patient/rewards/redeem
router.post('/rewards/redeem', authRequired, async (req, res) => {
  try {
    const patientId = requirePatientAuth(req, res);
    if (!patientId) return;
    const { redeemRewardPoints } = require('../db/rewardRepositories');
    const result = await redeemRewardPoints(
      patientId,
      req.body?.points != null ? Number(req.body.points) : 100,
    );
    return sendSuccess(res, {
      message: result.message,
      data: result,
    });
  } catch (err) {
    console.error(err);
    return sendError(
      res,
      err.message || 'Failed to redeem points',
      err.statusCode || 500,
    );
  }
});

module.exports = router;
