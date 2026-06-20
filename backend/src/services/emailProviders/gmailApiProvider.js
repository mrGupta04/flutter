const bcrypt = require('bcryptjs');
const MailComposer = require('nodemailer/lib/mail-composer');

const OTP_TTL_MS = 10 * 60 * 1000;
const GMAIL_API_TIMEOUT_MS = parseInt(
  process.env.GMAIL_API_TIMEOUT_MS || '15000',
  10,
);

function readGmailApiConfig() {
  const clientId = String(process.env.GMAIL_CLIENT_ID || '').trim();
  const clientSecret = String(process.env.GMAIL_CLIENT_SECRET || '').trim();
  const refreshToken = String(process.env.GMAIL_REFRESH_TOKEN || '').trim();
  const user = String(
    process.env.GMAIL_USER || process.env.SMTP_USER || process.env.SMTP_FROM || '',
  ).trim();

  if (!clientId || !clientSecret || !refreshToken) {
    throw new Error(
      'Gmail API is not configured. Set GMAIL_CLIENT_ID, GMAIL_CLIENT_SECRET, and GMAIL_REFRESH_TOKEN.',
    );
  }
  if (!user) {
    throw new Error('Gmail API sender is not configured. Set GMAIL_USER.');
  }

  return { clientId, clientSecret, refreshToken, user };
}

function buildFromAddress(user) {
  const fromName = String(
    process.env.SMTP_FROM_NAME || process.env.APP_NAME || 'MedConnect Doctors',
  ).trim();
  return `"${fromName}" <${user}>`;
}

async function gmailFetch(url, options = {}) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), GMAIL_API_TIMEOUT_MS);

  try {
    const response = await fetch(url, {
      ...options,
      signal: controller.signal,
    });
    const json = await response.json().catch(() => ({}));
    if (!response.ok) {
      const detail = json.error?.message || json.error || response.statusText;
      throw new Error(`Gmail API error (${response.status}): ${detail}`);
    }
    return json;
  } catch (err) {
    if (err.name === 'AbortError') {
      throw new Error(`Gmail API request timed out after ${GMAIL_API_TIMEOUT_MS}ms`);
    }
    throw err;
  } finally {
    clearTimeout(timeout);
  }
}

async function getAccessToken() {
  const { clientId, clientSecret, refreshToken } = readGmailApiConfig();

  const json = await gmailFetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      client_id: clientId,
      client_secret: clientSecret,
      refresh_token: refreshToken,
      grant_type: 'refresh_token',
    }),
  });

  if (!json.access_token) {
    throw new Error('Gmail API did not return an access token. Check OAuth credentials.');
  }

  return json.access_token;
}

function buildRawMessage(mailOptions) {
  return new Promise((resolve, reject) => {
    const mail = new MailComposer(mailOptions);
    mail.compile().build((err, message) => {
      if (err) {
        reject(err);
        return;
      }
      resolve(
        Buffer.from(message)
          .toString('base64')
          .replace(/\+/g, '-')
          .replace(/\//g, '_')
          .replace(/=+$/, ''),
      );
    });
  });
}

async function sendRawEmail(mailOptions) {
  const accessToken = await getAccessToken();
  const raw = await buildRawMessage(mailOptions);

  await gmailFetch('https://gmail.googleapis.com/gmail/v1/users/me/messages/send', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ raw }),
  });
}

function generateOtp() {
  return String(Math.floor(100000 + Math.random() * 900000));
}

async function verifyConnection() {
  await getAccessToken();
  return { ok: true };
}

async function sendVerificationEmail({ email, otp }) {
  const { user } = readGmailApiConfig();
  const appName = process.env.APP_NAME || 'MedConnect Doctors';
  const from = buildFromAddress(user);

  try {
    await sendRawEmail({
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
    });
  } catch (err) {
    console.error('[email-gmail-api] Failed to send verification email:', err.message);
    throw new Error(
      'Unable to send verification email right now. Check Gmail API settings and try again.',
    );
  }

  return {
    provider: 'gmail-api',
    message: `Verification code sent to ${email}.`,
  };
}

async function sendOtp({ email }) {
  const otp = generateOtp();
  const delivery = await sendVerificationEmail({ email, otp });

  return {
    provider: 'gmail-api',
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
  const { user } = readGmailApiConfig();
  const from = buildFromAddress(user);

  await sendRawEmail({
    from,
    to,
    subject,
    text,
    html,
    attachments: attachments || undefined,
  });

  return { provider: 'gmail-api', message: `Email sent to ${to}.` };
}

module.exports = {
  sendOtp,
  verifyOtp,
  verifyConnection,
  sendTransactionalEmail,
  name: 'gmail-api',
};
