const bcrypt = require('bcryptjs');

const OTP_TTL_MS = 10 * 60 * 1000;
const DEFAULT_TEST_OTP = '123456';

function generateOtp() {
  const configured = String(process.env.AADHAAR_TEST_OTP || '').trim();
  if (/^\d{4,8}$/.test(configured)) {
    return configured;
  }
  if (process.env.AADHAAR_FORCE_TEST_OTP === 'true') {
    return DEFAULT_TEST_OTP;
  }
  return String(Math.floor(100000 + Math.random() * 900000));
}

function isDevOtpExposed() {
  return (
    process.env.AADHAAR_OTP_DEV_MODE === 'true' ||
    process.env.NODE_ENV === 'development'
  );
}

/** Local simulated OTP — not sent by UIDAI. For development only. */
async function sendOtp() {
  const otp = generateOtp();
  return {
    provider: 'mock',
    otpHash: bcrypt.hashSync(otp, 10),
    clientId: null,
    expiresAt: new Date(Date.now() + OTP_TTL_MS),
    message:
      'Development OTP only. Configure SUREPASS_API_TOKEN for real UIDAI OTP.',
    uidaiOtp: false,
    devOtp: isDevOtpExposed() ? otp : undefined,
    devNote: isDevOtpExposed()
      ? 'This OTP is generated locally, not by UIDAI.'
      : undefined,
  };
}

async function verifyOtp({ record, otp }) {
  const valid = bcrypt.compareSync(String(otp).trim(), record.otpHash || '');
  return { valid, demographic: null };
}

module.exports = { sendOtp, verifyOtp, name: 'mock' };
