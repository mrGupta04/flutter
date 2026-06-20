const mockProvider = require('./mockProvider');
const resendProvider = require('./resendProvider');
const smtpProvider = require('./smtpProvider');

const REQUIRED_SMTP_VARS = ['SMTP_USER', 'SMTP_PASS'];
const REQUIRED_RESEND_VARS = ['RESEND_API_KEY'];

function resolveProviderName() {
  const configured = (process.env.EMAIL_PROVIDER || '').toLowerCase().trim();
  if (configured === 'mock') return 'mock';
  if (configured === 'smtp') return 'smtp';
  if (configured === 'resend') return 'resend';
  // Auto-detect: use Gmail SMTP when configured, otherwise mock (local dev).
  return getMissingSmtpVars().length === 0 ? 'smtp' : 'mock';
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

function assertResendConfigured() {
  const missing = getMissingResendVars();
  if (missing.length === 0) return;

  throw new Error(
    `Email verification requires Resend configuration. Set ${missing.join(', ')} in .env`,
  );
}

function getProviderByName(name) {
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
        'Mock email is disabled in production. Set EMAIL_PROVIDER=smtp and configure Gmail SMTP settings.',
      );
    }
    return mockProvider;
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
      : name === 'resend'
        ? getMissingResendVars()
        : [];

  return {
    provider: name,
    realEmail: name === 'smtp' || name === 'resend',
    configured: name === 'mock' || missing.length === 0,
    missingConfig: missing,
    description:
      name === 'resend'
        ? 'Verification codes are sent via Resend (HTTPS API — works on Render).'
        : name === 'smtp'
          ? 'Verification codes are sent to the doctor email via SMTP.'
          : 'Development mock only. Set EMAIL_PROVIDER=resend or smtp for real email delivery.',
  };
}

async function verifyEmailConnection() {
  const name = resolveProviderName();
  if (name === 'mock') return { ok: true, skipped: true };

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
  assertResendConfigured,
  verifyEmailConnection,
  verifySmtpConnection: verifyEmailConnection,
};
