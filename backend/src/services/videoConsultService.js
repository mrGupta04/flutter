const ConsultationBooking = require('../db/models/ConsultationBooking');

const { findDoctorById } = require('../db/repositories');

const { findPatientById } = require('../db/patientRepositories');

const { getVideoJoinWindow } = require('../utils/videoJoinWindow');

const { getAgoraConfig, buildRtcToken } = require('./agoraTokenService');



const PROVIDER = (process.env.VIDEO_PROVIDER || 'mock').toLowerCase();

const JITSI_BASE =

  process.env.JITSI_MEET_BASE_URL || 'https://meet.jit.si';



function normalizeMobile(mobile) {

  return String(mobile || '').replace(/\D/g, '').slice(-10);

}



function getProviderInfo() {

  const agora = getAgoraConfig();

  let configured = PROVIDER === 'mock' || PROVIDER === 'jitsi';

  if (PROVIDER === 'agora') {

    configured = agora.configured;

  }



  return {

    provider: PROVIDER,

    configured,

    jitsiBaseUrl: PROVIDER === 'jitsi' ? JITSI_BASE : null,

    agora: PROVIDER === 'agora' ? agora : null,

  };

}



function buildRoomId(bookingId) {

  const safe = String(bookingId || '')

    .replace(/[^a-zA-Z0-9]/g, '')

    .slice(0, 40);

  return `medconnect-${safe}`;

}



function buildJitsiJoinUrl(roomId, displayName) {

  const name = encodeURIComponent(displayName || 'Participant');

  return `${JITSI_BASE}/${roomId}#config.prejoinPageEnabled=false&userInfo.displayName="${name}"`;

}



async function findBookingForVideo(bookingId) {

  const booking = await ConsultationBooking.findOne({ id: bookingId }).lean();

  if (!booking) {

    const err = new Error('Booking not found');

    err.statusCode = 404;

    throw err;

  }

  if (booking.consultationType !== 'online_consult') {

    const err = new Error('Video calls are only available for online consultations');

    err.statusCode = 400;

    throw err;

  }

  if (booking.status !== 'confirmed') {

    const err = new Error('This consultation is not confirmed yet');

    err.statusCode = 409;

    throw err;

  }

  return booking;

}



async function assertBookingVideoAccess(auth, booking) {

  if (auth?.type === 'doctor' && auth.doctorId === booking.doctorId) {

    return { role: 'doctor' };

  }



  if (auth?.type === 'patient') {

    if (booking.patientId && booking.patientId === auth.patientId) {

      return { role: 'patient' };

    }

    const patient = await findPatientById(auth.patientId);

    const authMobile = normalizeMobile(patient?.mobileNumber);

    const bookingMobile = normalizeMobile(booking.patientMobile);

    if (

      authMobile.length === 10 &&

      bookingMobile.length === 10 &&

      authMobile === bookingMobile

    ) {

      return { role: 'patient' };

    }

  }



  const err = new Error('You are not allowed to join this consultation');

  err.statusCode = 403;

  throw err;

}



async function getVideoSession(bookingId, auth) {

  const booking = await findBookingForVideo(bookingId);

  const access = await assertBookingVideoAccess(auth, booking);

  const window = getVideoJoinWindow(booking.slotStart, booking.slotEnd);



  const doctor = await findDoctorById(booking.doctorId);

  const doctorName = doctor

    ? `${doctor.firstName || ''} ${doctor.lastName || ''}`.trim()

    : 'Doctor';



  const displayName =

    access.role === 'doctor' ? doctorName : booking.patientName || 'Patient';



  const roomId = booking.videoRoomId || buildRoomId(booking.id);



  const session = {

    bookingId: booking.id,

    consultationType: booking.consultationType,

    role: access.role,

    canJoin: window.canJoin,

    joinWindowStart: window.windowStart.toISOString(),

    joinWindowEnd: window.windowEnd.toISOString(),

    slotStart: new Date(booking.slotStart).toISOString(),

    slotEnd: new Date(booking.slotEnd).toISOString(),

    roomId,

    provider: PROVIDER,

    displayName,

    doctorName,

    patientName: booking.patientName,

    label: booking.label || null,

    videoCallStartedAt: booking.videoCallStartedAt || null,

    videoCallEndedAt: booking.videoCallEndedAt || null,

  };



  if (!window.canJoin) {

    session.message = window.isBeforeWindow

      ? 'Video call opens shortly before your scheduled time'

      : 'The video call window for this appointment has ended';

    return session;

  }



  if (PROVIDER === 'jitsi') {

    session.joinUrl = buildJitsiJoinUrl(roomId, displayName);

  } else if (PROVIDER === 'agora') {

    const agora = buildRtcToken(roomId, access.role);

    session.agoraAppId = agora.appId;

    session.agoraToken = agora.token;

    session.agoraChannel = agora.channelName;

    session.agoraUid = agora.uid;

    session.agoraTokenExpiresAt = agora.tokenExpiresAt;

    session.agoraTestingMode = agora.testingMode;

  } else {

    session.mockMode = true;

  }



  return session;

}



async function markVideoCallStarted(bookingId, auth) {

  const bookingDoc = await ConsultationBooking.findOne({ id: bookingId });

  if (!bookingDoc) {

    const err = new Error('Booking not found');

    err.statusCode = 404;

    throw err;

  }

  await assertBookingVideoAccess(auth, bookingDoc.toObject());



  const window = getVideoJoinWindow(bookingDoc.slotStart, bookingDoc.slotEnd);

  if (!window.canJoin) {

    const err = new Error('Video call is not available at this time');

    err.statusCode = 400;

    throw err;

  }



  if (!bookingDoc.videoRoomId) {

    bookingDoc.videoRoomId = buildRoomId(bookingDoc.id);

  }

  if (!bookingDoc.videoCallStartedAt) {

    bookingDoc.videoCallStartedAt = new Date();

  }

  await bookingDoc.save();



  return {

    bookingId: bookingDoc.id,

    videoRoomId: bookingDoc.videoRoomId,

    videoCallStartedAt: bookingDoc.videoCallStartedAt,

  };

}



async function markVideoCallEnded(bookingId, auth) {

  const bookingDoc = await ConsultationBooking.findOne({ id: bookingId });

  if (!bookingDoc) {

    const err = new Error('Booking not found');

    err.statusCode = 404;

    throw err;

  }

  await assertBookingVideoAccess(auth, bookingDoc.toObject());



  bookingDoc.videoCallEndedAt = new Date();

  await bookingDoc.save();



  return {

    bookingId: bookingDoc.id,

    videoCallEndedAt: bookingDoc.videoCallEndedAt,

  };

}



module.exports = {

  getVideoSession,

  markVideoCallStarted,

  markVideoCallEnded,

  getProviderInfo,

  buildRoomId,

};

