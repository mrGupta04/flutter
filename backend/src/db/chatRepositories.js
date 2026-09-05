const { v4: uuidv4 } = require('uuid');
const BookingChatMessage = require('./models/BookingChatMessage');
const ConsultationBooking = require('./models/ConsultationBooking');
const LabBooking = require('./models/LabBooking');
const ScanBooking = require('./models/ScanBooking');
const PrescriptionRequest = require('./models/PrescriptionRequest');
const PrescriptionQuotation = require('./models/PrescriptionQuotation');
const BloodOrder = require('./models/BloodOrder');
const AmbulanceBooking = require('./models/AmbulanceBooking');
const { createAndPushNotification } = require('./notificationRepositories');
const { isActiveTrip } = require('../services/ambulanceStatus');

function bloodOrderChatAllowed(booking, allowed) {
  return Boolean(booking.chatEnabled) || allowed.has(booking.status);
}

const LAB_CHAT_STATUSES = new Set([
  'confirmed',
  'sample_collected',
  'processing',
  'report_ready',
]);

const SCAN_CHAT_STATUSES = new Set([
  'confirmed',
  'in_progress',
  'report_ready',
]);

async function resolveBooking(bookingId) {
  const consultation = await ConsultationBooking.findOne({ id: bookingId }).lean();
  if (consultation) {
    return { kind: 'consultation', booking: consultation };
  }

  const lab = await LabBooking.findOne({ id: bookingId }).lean();
  if (lab) {
    return { kind: 'lab', booking: lab };
  }

  const scan = await ScanBooking.findOne({ id: bookingId }).lean();
  if (scan) {
    return { kind: 'scan', booking: scan };
  }

  const prescription = await PrescriptionRequest.findOne({ id: bookingId }).lean();
  if (prescription) {
    return { kind: 'prescription_request', booking: prescription };
  }

  const bloodOrder = await BloodOrder.findOne({ id: bookingId }).lean();
  if (bloodOrder) {
    return { kind: 'blood', booking: bloodOrder };
  }

  const ambulance = await AmbulanceBooking.findOne({ id: bookingId }).lean();
  if (ambulance) {
    return { kind: 'ambulance', booking: ambulance };
  }

  return null;
}

function assertChatAllowed(kind, booking) {
  if (kind === 'consultation') {
    if (booking.status !== 'confirmed') {
      const err = new Error('Chat is only available for confirmed bookings');
      err.statusCode = 403;
      throw err;
    }
    return;
  }
  if (kind === 'lab') {
    if (!LAB_CHAT_STATUSES.has(booking.status)) {
      const err = new Error(
        'Chat is available after the lab confirms your booking',
      );
      err.statusCode = 403;
      throw err;
    }
    return;
  }
  if (kind === 'scan') {
    if (!SCAN_CHAT_STATUSES.has(booking.status)) {
      const err = new Error(
        'Chat is available after the scan center confirms your booking',
      );
      err.statusCode = 403;
      throw err;
    }
    return;
  }
  if (kind === 'blood') {
    const allowed = new Set([
      'accepted',
      'blood_reserved',
      'payment_pickup',
      'ready_for_collection',
      'blood_ready',
      'out_for_delivery',
      'collected',
      'completed',
    ]);
    if (!bloodOrderChatAllowed(booking, allowed)) {
      const err = new Error('Chat is available after the blood bank accepts your request');
      err.statusCode = 403;
      throw err;
    }
    return;
  }
  if (kind === 'ambulance') {
    if (
      !isActiveTrip(booking.status) &&
      !['accepted', 'trip_completed', 'completed'].includes(booking.status)
    ) {
      const err = new Error('Chat is available after an ambulance is assigned');
      err.statusCode = 403;
      throw err;
    }
    return;
  }
  if (kind === 'prescription_request') {
    if (booking.paymentStatus !== 'PAID' || !booking.chatEnabled) {
      const err = new Error(
        'Chat will be available after payment confirmation.',
      );
      err.statusCode = 403;
      throw err;
    }
    if (!booking.selectedLabId) {
      const err = new Error('No lab selected for this prescription request');
      err.statusCode = 403;
      throw err;
    }
  }
}

async function assertChatParticipant(bookingId, auth) {
  const resolved = await resolveBooking(bookingId);
  if (!resolved) {
    const err = new Error('Booking not found');
    err.statusCode = 404;
    throw err;
  }

  const { kind, booking } = resolved;
  assertChatAllowed(kind, booking);

  const isPatient =
    auth?.type === 'patient' &&
    ((booking.patientId && auth.patientId === booking.patientId) ||
      (kind === 'prescription_request' &&
        booking.userId &&
        auth.patientId === booking.userId));

  const isDoctor =
    kind === 'consultation' &&
    auth?.type === 'doctor' &&
    booking.doctorId &&
    auth.doctorId === booking.doctorId;

  const isNurse =
    kind === 'consultation' &&
    auth?.type === 'nurse' &&
    booking.nurseId &&
    auth.nurseId === booking.nurseId;

  const isLab =
    (kind === 'lab' &&
      auth?.type === 'lab' &&
      booking.labId &&
      auth.labId === booking.labId) ||
    (kind === 'prescription_request' &&
      auth?.type === 'lab' &&
      booking.selectedLabId &&
      auth.labId === booking.selectedLabId);

  const isBloodBank =
    kind === 'blood' &&
    (auth?.type === 'bloodbank' || auth?.type === 'blood_bank_staff') &&
    booking.bloodBankId &&
    auth.bloodBankId === booking.bloodBankId;

  const isScanCenter =
    (kind === 'scan' &&
      auth?.type === 'scan_center' &&
      booking.scanCenterId &&
      auth.scanCenterId === booking.scanCenterId) ||
    (kind === 'prescription_request' &&
      auth?.type === 'scan_center' &&
      booking.selectedLabId &&
      auth.scanCenterId === booking.selectedLabId);

  const isAmbulance =
    kind === 'ambulance' &&
    (auth?.type === 'ambulance' || auth?.type === 'ambulance_driver') &&
    booking.ambulanceId &&
    auth.ambulanceId === booking.ambulanceId;

  if (!isPatient && !isDoctor && !isNurse && !isLab && !isScanCenter && !isBloodBank && !isAmbulance) {
    const err = new Error('You are not allowed to access this chat');
    err.statusCode = 403;
    throw err;
  }

  return {
    kind,
    booking,
    isPatient,
    isDoctor,
    isNurse,
    isLab,
    isScanCenter,
    isBloodBank,
    isAmbulance,
  };
}

async function listChatMessages(bookingId, auth, { after } = {}) {
  await assertChatParticipant(bookingId, auth);
  const filter = { bookingId };
  if (after) {
    const afterDate = new Date(after);
    if (!Number.isNaN(afterDate.getTime())) {
      filter.createdAt = { $gt: afterDate };
    }
  }
  const messages = await BookingChatMessage.find(filter)
    .sort({ createdAt: 1 })
    .limit(200)
    .lean();
  return messages;
}

async function sendChatMessage(bookingId, auth, body) {
  const text = String(body || '').trim();
  if (!text) {
    const err = new Error('Message body is required');
    err.statusCode = 400;
    throw err;
  }
  if (text.length > 2000) {
    const err = new Error('Message is too long');
    err.statusCode = 400;
    throw err;
  }

  const {
    booking,
    isPatient,
    isDoctor,
    isNurse,
    isLab,
    isScanCenter,
    isBloodBank,
    isAmbulance,
  } = await assertChatParticipant(bookingId, auth);

  let senderType = 'patient';
  let senderId = auth.patientId;
  if (isDoctor) {
    senderType = 'doctor';
    senderId = auth.doctorId;
  } else if (isNurse) {
    senderType = 'nurse';
    senderId = auth.nurseId;
  } else if (isLab) {
    senderType = 'lab';
    senderId = auth.labId;
  } else if (isScanCenter) {
    senderType = 'scan_center';
    senderId = auth.scanCenterId;
  } else if (isBloodBank) {
    senderType = 'blood_bank';
    senderId = auth.bloodBankId;
  } else if (isAmbulance) {
    senderType = auth.type === 'ambulance_driver' ? 'ambulance_driver' : 'ambulance';
    senderId = auth.driverId || auth.ambulanceId;
  }

  const message = await BookingChatMessage.create({
    id: uuidv4(),
    bookingId,
    senderType,
    senderId,
    body: text,
  });

  const payload = message.toObject();
  try {
    const { emitChatMessage } = require('../services/chatRealtime');
    emitChatMessage(bookingId, payload);
  } catch (_) {
    // Realtime fan-out is best-effort.
  }

  try {
    if (isPatient) {
      if (booking.doctorId) {
        await createAndPushNotification({
          userId: booking.doctorId,
          userType: 'doctor',
          title: 'New message',
          body: text.slice(0, 120),
          type: 'chat_message',
          data: { bookingId },
        });
      } else if (booking.nurseId) {
        await createAndPushNotification({
          userId: booking.nurseId,
          userType: 'nurse',
          title: 'New message',
          body: text.slice(0, 120),
          type: 'chat_message',
          data: { bookingId },
        });
      } else if (booking.labId) {
        await createAndPushNotification({
          userId: booking.labId,
          userType: 'lab',
          title: 'New message',
          body: text.slice(0, 120),
          type: 'chat_message',
          data: { bookingId },
        });
      } else if (booking.scanCenterId) {
        await createAndPushNotification({
          userId: booking.scanCenterId,
          userType: 'scan_center',
          title: 'New message',
          body: text.slice(0, 120),
          type: 'chat_message',
          data: { bookingId },
        });
      } else if (booking.bloodBankId) {
        await createAndPushNotification({
          userId: booking.bloodBankId,
          userType: 'bloodbank',
          title: 'New message',
          body: text.slice(0, 120),
          type: 'chat_message',
          data: { bookingId },
        });
      } else if (booking.ambulanceId) {
        await createAndPushNotification({
          userId: booking.ambulanceId,
          userType: 'ambulance',
          title: 'New message',
          body: text.slice(0, 120),
          type: 'chat_message',
          data: { bookingId },
        });
      } else if (booking.selectedLabId) {
        const quotation = await PrescriptionQuotation.findOne({
          prescriptionRequestId: bookingId,
          labId: booking.selectedLabId,
        }).lean();
        await createAndPushNotification({
          userId: booking.selectedLabId,
          userType:
            quotation?.providerType === 'scan_center' ? 'scan_center' : 'lab',
          title: 'New message',
          body: text.slice(0, 120),
          type: 'chat_message',
          data: { bookingId, prescriptionRequestId: bookingId },
        });
      }
    } else if (booking.patientId || booking.userId) {
      await createAndPushNotification({
        userId: booking.patientId || booking.userId,
        userType: 'patient',
        title: 'New message',
        body: text.slice(0, 120),
        type: 'chat_message',
        data: { bookingId },
      });
    }
  } catch (err) {
    console.error('[Chat] notification failed:', err.message);
  }

  return message.toObject();
}

module.exports = {
  listChatMessages,
  sendChatMessage,
  assertChatParticipant,
};