const express = require('express');
const path = require('path');
const fs = require('fs');
const multer = require('multer');
const { v4: uuidv4 } = require('uuid');
const {
  findDoctorById,
  findDoctorByEmail,
  findDoctorByMobile,
  ensureDoctorStub,
  upsertDoctor,
  updateDoctorDocumentUrl,
  createDocument,
  findDocumentsByDoctorId,
  listDoctors,
  submitDoctorForReview,
  touchDoctorPresence,
  clearDoctorPresence,
} = require('../db/repositories');
const { ensureDoctorDocumentsFromProfile } = require('../db/documentVerification');
const { sendSuccess, sendError } = require('../utils/response');
const { signToken, authOptional, authRequired } = require('../middleware/auth');
const { loginProvider } = require('../utils/providerAuth');
const { toDoctor } = require('../db/mappers');
const { listPublicDoctorFeedback } = require('../db/feedbackRepositories');
const { isDoctorLiveNow } = require('../utils/doctorPresence');
const Doctor = require('../db/models/Doctor');
const {
  getDoctorAvailability,
  getDoctorAvailabilityStatus,
  saveDoctorAvailability,
} = require('../db/availabilityRepositories');
const {
  getBookableSlots,
  holdConsultationSlot,
  releaseConsultationSlotHold,
  createOnlineConsultBooking,
  createHospitalVisitBooking,
  listDoctorBookings,
  verifyClinicAppointment,
} = require('../db/bookingRepositories');
const aadhaarRoutes = require('./aadhaarRoutes');
const emailRoutes = require('./emailRoutes');

const router = express.Router();

// Aadhaar OTP — must be registered on this router (POST /doctor/aadhaar/send-otp)
router.use('/aadhaar', aadhaarRoutes);
// Email verification — POST /doctor/email/send-otp, /doctor/email/verify-otp
router.use('/email', emailRoutes);

const uploadsDir = path.join(__dirname, '../../uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, uploadsDir),
  filename: (_req, file, cb) => {
    const ext = path.extname(file.originalname) || '';
    cb(null, `${uuidv4()}${ext}`);
  },
});

const upload = multer({
  storage,
  limits: { fileSize: 10 * 1024 * 1024 },
});

const { normalizeMobile, validateMobile } = require('../utils/mobile');

function mapBodyToDoctor(body) {
  return {
    id: body.id,
    firstName: body.firstName,
    lastName: body.lastName,
    email: body.email,
    mobileNumber: body.mobileNumber,
    countryCode: body.countryCode,
    password: body.password,
    profilePicture: body.profilePicture,
    gender: body.gender,
    dateOfBirth: body.dateOfBirth,
    medicalRegistrationNumber: body.medicalRegistrationNumber,
    medicalCouncilName: body.medicalCouncilName,
    specializations: body.specializations,
    qualification: body.qualification,
    yearsOfExperience: body.yearsOfExperience,
    clinicName: body.clinicName,
    consultationFee: body.consultationFee,
    onlineConsultFee: body.onlineConsultFee,
    homeVisitFee: body.homeVisitFee,
    visitSiteFee: body.visitSiteFee,
    offersOnlineConsult: body.offersOnlineConsult,
    offersBookHome: body.offersBookHome,
    offersVisitSite: body.offersVisitSite,
    languagesSpoken: body.languagesSpoken,
    bio: body.bio,
    address: body.address,
    city: body.city,
    state: body.state,
    pincode: body.pincode,
    latitude: body.latitude,
    longitude: body.longitude,
    medicalLicenseUrl: body.medicalLicenseUrl,
    governmentIdUrl: body.governmentIdUrl,
    degreeCertificateUrl: body.degreeCertificateUrl,
    clinicProofUrl: body.clinicProofUrl,
    hospitalPhoto1Url: body.hospitalPhoto1Url,
    hospitalPhoto2Url: body.hospitalPhoto2Url,
    hospitalPhoto3Url: body.hospitalPhoto3Url,
    hospitalPhoto4Url: body.hospitalPhoto4Url,
    hospitalPhoto5Url: body.hospitalPhoto5Url,
    bankAccountNumber: body.bankAccountNumber,
    ifscCode: body.ifscCode,
    cancelledChequeUrl: body.cancelledChequeUrl,
    payoutMethod: body.payoutMethod,
    upiId: body.upiId,
    aadhaarLast4: body.aadhaarLast4,
    aadhaarCardUrl: body.aadhaarCardUrl,
  };
}

const { filePublicUrl } = require('../middleware/multerUpload');

// GET /doctor/verified — public list for patients / home screen
router.get('/verified', async (req, res) => {
  try {
    const page = Math.max(1, parseInt(req.query.page || '1', 10));
    const pageSize = Math.min(50, parseInt(req.query.pageSize || '20', 10));
    const search = req.query.q || req.query.search || '';
    const city = req.query.city || '';
    const specialization = req.query.specialization || '';
    const consultationType = req.query.consultationType || '';

    const { doctors, pagination } = await listDoctors({
      status: 'verified',
      page,
      pageSize,
      search,
      city,
      specialization,
      consultationType,
    });

    return sendSuccess(res, {
      data: doctors,
      pagination,
    });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to list verified doctors', 500);
  }
});

// GET /doctor/live-status?ids=id1,id2 — lightweight presence for patient cards
router.get('/live-status', async (req, res) => {
  try {
    const raw = String(req.query.ids || '').trim();
    const ids = [...new Set(raw.split(',').map((id) => id.trim()).filter(Boolean))];
    if (!ids.length) {
      return sendSuccess(res, { data: [] });
    }

    const docs = await Doctor.find({ id: { $in: ids.slice(0, 50) } })
      .select('id lastActiveAt')
      .lean();

    const data = docs.map((doc) => ({
      id: doc.id,
      lastActiveAt: doc.lastActiveAt ?? null,
      isLiveNow: isDoctorLiveNow(doc.lastActiveAt),
    }));

    return sendSuccess(res, { data });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to load live status', 500);
  }
});

// GET /doctor/feedback — public patient reviews for a doctor profile
router.get('/feedback', async (req, res) => {
  try {
    const doctorId = req.query.doctorId;
    if (!doctorId) {
      return sendError(res, 'doctorId is required', 400);
    }

    const doctor = await findDoctorById(doctorId);
    if (!doctor) {
      return sendError(res, 'Doctor not found', 404);
    }

    const limit = Math.min(50, parseInt(req.query.limit || '20', 10));
    const reviews = await listPublicDoctorFeedback(doctorId, { limit });

    return sendSuccess(res, {
      data: {
        averageRating: doctor.averageRating ?? null,
        ratingCount: doctor.ratingCount ?? 0,
        reviews,
      },
    });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to load feedback', 500);
  }
});

// POST /doctor/login
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body || {};
    const result = await loginProvider({
      email,
      password,
      findByEmail: (e) => findDoctorByEmail(e),
      toPublic: (doc) => toDoctor(doc),
      buildTokenPayload: (profile) => ({
        doctorId: profile.id,
        mobileNumber: profile.mobileNumber,
        type: 'doctor',
      }),
    });

    if (!result.ok) {
      return sendError(res, result.error, result.status);
    }

    const token = signToken(result.tokenPayload, '30d');
    await touchDoctorPresence(result.profile.id);
    const profile = await findDoctorById(result.profile.id);
    return sendSuccess(res, {
      message: 'Login successful',
      data: profile,
      token,
    });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Login failed', 500);
  }
});

// POST /doctor/presence/heartbeat — doctor app pings while logged in
router.post('/presence/heartbeat', authRequired, async (req, res) => {
  try {
    if (req.auth?.type !== 'doctor' || !req.auth?.doctorId) {
      return sendError(res, 'Doctor authentication required', 403);
    }
    const doctor = await touchDoctorPresence(req.auth.doctorId);
    if (!doctor) {
      return sendError(res, 'Doctor not found', 404);
    }
    return sendSuccess(res, {
      message: 'Presence updated',
      data: { isLiveNow: doctor.isLiveNow, lastActiveAt: doctor.lastActiveAt },
    });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to update presence', 500);
  }
});

// POST /doctor/presence/offline — doctor logs out or closes app
router.post('/presence/offline', authRequired, async (req, res) => {
  try {
    if (req.auth?.type !== 'doctor' || !req.auth?.doctorId) {
      return sendError(res, 'Doctor authentication required', 403);
    }
    await clearDoctorPresence(req.auth.doctorId);
    return sendSuccess(res, { message: 'Marked offline' });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to clear presence', 500);
  }
});

// POST /doctor/verify-appointment — verify clinic visit with 4-digit patient code
router.post('/verify-appointment', authRequired, async (req, res) => {
  try {
    if (req.auth?.type !== 'doctor' || !req.auth?.doctorId) {
      return sendError(res, 'Doctor authentication required', 403);
    }
    const { appointmentCode, code } = req.body || {};
    const data = await verifyClinicAppointment(
      req.auth.doctorId,
      appointmentCode || code,
    );
    return sendSuccess(res, {
      message: 'Appointment verified successfully',
      data,
    });
  } catch (err) {
    console.error(err);
    const status = err.statusCode || 500;
    return sendError(res, err.message || 'Verification failed', status);
  }
});

// GET /doctor/bookings
router.get('/bookings', authOptional, async (req, res) => {
  try {
    const doctorId = req.query.doctorId || req.auth?.doctorId;
    if (!doctorId) {
      return sendError(res, 'doctorId is required', 400);
    }
    const data = await listDoctorBookings(doctorId);
    return sendSuccess(res, { data });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to load bookings', 500);
  }
});

// GET /doctor/bookable-slots — public slots for patient online consult
router.get('/bookable-slots', async (req, res) => {
  try {
    const doctorId = req.query.doctorId;
    if (!doctorId) {
      return sendError(res, 'doctorId is required', 400);
    }
    const consultationType = req.query.type || 'online_consult';
    const result = await getBookableSlots(doctorId, consultationType);
    if (result.error) {
      return sendError(res, result.error, result.status);
    }
    return sendSuccess(res, { data: result.data });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to load bookable slots', 500);
  }
});

// POST /doctor/slot-hold — temporarily reserve a slot while patient completes booking
router.post('/slot-hold', authOptional, async (req, res) => {
  try {
    const body = req.body || {};
    const {
      doctorId,
      consultationType = 'online_consult',
      dayOfWeek,
      startHour,
      slotStart,
      holdId,
    } = body;

    if (!doctorId) {
      return sendError(res, 'doctorId is required', 400);
    }

    const patientId =
      req.auth?.type === 'patient' ? req.auth.patientId : undefined;

    const data = await holdConsultationSlot({
      doctorId,
      consultationType,
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

// DELETE /doctor/slot-hold/:holdId — release a temporary slot reservation
router.delete('/slot-hold/:holdId', authOptional, async (req, res) => {
  try {
    const patientId =
      req.auth?.type === 'patient' ? req.auth.patientId : undefined;
    const data = await releaseConsultationSlotHold(req.params.holdId, patientId);
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

// POST /doctor/hospital-visit — book a hospital / clinic visit appointment
router.post('/hospital-visit', authOptional, async (req, res) => {
  try {
    const {
      doctorId,
      patientName,
      patientMobile,
      patientEmail,
      patientNotes,
      patientAddress,
      patientCity,
      patientState,
      patientPincode,
      visitReason,
      dayOfWeek,
      startHour,
      slotStart,
    } = req.body || {};

    if (!doctorId) {
      return sendError(res, 'doctorId is required', 400);
    }

    const patientId =
      req.auth?.type === 'patient' ? req.auth.patientId : undefined;

    const data = await createHospitalVisitBooking({
      doctorId,
      patientId,
      patientName,
      patientMobile,
      patientEmail,
      patientNotes,
      patientAddress,
      patientCity,
      patientState,
      patientPincode,
      visitReason,
      dayOfWeek,
      startHour,
      slotStart,
    });

    return res.status(201).json({
      success: true,
      message: 'Hospital visit appointment booked successfully',
      statusCode: 201,
      data,
    });
  } catch (err) {
    console.error(err);
    const status = err.statusCode || 500;
    return sendError(res, err.message || 'Booking failed', status);
  }
});

// POST /doctor/online-consult — book an online consultation
router.post('/online-consult', authOptional, async (req, res) => {
  try {
    const {
      doctorId,
      patientName,
      patientMobile,
      patientEmail,
      patientNotes,
      dayOfWeek,
      startHour,
      slotStart,
    } = req.body || {};

    if (!doctorId) {
      return sendError(res, 'doctorId is required', 400);
    }

    const patientId =
      req.auth?.type === 'patient' ? req.auth.patientId : undefined;

    const data = await createOnlineConsultBooking({
      doctorId,
      patientId,
      patientName,
      patientMobile,
      patientEmail,
      patientNotes,
      dayOfWeek,
      startHour,
      slotStart,
    });

    return res.status(201).json({
      success: true,
      message: 'Online consultation booked successfully',
      statusCode: 201,
      data,
    });
  } catch (err) {
    console.error(err);
    const status = err.statusCode || 500;
    return sendError(res, err.message || 'Booking failed', status);
  }
});

// POST /doctor/register
router.post('/register', authOptional, async (req, res) => {
  try {
    const data = mapBodyToDoctor(req.body);

    if (!data.firstName || !data.email || !data.mobileNumber) {
      return sendError(res, 'firstName, email, and mobileNumber are required');
    }

    const mobileCheck = validateMobile(data.mobileNumber, {
      countryCode: data.countryCode,
    });
    if (!mobileCheck.valid) {
      return sendError(res, mobileCheck.error, 400);
    }
    const mobile = mobileCheck.mobile;
    const normalizedEmail = String(data.email).trim().toLowerCase();
    const emailExists = await findDoctorByEmail(normalizedEmail, data.id || '');
    if (emailExists?.emailVerified && emailExists.id !== data.id) {
      return sendError(res, 'Email is already registered', 409);
    }

    const existingDoctor = data.id ? await findDoctorById(data.id) : null;
    if (
      !existingDoctor?.emailVerified ||
      String(existingDoctor.email || '').toLowerCase() !== normalizedEmail
    ) {
      return sendError(
        res,
        'Please verify your email before submitting registration',
        400,
      );
    }

    const mobileTaken = await findDoctorByMobile(mobile, data.id || '');
    if (mobileTaken && mobileTaken.id !== data.id) {
      return sendError(res, 'Mobile number is already registered', 409);
    }

    const doctor = await submitDoctorForReview(
      (await upsertDoctor({
        ...data,
        email: normalizedEmail,
        mobileNumber: mobile,
        countryCode: mobileCheck.countryCode,
      })).id,
    );

    const token = signToken(
      { doctorId: doctor.id, mobileNumber: mobile, type: 'doctor' },
      '30d',
    );

    return res.status(200).json({
      success: true,
      message: 'Application submitted for admin review',
      statusCode: 200,
      data: doctor,
      token,
    });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Registration failed', 500);
  }
});

// GET /doctor/profile
router.get('/profile', authOptional, async (req, res) => {
  try {
    let doctorId = req.query.doctorId;
    if (!doctorId && req.auth?.doctorId) {
      doctorId = req.auth.doctorId;
    }

    if (!doctorId) {
      return sendError(res, 'doctorId is required', 400);
    }

    const doctor = await findDoctorById(doctorId);
    if (!doctor) {
      return sendError(res, 'Doctor not found', 404);
    }

    const availabilityStatus = await getDoctorAvailabilityStatus(doctorId, doctor);

    return sendSuccess(res, {
      data: {
        ...doctor,
        availabilityReminder: availabilityStatus.needsUpdate
          ? {
              needsUpdate: true,
              message: availabilityStatus.reminderMessage,
              suggestedWeekStart: availabilityStatus.suggestedWeekStart,
              suggestedWeekEnd: availabilityStatus.suggestedWeekEnd,
            }
          : null,
      },
    });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to fetch profile', 500);
  }
});

// GET /doctor/availability
router.get('/availability', authOptional, async (req, res) => {
  try {
    let doctorId = req.query.doctorId;
    if (!doctorId && req.auth?.doctorId) {
      doctorId = req.auth.doctorId;
    }
    if (!doctorId) {
      return sendError(res, 'doctorId is required', 400);
    }

    const data = await getDoctorAvailability(doctorId, {
      forWeekStart: req.query.weekStart,
      consultationType: req.query.type || req.query.consultationType,
    });

    return sendSuccess(res, { data });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to fetch availability', 500);
  }
});

// PUT /doctor/availability
router.put('/availability', authOptional, async (req, res) => {
  try {
    const {
      doctorId: bodyDoctorId,
      slots,
      weekStartDate,
      consultationType,
      type,
    } = req.body || {};
    const doctorId = bodyDoctorId || req.auth?.doctorId;
    if (!doctorId) {
      return sendError(res, 'doctorId is required', 400);
    }

    const doctor = await findDoctorById(doctorId);
    if (!doctor) {
      return sendError(res, 'Doctor not found', 404);
    }

    const data = await saveDoctorAvailability(doctorId, {
      slots,
      weekStartDate,
      consultationType: consultationType || type,
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

// PUT /doctor/profile
router.put('/profile', authOptional, async (req, res) => {
  try {
    const data = mapBodyToDoctor(req.body);
    if (!data.id) {
      return sendError(res, 'Doctor id is required');
    }

    const existing = await findDoctorById(data.id);
    if (!existing) {
      return sendError(res, 'Doctor not found', 404);
    }

    const doctor = await upsertDoctor(data);
    return sendSuccess(res, {
      message: 'Profile updated successfully',
      data: doctor,
    });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to update profile', 500);
  }
});

// GET /doctor/documents — provider views document verification status
router.get('/documents', authOptional, async (req, res) => {
  try {
    let doctorId = req.query.doctorId;
    if (!doctorId && req.auth?.doctorId) {
      doctorId = req.auth.doctorId;
    }
    if (!doctorId) {
      return sendError(res, 'doctorId is required', 400);
    }

    const doctor = await findDoctorById(doctorId);
    if (!doctor) {
      return sendError(res, 'Doctor not found', 404);
    }

    const documents = await ensureDoctorDocumentsFromProfile(doctor);
    return sendSuccess(res, { data: documents });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to fetch documents', 500);
  }
});

// POST /doctor/upload-document
router.post('/upload-document', upload.single('file'), async (req, res) => {
  try {
    if (!req.file) {
      return sendError(res, 'File is required');
    }

    const doctorId = req.body.doctorId;
    const documentType = req.body.documentType;

    if (!doctorId || !documentType) {
      return sendError(res, 'doctorId and documentType are required');
    }

    await ensureDoctorStub(doctorId, req.body.mobileNumber);

    const fileUrl = filePublicUrl(req, req.file.filename);

    const document = await createDocument({
      doctorId,
      documentType,
      fileUrl,
      fileName: req.file.originalname,
      fileSize: req.file.size,
      mimeType: req.file.mimetype,
    });

    await updateDoctorDocumentUrl(doctorId, documentType, fileUrl);

    return sendSuccess(res, {
      message: 'Document uploaded successfully',
      data: document,
    });
  } catch (err) {
    console.error(err);
    const status = err.statusCode || 500;
    return sendError(res, err.message || 'Upload failed', status);
  }
});

// POST /doctor/upload-profile
router.post('/upload-profile', upload.single('file'), async (req, res) => {
  try {
    if (!req.file) {
      return sendError(res, 'File is required');
    }

    const doctorId = req.body.doctorId;
    if (!doctorId) {
      return sendError(res, 'doctorId is required');
    }

    await ensureDoctorStub(doctorId, req.body.mobileNumber);
    const fileUrl = filePublicUrl(req, req.file.filename);
    await updateDoctorDocumentUrl(doctorId, 'profile_picture', fileUrl);

    return sendSuccess(res, {
      message: 'Profile picture uploaded',
      data: { profilePicture: fileUrl },
    });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Upload failed', 500);
  }
});

// POST /doctor/upload-hospital-photo — profile-style upload, no admin verification
router.post('/upload-hospital-photo', upload.single('file'), async (req, res) => {
  try {
    if (!req.file) {
      return sendError(res, 'File is required');
    }

    const doctorId = req.body.doctorId;
    const photoIndex = parseInt(req.body.photoIndex, 10);
    if (!doctorId) {
      return sendError(res, 'doctorId is required', 400);
    }
    if (!Number.isInteger(photoIndex) || photoIndex < 1 || photoIndex > 4) {
      return sendError(res, 'photoIndex must be between 1 and 4', 400);
    }

    await ensureDoctorStub(doctorId, req.body.mobileNumber);
    const fileUrl = filePublicUrl(req, req.file.filename);
    await updateDoctorDocumentUrl(doctorId, `hospital_photo_${photoIndex}`, fileUrl);

    return sendSuccess(res, {
      message: 'Hospital photo uploaded',
      data: { photoIndex, url: fileUrl },
    });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Upload failed', 500);
  }
});

module.exports = router;
