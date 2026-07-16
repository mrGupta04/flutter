/**
 * Push notifications — logs in dev; FCM when FIREBASE_SERVER_KEY is set.
 * Sends to every token in `data.deviceTokens` (or single `data.deviceToken`).
 */
async function sendPushNotification({ userId, title, body, data = {} }) {
  const provider = process.env.PUSH_PROVIDER || 'console';
  const tokens = [];
  if (Array.isArray(data.deviceTokens)) {
    tokens.push(...data.deviceTokens.filter(Boolean).map(String));
  } else if (data.deviceToken) {
    tokens.push(String(data.deviceToken));
  }

  if (
    provider === 'console' ||
    provider === 'mock' ||
    process.env.NODE_ENV === 'development'
  ) {
    console.log(
      `[Push] user=${userId || 'anonymous'} title="${title}" body="${body}" tokens=${tokens.length}`,
      data,
    );
    return { success: true, provider: 'console', tokenCount: tokens.length };
  }

  const serverKey = process.env.FIREBASE_SERVER_KEY;
  if (provider === 'fcm' && serverKey && tokens.length) {
    const results = [];
    for (const deviceToken of tokens) {
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
              Object.entries(data)
                .filter(([k]) => k !== 'deviceToken' && k !== 'deviceTokens')
                .map(([k, v]) => [k, String(v)]),
            ),
          }),
        });
        if (!response.ok) {
          const text = await response.text();
          throw new Error(text || 'FCM request failed');
        }
        results.push({ token: deviceToken, success: true });
      } catch (err) {
        console.error('[Push] FCM failed:', err.message);
        results.push({ token: deviceToken, success: false, error: err.message });
      }
    }
    return { success: results.some((r) => r.success), provider: 'fcm', results };
  }

  console.log(`[Push] (no FCM token) user=${userId} title="${title}"`);
  return { success: true, provider: 'fallback-console' };
}

module.exports = { sendPushNotification };
