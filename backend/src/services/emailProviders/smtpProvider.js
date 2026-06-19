const bcrypt = require('bcryptjs');
const nodemailer = require('nodemailer');

const OTP_TTL_MS = 10 * 60 * 1000;

function generateOtp() {
  return String(Math.floor(100000 + Math.random() * 900000));
}

function readSmtpConfig() {
  const host = String(process.env.SMTP_HOST || '').trim();
  const port = Number(process.env.SMTP_PORT || 587);
  const user = String(process.env.SMTP_USER || '').trim();
  const pass = String(process.env.SMTP_PASS || '').trim();
  const service = String(process.env.SMTP_SERVICE || '').trim();
  const secure =
    process.env.SMTP_SECURE === 'true' || port === 465;

  if (!user || !pass) {
    throw new Error('SMTP is not configured. Set SMTP_USER and SMTP_PASS.');
  }
  if (!service && !host) {
    throw new Error(
      'SMTP is not configured. Set SMTP_SERVICE (e.g. gmail) or SMTP_HOST.',
    );
  }

  return { host, port, user, pass, service, secure };
}

function createTransport() {
  const { host, port, user, pass, service, secure } = readSmtpConfig();

  if (service) {
    return nodemailer.createTransport({
      service,
      auth: { user, pass },
    });
  }

  return nodemailer.createTransport({
    host,
    port,
    secure,
    auth: { user, pass },
    requireTLS: !secure && port === 587,
    tls: {
      minVersion: 'TLSv1.2',
    },
  });
}

let cachedTransport = null;

function getTransport() {
  if (!cachedTransport) {
    cachedTransport = createTransport();
  }
  return cachedTransport;
}

async function verifyConnection() {
  const transport = getTransport();
  await transport.verify();
}

function buildFromAddress() {
  const fromName = String(process.env.SMTP_FROM_NAME || process.env.APP_NAME || 'MedConnect Doctors').trim();
  const fromEmail = String(
    process.env.SMTP_FROM || process.env.SMTP_USER || '',
  ).trim();

  if (!fromEmail) {
    throw new Error('SMTP_FROM or SMTP_USER must be set for the sender address.');
  }

  return `"${fromName}" <${fromEmail}>`;
}

async function sendVerificationEmail({ email, otp }) {
  const appName = process.env.APP_NAME || 'MedConnect Doctors';
  const transport = getTransport();
  const from = buildFromAddress();

  try {
    await transport.sendMail({
      from,
      to: email,
      subject: `${appName} — your email verification code`,
      text: [
        `Hello,`,
        ``,
        `Use this code to verify your email for ${appName} doctor registration:`,
        ``,
        `${otp}`,
        ``,
        `This code expires in 10 minutes.`,
        `If you did not request this, you can ignore this email.`,
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
    });
  } catch (err) {
    console.error('[email-smtp] Failed to send verification email:', err.message);
    throw new Error(
      'Unable to send verification email right now. Check SMTP settings and try again.',
    );
  }

  return {
    provider: 'smtp',
    message: `Verification code sent to ${email}.`,
  };
}

async function sendOtp({ email }) {
  const otp = generateOtp();
  const delivery = await sendVerificationEmail({ email, otp });

  return {
    provider: 'smtp',
    otpHash: bcrypt.hashSync(otp, 10),
    expiresAt: new Date(Date.now() + OTP_TTL_MS),
    message: delivery.message,
  };
}

async function verifyOtp({ record, otp }) {
  const valid = bcrypt.compareSync(String(otp).trim(), record.otpHash || '');
  return { valid };
}

async function sendTransactionalEmail({ to, subject, text, html }) {
  const transport = getTransport();
  const from = buildFromAddress();

  await transport.sendMail({
    from,
    to,
    subject,
    text,
    html,
  });

  return { provider: 'smtp', message: `Email sent to ${to}.` };
}

module.exports = {
  sendOtp,
  verifyOtp,
  verifyConnection,
  sendTransactionalEmail,
  getTransport,
  buildFromAddress,
  name: 'smtp',
};
