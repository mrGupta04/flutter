const bcrypt = require('bcryptjs');

const OTP_TTL_MS = 10 * 60 * 1000;
const DEFAULT_TEST_OTP = '123456';

function generateOtp() {
  const configured = String(process.env.EMAIL_TEST_OTP || '').trim();
  if (/^\d{4,8}$/.test(configured)) {
    return configured;
  }
  if (process.env.EMAIL_FORCE_TEST_OTP === 'true') {
    return DEFAULT_TEST_OTP;
  }
  return String(Math.floor(100000 + Math.random() * 900000));
}

function isDevOtpExposed() {
  return (
    process.env.EMAIL_OTP_DEV_MODE === 'true' ||
    process.env.NODE_ENV === 'development'
  );
}

async function sendVerificationEmail({ email, otp }) {
  console.log(`[email-mock] Verification OTP for ${email}: ${otp}`);
  return {
    provider: 'mock',
    message: 'Development OTP only. Configure SMTP settings to send real emails.',
    devOtp: isDevOtpExposed() ? otp : undefined,
    devNote: isDevOtpExposed()
      ? 'This OTP is logged locally, not sent by email.'
      : undefined,
  };
}

async function sendOtp({ email }) {
  const otp = generateOtp();
  const delivery = await sendVerificationEmail({ email, otp });

  return {
    provider: 'mock',
    otpHash: bcrypt.hashSync(otp, 10),
    expiresAt: new Date(Date.now() + OTP_TTL_MS),
    message: delivery.message,
    devOtp: delivery.devOtp,
    devNote: delivery.devNote,
  };
}

async function verifyOtp({ record, otp }) {
  const valid = bcrypt.compareSync(String(otp).trim(), record.otpHash || '');
  return { valid };
}

module.exports = { sendOtp, verifyOtp, name: 'mock' };
