const mockProvider = require('./mockProvider');
const smtpProvider = require('./smtpProvider');

const REQUIRED_SMTP_VARS = ['SMTP_USER', 'SMTP_PASS'];

function resolveProviderName() {
  const configured = (process.env.EMAIL_PROVIDER || 'smtp').toLowerCase().trim();
  if (configured === 'mock') return 'mock';
  return 'smtp';
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

function getProvider() {
  const name = resolveProviderName();

  if (name === 'mock') {
    if (
      process.env.NODE_ENV === 'production' &&
      process.env.EMAIL_ALLOW_MOCK !== 'true'
    ) {
      throw new Error(
        'Mock email is disabled in production. Set EMAIL_PROVIDER=smtp and configure SMTP settings.',
      );
    }
    return mockProvider;
  }

  assertSmtpConfigured();
  return smtpProvider;
}

function getProviderInfo() {
  const name = resolveProviderName();
  const missing = name === 'smtp' ? getMissingSmtpVars() : [];

  return {
    provider: name,
    realEmail: name === 'smtp',
    configured: name === 'mock' || missing.length === 0,
    missingConfig: missing,
    description:
      name === 'smtp'
        ? 'Verification codes are sent to the doctor email via SMTP.'
        : 'Development mock only. Set EMAIL_PROVIDER=smtp for real email delivery.',
  };
}

async function verifySmtpConnection() {
  if (resolveProviderName() !== 'smtp') return { ok: true, skipped: true };
  assertSmtpConfigured();
  await smtpProvider.verifyConnection();
  return { ok: true };
}

module.exports = {
  getProvider,
  getProviderInfo,
  resolveProviderName,
  assertSmtpConfigured,
  verifySmtpConnection,
};
