const { v4: uuidv4 } = require('uuid');
const BookingChatMessage = require('./models/BookingChatMessage');
const ConsultationBooking = require('./models/ConsultationBooking');
const LabBooking = require('./models/LabBooking');
const ScanBooking = require('./models/ScanBooking');
const { createAndPushNotification } = require('./notificationRepositories');

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
    booking.patientId &&
    auth.patientId === booking.patientId;

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
    kind === 'lab' &&
    auth?.type === 'lab' &&
    booking.labId &&
    auth.labId === booking.labId;

  const isScanCenter =
    kind === 'scan' &&
    auth?.type === 'scan_center' &&
    booking.scanCenterId &&
    auth.scanCenterId === booking.scanCenterId;

  if (!isPatient && !isDoctor && !isNurse && !isLab && !isScanCenter) {
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
      }
    } else if (booking.patientId) {
      await createAndPushNotification({
        userId: booking.patientId,
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
