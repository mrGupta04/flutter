/**
 * Generic SMS helper — logs in dev; doctor phone OTP uses Firebase Auth.
 */
async function sendSms(mobileNumber, message) {
  const provider = process.env.SMS_PROVIDER || 'console';

  if (provider === 'console' || provider === 'mock' || process.env.NODE_ENV === 'development') {
    console.log(`[SMS] To +91${mobileNumber}: ${message}`);
    return { success: true };
  }

  console.log(`[SMS] (no generic provider configured) To +91${mobileNumber}: ${message}`);
  return { success: true };
}

module.exports = { sendSms };
