const { v4: uuidv4 } = require('uuid');
const BookingChatMessage = require('./models/BookingChatMessage');
const ConsultationBooking = require('./models/ConsultationBooking');
const { createAndPushNotification } = require('./notificationRepositories');

async function assertChatParticipant(bookingId, auth) {
  const booking = await ConsultationBooking.findOne({ id: bookingId }).lean();
  if (!booking) {
    const err = new Error('Booking not found');
    err.statusCode = 404;
    throw err;
  }
  if (booking.status !== 'confirmed') {
    const err = new Error('Chat is only available for confirmed bookings');
    err.statusCode = 403;
    throw err;
  }

  const isPatient =
    auth?.type === 'patient' && auth.patientId === booking.patientId;
  const isDoctor =
    auth?.type === 'doctor' &&
    booking.doctorId &&
    auth.doctorId === booking.doctorId;
  const isNurse =
    auth?.type === 'nurse' &&
    booking.nurseId &&
    auth.nurseId === booking.nurseId;

  if (!isPatient && !isDoctor && !isNurse) {
    const err = new Error('You are not allowed to access this chat');
    err.statusCode = 403;
    throw err;
  }

  return { booking, isPatient, isDoctor, isNurse };
}

async function listChatMessages(bookingId, auth) {
  await assertChatParticipant(bookingId, auth);
  const messages = await BookingChatMessage.find({ bookingId })
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

  const { booking, isPatient, isDoctor, isNurse } = await assertChatParticipant(
    bookingId,
    auth,
  );

  const senderType = isPatient ? 'patient' : isDoctor ? 'doctor' : 'nurse';
  const senderId = isPatient
    ? auth.patientId
    : isDoctor
      ? auth.doctorId
      : auth.nurseId;

  const message = await BookingChatMessage.create({
    id: uuidv4(),
    bookingId,
    senderType,
    senderId,
    body: text,
  });

  // Notify the other party
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
