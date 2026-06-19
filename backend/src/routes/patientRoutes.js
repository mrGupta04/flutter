const express = require('express');
const {
  registerPatient,
  loginPatient,
  updatePatient,
  findPatientById,
} = require('../db/patientRepositories');
const { listPatientBookings, addPreviousReportToBooking } = require('../db/bookingRepositories');
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
        profilePicture: filePublicUrl(req, profileFile.filename),
        aadhaarCardUrl: filePublicUrl(req, aadhaarFile.filename),
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
      if (profileFile) {
        updateData.profilePicture = filePublicUrl(req, profileFile.filename);
      }
      if (aadhaarFile) {
        updateData.aadhaarCardUrl = filePublicUrl(req, aadhaarFile.filename);
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
        fileUrl: filePublicUrl(req, req.file.filename),
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

module.exports = router;
