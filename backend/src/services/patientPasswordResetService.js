const bcrypt = require('bcryptjs');
const PasswordReset = require('../db/models/PasswordReset');
const Patient = require('../db/models/Patient');
const { hashPassword } = require('../utils/providerAuth');
const { isVerificationSkipped } = require('../config/verification');
const { getProvider } = require('./emailProviders');

const MAX_ATTEMPTS = 5;
const RESEND_COOLDOWN_MS = 60 * 1000;
const PURPOSE = 'patient_password_reset';

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

const GENERIC_SEND_MESSAGE =
  'If an account exists for this email, a reset code has been sent.';

async function sendPatientPasswordResetOtp({ email }) {
  const normalizedEmail = normalizeEmail(email);
  if (!isValidEmail(normalizedEmail)) {
    const err = new Error('Enter a valid email address');
    err.statusCode = 400;
    throw err;
  }

  const patient = await Patient.findOne({ email: normalizedEmail });

  // Always look successful to avoid account enumeration.
  if (!patient) {
    return {
      message: GENERIC_SEND_MESSAGE,
      maskedEmail: maskEmail(normalizedEmail),
      expiresInSeconds: 600,
    };
  }

  if (isVerificationSkipped()) {
    await PasswordReset.deleteMany({
      email: normalizedEmail,
      purpose: PURPOSE,
      consumed: false,
    });
    await PasswordReset.create({
      email: normalizedEmail,
      purpose: PURPOSE,
      patientId: patient.id,
      otpHash: bcrypt.hashSync('123456', 10),
      provider: 'skipped',
      expiresAt: new Date(Date.now() + 10 * 60 * 1000),
      attempts: 0,
      verified: false,
      consumed: false,
    });
    return {
      message: GENERIC_SEND_MESSAGE,
      maskedEmail: maskEmail(normalizedEmail),
      expiresInSeconds: 600,
      provider: 'skipped',
      devOtp: '123456',
      devNote: 'SKIP_VERIFICATION is enabled. Use OTP 123456.',
    };
  }

  const existing = await PasswordReset.findOne({
    email: normalizedEmail,
    purpose: PURPOSE,
    consumed: false,
  }).sort({ createdAt: -1 });

  if (existing) {
    const since = Date.now() - new Date(existing.createdAt).getTime();
    if (since < RESEND_COOLDOWN_MS) {
      const waitSec = Math.ceil((RESEND_COOLDOWN_MS - since) / 1000);
      const err = new Error(`Please wait ${waitSec}s before requesting another code`);
      err.statusCode = 429;
      throw err;
    }
  }

  const provider = getProvider();
  const result = await provider.sendOtp({ email: normalizedEmail });

  await PasswordReset.deleteMany({
    email: normalizedEmail,
    purpose: PURPOSE,
    consumed: false,
  });
  await PasswordReset.create({
    email: normalizedEmail,
    purpose: PURPOSE,
    patientId: patient.id,
    otpHash: result.otpHash || '',
    provider: result.provider || provider.name,
    expiresAt: result.expiresAt,
    attempts: 0,
    verified: false,
    consumed: false,
  });

  return {
    message: GENERIC_SEND_MESSAGE,
    maskedEmail: maskEmail(normalizedEmail),
    expiresInSeconds: Math.floor((result.expiresAt - new Date()) / 1000),
    provider: result.provider || provider.name,
    ...(result.devOtp ? { devOtp: result.devOtp, devNote: result.devNote } : {}),
  };
}

async function resetPatientPassword({ email, otp, newPassword }) {
  const normalizedEmail = normalizeEmail(email);
  const code = String(otp || '').trim();
  const password = String(newPassword || '');

  if (!isValidEmail(normalizedEmail)) {
    const err = new Error('Enter a valid email address');
    err.statusCode = 400;
    throw err;
  }
  if (!/^\d{4,8}$/.test(code)) {
    const err = new Error('Enter a valid OTP');
    err.statusCode = 400;
    throw err;
  }
  if (password.length < 8) {
    const err = new Error('Password must be at least 8 characters');
    err.statusCode = 400;
    throw err;
  }

  const record = await PasswordReset.findOne({
    email: normalizedEmail,
    purpose: PURPOSE,
    consumed: false,
  }).sort({ createdAt: -1 });

  if (!record) {
    const err = new Error('Reset code expired or not found. Request a new one.');
    err.statusCode = 400;
    throw err;
  }

  if (new Date(record.expiresAt).getTime() < Date.now()) {
    const err = new Error('Reset code expired. Request a new one.');
    err.statusCode = 400;
    throw err;
  }

  if (record.attempts >= MAX_ATTEMPTS) {
    const err = new Error('Too many attempts. Request a new code.');
    err.statusCode = 429;
    throw err;
  }

  const provider = getProvider();
  let valid = false;
  if (record.provider === 'skipped' || isVerificationSkipped()) {
    valid = code === '123456';
  } else if (typeof provider.verifyOtp === 'function') {
    const result = await provider.verifyOtp({ record, otp: code });
    valid = Boolean(result?.valid);
  } else {
    valid = bcrypt.compareSync(code, record.otpHash || '');
  }

  record.attempts += 1;
  if (!valid) {
    await record.save();
    const err = new Error('Incorrect OTP. Please try again.');
    err.statusCode = 400;
    throw err;
  }

  const patient = await Patient.findOne({
    id: record.patientId,
    email: normalizedEmail,
  });
  if (!patient) {
    const err = new Error('Account not found');
    err.statusCode = 404;
    throw err;
  }

  patient.passwordHash = hashPassword(password);
  await patient.save();

  record.verified = true;
  record.consumed = true;
  await record.save();

  await PasswordReset.updateMany(
    { email: normalizedEmail, purpose: PURPOSE, consumed: false },
    { $set: { consumed: true } },
  );

  return {
    message: 'Password updated successfully. You can sign in now.',
    maskedEmail: maskEmail(normalizedEmail),
  };
}

module.exports = {
  sendPatientPasswordResetOtp,
  resetPatientPassword,
};
