/**
 * Push notifications.
 * In-app rows are always created separately. This sends FCM when a real
 * device token and FIREBASE_SERVER_KEY are available — including local/dev
 * so testers still get OS alerts. Placeholder `dev_*` tokens are never sent.
 */
function isPlaceholderToken(token) {
  const value = String(token || '').trim();
  return !value || value.startsWith('dev_') || value.startsWith('dev:');
}

async function sendPushNotification({ userId, title, body, data = {} }) {
  const provider = String(process.env.PUSH_PROVIDER || 'console').trim().toLowerCase();
  const tokens = [];
  if (Array.isArray(data.deviceTokens)) {
    tokens.push(...data.deviceTokens.filter(Boolean).map(String));
  } else if (data.deviceToken) {
    tokens.push(String(data.deviceToken));
  }

  const realTokens = [...new Set(tokens.filter((token) => !isPlaceholderToken(token)))];
  const serverKey = process.env.FIREBASE_SERVER_KEY;
  const skipFcm = provider === 'mock' || provider === 'disabled';

  console.log(
    `[Push] user=${userId || 'anonymous'} title="${title}" body="${body}" tokens=${tokens.length} fcm=${realTokens.length}`,
  );

  if (skipFcm || !serverKey || realTokens.length === 0) {
    return {
      success: true,
      provider: skipFcm ? provider : 'console',
      tokenCount: tokens.length,
      fcmTokenCount: realTokens.length,
    };
  }

  const results = [];
  for (const deviceToken of realTokens) {
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
              .map(([k, v]) => [k, v == null ? '' : String(v)]),
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

module.exports = { sendPushNotification };
