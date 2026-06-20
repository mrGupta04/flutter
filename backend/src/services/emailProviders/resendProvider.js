const fs = require('fs/promises');
const bcrypt = require('bcryptjs');

const OTP_TTL_MS = 10 * 60 * 1000;
const RESEND_TIMEOUT_MS = parseInt(process.env.RESEND_TIMEOUT_MS || '15000', 10);
const RESEND_API_URL = 'https://api.resend.com/emails';

function generateOtp() {
  return String(Math.floor(100000 + Math.random() * 900000));
}

function readResendConfig() {
  const apiKey = String(process.env.RESEND_API_KEY || '').trim();
  const fromEmail = String(
    process.env.RESEND_FROM || process.env.SMTP_FROM || process.env.SMTP_USER || '',
  ).trim();
  const fromName = String(
    process.env.RESEND_FROM_NAME || process.env.SMTP_FROM_NAME || process.env.APP_NAME || 'MedConnect Doctors',
  ).trim();

  if (!apiKey) {
    throw new Error('Resend is not configured. Set RESEND_API_KEY.');
  }
  if (!fromEmail) {
    throw new Error(
      'Resend sender is not configured. Set RESEND_FROM (or SMTP_FROM).',
    );
  }

  return {
    apiKey,
    from: `"${fromName}" <${fromEmail}>`,
  };
}

async function resendFetch(body) {
  const { apiKey } = readResendConfig();
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), RESEND_TIMEOUT_MS);

  try {
    const response = await fetch(RESEND_API_URL, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body),
      signal: controller.signal,
    });

    const json = await response.json().catch(() => ({}));
    if (!response.ok) {
      const detail = json.message || json.error || response.statusText;
      throw new Error(`Resend API error (${response.status}): ${detail}`);
    }

    return json;
  } catch (err) {
    if (err.name === 'AbortError') {
      throw new Error(`Resend request timed out after ${RESEND_TIMEOUT_MS}ms`);
    }
    throw err;
  } finally {
    clearTimeout(timeout);
  }
}

async function verifyConnection() {
  // Resend has no dedicated verify endpoint; a lightweight auth check is enough.
  readResendConfig();
  return { ok: true };
}

function buildVerificationEmailContent({ email, otp }) {
  const appName = process.env.APP_NAME || 'MedConnect Doctors';

  return {
    subject: `${appName} — your email verification code`,
    text: [
      'Hello,',
      '',
      `Use this code to verify your email for ${appName} doctor registration:`,
      '',
      otp,
      '',
      'This code expires in 10 minutes.',
      'If you did not request this, you can ignore this email.',
    ].join('\n'),
    html: `
      <div style="font-family:Arial,sans-serif;line-height:1.5;color:#1f2937;max-width:520px;">
        <h2 style="margin:0 0 12px;">Verify your email</h2>
        <p style="margin:0 0 16px;">
          Enter this verification code in the ${appName} doctor registration form:
        </p>
        <p style="margin:0 0 20px;font-size:28px;font-weight:700;letter-spacing:6px;color:#208376;">
          ${otp}
        </p>
        <p style="margin:0;color:#6b7280;font-size:14px;">
          This code expires in 10 minutes. If you did not request this, you can ignore this email.
        </p>
      </div>
    `,
  };
}

async function sendVerificationEmail({ email, otp }) {
  const { from } = readResendConfig();
  const { subject, text, html } = buildVerificationEmailContent({ email, otp });

  try {
    await resendFetch({
      from,
      to: [email],
      subject,
      text,
      html,
    });
  } catch (err) {
    console.error('[email-resend] Failed to send verification email:', err.message);
    throw new Error(
      'Unable to send verification email right now. Check Resend settings and try again.',
    );
  }

  return {
    provider: 'resend',
    message: `Verification code sent to ${email}.`,
  };
}

async function sendOtp({ email }) {
  const otp = generateOtp();
  const delivery = await sendVerificationEmail({ email, otp });

  return {
    provider: 'resend',
    otpHash: bcrypt.hashSync(otp, 10),
    expiresAt: new Date(Date.now() + OTP_TTL_MS),
    message: delivery.message,
  };
}

async function verifyOtp({ record, otp }) {
  const valid = bcrypt.compareSync(String(otp).trim(), record.otpHash || '');
  return { valid };
}

async function encodeAttachments(attachments = []) {
  const encoded = [];

  for (const attachment of attachments) {
    if (attachment.content) {
      encoded.push({
        filename: attachment.filename || 'attachment',
        content:
          typeof attachment.content === 'string'
            ? attachment.content
            : attachment.content.toString('base64'),
        content_type: attachment.contentType || undefined,
      });
      continue;
    }

    if (attachment.path) {
      const buffer = await fs.readFile(attachment.path);
      encoded.push({
        filename: attachment.filename || attachment.path.split(/[/\\]/).pop(),
        content: buffer.toString('base64'),
        content_type: attachment.contentType || undefined,
      });
    }
  }

  return encoded;
}

async function sendTransactionalEmail({ to, subject, text, html, attachments }) {
  const { from } = readResendConfig();
  const body = {
    from,
    to: [to],
    subject,
    text,
    html,
  };

  if (attachments?.length) {
    body.attachments = await encodeAttachments(attachments);
  }

  await resendFetch(body);
  return { provider: 'resend', message: `Email sent to ${to}.` };
}

module.exports = {
  sendOtp,
  verifyOtp,
  verifyConnection,
  sendTransactionalEmail,
  name: 'resend',
};
