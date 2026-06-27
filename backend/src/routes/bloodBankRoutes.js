const express = require('express');

const { v4: uuidv4 } = require('uuid');

const {

  findBloodBankById,

  findBloodBankByEmail,

  ensureBloodBankStub,

  updateBloodBankProfilePicture,

  upsertBloodBank,

  listBloodBanks,

  submitBloodBankForReview,

} = require('../db/bloodBankRepositories');

const { sendSuccess, sendError } = require('../utils/response');

const { signToken, authOptional } = require('../middleware/auth');

const { upload, filePublicUrl } = require('../middleware/multerUpload');

const { loginProvider } = require('../utils/providerAuth');

const { toBloodBank } = require('../db/bloodBankMappers');



const router = express.Router();



const { normalizeMobile, validateMobile } = require('../utils/mobile');



router.get('/verified', async (req, res) => {

  try {

    const page = Math.max(1, parseInt(req.query.page || '1', 10));

    const pageSize = Math.min(50, parseInt(req.query.pageSize || '20', 10));

    const search = req.query.q || req.query.search || '';

    const city = req.query.city || '';

    const available24x7 = req.query.available24x7 || '';

    const bloodGroup = req.query.bloodGroup || '';

    const hasApheresis = req.query.hasApheresis || '';



    const { bloodBanks, pagination } = await listBloodBanks({

      status: 'verified',

      page,

      pageSize,

      search,

      city,

      available24x7,

      bloodGroup,

      hasApheresis,

    });



    return sendSuccess(res, { data: bloodBanks, pagination });

  } catch (err) {

    console.error(err);

    return sendError(res, err.message || 'Failed to list blood banks', 500);

  }

});



router.post('/login', async (req, res) => {

  try {

    const { email, password } = req.body || {};

    const result = await loginProvider({

      email,

      password,

      findByEmail: (e) => findBloodBankByEmail(e),

      toPublic: (doc) => toBloodBank(doc),

      buildTokenPayload: (profile) => ({

        bloodBankId: profile.id,

        mobileNumber: profile.mobileNumber,

        type: 'bloodbank',

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

  const bloodBankId = req.query.bloodBankId || req.auth?.bloodBankId;

  if (!bloodBankId) {

    return sendError(res, 'bloodBankId is required', 400);

  }

  return sendSuccess(res, { data: [], message: 'No bookings yet' });

});



router.put('/profile', authOptional, async (req, res) => {

  try {

    const body = req.body || {};

    if (!body.id) {

      return sendError(res, 'Blood bank id is required');

    }



    const existing = await findBloodBankById(body.id);

    if (!existing) {

      return sendError(res, 'Blood bank not found', 404);

    }



    const bloodGroupsAvailable = Array.isArray(body.bloodGroupsAvailable)

      ? body.bloodGroupsAvailable

      : body.bloodGroupsAvailable

        ? String(body.bloodGroupsAvailable).split(',').map((s) => s.trim().toUpperCase()).filter(Boolean)

        : existing.bloodGroupsAvailable;



    const bloodBank = await upsertBloodBank({

      id: body.id,

      institutionName: body.institutionName?.trim(),

      licenseNumber: body.licenseNumber?.trim(),

      contactPerson: body.contactPerson?.trim(),

      email: body.email?.trim().toLowerCase(),

      mobileNumber: body.mobileNumber,

      profilePicture: body.profilePicture?.trim(),

      emergencyContact: body.emergencyContact,

      address: body.address?.trim(),

      city: body.city?.trim(),

      state: body.state?.trim(),

      pincode: body.pincode?.trim(),

      bloodGroupsAvailable,

      hasApheresis: body.hasApheresis != null ? Boolean(body.hasApheresis) : existing.hasApheresis,

      hasComponentSeparation: body.hasComponentSeparation != null

        ? Boolean(body.hasComponentSeparation)

        : existing.hasComponentSeparation,

      available24x7: body.available24x7 != null ? Boolean(body.available24x7) : existing.available24x7,

    });



    return sendSuccess(res, {

      message: 'Profile updated successfully',

      data: bloodBank,

    });

  } catch (err) {

    console.error(err);

    return sendError(res, err.message || 'Failed to update profile', 500);

  }

});



router.get('/profile', authOptional, async (req, res) => {

  try {

    const bloodBankId = req.query.bloodBankId || req.auth?.bloodBankId;

    if (!bloodBankId) {

      return sendError(res, 'bloodBankId is required', 400);

    }

    const bloodBank = await findBloodBankById(bloodBankId);

    if (!bloodBank) {

      return sendError(res, 'Blood bank not found', 404);

    }

    return sendSuccess(res, { data: bloodBank });

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



    const bloodBankId = req.body.bloodBankId;

    if (!bloodBankId) {

      return sendError(res, 'bloodBankId is required');

    }



    await ensureBloodBankStub(bloodBankId, req.body.mobileNumber);

    const fileUrl = await filePublicUrl(req, req.file);

    await updateBloodBankProfilePicture(bloodBankId, fileUrl);



    return sendSuccess(res, {

      message: 'Profile picture uploaded',

      data: { profilePicture: fileUrl },

    });

  } catch (err) {

    console.error(err);

    return sendError(res, err.message || 'Upload failed', 500);

  }

});



router.post('/register', async (req, res) => {

  try {

    const body = req.body || {};

    const bloodBankId = body.id || uuidv4();

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

      const emailTaken = await findBloodBankByEmail(

        body.email.trim().toLowerCase(),

        bloodBankId,

      );

      if (emailTaken) {

        return sendError(res, 'Email already registered', 409);

      }

    }



    const bloodGroupsAvailable = Array.isArray(body.bloodGroupsAvailable)

      ? body.bloodGroupsAvailable

      : String(body.bloodGroupsAvailable || '')

          .split(',')

          .map((s) => s.trim().toUpperCase())

          .filter(Boolean);



    const bloodBank = await submitBloodBankForReview(

      (

        await upsertBloodBank({

          id: bloodBankId,

          institutionName: body.institutionName?.trim(),

          licenseNumber: body.licenseNumber?.trim(),

          contactPerson: body.contactPerson?.trim(),

          email: body.email?.trim().toLowerCase(),

          mobileNumber: mobile || body.mobileNumber,

          countryCode: mobileCheck.countryCode,

          profilePicture: body.profilePicture?.trim(),

          emergencyContact: normalizeMobile(body.emergencyContact) || body.emergencyContact,

          address: body.address?.trim(),

          city: body.city?.trim(),

          state: body.state?.trim(),

          pincode: body.pincode?.trim(),

          bloodGroupsAvailable,

          hasApheresis: Boolean(body.hasApheresis),

          hasComponentSeparation: Boolean(body.hasComponentSeparation),

          available24x7: Boolean(body.available24x7),

          password: body.password,

        })

      ).id,

    );



    const token = signToken(

      { bloodBankId: bloodBank.id, mobileNumber: bloodBank.mobileNumber, type: 'bloodbank' },

      '30d',

    );



    return res.status(200).json({

      success: true,

      message: 'Application submitted for admin review',

      statusCode: 200,

      data: bloodBank,

      token,

    });

  } catch (err) {

    console.error(err);

    return sendError(res, err.message || 'Registration failed', 500);

  }

});



module.exports = router;

