const net = require('net');
const bcrypt = require('bcryptjs');
const nodemailer = require('nodemailer');

const OTP_TTL_MS = 10 * 60 * 1000;
const SMTP_TIMEOUT_MS = parseInt(
  process.env.SMTP_TIMEOUT_MS ||
    (process.env.RENDER === 'true' ? '60000' : '30000'),
  10,
);

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
  return String(pass || '').replace(/\s+/g, '').trim();
}

function readSmtpConfig() {
  const host = String(process.env.SMTP_HOST || '').trim();
  const port = Number(process.env.SMTP_PORT || 465);
  const user = String(process.env.SMTP_USER || '').trim();
  const pass = normalizeSmtpPass(process.env.SMTP_PASS);
  const service = String(process.env.SMTP_SERVICE || '').trim().toLowerCase();
  const secure = process.env.SMTP_SECURE === 'true' || port === 465;

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

function isGmailSmtp(config) {
  const host = String(config.host || '').toLowerCase();
  return config.service === 'gmail' || host === 'smtp.gmail.com';
}

function buildTransportOptions({ host, port, user, pass, secure }) {
  return {
    host,
    port,
    secure,
    auth: { user, pass },
    pool: false,
    family: 4,
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

  if (isGmailSmtp(config)) {
    const preferredPort = Number.isFinite(port) ? port : 465;
    const ports =
      preferredPort === 587 ? [587, 465] : [465, 587];

    return ports.map((smtpPort) => ({
      label: String(smtpPort),
      options: buildTransportOptions({
        host: 'smtp.gmail.com',
        port: smtpPort,
        user,
        pass,
        secure: smtpPort === 465,
      }),
    }));
  }

  const resolvedHost = host || 'localhost';
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

function getSmtpConfigSummary() {
  const config = readSmtpConfig();
  const profiles = getTransportProfiles();
  return {
    host: isGmailSmtp(config) ? 'smtp.gmail.com' : config.host,
    ports: profiles.map((profile) => profile.label),
    user: config.user,
    secure: config.secure,
    timeoutMs: SMTP_TIMEOUT_MS,
    onRender: process.env.RENDER === 'true',
  };
}

function logSmtpConfigSummary() {
  try {
    const summary = getSmtpConfigSummary();
    console.log(
      `[email-smtp] Config: ${summary.host}:${summary.ports.join('/')} user=${summary.user} timeout=${summary.timeoutMs}ms render=${summary.onRender}`,
    );
  } catch (err) {
    console.warn(`[email-smtp] Config incomplete: ${err.message}`);
  }
}

function probeTcpPort(host, port, timeoutMs = 10000) {
  return new Promise((resolve) => {
    const socket = net.connect({
      host,
      port,
      family: 4,
    });

    const finish = (open) => {
      socket.removeAllListeners();
      socket.destroy();
      resolve(open);
    };

    socket.setTimeout(timeoutMs);
    socket.once('connect', () => finish(true));
    socket.once('timeout', () => finish(false));
    socket.once('error', () => finish(false));
  });
}

function isConnectionError(err) {
  const message = String(err?.message || err || '');
  return /timeout|ETIMEDOUT|ECONNREFUSED|ENETUNREACH|ECONNRESET|EPIPE/i.test(
    message,
  );
}

function smtpRenderHint() {
  if (process.env.RENDER === 'true') {
    return (
      ' On Render: set EMAIL_PROVIDER=smtp, SMTP_HOST=smtp.gmail.com, SMTP_PORT=465, SMTP_SECURE=true, SMTP_USER, SMTP_PASS (Google App Password). ' +
      'Confirm Instance Type is Starter (not Free), save env vars, then Manual Deploy. ' +
      'If TCP probe shows ports blocked, the service is still on Free tier.'
    );
  }

  return (
    ' Use SMTP_HOST=smtp.gmail.com, SMTP_PORT=465, SMTP_SECURE=true, and a Google App Password.'
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
  logSmtpConfigSummary();

  const config = readSmtpConfig();
  if (isGmailSmtp(config)) {
    const probe465 = await probeTcpPort('smtp.gmail.com', 465, 10000);
    const probe587 = await probeTcpPort('smtp.gmail.com', 587, 10000);
    console.log(
      `[email-smtp] TCP probe smtp.gmail.com:465=${probe465 ? 'open' : 'blocked'} smtp.gmail.com:587=${probe587 ? 'open' : 'blocked'}`,
    );

    if (!probe465 && !probe587) {
      throw new Error(
        'Cannot reach Gmail SMTP ports (465/587). Render free tier blocks outbound SMTP — upgrade to Starter and redeploy.' +
          smtpRenderHint(),
      );
    }
  }

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
  getSmtpConfigSummary,
  logSmtpConfigSummary,
  name: 'smtp',
};
