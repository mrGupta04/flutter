const mockProvider = require('./mockProvider');
const gmailApiProvider = require('./gmailApiProvider');
const resendProvider = require('./resendProvider');
const smtpProvider = require('./smtpProvider');

const REQUIRED_SMTP_VARS = ['SMTP_USER', 'SMTP_PASS'];
const REQUIRED_GMAIL_API_VARS = [
  'GMAIL_CLIENT_ID',
  'GMAIL_CLIENT_SECRET',
  'GMAIL_REFRESH_TOKEN',
];
const REQUIRED_RESEND_VARS = ['RESEND_API_KEY'];

function resolveProviderName() {
  const configured = (process.env.EMAIL_PROVIDER || '').toLowerCase().trim();
  if (configured === 'mock') return 'mock';
  if (configured === 'smtp') return 'smtp';
  if (configured === 'gmail-api' || configured === 'gmail_api') return 'gmail-api';
  if (configured === 'resend') return 'resend';
  // Auto-detect: Gmail API (HTTPS) first, then SMTP, otherwise mock.
  if (getMissingGmailApiVars().length === 0) return 'gmail-api';
  return getMissingSmtpVars().length === 0 ? 'smtp' : 'mock';
}

function getMissingGmailApiVars() {
  const missing = REQUIRED_GMAIL_API_VARS.filter(
    (key) => !String(process.env[key] || '').trim(),
  );
  const hasUser =
    Boolean(String(process.env.GMAIL_USER || '').trim()) ||
    Boolean(String(process.env.SMTP_USER || '').trim()) ||
    Boolean(String(process.env.SMTP_FROM || '').trim());
  if (!hasUser) {
    missing.push('GMAIL_USER or SMTP_USER');
  }
  return missing;
}

function getMissingResendVars() {
  const missing = REQUIRED_RESEND_VARS.filter(
    (key) => !String(process.env[key] || '').trim(),
  );
  const hasFrom =
    Boolean(String(process.env.RESEND_FROM || '').trim()) ||
    Boolean(String(process.env.SMTP_FROM || '').trim()) ||
    Boolean(String(process.env.SMTP_USER || '').trim());
  if (!hasFrom) {
    missing.push('RESEND_FROM or SMTP_FROM');
  }
  return missing;
}

function getMissingSmtpVars() {
  const missing = REQUIRED_SMTP_VARS.filter(
    (key) => !String(process.env[key] || '').trim(),
  );
  const hasService = Boolean(String(process.env.SMTP_SERVICE || '').trim());
  const hasHost = Boolean(String(process.env.SMTP_HOST || '').trim());
  if (!hasService && !hasHost) {
    missing.push('SMTP_HOST or SMTP_SERVICE');
  }
  return missing;
}

function assertSmtpConfigured() {
  const missing = getMissingSmtpVars();
  if (missing.length === 0) return;

  throw new Error(
    `Email verification requires SMTP configuration. Set ${missing.join(', ')} in .env`,
  );
}

function assertGmailApiConfigured() {
  const missing = getMissingGmailApiVars();
  if (missing.length === 0) return;

  throw new Error(
    `Email verification requires Gmail API configuration. Set ${missing.join(', ')} in .env`,
  );
}

function assertResendConfigured() {
  const missing = getMissingResendVars();
  if (missing.length === 0) return;

  throw new Error(
    `Email verification requires Resend configuration. Set ${missing.join(', ')} in .env`,
  );
}

function getProviderByName(name) {
  if (name === 'gmail-api' || name === 'gmail_api') return gmailApiProvider;
  if (name === 'resend') return resendProvider;
  if (name === 'smtp') return smtpProvider;
  return mockProvider;
}

function getProvider() {
  const name = resolveProviderName();

  if (name === 'mock') {
    if (
      process.env.NODE_ENV === 'production' &&
      process.env.EMAIL_ALLOW_MOCK !== 'true'
    ) {
      throw new Error(
        'Mock email is disabled in production. Set EMAIL_PROVIDER=gmail-api or smtp and configure email settings.',
      );
    }
    return mockProvider;
  }

  if (name === 'gmail-api') {
    assertGmailApiConfigured();
    return gmailApiProvider;
  }

  if (name === 'resend') {
    assertResendConfigured();
    return resendProvider;
  }

  assertSmtpConfigured();
  return smtpProvider;
}

function getProviderInfo() {
  const name = resolveProviderName();
  const missing =
    name === 'smtp'
      ? getMissingSmtpVars()
      : name === 'gmail-api'
        ? getMissingGmailApiVars()
        : name === 'resend'
          ? getMissingResendVars()
          : [];

  return {
    provider: name,
    realEmail: name === 'smtp' || name === 'gmail-api' || name === 'resend',
    configured: name === 'mock' || missing.length === 0,
    missingConfig: missing,
    description:
      name === 'gmail-api'
        ? 'Verification codes are sent from your Gmail account via Gmail API (HTTPS — works on Render).'
        : name === 'resend'
          ? 'Verification codes are sent via Resend (HTTPS API — works on Render).'
          : name === 'smtp'
            ? 'Verification codes are sent via Gmail SMTP (blocked on Render free tier).'
            : 'Development mock only. Set EMAIL_PROVIDER=gmail-api for Gmail on Render.',
  };
}

async function verifyEmailConnection() {
  const name = resolveProviderName();
  if (name === 'mock') return { ok: true, skipped: true };

  if (name === 'gmail-api') {
    assertGmailApiConfigured();
    await gmailApiProvider.verifyConnection();
    return { ok: true };
  }

  if (name === 'resend') {
    assertResendConfigured();
    await resendProvider.verifyConnection();
    return { ok: true };
  }

  assertSmtpConfigured();
  await smtpProvider.verifyConnection();
  return { ok: true };
}

module.exports = {
  getProvider,
  getProviderByName,
  getProviderInfo,
  resolveProviderName,
  assertSmtpConfigured,
  assertGmailApiConfigured,
  assertResendConfigured,
  verifyEmailConnection,
  verifySmtpConnection: verifyEmailConnection,
};
