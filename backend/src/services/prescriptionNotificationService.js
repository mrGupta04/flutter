const path = require('path');
const { getProvider } = require('./emailProviders');
const { resolveProviderName } = require('./emailProviders');

const APP_NAME = process.env.APP_NAME || 'MedConnect';

function buildPrescriptionEmailHtml({
  patientName,
  doctorName,
  slotLabel,
  pdfUrl,
}) {
  return `
    <div style="font-family:Arial,sans-serif;line-height:1.6;color:#1f2937;max-width:560px;">
      <h2 style="margin:0 0 12px;color:#208376;">Your prescription is ready</h2>
      <p style="margin:0 0 16px;">Hello ${patientName},</p>
      <p style="margin:0 0 16px;">
        Dr. <strong>${doctorName}</strong> has shared your prescription from your consultation on
        <strong>${slotLabel}</strong>.
      </p>
      <p style="margin:0 0 16px;">
        A PDF copy is attached to this email. You can also view it anytime in the
        <strong>My bookings</strong> section of the ${APP_NAME} app.
      </p>
      ${
        pdfUrl
          ? `<p style="margin:0 0 16px;">
        <a href="${pdfUrl}" style="color:#208376;word-break:break-all;">View prescription online</a>
      </p>`
          : ''
      }
      <p style="margin:0;font-size:13px;color:#9ca3af;">
        Please follow your doctor's advice. This email was sent automatically after your consultation.
      </p>
    </div>
  `;
}

function buildPrescriptionEmailText({
  patientName,
  doctorName,
  slotLabel,
  pdfUrl,
}) {
  return [
    `Hello ${patientName},`,
    '',
    `Dr. ${doctorName} has shared your prescription from your consultation on ${slotLabel}.`,
    '',
    'A PDF copy is attached to this email. You can also view it in the My bookings section of the app.',
    pdfUrl ? `Online link: ${pdfUrl}` : '',
    '',
    'Please follow your doctor\'s advice.',
  ]
    .filter(Boolean)
    .join('\n');
}

async function sendPrescriptionEmail({
  to,
  patientName,
  doctorName,
  slotLabel,
  pdfPath,
  pdfFileName,
  pdfUrl,
}) {
  if (!to) {
    return { sent: false, reason: 'Patient email not provided' };
  }

  const subject = `${APP_NAME} — Prescription from Dr. ${doctorName}`;
  const text = buildPrescriptionEmailText({
    patientName,
    doctorName,
    slotLabel,
    pdfUrl,
  });
  const html = buildPrescriptionEmailHtml({
    patientName,
    doctorName,
    slotLabel,
    pdfUrl,
  });

  const provider = getProvider();
  if (typeof provider.sendTransactionalEmail !== 'function') {
    console.log(`[prescription-email] Mock — would email ${to} with ${pdfFileName}`);
    return { sent: false, provider: resolveProviderName(), reason: 'Email provider unavailable' };
  }

  await provider.sendTransactionalEmail({
    to,
    subject,
    text,
    html,
    attachments: [
      {
        filename: pdfFileName || path.basename(pdfPath),
        path: pdfPath,
        contentType: 'application/pdf',
      },
    ],
  });

  return { sent: true, provider: resolveProviderName(), to };
}

module.exports = {
  sendPrescriptionEmail,
};
