const express = require('express');
const { v4: uuidv4 } = require('uuid');
const {
  findAmbulanceById,
  findAmbulanceByEmail,
  ensureAmbulanceStub,
  updateAmbulanceProfilePicture,
  updateAmbulanceDocumentUrl,
  updateVehicleDocumentUrl,
  updateDriverDocumentUrl,
  upsertAmbulance,
  listAmbulances,
  submitAmbulanceForReview,
} = require('../db/ambulanceRepositories');
const {
  upsertDocument,
  ensureAmbulanceDocumentsFromProfile,
} = require('../db/documentVerification');
const { sendSuccess, sendError } = require('../utils/response');
const { signToken, authOptional } = require('../middleware/auth');
const { upload, filePublicUrl } = require('../middleware/multerUpload');
const { loginProvider } = require('../utils/providerAuth');
const { toAmbulance } = require('../db/ambulanceMappers');

const router = express.Router();

const { normalizeMobile, validateMobile } = require('../utils/mobile');

function parseVehicleTypes(body, existing) {
  if (Array.isArray(body.vehicleTypes)) return body.vehicleTypes;
  if (body.vehicleTypes) {
    return String(body.vehicleTypes)
      .split(',')
      .map((s) => s.trim())
      .filter(Boolean);
  }
  return existing?.vehicleTypes ?? [];
}

function buildAmbulancePayload(body, existing, ambulanceId, mobile, countryCode = '91') {
  const vehicles = Array.isArray(body.vehicles)
    ? body.vehicles
    : existing?.vehicles ?? [];
  const drivers = Array.isArray(body.drivers)
    ? body.drivers
    : existing?.drivers ?? [];

  return {
    id: ambulanceId,
    serviceName: body.serviceName?.trim(),
    ownerName: body.ownerName?.trim(),
    email: body.email?.trim().toLowerCase(),
    mobileNumber: mobile || body.mobileNumber,
    countryCode: countryCode || body.countryCode || '91',
    profilePicture: body.profilePicture?.trim(),
    emergencyContact:
      normalizeMobile(body.emergencyContact) || body.emergencyContact,
    licenseNumber: body.licenseNumber?.trim(),
    registrationNumber: body.registrationNumber?.trim(),
    panNumber: body.panNumber?.trim()?.toUpperCase(),
    gstNumber: body.gstNumber?.trim()?.toUpperCase(),
    companyRegistrationNumber: body.companyRegistrationNumber?.trim(),
    vehicleCount: vehicles.length || parseInt(body.vehicleCount, 10) || 0,
    vehicleTypes: parseVehicleTypes(body, existing),
    vehicles,
    drivers,
    address: body.address?.trim(),
    city: body.city?.trim(),
    state: body.state?.trim(),
    pincode: body.pincode?.trim(),
    latitude: body.latitude != null ? Number(body.latitude) : undefined,
    longitude: body.longitude != null ? Number(body.longitude) : undefined,
    serviceArea: body.serviceArea?.trim(),
    available24x7: body.available24x7 != null
      ? Boolean(body.available24x7)
      : undefined,
    serviceLicenseUrl: body.serviceLicenseUrl?.trim(),
    companyRegistrationUrl: body.companyRegistrationUrl?.trim(),
    gstCertificateUrl: body.gstCertificateUrl?.trim(),
    fleetInsuranceUrl: body.fleetInsuranceUrl?.trim(),
    bankAccountHolderName: body.bankAccountHolderName?.trim(),
    bankAccountNumber: body.bankAccountNumber?.trim(),
    ifscCode: body.ifscCode?.trim()?.toUpperCase(),
    bankName: body.bankName?.trim(),
    cancelledChequeUrl: body.cancelledChequeUrl?.trim(),
    password: body.password,
  };
}

router.get('/verified', async (req, res) => {
  try {
    const page = Math.max(1, parseInt(req.query.page || '1', 10));
    const pageSize = Math.min(50, parseInt(req.query.pageSize || '20', 10));
    const search = req.query.q || req.query.search || '';
    const city = req.query.city || '';
    const available24x7 = req.query.available24x7 || '';
    const vehicleType = req.query.vehicleType || '';

    const { ambulances, pagination } = await listAmbulances({
      status: 'verified',
      page,
      pageSize,
      search,
      city,
      available24x7,
      vehicleType,
    });

    return sendSuccess(res, { data: ambulances, pagination });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to list ambulances', 500);
  }
});

router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body || {};
    const result = await loginProvider({
      email,
      password,
      findByEmail: (e) => findAmbulanceByEmail(e),
      toPublic: (doc) => toAmbulance(doc),
      buildTokenPayload: (profile) => ({
        ambulanceId: profile.id,
        mobileNumber: profile.mobileNumber,
        type: 'ambulance',
      }),
    });

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

router.get('/bookings', authOptional, async (req, res) => {
  const ambulanceId = req.query.ambulanceId || req.auth?.ambulanceId;
  if (!ambulanceId) {
    return sendError(res, 'ambulanceId is required', 400);
  }
  return sendSuccess(res, { data: [], message: 'No bookings yet' });
});

router.put('/profile', authOptional, async (req, res) => {
  try {
    const body = req.body || {};
    if (!body.id) {
      return sendError(res, 'Ambulance id is required');
    }

    const existing = await findAmbulanceById(body.id);
    if (!existing) {
      return sendError(res, 'Ambulance service not found', 404);
    }

    const ambulance = await upsertAmbulance(
      buildAmbulancePayload(body, existing, body.id, null),
    );

    return sendSuccess(res, {
      message: 'Profile updated successfully',
      data: ambulance,
    });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to update profile', 500);
  }
});

router.get('/profile', authOptional, async (req, res) => {
  try {
    const ambulanceId = req.query.ambulanceId || req.auth?.ambulanceId;
    if (!ambulanceId) {
      return sendError(res, 'ambulanceId is required', 400);
    }
    const ambulance = await findAmbulanceById(ambulanceId);
    if (!ambulance) {
      return sendError(res, 'Ambulance service not found', 404);
    }
    return sendSuccess(res, { data: ambulance });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to fetch profile', 500);
  }
});

router.post('/upload-profile', upload.single('file'), async (req, res) => {
  try {
    if (!req.file) {
      return sendError(res, 'File is required');
    }

    const ambulanceId = req.body.ambulanceId;
    if (!ambulanceId) {
      return sendError(res, 'ambulanceId is required');
    }

    await ensureAmbulanceStub(ambulanceId, req.body.mobileNumber);
    const fileUrl = filePublicUrl(req, req.file.filename);
    await updateAmbulanceProfilePicture(ambulanceId, fileUrl);

    return sendSuccess(res, {
      message: 'Profile picture uploaded',
      data: { profilePicture: fileUrl },
    });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Upload failed', 500);
  }
});

router.get('/documents', authOptional, async (req, res) => {
  try {
    let ambulanceId = req.query.ambulanceId;
    if (!ambulanceId && req.auth?.ambulanceId) {
      ambulanceId = req.auth.ambulanceId;
    }
    if (!ambulanceId) {
      return sendError(res, 'ambulanceId is required', 400);
    }

    const ambulance = await findAmbulanceById(ambulanceId);
    if (!ambulance) {
      return sendError(res, 'Ambulance service not found', 404);
    }

    const documents = await ensureAmbulanceDocumentsFromProfile(ambulance);
    return sendSuccess(res, { data: documents });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to fetch documents', 500);
  }
});

router.post('/upload-document', upload.single('file'), async (req, res) => {
  try {
    if (!req.file) {
      return sendError(res, 'File is required');
    }

    const { ambulanceId, documentType, vehicleId, driverId } = req.body || {};
    if (!ambulanceId || !documentType) {
      return sendError(res, 'ambulanceId and documentType are required');
    }

    await ensureAmbulanceStub(ambulanceId, req.body.mobileNumber);
    const fileUrl = filePublicUrl(req, req.file.filename);

    let ambulance;
    if (vehicleId) {
      ambulance = await updateVehicleDocumentUrl(
        ambulanceId,
        vehicleId,
        documentType,
        fileUrl,
      );
    } else if (driverId) {
      ambulance = await updateDriverDocumentUrl(
        ambulanceId,
        driverId,
        documentType,
        fileUrl,
      );
    } else {
      ambulance = await updateAmbulanceDocumentUrl(
        ambulanceId,
        documentType,
        fileUrl,
      );
    }

    const document = await upsertDocument({
      ambulanceId,
      vehicleId: vehicleId || undefined,
      driverId: driverId || undefined,
      documentType,
      fileUrl,
      fileName: req.file.originalname,
      fileSize: req.file.size,
      mimeType: req.file.mimetype,
    });

    return sendSuccess(res, {
      message: 'Document uploaded successfully',
      data: { fileUrl, ambulance, document },
    });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Upload failed', 500);
  }
});

router.post('/register', async (req, res) => {
  try {
    const body = req.body || {};
    const ambulanceId = body.id || uuidv4();
    const mobileCheck = validateMobile(body.mobileNumber, {
      countryCode: body.countryCode,
    });
    if (!mobileCheck.valid) {
      return sendError(res, mobileCheck.error, 400);
    }
    const mobile = mobileCheck.mobile;

    if (body.emergencyContact) {
      const emergencyCheck = validateMobile(body.emergencyContact, {
        countryCode: body.emergencyCountryCode || body.countryCode,
      });
      if (!emergencyCheck.valid) {
        return sendError(res, `Emergency contact: ${emergencyCheck.error}`, 400);
      }
    }

    if (body.email) {
      const emailTaken = await findAmbulanceByEmail(
        body.email.trim().toLowerCase(),
        ambulanceId,
      );
      if (emailTaken) {
        return sendError(res, 'Email already registered', 409);
      }
    }

    const ambulance = await submitAmbulanceForReview(
      (
        await upsertAmbulance(
          buildAmbulancePayload(body, null, ambulanceId, mobile, mobileCheck.countryCode),
        )
      ).id,
    );

    const token = signToken(
      { ambulanceId: ambulance.id, mobileNumber: ambulance.mobileNumber, type: 'ambulance' },
      '30d',
    );

    return res.status(200).json({
      success: true,
      message: 'Application submitted for admin review',
      statusCode: 200,
      data: ambulance,
      token,
    });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Registration failed', 500);
  }
});

module.exports = router;
