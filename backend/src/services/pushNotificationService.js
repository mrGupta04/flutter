/**
 * Push notifications — logs in dev; FCM when FIREBASE_SERVER_KEY is set.
 */
async function sendPushNotification({ userId, title, body, data = {} }) {
  const provider = process.env.PUSH_PROVIDER || 'console';

  if (provider === 'console' || provider === 'mock' || process.env.NODE_ENV === 'development') {
    console.log(`[Push] user=${userId || 'anonymous'} title="${title}" body="${body}"`, data);
    return { success: true, provider: 'console' };
  }

  const serverKey = process.env.FIREBASE_SERVER_KEY;
  const deviceToken = data.deviceToken;

  if (provider === 'fcm' && serverKey && deviceToken) {
    try {
      const response = await fetch('https://fcm.googleapis.com/fcm/send', {
        method: 'POST',
        headers: {
          Authorization: `key=${serverKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          to: deviceToken,
          notification: { title, body },
          data: Object.fromEntries(
            Object.entries(data).map(([k, v]) => [k, String(v)]),
          ),
        }),
      });
      if (!response.ok) {
        const text = await response.text();
        throw new Error(text || 'FCM request failed');
      }
      return { success: true, provider: 'fcm' };
    } catch (err) {
      console.error('[Push] FCM failed:', err.message);
      return { success: false, error: err.message };
    }
  }

  console.log(`[Push] (no FCM token) user=${userId} title="${title}"`);
  return { success: true, provider: 'fallback-console' };
}

module.exports = { sendPushNotification };
