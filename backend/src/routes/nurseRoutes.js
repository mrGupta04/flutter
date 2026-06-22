const express = require('express');

const { v4: uuidv4 } = require('uuid');

const {

  findNurseById,

  findNurseByEmail,

  ensureNurseStub,

  updateNurseProfilePicture,

  upsertNurse,

  listNurses,

  submitNurseForReview,

  findDocumentsByNurseId,
} = require('../db/nurseRepositories');

const {
  upsertDocument,
  ensureNurseDocumentsFromProfile,
} = require('../db/documentVerification');

const { sendSuccess, sendError } = require('../utils/response');

const { signToken, authOptional } = require('../middleware/auth');

const { upload, filePublicUrl } = require('../middleware/multerUpload');

const { loginProvider } = require('../utils/providerAuth');

const { toNurse } = require('../db/nurseMappers');



const router = express.Router();



const { normalizeMobile, validateMobile } = require('../utils/mobile');



// GET /nurse/verified — public list for user app

router.get('/verified', async (req, res) => {

  try {

    const page = Math.max(1, parseInt(req.query.page || '1', 10));

    const pageSize = Math.min(50, parseInt(req.query.pageSize || '20', 10));

    const search = req.query.q || req.query.search || '';

    const city = req.query.city || '';

    const specialization = req.query.specialization || '';

    const homeVisit = req.query.homeVisit || '';



    const { nurses, pagination } = await listNurses({

      status: 'verified',

      page,

      pageSize,

      search,

      city,

      specialization,

      homeVisit,

    });



    return sendSuccess(res, { data: nurses, pagination });

  } catch (err) {

    console.error(err);

    return sendError(res, err.message || 'Failed to list nurses', 500);

  }

});



// GET /nurse/profile

router.get('/profile', authOptional, async (req, res) => {

  try {

    const nurseId = req.query.nurseId || req.auth?.nurseId;

    if (!nurseId) {

      return sendError(res, 'nurseId is required', 400);

    }

    const nurse = await findNurseById(nurseId);

    if (!nurse) {

      return sendError(res, 'Nurse not found', 404);

    }

    return sendSuccess(res, { data: nurse });

  } catch (err) {

    console.error(err);

    return sendError(res, err.message || 'Failed to fetch profile', 500);

  }

});



// POST /nurse/login

router.post('/login', async (req, res) => {

  try {

    const { email, password } = req.body || {};

    const result = await loginProvider({

      email,

      password,

      findByEmail: (e) => findNurseByEmail(e),

      toPublic: (doc) => toNurse(doc),

      buildTokenPayload: (profile) => ({

        nurseId: profile.id,

        mobileNumber: profile.mobileNumber,

        type: 'nurse',

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



// GET /nurse/bookings

router.get('/bookings', authOptional, async (req, res) => {

  const nurseId = req.query.nurseId || req.auth?.nurseId;

  if (!nurseId) {

    return sendError(res, 'nurseId is required', 400);

  }

  return sendSuccess(res, { data: [], message: 'No bookings yet' });

});



// PUT /nurse/profile

router.put('/profile', authOptional, async (req, res) => {

  try {

    const body = req.body || {};

    if (!body.id) {

      return sendError(res, 'Nurse id is required');

    }



    const existing = await findNurseById(body.id);

    if (!existing) {

      return sendError(res, 'Nurse not found', 404);

    }



    const nurse = await upsertNurse({

      id: body.id,

      firstName: body.firstName?.trim(),

      lastName: body.lastName?.trim(),

      email: body.email?.trim().toLowerCase(),

      mobileNumber: body.mobileNumber,

      profilePicture: body.profilePicture?.trim(),

      qualification: body.qualification?.trim(),

      registrationNumber: body.registrationNumber?.trim(),

      nursingCouncil: body.nursingCouncil?.trim(),

      yearsOfExperience: parseInt(body.yearsOfExperience, 10) || existing.yearsOfExperience,

      specialization: body.specialization?.trim(),

      address: body.address?.trim(),

      city: body.city?.trim(),

      state: body.state?.trim(),

      pincode: body.pincode?.trim(),

      availableForHomeVisit: body.availableForHomeVisit != null

        ? Boolean(body.availableForHomeVisit)

        : existing.availableForHomeVisit,

      shiftAvailability: body.shiftAvailability?.trim(),

    });



    return sendSuccess(res, {

      message: 'Profile updated successfully',

      data: nurse,

    });

  } catch (err) {

    console.error(err);

    return sendError(res, err.message || 'Failed to update profile', 500);

  }

});



// GET /nurse/documents
router.get('/documents', authOptional, async (req, res) => {
  try {
    let nurseId = req.query.nurseId;
    if (!nurseId && req.auth?.nurseId) {
      nurseId = req.auth.nurseId;
    }
    if (!nurseId) {
      return sendError(res, 'nurseId is required', 400);
    }

    const nurse = await findNurseById(nurseId);
    if (!nurse) {
      return sendError(res, 'Nurse not found', 404);
    }

    const documents = await ensureNurseDocumentsFromProfile(nurse);
    return sendSuccess(res, { data: documents });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to fetch documents', 500);
  }
});

// POST /nurse/upload-profile
router.post('/upload-profile', upload.single('file'), async (req, res) => {
  try {
    if (!req.file) {
      return sendError(res, 'File is required');
    }

    const nurseId = req.body.nurseId;
    if (!nurseId) {
      return sendError(res, 'nurseId is required');
    }

    await ensureNurseStub(nurseId, req.body.mobileNumber);
    const fileUrl = filePublicUrl(req, req.file.filename);
    await updateNurseProfilePicture(nurseId, fileUrl);

    const document = await upsertDocument({
      nurseId,
      documentType: 'profile_picture',
      fileUrl,
      fileName: req.file.originalname,
      fileSize: req.file.size,
      mimeType: req.file.mimetype,
    });

    return sendSuccess(res, {
      message: 'Profile picture uploaded',
      data: { profilePicture: fileUrl, document },
    });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Upload failed', 500);

  }

});



// POST /nurse/register

router.post('/register', async (req, res) => {

  try {

    const body = req.body || {};

    const nurseId = body.id || uuidv4();

    const mobileCheck = validateMobile(body.mobileNumber, {
      countryCode: body.countryCode,
    });
    if (!mobileCheck.valid) {
      return sendError(res, mobileCheck.error, 400);
    }
    const mobile = mobileCheck.mobile;



    if (body.email) {

      const emailTaken = await findNurseByEmail(body.email, nurseId);

      if (emailTaken) {

        return sendError(res, 'Email already registered', 409);

      }

    }



    const nurse = await submitNurseForReview(

      (

        await upsertNurse({

          id: nurseId,

          firstName: body.firstName?.trim(),

          lastName: body.lastName?.trim(),

          email: body.email?.trim().toLowerCase(),

          mobileNumber: mobile || body.mobileNumber,

          countryCode: mobileCheck.countryCode,

          profilePicture: body.profilePicture?.trim(),

          qualification: body.qualification?.trim(),

          registrationNumber: body.registrationNumber?.trim(),

          nursingCouncil: body.nursingCouncil?.trim(),

          yearsOfExperience: parseInt(body.yearsOfExperience, 10) || 0,

          specialization: body.specialization?.trim(),

          address: body.address?.trim(),

          city: body.city?.trim(),

          state: body.state?.trim(),

          pincode: body.pincode?.trim(),

          availableForHomeVisit: Boolean(body.availableForHomeVisit),

          shiftAvailability: body.shiftAvailability?.trim(),

          password: body.password,

        })

      ).id,

    );



    const token = signToken(

      { nurseId: nurse.id, mobileNumber: nurse.mobileNumber, type: 'nurse' },

      '30d',

    );



    return res.status(200).json({

      success: true,

      message: 'Application submitted for admin review',

      statusCode: 200,

      data: nurse,

      token,

    });

  } catch (err) {

    console.error(err);

    return sendError(res, err.message || 'Registration failed', 500);

  }

});



module.exports = router;

