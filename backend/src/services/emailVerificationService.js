const EmailVerification = require('../db/models/EmailVerification');
const { findDoctorByEmail } = require('../db/repositories');
const { getProvider, getProviderInfo } = require('./emailProviders');

const MAX_ATTEMPTS = 5;
const RESEND_COOLDOWN_MS = 60 * 1000;

function normalizeEmail(value) {
  return String(value || '').trim().toLowerCase();
}

function isValidEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

function maskEmail(email) {
  const [local, domain] = email.split('@');
  if (!local || !domain) return email;
  if (local.length <= 2) {
    return `${local[0] ?? '*'}***@${domain}`;
  }
  return `${local.slice(0, 2)}***@${domain}`;
}

async function sendEmailVerificationOtp({ doctorId, email }) {
  const normalizedEmail = normalizeEmail(email);

  if (!doctorId) {
    throw new Error('doctorId is required');
  }
  if (!isValidEmail(normalizedEmail)) {
    throw new Error('Enter a valid email address');
  }

  const emailTaken = await findDoctorByEmail(normalizedEmail, doctorId);
  if (emailTaken) {
    throw new Error('Email is already registered');
  }

  const existing = await EmailVerification.findOne({
    doctorId,
    email: normalizedEmail,
  }).sort({ createdAt: -1 });

  if (existing && !existing.verified) {
    const since = Date.now() - new Date(existing.createdAt).getTime();
    if (since < RESEND_COOLDOWN_MS) {
      const waitSec = Math.ceil((RESEND_COOLDOWN_MS - since) / 1000);
      throw new Error(`Please wait ${waitSec}s before requesting another code`);
    }
  }

  const provider = getProvider();
  const result = await provider.sendOtp({ email: normalizedEmail });

  await EmailVerification.deleteMany({ doctorId, verified: false });
  await EmailVerification.create({
    doctorId,
    email: normalizedEmail,
    otpHash: result.otpHash || '',
    provider: result.provider || provider.name,
    expiresAt: result.expiresAt,
    attempts: 0,
    verified: false,
  });

  return {
    message: result.message,
    maskedEmail: maskEmail(normalizedEmail),
    expiresInSeconds: Math.floor((result.expiresAt - new Date()) / 1000),
    provider: result.provider || provider.name,
    ...(result.devOtp ? { devOtp: result.devOtp, devNote: result.devNote } : {}),
  };
}

async function verifyEmailVerificationOtp({ doctorId, email, otp }) {
  const normalizedEmail = normalizeEmail(email);
  const code = String(otp || '').trim();

  if (!doctorId) {
    throw new Error('doctorId is required');
  }
  if (!isValidEmail(normalizedEmail)) {
    throw new Error('Invalid email address');
  }
  if (!/^\d{6}$/.test(code)) {
    throw new Error('Enter the 6-digit verification code');
  }

  const record = await EmailVerification.findOne({
    doctorId,
    email: normalizedEmail,
  }).sort({ createdAt: -1 });

  if (!record) {
    throw new Error('No verification code found. Please request a new one.');
  }
  if (record.verified) {
    return {
      verified: true,
      email: normalizedEmail,
      maskedEmail: maskEmail(normalizedEmail),
    };
  }
  if (new Date() > record.expiresAt) {
    throw new Error('Verification code expired. Please request a new one.');
  }
  if (record.attempts >= MAX_ATTEMPTS) {
    throw new Error('Too many attempts. Please request a new code.');
  }

  const provider =
    record.provider === 'smtp'
      ? require('./emailProviders/smtpProvider')
      : require('./emailProviders/mockProvider');

  let valid = false;
  try {
    const outcome = await provider.verifyOtp({ record, otp: code });
    valid = outcome.valid;
  } catch (err) {
    record.attempts += 1;
    await record.save();
    throw err;
  }

  record.attempts += 1;
  if (!valid) {
    await record.save();
    throw new Error('Invalid verification code. Please try again.');
  }

  record.verified = true;
  await record.save();

  return {
    verified: true,
    email: normalizedEmail,
    maskedEmail: maskEmail(normalizedEmail),
  };
}

module.exports = {
  sendEmailVerificationOtp,
  verifyEmailVerificationOtp,
  normalizeEmail,
  isValidEmail,
  maskEmail,
  getProviderInfo,
};
