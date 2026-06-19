const { formatSlotLabel } = require('../utils/slotDateTime');
const { sendSms } = require('./smsService');
const { resolveProviderName } = require('./emailProviders');
const smtpProvider = require('./emailProviders/smtpProvider');

const APP_NAME = process.env.APP_NAME || 'MedConnect';

function buildMeetingLink(bookingId, audience) {
  const prefix =
    audience === 'doctor'
      ? process.env.DOCTOR_MEETING_LINK_PREFIX ||
        'medconnect-doctor://video-consult?bookingId='
      : process.env.PATIENT_MEETING_LINK_PREFIX ||
        'medconnect://video-consult?bookingId=';
  return `${prefix}${bookingId}`;
}

function buildConfirmationEmailHtml({
  recipientName,
  isDoctor,
  peerName,
  slotLabel,
  meetingLink,
  bookingId,
}) {
  const roleLabel = isDoctor ? 'doctor' : 'patient';
  const joinInstructions = isDoctor
    ? 'Open the MedConnect Doctor app, go to your dashboard, and tap <strong>Join video call</strong> at the scheduled time.'
    : 'Open the MedConnect Care app, go to <strong>My appointments</strong>, and tap <strong>Join video call</strong> at the scheduled time.';

  return `
    <div style="font-family:Arial,sans-serif;line-height:1.6;color:#1f2937;max-width:560px;">
      <h2 style="margin:0 0 12px;color:#208376;">Online consultation confirmed</h2>
      <p style="margin:0 0 16px;">Hello ${recipientName},</p>
      <p style="margin:0 0 16px;">
        Your online video consultation with <strong>${peerName}</strong> is confirmed.
      </p>
      <table style="width:100%;border-collapse:collapse;margin:0 0 20px;">
        <tr>
          <td style="padding:8px 0;color:#6b7280;">Appointment</td>
          <td style="padding:8px 0;font-weight:600;">${slotLabel}</td>
        </tr>
        <tr>
          <td style="padding:8px 0;color:#6b7280;">Booking ID</td>
          <td style="padding:8px 0;font-family:monospace;">${bookingId}</td>
        </tr>
      </table>
      <p style="margin:0 0 12px;font-weight:600;">Your video meeting link</p>
      <p style="margin:0 0 16px;">
        <a href="${meetingLink}" style="color:#208376;word-break:break-all;">${meetingLink}</a>
      </p>
      <p style="margin:0 0 20px;font-size:14px;color:#4b5563;">${joinInstructions}</p>
      <p style="margin:0;font-size:13px;color:#9ca3af;">
        Video calls open 10 minutes before your slot. Join as ${roleLabel} using the link above or from the app.
      </p>
    </div>
  `;
}

function buildConfirmationEmailText({
  recipientName,
  isDoctor,
  peerName,
  slotLabel,
  meetingLink,
  bookingId,
}) {
  const joinHint = isDoctor
    ? 'Open the MedConnect Doctor app → Dashboard → Join video call.'
    : 'Open the MedConnect Care app → My appointments → Join video call.';

  return [
    `Hello ${recipientName},`,
    '',
    `Your online video consultation with ${peerName} is confirmed.`,
    '',
    `Appointment: ${slotLabel}`,
    `Booking ID: ${bookingId}`,
    '',
    'Your video meeting link:',
    meetingLink,
    '',
    joinHint,
    '',
    'Video calls open 10 minutes before your scheduled time.',
    '',
    `— ${APP_NAME}`,
  ].join('\n');
}

async function sendBookingEmail({ to, subject, text, html }) {
  const provider = resolveProviderName();

  if (provider === 'mock') {
    console.log(`[email-mock] Booking confirmation to ${to}`);
    console.log(`[email-mock] Subject: ${subject}`);
    console.log(text);
    return { sent: true, provider: 'mock' };
  }

  await smtpProvider.sendTransactionalEmail({ to, subject, text, html });
  return { sent: true, provider: 'smtp' };
}

async function notifyBookingConfirmed({ booking, doctor }) {
  if (booking.consultationType !== 'online_consult') {
    return { skipped: true, reason: 'not_online_consult' };
  }

  const doctorName = `${doctor.firstName || ''} ${doctor.lastName || ''}`.trim() || 'Doctor';
  const patientName = booking.patientName || 'Patient';
  const slotLabel = formatSlotLabel(
    new Date(booking.slotStart),
    new Date(booking.slotEnd),
  );
  const bookingId = booking.id;

  const patientLink = buildMeetingLink(bookingId, 'patient');
  const doctorLink = buildMeetingLink(bookingId, 'doctor');
  const subject = `${APP_NAME} — Online consultation confirmed (${slotLabel})`;

  const results = {
    patientEmail: null,
    doctorEmail: null,
    patientSms: null,
    doctorSms: null,
    patientMeetingLink: patientLink,
    doctorMeetingLink: doctorLink,
  };

  const patientEmail = String(booking.patientEmail || '').trim();
  if (patientEmail && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(patientEmail)) {
    try {
      results.patientEmail = await sendBookingEmail({
        to: patientEmail,
        subject,
        text: buildConfirmationEmailText({
          recipientName: patientName,
          isDoctor: false,
          peerName: doctorName,
          slotLabel,
          meetingLink: patientLink,
          bookingId,
        }),
        html: buildConfirmationEmailHtml({
          recipientName: patientName,
          isDoctor: false,
          peerName: doctorName,
          slotLabel,
          meetingLink: patientLink,
          bookingId,
        }),
      });
    } catch (err) {
      console.error('[booking-notify] Patient email failed:', err.message);
      results.patientEmail = { sent: false, error: err.message };
    }
  }

  const doctorEmail = String(doctor.email || '').trim();
  if (doctorEmail && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(doctorEmail)) {
    try {
      results.doctorEmail = await sendBookingEmail({
        to: doctorEmail,
        subject: `${APP_NAME} — New online consult: ${patientName} (${slotLabel})`,
        text: buildConfirmationEmailText({
          recipientName: doctorName,
          isDoctor: true,
          peerName: patientName,
          slotLabel,
          meetingLink: doctorLink,
          bookingId,
        }),
        html: buildConfirmationEmailHtml({
          recipientName: doctorName,
          isDoctor: true,
          peerName: patientName,
          slotLabel,
          meetingLink: doctorLink,
          bookingId,
        }),
      });
    } catch (err) {
      console.error('[booking-notify] Doctor email failed:', err.message);
      results.doctorEmail = { sent: false, error: err.message };
    }
  }

  const patientMobile = String(booking.patientMobile || '').replace(/\D/g, '').slice(-10);
  if (patientMobile.length === 10) {
    const smsText = `${APP_NAME}: Online consult with Dr. ${doctorName} on ${slotLabel}. Join: ${patientLink}`;
    results.patientSms = await sendSms(patientMobile, smsText);
  }

  const doctorMobile = String(doctor.mobileNumber || '').replace(/\D/g, '').slice(-10);
  if (doctorMobile.length === 10) {
    const smsText = `${APP_NAME}: Online consult with ${patientName} on ${slotLabel}. Join: ${doctorLink}`;
    results.doctorSms = await sendSms(doctorMobile, smsText);
  }

  return results;
}

module.exports = {
  notifyBookingConfirmed,
  buildMeetingLink,
};
