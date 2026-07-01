/**
 * WhatsApp messaging — logs in dev; configure Twilio/Meta Cloud API in production.
 */
async function sendWhatsApp(mobileNumber, message) {
  const provider = process.env.WHATSAPP_PROVIDER || 'console';
  const normalized = String(mobileNumber || '').replace(/\D/g, '').slice(-10);

  if (!normalized || normalized.length !== 10) {
    return { success: false, error: 'Invalid mobile number' };
  }

  if (provider === 'console' || provider === 'mock' || process.env.NODE_ENV === 'development') {
    console.log(`[WhatsApp] To +91${normalized}: ${message}`);
    return { success: true, provider: 'console' };
  }

  const accountSid = process.env.TWILIO_ACCOUNT_SID;
  const authToken = process.env.TWILIO_AUTH_TOKEN;
  const from = process.env.TWILIO_WHATSAPP_FROM;

  if (provider === 'twilio' && accountSid && authToken && from) {
    try {
      // eslint-disable-next-line global-require
      const twilio = require('twilio')(accountSid, authToken);
      await twilio.messages.create({
        from,
        to: `whatsapp:+91${normalized}`,
        body: message,
      });
      return { success: true, provider: 'twilio' };
    } catch (err) {
      console.error('[WhatsApp] Twilio failed:', err.message);
      return { success: false, error: err.message };
    }
  }

  console.log(`[WhatsApp] (no provider) To +91${normalized}: ${message}`);
  return { success: true, provider: 'fallback-console' };
}

module.exports = { sendWhatsApp };
