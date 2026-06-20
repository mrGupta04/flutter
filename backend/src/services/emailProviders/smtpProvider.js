const bcrypt = require('bcryptjs');
const nodemailer = require('nodemailer');

const OTP_TTL_MS = 10 * 60 * 1000;
const SMTP_TIMEOUT_MS = parseInt(process.env.SMTP_TIMEOUT_MS || '30000', 10);

function smtpTimeouts() {
  return {
    connectionTimeout: SMTP_TIMEOUT_MS,
    greetingTimeout: SMTP_TIMEOUT_MS,
    socketTimeout: SMTP_TIMEOUT_MS,
  };
}

function generateOtp() {
  return String(Math.floor(100000 + Math.random() * 900000));
}

function normalizeSmtpPass(pass) {
  // Google app passwords are 16 chars; users often paste "abcd efgh ijkl mnop".
  return String(pass || '').replace(/\s+/g, '').trim();
}

function readSmtpConfig() {
  const host = String(process.env.SMTP_HOST || '').trim();
  const port = Number(process.env.SMTP_PORT || 465);
  const user = String(process.env.SMTP_USER || '').trim();
  const pass = normalizeSmtpPass(process.env.SMTP_PASS);
  const service = String(process.env.SMTP_SERVICE || '').trim().toLowerCase();
  const secure =
    process.env.SMTP_SECURE === 'true' || port === 465;

  if (!user || !pass) {
    throw new Error('SMTP is not configured. Set SMTP_USER and SMTP_PASS.');
  }
  if (!service && !host) {
    throw new Error(
      'SMTP is not configured. Set SMTP_HOST=smtp.gmail.com or SMTP_SERVICE=gmail.',
    );
  }

  return { host, port, user, pass, service, secure };
}

function buildTransportOptions({ host, port, user, pass, secure }) {
  return {
    host,
    port,
    secure,
    auth: { user, pass },
    requireTLS: !secure && port === 587,
    tls: {
      minVersion: 'TLSv1.2',
    },
    ...smtpTimeouts(),
  };
}

function getTransportProfiles() {
  const config = readSmtpConfig();
  const { host, port, user, pass, service, secure } = config;

  if (service === 'gmail' && !host) {
    // Port 465 (SSL) is more reliable on cloud hosts like Render than 587 (STARTTLS).
    return [
      {
        label: '465',
        options: buildTransportOptions({
          host: 'smtp.gmail.com',
          port: 465,
          user,
          pass,
          secure: true,
        }),
      },
      {
        label: '587',
        options: buildTransportOptions({
          host: 'smtp.gmail.com',
          port: 587,
          user,
          pass,
          secure: false,
        }),
      },
    ];
  }

  const resolvedHost = host || (service === 'gmail' ? 'smtp.gmail.com' : host);
  return [
    {
      label: String(port),
      options: buildTransportOptions({
        host: resolvedHost,
        port,
        user,
        pass,
        secure,
      }),
    },
  ];
}

function isConnectionError(err) {
  const message = String(err?.message || err || '');
  return /timeout|ETIMEDOUT|ECONNREFUSED|ENETUNREACH|ECONNRESET|EPIPE/i.test(
    message,
  );
}

function smtpRenderHint() {
  return (
    ' Gmail SMTP uses ports 465/587 which are blocked on Render free tier. ' +
    'Upgrade to Starter, or switch to EMAIL_PROVIDER=gmail-api (same Gmail account, uses HTTPS and works on all Render tiers). ' +
    'Run: node scripts/gmailAuthSetup.js to get GMAIL_REFRESH_TOKEN.'
  );
}

async function withSmtpTransport(action) {
  const profiles = getTransportProfiles();
  let lastError;

  for (let index = 0; index < profiles.length; index += 1) {
    const profile = profiles[index];
    const transport = nodemailer.createTransport(profile.options);

    try {
      const result = await action(transport);
      if (index > 0) {
        console.log(
          `[email-smtp] Connected via Gmail port ${profile.label} (fallback)`,
        );
      }
      return result;
    } catch (err) {
      lastError = err;
      const hasFallback = index < profiles.length - 1;
      if (hasFallback && isConnectionError(err)) {
        console.warn(
          `[email-smtp] Gmail port ${profile.label} failed (${err.message}), trying next port...`,
        );
        continue;
      }
      throw err;
    } finally {
      transport.close?.();
    }
  }

  throw lastError || new Error('SMTP connection failed');
}

async function verifyConnection() {
  try {
    await withSmtpTransport(async (transport) => {
      await Promise.race([
        transport.verify(),
        new Promise((_, reject) => {
          setTimeout(
            () => reject(new Error('Connection timeout')),
            SMTP_TIMEOUT_MS,
          );
        }),
      ]);
    });
  } catch (err) {
    if (isConnectionError(err)) {
      throw new Error(err.message + smtpRenderHint());
    }
    throw err;
  }
}

function buildFromAddress() {
  const fromName = String(
    process.env.SMTP_FROM_NAME || process.env.APP_NAME || 'MedConnect Doctors',
  ).trim();
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
  const from = buildFromAddress();

  try {
    await withSmtpTransport((transport) =>
      transport.sendMail({
        from,
        to: email,
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
      }),
    );
  } catch (err) {
    const hint = isConnectionError(err) ? smtpRenderHint() : '';
    console.error('[email-smtp] Failed to send verification email:', err.message);
    throw new Error(
      'Unable to send verification email right now. Check Gmail SMTP settings and try again.' +
        hint,
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

async function sendTransactionalEmail({ to, subject, text, html, attachments }) {
  const from = buildFromAddress();

  await withSmtpTransport((transport) =>
    transport.sendMail({
      from,
      to,
      subject,
      text,
      html,
      attachments: attachments || undefined,
    }),
  );

  return { provider: 'smtp', message: `Email sent to ${to}.` };
}

module.exports = {
  sendOtp,
  verifyOtp,
  verifyConnection,
  sendTransactionalEmail,
  buildFromAddress,
  name: 'smtp',
};
