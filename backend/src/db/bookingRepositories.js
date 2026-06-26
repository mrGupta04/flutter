const { v4: uuidv4 } = require('uuid');
const ConsultationBooking = require('./models/ConsultationBooking');
const { findDoctorById, getConsultationFeeForType } = require('./repositories');
const { normalizeUploadUrl } = require('../utils/uploadUrl');
const { findAvailabilityForActiveWeek } = require('./availabilityRepositories');
const { isWeekExpired } = require('../utils/availabilityWeek');
const {
  slotDateTime,
  slotEndDateTime,
  formatSlotLabel,
} = require('../utils/slotDateTime');
const { videoJoinFields } = require('../utils/videoJoinWindow');
const { findFeedbackByBookingIds, feedbackFieldsForBooking } = require('./feedbackRepositories');
const {
  findPrescriptionsByBookingIds,
  prescriptionFieldsForBooking,
} = require('./prescriptionRepositories');
const { buildRoomId } = require('../services/videoConsultService');
const { notifyBookingConfirmed } = require('../services/bookingNotificationService');

function normalizeMobile(mobile) {
  return String(mobile || '').replace(/\D/g, '').slice(-10);
}

async function getActiveAvailabilityForBooking(doctorId, consultationType) {
  const weekDoc = await findAvailabilityForActiveWeek(doctorId, consultationType);
  if (!weekDoc) {
    return { error: 'Doctor has not set availability yet', status: 404 };
  }
  if (isWeekExpired(weekDoc.weekEndDate)) {
    return {
      error: 'Doctor is updating their schedule. Please try again later.',
      status: 409,
    };
  }
  return { availability: weekDoc };
}

function consultationTypeChecks(doctor, consultationType) {
  if (consultationType === 'visit_site') {
    if (!doctor.offersVisitSite) {
      return { error: 'This doctor does not offer hospital visits', status: 400 };
    }
  } else if (consultationType === 'book_home') {
    if (!doctor.offersBookHome) {
      return { error: 'This doctor does not offer home visits', status: 400 };
    }
  } else if (!doctor.offersOnlineConsult) {
    return { error: 'This doctor does not offer online consultation', status: 400 };
  }
  return null;
}

function generateAppointmentCode() {
  return String(Math.floor(1000 + Math.random() * 9000));
}

async function generateUniqueAppointmentCode(doctorId) {
  for (let attempt = 0; attempt < 15; attempt += 1) {
    const code = generateAppointmentCode();
    const existing = await ConsultationBooking.findOne({
      doctorId,
      appointmentCode: code,
      consultationType: 'visit_site',
      status: 'confirmed',
      slotStart: { $gte: new Date() },
    }).lean();
    if (!existing) return code;
  }
  const err = new Error('Could not generate appointment code. Please try again.');
  err.statusCode = 503;
  throw err;
}

function bookingAppointmentFields(booking) {
  if (!booking?.appointmentCode) return {};
  return {
    appointmentCode: booking.appointmentCode,
    appointmentVerifiedAt: booking.appointmentVerifiedAt ?? null,
    isAppointmentVerified: Boolean(booking.appointmentVerifiedAt),
  };
}

function bookingPreviousReportsFields(booking) {
  const reports = Array.isArray(booking?.previousReports)
    ? booking.previousReports
    : [];
  return {
    previousReports: reports.map((report) => ({
      id: report.id,
      fileUrl: report.fileUrl,
      fileName: report.fileName,
      mimeType: report.mimeType,
      uploadedAt: report.uploadedAt,
    })),
    previousReportCount: reports.length,
  };
}

const MAX_PREVIOUS_REPORTS = 5;

async function assertPatientCanAccessBooking(bookingId, patientId, mobileNumber) {
  const booking = await ConsultationBooking.findOne({ id: bookingId }).lean();
  if (!booking) {
    const err = new Error('Booking not found');
    err.statusCode = 404;
    throw err;
  }

  const mobile = normalizeMobile(mobileNumber);
  const ownsBooking =
    (booking.patientId && booking.patientId === patientId) ||
    (mobile.length === 10 && normalizeMobile(booking.patientMobile) === mobile);

  if (!ownsBooking) {
    const err = new Error('You are not allowed to update this booking');
    err.statusCode = 403;
    throw err;
  }

  return booking;
}

async function addPreviousReportToBooking({
  bookingId,
  patientId,
  mobileNumber,
  fileUrl,
  fileName,
  mimeType,
}) {
  const booking = await assertPatientCanAccessBooking(
    bookingId,
    patientId,
    mobileNumber,
  );

  if (!['pending', 'confirmed'].includes(booking.status)) {
    const err = new Error('Reports cannot be added to this booking');
    err.statusCode = 400;
    throw err;
  }

  const existing = Array.isArray(booking.previousReports)
    ? booking.previousReports
    : [];
  if (existing.length >= MAX_PREVIOUS_REPORTS) {
    const err = new Error(`You can upload up to ${MAX_PREVIOUS_REPORTS} reports`);
    err.statusCode = 400;
    throw err;
  }

  const report = {
    id: uuidv4(),
    fileUrl,
    fileName: fileName || fileUrl.split('/').pop(),
    mimeType: mimeType || undefined,
    uploadedAt: new Date(),
  };

  await ConsultationBooking.updateOne(
    { id: bookingId },
    { $push: { previousReports: report } },
  );

  return report;
}

function bookingPaymentFields(booking) {
  return {
    paymentStatus: booking.paymentStatus || 'pending',
    amountPaid: booking.amountPaid ?? null,
    currency: booking.currency || 'INR',
    paidAt: booking.paidAt ?? null,
  };
}

const SLOT_HOLD_MINUTES = parseInt(process.env.SLOT_HOLD_MINUTES || '10', 10);

async function expirePendingBookings(doctorId) {
  const now = new Date();
  await ConsultationBooking.updateMany(
    {
      ...(doctorId ? { doctorId } : {}),
      status: { $in: ['pending', 'held'] },
      paymentExpiresAt: { $lte: now },
    },
    {
      $set: {
        status: 'cancelled',
        paymentStatus: 'failed',
      },
    },
  );
}

function isActivePendingBooking(booking, now = new Date()) {
  return (
    booking.status === 'pending' &&
    booking.paymentExpiresAt &&
    new Date(booking.paymentExpiresAt) > now
  );
}

function isActiveHeldBooking(booking, now = new Date()) {
  return (
    booking.status === 'held' &&
    booking.paymentExpiresAt &&
    new Date(booking.paymentExpiresAt) > now
  );
}

function isSlotReserved(booking, now = new Date()) {
  return (
    booking.status === 'confirmed' ||
    isActivePendingBooking(booking, now) ||
    isActiveHeldBooking(booking, now)
  );
}

function buildClinicAddress(doctor) {
  const parts = [
    doctor.address,
    doctor.city,
    doctor.state,
    doctor.pincode,
  ].filter((p) => p && String(p).trim());
  return parts.join(', ');
}

async function getBookableSlots(doctorId, consultationType = 'online_consult') {
  const doctor = await findDoctorById(doctorId);
  if (!doctor) {
    return { error: 'Doctor not found', status: 404 };
  }
  const typeCheck = consultationTypeChecks(doctor, consultationType);
  if (typeCheck) {
    return typeCheck;
  }

  const availResult = await getActiveAvailabilityForBooking(
    doctorId,
    consultationType,
  );
  if (availResult.error) {
    return { error: availResult.error, status: availResult.status };
  }

  const availability = availResult.availability;
  const weekStart = availability.weekStartDate;
  const weekEnd = availability.weekEndDate;
  const now = new Date();

  await expirePendingBookings(doctorId);

  const reserved = await ConsultationBooking.find({
    doctorId,
    consultationType,
    status: { $in: ['confirmed', 'pending', 'held'] },
    slotStart: { $gte: weekStart, $lte: weekEnd },
  }).lean();

  const bookedKeys = new Set();
  const bookedSlotStarts = new Set();
  for (const booking of reserved) {
    if (!isSlotReserved(booking, now)) continue;
    bookedKeys.add(`${booking.dayOfWeek}_${booking.startHour}`);
    bookedSlotStarts.add(new Date(booking.slotStart).getTime());
  }

  const slotMap = new Map();
  (availability.slots || []).forEach((s) => {
    slotMap.set(`${s.dayOfWeek}_${s.startHour}`, s);
  });

  const bookable = [];
  for (let day = 0; day <= 6; day += 1) {
    for (let hour = 8; hour <= 17; hour += 1) {
      const key = `${day}_${hour}`;
      const slot = slotMap.get(key) || { dayOfWeek: day, startHour: hour, available: false };
      if (!slot.available || bookedKeys.has(key)) continue;

      const slotStart = slotDateTime(weekStart, day, hour);
      const slotEnd = slotEndDateTime(weekStart, day, hour);
      if (slotStart <= now) continue;
      if (bookedSlotStarts.has(slotStart.getTime())) continue;

      bookable.push({
        dayOfWeek: day,
        startHour: hour,
        slotStart: slotStart.toISOString(),
        slotEnd: slotEnd.toISOString(),
        label: formatSlotLabel(slotStart, slotEnd),
      });
    }
  }

  bookable.sort(
    (a, b) => new Date(a.slotStart).getTime() - new Date(b.slotStart).getTime(),
  );

  const data = {
    doctorId,
    consultationType,
    weekStartDate: weekStart.toISOString(),
    weekEndDate: weekEnd.toISOString(),
    consultationFee: getConsultationFeeForType(doctor, consultationType),
    slots: bookable,
    totalBookable: bookable.length,
    totalAvailableInWeek: (availability.slots || []).filter((s) => s.available).length,
    message:
      bookable.length === 0
        ? 'No upcoming slots this week. Past times are hidden — the doctor may need to update their schedule.'
        : null,
  };

  if (consultationType === 'visit_site') {
    data.clinicName = doctor.clinicName;
    data.clinicAddress = buildClinicAddress(doctor);
    data.clinicCity = doctor.city;
    data.clinicState = doctor.state;
    data.clinicPincode = doctor.pincode;
    data.clinicLatitude = doctor.latitude;
    data.clinicLongitude = doctor.longitude;
  }

  return { data };
}

function formatBookingResponse(booking, doctor) {
  const doctorName = `${doctor.firstName || ''} ${doctor.lastName || ''}`.trim();
  return {
    id: booking.id,
    doctorId: booking.doctorId,
    consultationType: booking.consultationType,
    patientName: booking.patientName,
    patientMobile: booking.patientMobile,
    patientEmail: booking.patientEmail,
    patientNotes: booking.patientNotes,
    patientAddress: booking.patientAddress,
    patientCity: booking.patientCity,
    patientState: booking.patientState,
    patientPincode: booking.patientPincode,
    visitReason: booking.visitReason,
    dayOfWeek: booking.dayOfWeek,
    startHour: booking.startHour,
    slotStart: booking.slotStart,
    slotEnd: booking.slotEnd,
    weekStartDate: booking.weekStartDate,
    consultationFee: booking.consultationFee,
    status: booking.status,
    label: formatSlotLabel(booking.slotStart, booking.slotEnd),
    doctorName,
    clinicName: doctor.clinicName,
    clinicAddress: buildClinicAddress(doctor),
    createdAt: booking.createdAt,
    ...bookingAppointmentFields(booking),
    ...bookingPaymentFields(booking),
    ...videoJoinFields(booking),
    ...bookingPreviousReportsFields(booking),
  };
}

async function validateBookingPayload(payload, consultationType) {
  const {
    doctorId,
    patientName,
    patientMobile,
    patientEmail,
    patientNotes,
    dayOfWeek,
    startHour,
    slotStart: slotStartRaw,
    patientId,
    patientAddress,
    patientCity,
    patientState,
    patientPincode,
    visitReason,
  } = payload;

  const doctor = await findDoctorById(doctorId);
  if (!doctor) {
    const err = new Error('Doctor not found');
    err.statusCode = 404;
    throw err;
  }
  const typeCheck = consultationTypeChecks(doctor, consultationType);
  if (typeCheck) {
    const err = new Error(typeCheck.error);
    err.statusCode = typeCheck.status;
    throw err;
  }

  const typeFee = getConsultationFeeForType(doctor, consultationType);
  if (!typeFee || typeFee < 1) {
    const err = new Error('Doctor consultation fee is not set for this visit type');
    err.statusCode = 400;
    throw err;
  }

  await expirePendingBookings(doctorId);

  const availResult = await getActiveAvailabilityForBooking(
    doctorId,
    consultationType,
  );
  if (availResult.error) {
    const err = new Error(availResult.error);
    err.statusCode = availResult.status;
    throw err;
  }

  const availability = availResult.availability;
  const weekStart = availability.weekStartDate;
  const d = Number(dayOfWeek);
  const h = Number(startHour);

  const slotStart = slotStartRaw
    ? new Date(slotStartRaw)
    : slotDateTime(weekStart, d, h);
  const slotEnd = slotEndDateTime(weekStart, d, h);

  const slotDef = (availability.slots || []).find(
    (s) => s.dayOfWeek === d && s.startHour === h,
  );
  if (!slotDef?.available) {
    const err = new Error('Selected time slot is not available');
    err.statusCode = 409;
    throw err;
  }

  if (slotStart <= new Date()) {
    const err = new Error('Cannot book a past time slot');
    err.statusCode = 400;
    throw err;
  }

  const existing = await ConsultationBooking.findOne({
    doctorId,
    slotStart,
    consultationType,
    status: { $in: ['confirmed', 'pending', 'held'] },
  });
  if (existing && isSlotReserved(existing)) {
    const err = new Error('This slot was just booked. Please choose another time.');
    err.statusCode = 409;
    throw err;
  }

  const mobile = normalizeMobile(patientMobile);
  if (mobile.length !== 10) {
    const err = new Error('A valid 10-digit mobile number is required');
    err.statusCode = 400;
    throw err;
  }

  const name = String(patientName || '').trim();
  if (name.length < 2) {
    const err = new Error('Patient name is required');
    err.statusCode = 400;
    throw err;
  }

  if (consultationType === 'visit_site' || consultationType === 'book_home') {
    const address = String(patientAddress || '').trim();
    const city = String(patientCity || '').trim();
    const pincode = String(patientPincode || '').trim();
    const addressError =
      consultationType === 'book_home'
        ? 'Your home address is required for the doctor to visit you'
        : 'Your address is required for hospital visit';
    if (address.length < 5) {
      const err = new Error(addressError);
      err.statusCode = 400;
      throw err;
    }
    if (city.length < 2) {
      const err = new Error('City is required');
      err.statusCode = 400;
      throw err;
    }
    if (pincode.length < 6) {
      const err = new Error('A valid 6-digit pincode is required');
      err.statusCode = 400;
      throw err;
    }
  }

  return {
    doctor,
    availability,
    weekStart,
    slotStart,
    slotEnd,
    d,
    h,
    mobile,
    name,
    patientId,
    patientEmail,
    patientNotes,
    patientAddress,
    patientCity,
    patientState,
    patientPincode,
    visitReason,
  };
}

async function createPendingBookingForPayment(payload, holdMinutes = 15) {
  const consultationType = payload.consultationType || 'online_consult';
  const validated = await validateBookingPayload(payload, consultationType);
  const {
    doctor,
    weekStart,
    slotStart,
    slotEnd,
    d,
    h,
    mobile,
    name,
    patientId,
    patientEmail,
    patientNotes,
    patientAddress,
    patientCity,
    patientState,
    patientPincode,
    visitReason,
  } = validated;

  const paymentExpiresAt = new Date(Date.now() + holdMinutes * 60 * 1000);

  const existingHold = await ConsultationBooking.findOne({
    doctorId: payload.doctorId,
    slotStart,
    consultationType,
    status: 'held',
    paymentExpiresAt: { $gt: new Date() },
  });

  if (existingHold) {
    if (patientId && existingHold.patientId && existingHold.patientId !== patientId) {
      const err = new Error('This slot was just booked. Please choose another time.');
      err.statusCode = 409;
      throw err;
    }
    existingHold.status = 'pending';
    existingHold.patientId = patientId ? String(patientId) : existingHold.patientId;
    existingHold.patientName = name;
    existingHold.patientMobile = mobile;
    existingHold.patientEmail = patientEmail ? String(patientEmail).trim() : undefined;
    existingHold.patientNotes = patientNotes ? String(patientNotes).trim() : undefined;
    existingHold.patientAddress = patientAddress ? String(patientAddress).trim() : undefined;
    existingHold.patientCity = patientCity ? String(patientCity).trim() : undefined;
    existingHold.patientState = patientState ? String(patientState).trim() : undefined;
    existingHold.patientPincode = patientPincode ? String(patientPincode).trim() : undefined;
    existingHold.visitReason = visitReason ? String(visitReason).trim() : undefined;
    existingHold.paymentExpiresAt = paymentExpiresAt;
    existingHold.paymentStatus = 'pending';
    await existingHold.save();
    const doctorName = `${doctor.firstName || ''} ${doctor.lastName || ''}`.trim();
    return { booking: existingHold, doctorName };
  }

  const booking = await ConsultationBooking.create({
    id: uuidv4(),
    doctorId: payload.doctorId,
    patientId: patientId ? String(patientId) : undefined,
    consultationType,
    patientName: name,
    patientMobile: mobile,
    patientEmail: patientEmail ? String(patientEmail).trim() : undefined,
    patientNotes: patientNotes ? String(patientNotes).trim() : undefined,
    patientAddress: patientAddress ? String(patientAddress).trim() : undefined,
    patientCity: patientCity ? String(patientCity).trim() : undefined,
    patientState: patientState ? String(patientState).trim() : undefined,
    patientPincode: patientPincode ? String(patientPincode).trim() : undefined,
    visitReason: visitReason ? String(visitReason).trim() : undefined,
    dayOfWeek: d,
    startHour: h,
    slotStart,
    slotEnd,
    weekStartDate: weekStart,
    consultationFee: getConsultationFeeForType(doctor, consultationType),
    status: 'pending',
    paymentStatus: 'pending',
    paymentProvider: 'razorpay',
    currency: 'INR',
    paymentExpiresAt,
  });

  const doctorName = `${doctor.firstName || ''} ${doctor.lastName || ''}`.trim();
  return { booking, doctorName };
}

async function confirmBookingAfterPayment({
  bookingId,
  razorpayOrderId,
  razorpayPaymentId,
  razorpaySignature,
}) {
  const booking = await ConsultationBooking.findOne({ id: bookingId });
  if (!booking) {
    const err = new Error('Booking not found');
    err.statusCode = 404;
    throw err;
  }

  if (booking.status === 'confirmed' && booking.paymentStatus === 'paid') {
    const doctor = await findDoctorById(booking.doctorId);
    return formatBookingResponse(booking, doctor);
  }

  if (booking.status !== 'pending') {
    const err = new Error('This booking is no longer available for payment');
    err.statusCode = 409;
    throw err;
  }

  if (booking.paymentExpiresAt && booking.paymentExpiresAt <= new Date()) {
    booking.status = 'cancelled';
    booking.paymentStatus = 'failed';
    await booking.save();
    const err = new Error('Payment window expired. Please book again.');
    err.statusCode = 410;
    throw err;
  }

  if (
    booking.razorpayOrderId &&
    razorpayOrderId &&
    booking.razorpayOrderId !== razorpayOrderId
  ) {
    const err = new Error('Payment order mismatch');
    err.statusCode = 400;
    throw err;
  }

  const doctor = await findDoctorById(booking.doctorId);
  if (!doctor) {
    const err = new Error('Doctor not found');
    err.statusCode = 404;
    throw err;
  }

  if (booking.consultationType === 'visit_site' && !booking.appointmentCode) {
    booking.appointmentCode = await generateUniqueAppointmentCode(booking.doctorId);
  }

  if (booking.consultationType === 'online_consult' && !booking.videoRoomId) {
    booking.videoRoomId = buildRoomId(booking.id);
  }

  booking.status = 'confirmed';
  booking.paymentStatus = 'paid';
  booking.razorpayOrderId = razorpayOrderId;
  booking.razorpayPaymentId = razorpayPaymentId;
  booking.razorpaySignature = razorpaySignature;
  booking.amountPaid = booking.consultationFee;
  booking.paidAt = new Date();
  await booking.save();

  if (booking.consultationType === 'online_consult') {
    notifyBookingConfirmed({ booking: booking.toObject(), doctor }).catch((err) => {
      console.error('[booking] Notification failed:', err.message);
    });
  }

  return formatBookingResponse(booking, doctor);
}

async function createSlotBooking(payload, consultationType) {
  const err = new Error(
    'Payment is required to book. Use POST /api/v1/payments/create-order',
  );
  err.statusCode = 402;
  throw err;
}

async function holdConsultationSlot(payload, holdMinutes = SLOT_HOLD_MINUTES) {
  const consultationType = payload.consultationType || 'online_consult';
  const {
    doctorId,
    dayOfWeek,
    startHour,
    slotStart: slotStartRaw,
    patientId,
    holdId,
  } = payload;

  if (!doctorId) {
    const err = new Error('doctorId is required');
    err.statusCode = 400;
    throw err;
  }

  await expirePendingBookings(doctorId);

  if (holdId) {
    const existing = await ConsultationBooking.findOne({ id: holdId });
    if (
      existing &&
      existing.status === 'held' &&
      (!patientId || !existing.patientId || existing.patientId === patientId)
    ) {
      existing.status = 'cancelled';
      existing.paymentStatus = 'failed';
      await existing.save();
    }
  }

  const doctor = await findDoctorById(doctorId);
  if (!doctor) {
    const err = new Error('Doctor not found');
    err.statusCode = 404;
    throw err;
  }
  const typeCheck = consultationTypeChecks(doctor, consultationType);
  if (typeCheck) {
    const err = new Error(typeCheck.error);
    err.statusCode = typeCheck.status;
    throw err;
  }

  const availResult = await getActiveAvailabilityForBooking(
    doctorId,
    consultationType,
  );
  if (availResult.error) {
    const err = new Error(availResult.error);
    err.statusCode = availResult.status;
    throw err;
  }

  const availability = availResult.availability;
  const weekStart = availability.weekStartDate;
  const d = Number(dayOfWeek);
  const h = Number(startHour);
  const slotStart = slotStartRaw
    ? new Date(slotStartRaw)
    : slotDateTime(weekStart, d, h);
  const slotEnd = slotEndDateTime(weekStart, d, h);

  const slotDef = (availability.slots || []).find(
    (s) => s.dayOfWeek === d && s.startHour === h,
  );
  if (!slotDef?.available) {
    const err = new Error('Selected time slot is not available');
    err.statusCode = 409;
    throw err;
  }

  if (slotStart <= new Date()) {
    const err = new Error('Cannot hold a past time slot');
    err.statusCode = 400;
    throw err;
  }

  const existing = await ConsultationBooking.findOne({
    doctorId,
    slotStart,
    consultationType,
    status: { $in: ['confirmed', 'pending', 'held'] },
  });

  if (existing && isSlotReserved(existing)) {
    if (
      existing.status === 'held' &&
      patientId &&
      existing.patientId === patientId
    ) {
      existing.paymentExpiresAt = new Date(Date.now() + holdMinutes * 60 * 1000);
      await existing.save();
      return {
        holdId: existing.id,
        expiresAt: existing.paymentExpiresAt,
      };
    }
    const err = new Error('This slot was just booked. Please choose another time.');
    err.statusCode = 409;
    throw err;
  }

  if (patientId) {
    await ConsultationBooking.updateMany(
      {
        doctorId,
        consultationType,
        patientId,
        status: 'held',
      },
      {
        $set: {
          status: 'cancelled',
          paymentStatus: 'failed',
        },
      },
    );
  }

  const paymentExpiresAt = new Date(Date.now() + holdMinutes * 60 * 1000);
  const booking = await ConsultationBooking.create({
    id: uuidv4(),
    doctorId,
    patientId: patientId ? String(patientId) : undefined,
    consultationType,
    patientName: 'Slot hold',
    patientMobile: '0000000000',
    dayOfWeek: d,
    startHour: h,
    slotStart,
    slotEnd,
    weekStartDate: weekStart,
    consultationFee: getConsultationFeeForType(doctor, consultationType),
    status: 'held',
    paymentStatus: 'pending',
    paymentExpiresAt,
  });

  return {
    holdId: booking.id,
    expiresAt: booking.paymentExpiresAt,
  };
}

async function releaseConsultationSlotHold(holdId, patientId) {
  const booking = await ConsultationBooking.findOne({ id: holdId });
  if (!booking || booking.status !== 'held') {
    return { released: false };
  }

  if (
    patientId &&
    booking.patientId &&
    booking.patientId !== patientId
  ) {
    const err = new Error('You are not allowed to release this slot hold');
    err.statusCode = 403;
    throw err;
  }

  booking.status = 'cancelled';
  booking.paymentStatus = 'failed';
  await booking.save();
  return { released: true };
}

async function verifyClinicAppointment(doctorId, appointmentCode) {
  const code = String(appointmentCode || '').trim();
  if (!/^\d{4}$/.test(code)) {
    const err = new Error('Enter a valid 4-digit appointment code');
    err.statusCode = 400;
    throw err;
  }

  const booking = await ConsultationBooking.findOne({
    doctorId,
    appointmentCode: code,
    consultationType: 'visit_site',
    status: 'confirmed',
  });

  if (!booking) {
    const err = new Error('Invalid appointment code');
    err.statusCode = 404;
    throw err;
  }

  if (booking.appointmentVerifiedAt) {
    const err = new Error('This appointment was already verified');
    err.statusCode = 409;
    throw err;
  }

  const slotStart = new Date(booking.slotStart);
  const windowStart = new Date(slotStart.getTime() - 2 * 60 * 60 * 1000);
  const windowEnd = new Date(booking.slotEnd.getTime() + 2 * 60 * 60 * 1000);
  const now = new Date();
  if (now < windowStart || now > windowEnd) {
    const err = new Error(
      'Appointment code can only be verified around the scheduled visit time',
    );
    err.statusCode = 400;
    throw err;
  }

  booking.appointmentVerifiedAt = now;
  await booking.save();

  const doctor = await findDoctorById(doctorId);
  const slotLabel = formatSlotLabel(
    new Date(booking.slotStart),
    new Date(booking.slotEnd),
  );

  return {
    id: booking.id,
    patientName: booking.patientName,
    patientMobile: booking.patientMobile,
    slotStart: booking.slotStart,
    slotEnd: booking.slotEnd,
    label: slotLabel,
    appointmentCode: booking.appointmentCode,
    appointmentVerifiedAt: booking.appointmentVerifiedAt,
    isAppointmentVerified: true,
    clinicName: doctor?.clinicName,
  };
}

async function createOnlineConsultBooking(payload) {
  return createSlotBooking(payload, 'online_consult');
}

async function createHospitalVisitBooking(payload) {
  return createSlotBooking(payload, 'visit_site');
}

async function createHomeVisitBooking(payload) {
  return createSlotBooking(payload, 'book_home');
}

async function listPatientBookings(patientId, mobileNumber) {
  const mobile = String(mobileNumber || '').replace(/\D/g, '').slice(-10);
  const orConditions = [{ patientId }];
  if (mobile.length === 10) {
    orConditions.push({
      patientMobile: mobile,
      $or: [
        { patientId: { $exists: false } },
        { patientId: null },
        { patientId: '' },
      ],
    });
  }

  const bookings = await ConsultationBooking.find({
    status: 'confirmed',
    $or: orConditions,
  })
    .sort({ slotStart: -1 })
    .limit(100)
    .lean();

  const now = new Date();
  const feedbackMap = await findFeedbackByBookingIds(bookings.map((b) => b.id));
  const prescriptionMap = await findPrescriptionsByBookingIds(
    bookings.map((b) => b.id),
  );

  const results = [];
  for (const b of bookings) {
    const doctor = await findDoctorById(b.doctorId);
    const doctorName = doctor
      ? `${doctor.firstName || ''} ${doctor.lastName || ''}`.trim()
      : 'Doctor';
    const slotLabel = formatSlotLabel(
      new Date(b.slotStart),
      new Date(b.slotEnd),
    );
    let typeLabel = 'Consultation';
    if (b.consultationType === 'online_consult') {
      typeLabel = 'Online consult';
    } else if (b.consultationType === 'visit_site') {
      typeLabel = 'Clinic visit';
    } else if (b.consultationType === 'book_home') {
      typeLabel = 'Home visit';
    }

    results.push({
      id: b.id,
      doctorId: b.doctorId,
      doctorName,
      doctorProfilePicture: normalizeUploadUrl(doctor?.profilePicture),
      consultationType: b.consultationType,
      typeLabel,
      patientName: b.patientName,
      patientMobile: b.patientMobile,
      patientEmail: b.patientEmail,
      patientNotes: b.patientNotes,
      patientAddress: b.patientAddress,
      patientCity: b.patientCity,
      patientState: b.patientState,
      patientPincode: b.patientPincode,
      visitReason: b.visitReason,
      dayOfWeek: b.dayOfWeek,
      startHour: b.startHour,
      slotStart: b.slotStart,
      slotEnd: b.slotEnd,
      label: slotLabel,
      consultationFee: b.consultationFee,
      status: b.status,
      clinicName: doctor?.clinicName,
      clinicAddress: doctor ? buildClinicAddress(doctor) : undefined,
      createdAt: b.createdAt,
      isUpcoming: new Date(b.slotStart) >= now,
      ...bookingAppointmentFields(b),
      ...videoJoinFields(b, now),
      ...feedbackFieldsForBooking(b, feedbackMap, now),
      ...bookingPreviousReportsFields(b),
      ...prescriptionFieldsForBooking(b, prescriptionMap.get(b.id), now),
    });
  }

  return results;
}

async function listDoctorBookings(doctorId) {
  const bookings = await ConsultationBooking.find({
    doctorId,
    status: 'confirmed',
  })
    .sort({ slotStart: 1 })
    .limit(50)
    .lean();

  const now = new Date();
  const prescriptionMap = await findPrescriptionsByBookingIds(
    bookings.map((b) => b.id),
  );

  return bookings.map((b) => {
    const slotStart = new Date(b.slotStart);
    const slotEnd = new Date(b.slotEnd);
    const slotLabel = formatSlotLabel(slotStart, slotEnd);
    let title = `Booking — ${b.patientName}`;
    let typeLabel = 'Consultation';
    if (b.consultationType === 'online_consult') {
      title = `Online consult — ${b.patientName}`;
      typeLabel = 'Online consult';
    } else if (b.consultationType === 'visit_site') {
      title = `Clinic visit — ${b.patientName}`;
      typeLabel = 'Clinic visit';
    } else if (b.consultationType === 'book_home') {
      title = `Home visit — ${b.patientName}`;
      typeLabel = 'Home visit';
    }
    return {
      id: b.id,
      title,
      subtitle: slotLabel,
      status: b.status,
      slotStart: b.slotStart,
      slotEnd: b.slotEnd,
      patientName: b.patientName,
      patientMobile: b.patientMobile,
      patientEmail: b.patientEmail,
      patientNotes: b.patientNotes,
      patientAddress: b.patientAddress,
      patientCity: b.patientCity,
      patientState: b.patientState,
      patientPincode: b.patientPincode,
      visitReason: b.visitReason,
      consultationType: b.consultationType,
      typeLabel,
      consultationFee: b.consultationFee,
      isUpcoming: slotStart >= now,
      createdAt: b.createdAt,
      ...bookingAppointmentFields(b),
      ...videoJoinFields(b, now),
      ...bookingPreviousReportsFields(b),
      ...prescriptionFieldsForBooking(b, prescriptionMap.get(b.id), now),
    };
  });
}

module.exports = {
  getBookableSlots,
  holdConsultationSlot,
  releaseConsultationSlotHold,
  createOnlineConsultBooking,
  createHospitalVisitBooking,
  createHomeVisitBooking,
  createPendingBookingForPayment,
  confirmBookingAfterPayment,
  verifyClinicAppointment,
  listDoctorBookings,
  listPatientBookings,
  addPreviousReportToBooking,
  MAX_PREVIOUS_REPORTS,
};
