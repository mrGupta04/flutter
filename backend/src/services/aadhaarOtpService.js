const AadhaarOtp = require('../db/models/AadhaarOtp');
const { getProvider, getProviderInfo } = require('./aadhaarProviders');

const MAX_ATTEMPTS = 5;
const RESEND_COOLDOWN_MS = 60 * 1000;

function normalizeAadhaar(value) {
  return String(value || '').replace(/\D/g, '');
}

function normalizeMobile(value) {
  return String(value || '').replace(/\D/g, '').slice(-10);
}

function isValidAadhaar(aadhaar) {
  if (!/^\d{12}$/.test(aadhaar)) return false;
  if (/^(\d)\1{11}$/.test(aadhaar)) return false;
  return true;
}

function maskAadhaar(aadhaar) {
  return `XXXX-XXXX-${aadhaar.slice(-4)}`;
}

async function sendAadhaarOtp({ doctorId, aadhaarNumber, mobileNumber }) {
  const aadhaar = normalizeAadhaar(aadhaarNumber);
  const mobile = normalizeMobile(mobileNumber);

  if (!doctorId) {
    throw new Error('doctorId is required');
  }
  if (!isValidAadhaar(aadhaar)) {
    throw new Error('Enter a valid 12-digit Aadhaar number');
  }
  if (!/^[6-9]\d{9}$/.test(mobile)) {
    throw new Error('Enter a valid 10-digit mobile number linked to Aadhaar');
  }

  const existing = await AadhaarOtp.findOne({ doctorId, aadhaarNumber: aadhaar })
    .sort({ createdAt: -1 });

  if (existing && !existing.verified) {
    const since = Date.now() - new Date(existing.createdAt).getTime();
    if (since < RESEND_COOLDOWN_MS) {
      const waitSec = Math.ceil((RESEND_COOLDOWN_MS - since) / 1000);
      throw new Error(`Please wait ${waitSec}s before requesting another OTP`);
    }
  }

  const provider = getProvider();
  const result = await provider.sendOtp({ aadhaarNumber: aadhaar, mobileNumber: mobile });

  await AadhaarOtp.deleteMany({ doctorId, verified: false });
  await AadhaarOtp.create({
    doctorId,
    aadhaarNumber: aadhaar,
    mobileNumber: mobile,
    otpHash: result.otpHash || '',
    clientId: result.clientId || null,
    provider: result.provider || provider.name,
    expiresAt: result.expiresAt,
    attempts: 0,
    verified: false,
  });

  return {
    message: result.message,
    maskedAadhaar: maskAadhaar(aadhaar),
    expiresInSeconds: Math.floor((result.expiresAt - new Date()) / 1000),
    uidaiOtp: result.uidaiOtp === true,
    provider: result.provider || provider.name,
    devOtp: result.devOtp,
    devNote: result.devNote,
    maskedMobile: result.maskedMobile,
  };
}

async function verifyAadhaarOtp({ doctorId, aadhaarNumber, otp }) {
  const aadhaar = normalizeAadhaar(aadhaarNumber);
  const code = String(otp || '').trim();

  if (!doctorId) {
    throw new Error('doctorId is required');
  }
  if (!isValidAadhaar(aadhaar)) {
    throw new Error('Invalid Aadhaar number');
  }
  if (!/^\d{6}$/.test(code)) {
    throw new Error('Enter the 6-digit OTP');
  }

  const record = await AadhaarOtp.findOne({ doctorId, aadhaarNumber: aadhaar })
    .sort({ createdAt: -1 });

  if (!record) {
    throw new Error('No OTP found. Please request a new OTP.');
  }
  if (record.verified) {
    return {
      verified: true,
      maskedAadhaar: maskAadhaar(aadhaar),
      aadhaarLast4: aadhaar.slice(-4),
      uidaiOtp: record.provider === 'surepass',
    };
  }
  if (new Date() > record.expiresAt) {
    throw new Error('OTP expired. Please request a new OTP.');
  }
  if (record.attempts >= MAX_ATTEMPTS) {
    throw new Error('Too many attempts. Please request a new OTP.');
  }

  const provider =
    record.provider === 'surepass'
      ? require('./aadhaarProviders/surepassProvider')
      : require('./aadhaarProviders/mockProvider');

  let valid = false;
  let demographic = null;

  try {
    const outcome = await provider.verifyOtp({ record, otp: code });
    valid = outcome.valid;
    demographic = outcome.demographic;
  } catch (err) {
    record.attempts += 1;
    await record.save();
    throw err;
  }

  record.attempts += 1;
  if (!valid) {
    await record.save();
    throw new Error('Invalid OTP. Please try again.');
  }

  record.verified = true;
  await record.save();

  return {
    verified: true,
    maskedAadhaar: maskAadhaar(aadhaar),
    aadhaarLast4: aadhaar.slice(-4),
    mobileNumber: record.mobileNumber,
    uidaiOtp: record.provider === 'surepass',
    demographic,
  };
}

module.exports = {
  sendAadhaarOtp,
  verifyAadhaarOtp,
  normalizeAadhaar,
  isValidAadhaar,
  maskAadhaar,
  getProviderInfo,
};
