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
  getNurseAvailability,
  getNurseAvailabilityStatus,
  saveNurseAvailability,
} = require('../db/nurseAvailabilityRepositories');

const {
  getNurseBookableSlots,
  holdNurseSlot,
  releaseNurseSlotHold,
  createNurseHomeVisitRequest,
  approveNurseHomeVisitRequest,
  rejectNurseHomeVisitRequest,
  listNurseBookings,
} = require('../db/nurseBookingRepositories');

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

    const gender = req.query.gender || '';



    const { nurses, pagination } = await listNurses({

      status: 'verified',

      page,

      pageSize,

      search,

      city,

      specialization,

      homeVisit,

      gender,

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

  try {

    const nurseId = req.query.nurseId || req.auth?.nurseId;

    if (!nurseId) {

      return sendError(res, 'nurseId is required', 400);

    }

    const data = await listNurseBookings(nurseId);

    return sendSuccess(res, { data });

  } catch (err) {

    console.error(err);

    return sendError(res, err.message || 'Failed to load bookings', 500);

  }

});



// GET /nurse/availability

router.get('/availability', authOptional, async (req, res) => {

  try {

    const nurseId = req.query.nurseId || req.auth?.nurseId;

    if (!nurseId) {

      return sendError(res, 'nurseId is required', 400);

    }

    const data = await getNurseAvailability(nurseId, {

      forWeekStart: req.query.weekStart,

    });

    return sendSuccess(res, { data });

  } catch (err) {

    console.error(err);

    return sendError(res, err.message || 'Failed to load availability', 500);

  }

});



// GET /nurse/availability/status

router.get('/availability/status', authOptional, async (req, res) => {

  try {

    const nurseId = req.query.nurseId || req.auth?.nurseId;

    if (!nurseId) {

      return sendError(res, 'nurseId is required', 400);

    }

    const data = await getNurseAvailabilityStatus(nurseId);

    return sendSuccess(res, { data });

  } catch (err) {

    console.error(err);

    return sendError(res, err.message || 'Failed to load availability status', 500);

  }

});



// PUT /nurse/availability

router.put('/availability', authOptional, async (req, res) => {

  try {

    const body = req.body || {};

    const nurseId = body.nurseId || req.auth?.nurseId;

    if (!nurseId) {

      return sendError(res, 'nurseId is required', 400);

    }

    const data = await saveNurseAvailability(nurseId, {

      slots: body.slots,

      weekStartDate: body.weekStartDate,

    });

    return sendSuccess(res, {

      message: 'Availability saved',

      data,

    });

  } catch (err) {

    console.error(err);

    const status = err.statusCode || 500;

    return sendError(res, err.message || 'Failed to save availability', status);

  }

});



// GET /nurse/bookable-slots

router.get('/bookable-slots', async (req, res) => {

  try {

    const nurseId = req.query.nurseId;

    if (!nurseId) {

      return sendError(res, 'nurseId is required', 400);

    }

    const result = await getNurseBookableSlots(nurseId);

    if (result.error) {

      return sendError(res, result.error, result.status);

    }

    return sendSuccess(res, { data: result.data });

  } catch (err) {

    console.error(err);

    return sendError(res, err.message || 'Failed to load bookable slots', 500);

  }

});



// POST /nurse/slot-hold

router.post('/slot-hold', authOptional, async (req, res) => {

  try {

    const body = req.body || {};

    const { nurseId, dayOfWeek, startHour, slotStart, holdId } = body;

    if (!nurseId) {

      return sendError(res, 'nurseId is required', 400);

    }

    const patientId =

      req.auth?.type === 'patient' ? req.auth.patientId : undefined;

    const data = await holdNurseSlot({

      nurseId,

      dayOfWeek,

      startHour,

      slotStart,

      patientId,

      holdId,

    });

    return sendSuccess(res, {

      statusCode: 201,

      message: 'Slot reserved',

      data,

    });

  } catch (err) {

    console.error(err);

    const status = err.statusCode || 500;

    return sendError(res, err.message || 'Could not reserve slot', status);

  }

});



// DELETE /nurse/slot-hold/:holdId

router.delete('/slot-hold/:holdId', authOptional, async (req, res) => {

  try {

    const patientId =

      req.auth?.type === 'patient' ? req.auth.patientId : undefined;

    const data = await releaseNurseSlotHold(req.params.holdId, patientId);

    return sendSuccess(res, {

      message: data.released ? 'Slot hold released' : 'No active hold found',

      data,

    });

  } catch (err) {

    console.error(err);

    const status = err.statusCode || 500;

    return sendError(res, err.message || 'Could not release slot hold', status);

  }

});



// POST /nurse/home-visit/request

router.post('/home-visit/request', authOptional, async (req, res) => {

  try {

    const body = req.body || {};

    if (!body.nurseId) {

      return sendError(res, 'nurseId is required', 400);

    }

    const patientId =

      req.auth?.type === 'patient' ? req.auth.patientId : undefined;

    const data = await createNurseHomeVisitRequest({

      ...body,

      patientId: body.patientId || patientId,

    });

    return sendSuccess(res, {

      statusCode: 201,

      message: 'Home visit request sent. Nurse will review and approve.',

      data,

    });

  } catch (err) {

    console.error(err);

    const status = err.statusCode || 500;

    return sendError(res, err.message || 'Request failed', status);

  }

});



// POST /nurse/bookings/:bookingId/approve-home-visit

router.post('/bookings/:bookingId/approve-home-visit', authOptional, async (req, res) => {

  try {

    const { bookingId } = req.params;

    const nurseId = req.body?.nurseId || req.auth?.nurseId;

    if (!nurseId) {

      return sendError(res, 'nurseId is required', 400);

    }

    const data = await approveNurseHomeVisitRequest(bookingId, nurseId);

    return sendSuccess(res, {

      message: 'Home visit approved. Patient can now pay to confirm.',

      data,

    });

  } catch (err) {

    console.error(err);

    const status = err.statusCode || 500;

    return sendError(res, err.message || 'Approval failed', status);

  }

});



// POST /nurse/bookings/:bookingId/reject-home-visit

router.post('/bookings/:bookingId/reject-home-visit', authOptional, async (req, res) => {

  try {

    const { bookingId } = req.params;

    const nurseId = req.body?.nurseId || req.auth?.nurseId;

    if (!nurseId) {

      return sendError(res, 'nurseId is required', 400);

    }

    const data = await rejectNurseHomeVisitRequest(bookingId, nurseId);

    return sendSuccess(res, {

      message: 'Home visit request declined',

      data,

    });

  } catch (err) {

    console.error(err);

    const status = err.statusCode || 500;

    return sendError(res, err.message || 'Rejection failed', status);

  }

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

      homeVisitFee: body.homeVisitFee != null

        ? parseInt(body.homeVisitFee, 10)

        : existing.homeVisitFee,

      shiftAvailability: body.shiftAvailability?.trim(),

      bankAccountHolderName: body.bankAccountHolderName?.trim(),

      bankAccountNumber: body.bankAccountNumber?.trim(),

      ifscCode: body.ifscCode?.trim(),

      bankName: body.bankName?.trim(),

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
    const fileUrl = await filePublicUrl(req, req.file);
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

          gender: body.gender?.trim(),

          dateOfBirth: body.dateOfBirth
            ? new Date(body.dateOfBirth)
            : undefined,

          languagesSpoken: Array.isArray(body.languagesSpoken)
            ? body.languagesSpoken
            : undefined,

          emergencyContactName: body.emergencyContactName?.trim(),

          emergencyContactNumber: body.emergencyContactNumber?.trim(),

          qualification: body.qualification?.trim(),

          registrationNumber: body.registrationNumber?.trim(),

          nursingCouncil: body.nursingCouncil?.trim(),

          nuid: body.nuid?.trim(),

          yearsOfExperience: parseInt(body.yearsOfExperience, 10) || 0,

          specialization: body.specialization?.trim(),

          nursingSkills: Array.isArray(body.nursingSkills)
            ? body.nursingSkills
            : undefined,

          address: body.address?.trim(),

          city: body.city?.trim(),

          state: body.state?.trim(),

          pincode: body.pincode?.trim(),

          latitude:
            body.latitude != null ? parseFloat(body.latitude) : undefined,

          longitude:
            body.longitude != null ? parseFloat(body.longitude) : undefined,

          serviceRadiusKm:
            body.serviceRadiusKm != null
              ? parseInt(body.serviceRadiusKm, 10)
              : undefined,

          availableForHomeVisit: body.availableForHomeVisit != null

            ? Boolean(body.availableForHomeVisit)

            : true,

          homeVisitFee: parseInt(body.homeVisitFee, 10) || 0,

          shiftAvailability: body.shiftAvailability?.trim(),

          bankAccountHolderName: body.bankAccountHolderName?.trim(),

          bankAccountNumber: body.bankAccountNumber?.trim(),

          ifscCode: body.ifscCode?.trim(),

          bankName: body.bankName?.trim(),

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



// POST /nurse/upload-document

router.post('/upload-document', upload.single('file'), async (req, res) => {

  try {

    if (!req.file) {

      return sendError(res, 'File is required');

    }

    const { nurseId, documentType } = req.body || {};

    if (!nurseId || !documentType) {

      return sendError(res, 'nurseId and documentType are required');

    }

    await ensureNurseStub(nurseId, req.body.mobileNumber);

    const fileUrl = await filePublicUrl(req, req.file);

    const document = await upsertDocument({

      nurseId,

      documentType,

      fileUrl,

      fileName: req.file.originalname,

      fileSize: req.file.size,

      mimeType: req.file.mimetype,

    });

    return sendSuccess(res, {

      message: 'Document uploaded',

      data: document,

    });

  } catch (err) {

    console.error(err);

    return sendError(res, err.message || 'Upload failed', 500);

  }

});



module.exports = router;

