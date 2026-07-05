/**
 * Temporary dev bypass for OTP / email verification during registration.
 * Re-enable before production: set SKIP_VERIFICATION=false in env.
 */
function isVerificationSkipped() {
  return process.env.SKIP_VERIFICATION !== 'false';
}

module.exports = { isVerificationSkipped };
