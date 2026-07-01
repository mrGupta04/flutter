const express = require('express');
const { v4: uuidv4 } = require('uuid');

const {
  findScanCenterById,
  findScanCenterByEmail,
  ensureScanCenterStub,
  updateScanCenterProfilePicture,
  addScanCenterDocument,
  addScanCenterImage,
  upsertScanCenter,
  listScanCenters,
  submitScanCenterForReview,
} = require('../db/scanCenterRepositories');
const { sendSuccess, sendError } = require('../utils/response');
const { signToken, authOptional } = require('../middleware/auth');
const { upload, filePublicUrl } = require('../middleware/multerUpload');
const { loginProvider } = require('../utils/providerAuth');
const { toScanCenter } = require('../db/scanCenterMappers');
const { validateMobile } = require('../utils/mobile');

const router = express.Router();

router.get('/verified', async (req, res) => {
  try {
    const page = Math.max(1, parseInt(req.query.page || '1', 10));
    const pageSize = Math.min(50, parseInt(req.query.pageSize || '20', 10));
    const search = req.query.q || req.query.search || '';
    const city = req.query.city || '';
    const scanId = req.query.scanId || req.query.testId || '';
    const categoryId = req.query.categoryId || req.query.category || '';
    const homeVisit = req.query.homeVisit || '';
    const hasOffer = req.query.hasOffer || req.query.discount || '';
    const minPrice = req.query.minPrice || '';
    const maxPrice = req.query.maxPrice || '';
    const openNow = req.query.openNow || '';
    const latitude = req.query.latitude || req.query.lat || '';
    const longitude = req.query.longitude || req.query.lng || '';

    const { scanCenters, pagination } = await listScanCenters({
      status: 'verified',
      page,
      pageSize,
      search,
      city,
      scanId,
      categoryId,
      homeVisit,
      hasOffer,
      minPrice,
      maxPrice,
      openNow,
      latitude,
      longitude,
    });

    return sendSuccess(res, { data: scanCenters, pagination });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to list scan centers', 500);
  }
});

router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body || {};
    const result = await loginProvider({
      email,
      password,
      findByEmail: (e) => findScanCenterByEmail(e),
      toPublic: (doc) => toScanCenter(doc),
      buildTokenPayload: (profile) => ({
        scanCenterId: profile.id,
        mobileNumber: profile.mobileNumber,
        type: 'scan_center',
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

router.get('/profile', authOptional, async (req, res) => {
  try {
    const scanCenterId = req.query.scanCenterId || req.auth?.scanCenterId;
    if (!scanCenterId) {
      return sendError(res, 'scanCenterId is required', 400);
    }
    const center = await findScanCenterById(scanCenterId);
    if (!center) {
      return sendError(res, 'Scan center not found', 404);
    }
    return sendSuccess(res, { data: center });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to fetch profile', 500);
  }
});

router.put('/profile', authOptional, async (req, res) => {
  try {
    const body = req.body || {};
    if (!body.id) {
      return sendError(res, 'Scan center id is required');
    }

    const existing = await findScanCenterById(body.id);
    if (!existing) {
      return sendError(res, 'Scan center not found', 404);
    }

    const center = await upsertScanCenter({
      id: body.id,
      centerName: body.centerName?.trim(),
      ownerName: body.ownerName?.trim(),
      email: body.email?.trim().toLowerCase(),
      mobileNumber: body.mobileNumber,
      profilePicture: body.profilePicture?.trim(),
      address: body.address?.trim(),
      city: body.city?.trim(),
      state: body.state?.trim(),
      pincode: body.pincode?.trim(),
      latitude: body.latitude,
      longitude: body.longitude,
      gstNumber: body.gstNumber?.trim(),
      licenseNumber: body.licenseNumber?.trim(),
      operatingHours: body.operatingHours?.trim(),
      homeVisitAvailable: body.homeVisitAvailable,
      available24x7: body.available24x7,
      cashPaymentEnabled: body.cashPaymentEnabled,
      offeredScans: body.offeredScans,
      offers: body.offers,
      appointmentSlots: body.appointmentSlots,
      centerImages: body.centerImages,
      documents: body.documents,
    });

    return sendSuccess(res, {
      message: 'Profile updated successfully',
      data: center,
    });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to update profile', 500);
  }
});

router.post('/upload-profile', upload.single('file'), async (req, res) => {
  try {
    if (!req.file) {
      return sendError(res, 'File is required');
    }

    const scanCenterId = req.body.scanCenterId;
    if (!scanCenterId) {
      return sendError(res, 'scanCenterId is required');
    }

    await ensureScanCenterStub(scanCenterId, req.body.mobileNumber);
    const fileUrl = await filePublicUrl(req, req.file);
    await updateScanCenterProfilePicture(scanCenterId, fileUrl);

    return sendSuccess(res, {
      message: 'Scan center logo uploaded',
      data: { profilePicture: fileUrl },
    });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Upload failed', 500);
  }
});

router.post('/upload-document', upload.single('file'), async (req, res) => {
  try {
    if (!req.file) {
      return sendError(res, 'File is required');
    }

    const scanCenterId = req.body.scanCenterId;
    const docType = req.body.type || 'license';
    const docLabel = req.body.label || docType;
    if (!scanCenterId) {
      return sendError(res, 'scanCenterId is required');
    }

    await ensureScanCenterStub(scanCenterId, req.body.mobileNumber);
    const fileUrl = await filePublicUrl(req, req.file);
    const document = {
      id: uuidv4(),
      type: docType,
      label: docLabel,
      url: fileUrl,
      verificationStatus: 'pending',
    };
    await addScanCenterDocument(scanCenterId, document);

    return sendSuccess(res, {
      message: 'Document uploaded',
      data: document,
    });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Upload failed', 500);
  }
});

router.post('/upload-image', upload.single('file'), async (req, res) => {
  try {
    if (!req.file) {
      return sendError(res, 'File is required');
    }

    const scanCenterId = req.body.scanCenterId;
    if (!scanCenterId) {
      return sendError(res, 'scanCenterId is required');
    }

    await ensureScanCenterStub(scanCenterId, req.body.mobileNumber);
    const fileUrl = await filePublicUrl(req, req.file);
    await addScanCenterImage(scanCenterId, fileUrl);

    return sendSuccess(res, {
      message: 'Center image uploaded',
      data: { url: fileUrl },
    });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Upload failed', 500);
  }
});

router.post('/register', async (req, res) => {
  try {
    const body = req.body || {};
    const scanCenterId = body.id || uuidv4();

    const mobileCheck = validateMobile(body.mobileNumber, {
      countryCode: body.countryCode,
    });
    if (!mobileCheck.valid) {
      return sendError(res, mobileCheck.error, 400);
    }
    const mobile = mobileCheck.mobile;

    if (!body.licenseNumber?.trim()) {
      return sendError(res, 'Registration/License number is required', 400);
    }

    if (body.email) {
      const emailTaken = await findScanCenterByEmail(
        body.email.trim().toLowerCase(),
        scanCenterId,
      );
      if (emailTaken) {
        return sendError(res, 'Email already registered', 409);
      }
    }

    const center = await submitScanCenterForReview(
      (
        await upsertScanCenter({
          id: scanCenterId,
          centerName: body.centerName?.trim(),
          ownerName: body.ownerName?.trim(),
          email: body.email?.trim().toLowerCase(),
          mobileNumber: mobile || body.mobileNumber,
          countryCode: mobileCheck.countryCode,
          profilePicture: body.profilePicture?.trim(),
          address: body.address?.trim(),
          city: body.city?.trim(),
          state: body.state?.trim(),
          pincode: body.pincode?.trim(),
          latitude: body.latitude,
          longitude: body.longitude,
          gstNumber: body.gstNumber?.trim(),
          licenseNumber: body.licenseNumber?.trim(),
          operatingHours: body.operatingHours?.trim(),
          homeVisitAvailable: Boolean(body.homeVisitAvailable),
          available24x7: Boolean(body.available24x7),
          cashPaymentEnabled: body.cashPaymentEnabled !== false,
          offeredScans: Array.isArray(body.offeredScans) ? body.offeredScans : [],
          offers: Array.isArray(body.offers) ? body.offers : [],
          appointmentSlots: Array.isArray(body.appointmentSlots)
            ? body.appointmentSlots
            : [],
          centerImages: Array.isArray(body.centerImages) ? body.centerImages : [],
          documents: Array.isArray(body.documents) ? body.documents : [],
          password: body.password,
        })
      ).id,
    );

    const token = signToken(
      {
        scanCenterId: center.id,
        mobileNumber: center.mobileNumber,
        type: 'scan_center',
      },
      '30d',
    );

    return res.status(200).json({
      success: true,
      message: 'Scan center application submitted for admin review',
      statusCode: 200,
      data: center,
      token,
    });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Registration failed', 500);
  }
});

module.exports = router;
