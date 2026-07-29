const {
  sendProviderPasswordResetOtp,
  resetProviderPassword,
} = require('../../services/providerPasswordResetService');
const { sendSuccess, sendError } = require('../../utils/response');

/**
 * Mounts email-OTP forgot/reset password routes on a provider router.
 * @param {import('express').Router} router
 * @param {'doctor'|'nurse'|'ambulance'|'blood-bank'|'lab'|'scan'} providerType
 */
function mountProviderPasswordResetRoutes(router, providerType) {
  router.post('/forgot-password', async (req, res) => {
    try {
      const result = await sendProviderPasswordResetOtp({
        providerType,
        email: req.body?.email,
      });
      return sendSuccess(res, {
        message: result.message,
        data: result,
      });
    } catch (err) {
      console.error(err);
      return sendError(
        res,
        err.message || 'Failed to send reset code',
        err.statusCode || 500,
      );
    }
  });

  router.post('/reset-password', async (req, res) => {
    try {
      const result = await resetProviderPassword({
        providerType,
        email: req.body?.email,
        otp: req.body?.otp,
        newPassword: req.body?.newPassword || req.body?.password,
      });
      return sendSuccess(res, {
        message: result.message,
        data: result,
      });
    } catch (err) {
      console.error(err);
      return sendError(
        res,
        err.message || 'Failed to reset password',
        err.statusCode || 500,
      );
    }
  });
}

module.exports = { mountProviderPasswordResetRoutes };
