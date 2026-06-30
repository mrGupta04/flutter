const express = require('express');
const { v4: uuidv4 } = require('uuid');

const {
  findLabById,
  findLabByEmail,
  ensureLabStub,
  updateLabProfilePicture,
  addLabDocument,
  addLabImage,
  upsertLab,
  listLabs,
  submitLabForReview,
} = require('../db/labRepositories');
const { sendSuccess, sendError } = require('../utils/response');
const { signToken, authOptional } = require('../middleware/auth');
const { upload, filePublicUrl } = require('../middleware/multerUpload');
const { loginProvider } = require('../utils/providerAuth');
const { toLab } = require('../db/labMappers');
const { normalizeMobile, validateMobile } = require('../utils/mobile');

const router = express.Router();

router.get('/verified', async (req, res) => {
  try {
    const page = Math.max(1, parseInt(req.query.page || '1', 10));
    const pageSize = Math.min(50, parseInt(req.query.pageSize || '20', 10));
    const search = req.query.q || req.query.search || '';
    const city = req.query.city || '';
    const testId = req.query.testId || '';
    const homeCollection = req.query.homeCollection || '';
    const latitude = req.query.latitude || req.query.lat || '';
    const longitude = req.query.longitude || req.query.lng || '';

    const { labs, pagination } = await listLabs({
      status: 'verified',
      page,
      pageSize,
      search,
      city,
      testId,
      homeCollection,
      latitude,
      longitude,
    });

    return sendSuccess(res, { data: labs, pagination });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to list labs', 500);
  }
});

router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body || {};
    const result = await loginProvider({
      email,
      password,
      findByEmail: (e) => findLabByEmail(e),
      toPublic: (doc) => toLab(doc),
      buildTokenPayload: (profile) => ({
        labId: profile.id,
        mobileNumber: profile.mobileNumber,
        type: 'lab',
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
    const labId = req.query.labId || req.auth?.labId;
    if (!labId) {
      return sendError(res, 'labId is required', 400);
    }
    const lab = await findLabById(labId);
    if (!lab) {
      return sendError(res, 'Lab not found', 404);
    }
    return sendSuccess(res, { data: lab });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to fetch profile', 500);
  }
});

router.put('/profile', authOptional, async (req, res) => {
  try {
    const body = req.body || {};
    if (!body.id) {
      return sendError(res, 'Lab id is required');
    }

    const existing = await findLabById(body.id);
    if (!existing) {
      return sendError(res, 'Lab not found', 404);
    }

    const lab = await upsertLab({
      id: body.id,
      labName: body.labName?.trim(),
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
      accreditation: body.accreditation?.trim(),
      operatingHours: body.operatingHours?.trim(),
      homeCollectionAvailable: body.homeCollectionAvailable,
      available24x7: body.available24x7,
      offeredTests: body.offeredTests,
      branches: body.branches,
      serviceablePincodes: body.serviceablePincodes,
      homeVisitSlots: body.homeVisitSlots,
      labImages: body.labImages,
      documents: body.documents,
    });

    return sendSuccess(res, {
      message: 'Profile updated successfully',
      data: lab,
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

    const labId = req.body.labId;
    if (!labId) {
      return sendError(res, 'labId is required');
    }

    await ensureLabStub(labId, req.body.mobileNumber);
    const fileUrl = await filePublicUrl(req, req.file);
    await updateLabProfilePicture(labId, fileUrl);

    return sendSuccess(res, {
      message: 'Lab logo uploaded',
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

    const labId = req.body.labId;
    const docType = req.body.type || 'license';
    const docLabel = req.body.label || docType;
    if (!labId) {
      return sendError(res, 'labId is required');
    }

    await ensureLabStub(labId, req.body.mobileNumber);
    const fileUrl = await filePublicUrl(req, req.file);
    const document = {
      id: uuidv4(),
      type: docType,
      label: docLabel,
      url: fileUrl,
      verificationStatus: 'pending',
    };
    await addLabDocument(labId, document);

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

    const labId = req.body.labId;
    if (!labId) {
      return sendError(res, 'labId is required');
    }

    await ensureLabStub(labId, req.body.mobileNumber);
    const fileUrl = await filePublicUrl(req, req.file);
    await addLabImage(labId, fileUrl);

    return sendSuccess(res, {
      message: 'Lab image uploaded',
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
    const labId = body.id || uuidv4();

    const mobileCheck = validateMobile(body.mobileNumber, {
      countryCode: body.countryCode,
    });
    if (!mobileCheck.valid) {
      return sendError(res, mobileCheck.error, 400);
    }
    const mobile = mobileCheck.mobile;

    if (!body.licenseNumber?.trim()) {
      return sendError(res, 'License/Certification number is required', 400);
    }

    if (body.email) {
      const emailTaken = await findLabByEmail(
        body.email.trim().toLowerCase(),
        labId,
      );
      if (emailTaken) {
        return sendError(res, 'Email already registered', 409);
      }
    }

    const lab = await submitLabForReview(
      (
        await upsertLab({
          id: labId,
          labName: body.labName?.trim(),
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
          accreditation: body.accreditation?.trim(),
          operatingHours: body.operatingHours?.trim(),
          homeCollectionAvailable: Boolean(body.homeCollectionAvailable),
          available24x7: Boolean(body.available24x7),
          offeredTests: Array.isArray(body.offeredTests) ? body.offeredTests : [],
          branches: Array.isArray(body.branches) ? body.branches : [],
          serviceablePincodes: Array.isArray(body.serviceablePincodes)
            ? body.serviceablePincodes
            : [],
          homeVisitSlots: Array.isArray(body.homeVisitSlots)
            ? body.homeVisitSlots
            : [],
          labImages: Array.isArray(body.labImages) ? body.labImages : [],
          documents: Array.isArray(body.documents) ? body.documents : [],
          password: body.password,
        })
      ).id,
    );

    const token = signToken(
      { labId: lab.id, mobileNumber: lab.mobileNumber, type: 'lab' },
      '30d',
    );

    return res.status(200).json({
      success: true,
      message: 'Lab application submitted for admin review',
      statusCode: 200,
      data: lab,
      token,
    });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Registration failed', 500);
  }
});

module.exports = router;
