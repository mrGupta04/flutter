/**
 * OS push via FCM (Firebase Admin HTTP v1).
 * In-app rows and Socket.IO alerts are created separately.
 * Placeholder `dev_*` tokens are never sent.
 *
 * Configure one of:
 *   FIREBASE_SERVICE_ACCOUNT_JSON   — full service-account JSON string
 *   FIREBASE_SERVICE_ACCOUNT_BASE64 — base64 of that JSON
 *   FIREBASE_SERVICE_ACCOUNT_PATH   — path to the JSON file
 *   GOOGLE_APPLICATION_CREDENTIALS  — same as PATH (Google default)
 *   firebase-service-account.json   — file in the backend root
 *
 * Legacy FIREBASE_SERVER_KEY still works as a fallback.
 */
const fs = require('fs');
const path = require('path');

let admin = null;
let firebaseReady = false;
let firebaseInitAttempted = false;

function isPlaceholderToken(token) {
  const value = String(token || '').trim();
  return !value || value.startsWith('dev_') || value.startsWith('dev:');
}

function stringifyData(data = {}) {
  return Object.fromEntries(
    Object.entries(data)
      .filter(([k]) => k !== 'deviceToken' && k !== 'deviceTokens')
      .map(([k, v]) => [k, v == null ? '' : typeof v === 'string' ? v : JSON.stringify(v)]),
  );
}

function loadServiceAccount() {
  const jsonEnv = String(process.env.FIREBASE_SERVICE_ACCOUNT_JSON || '').trim();
  if (jsonEnv.startsWith('{')) {
    return JSON.parse(jsonEnv);
  }

  const b64 = String(process.env.FIREBASE_SERVICE_ACCOUNT_BASE64 || '').trim();
  if (b64) {
    return JSON.parse(Buffer.from(b64, 'base64').toString('utf8'));
  }

  const filePath =
    process.env.FIREBASE_SERVICE_ACCOUNT_PATH ||
    process.env.GOOGLE_APPLICATION_CREDENTIALS;
  const candidates = [
    filePath,
    path.join(__dirname, '../../firebase-service-account.json'),
  ].filter(Boolean);

  for (const candidate of candidates) {
    if (fs.existsSync(candidate)) {
      return JSON.parse(fs.readFileSync(candidate, 'utf8'));
    }
  }
  return null;
}

function initFirebaseAdmin() {
  if (firebaseInitAttempted) return firebaseReady;
  firebaseInitAttempted = true;
  try {
    admin = require('firebase-admin');
    if (admin.apps.length) {
      firebaseReady = true;
      return true;
    }
    const serviceAccount = loadServiceAccount();
    if (!serviceAccount) {
      console.warn(
        '[Push] Firebase Admin not configured — background OS push needs FIREBASE_SERVICE_ACCOUNT_JSON / PATH',
      );
      return false;
    }
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    firebaseReady = true;
    console.log('[Push] Firebase Admin initialized');
    return true;
  } catch (err) {
    console.error('[Push] Firebase Admin init failed:', err.message);
    return false;
  }
}

function collectTokens(data = {}) {
  const tokens = [];
  if (Array.isArray(data.deviceTokens)) {
    tokens.push(...data.deviceTokens.filter(Boolean).map(String));
  } else if (data.deviceToken) {
    tokens.push(String(data.deviceToken));
  }
  return [...new Set(tokens.filter((token) => !isPlaceholderToken(token)))];
}

async function sendWithAdminSdk(title, body, data, tokens) {
  const payload = stringifyData(data);
  const message = {
    tokens,
    notification: { title, body },
    data: payload,
    android: {
      priority: 'high',
      notification: {
        channelId: 'medconnect_alerts',
        sound: 'default',
        priority: 'high',
        defaultSound: true,
        defaultVibrateTimings: true,
      },
    },
    apns: {
      headers: { 'apns-priority': '10' },
      payload: {
        aps: {
          alert: { title, body },
          sound: 'default',
          badge: 1,
        },
      },
    },
  };

  const response = await admin.messaging().sendEachForMulticast(message);
  const results = [];
  const invalidTokens = [];
  response.responses.forEach((item, index) => {
    const token = tokens[index];
    if (item.success) {
      results.push({ token, success: true });
      return;
    }
    const code = item.error?.code || '';
    const error = item.error?.message || 'FCM send failed';
    results.push({ token, success: false, error, code });
    if (
      code === 'messaging/registration-token-not-registered' ||
      code === 'messaging/invalid-registration-token'
    ) {
      invalidTokens.push(token);
    }
  });
  return { success: results.some((r) => r.success), provider: 'fcm', results, invalidTokens };
}

async function sendWithLegacyServerKey(title, body, data, tokens, serverKey) {
  const results = [];
  const invalidTokens = [];
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
          priority: 'high',
          notification: { title, body, sound: 'default' },
          data: stringifyData(data),
          android: { priority: 'high' },
        }),
      });
      const text = await response.text();
      if (!response.ok) {
        throw new Error(text || 'FCM request failed');
      }
      let parsed = {};
      try {
        parsed = JSON.parse(text);
      } catch {
        parsed = {};
      }
      if (parsed.results?.[0]?.error === 'NotRegistered' || parsed.results?.[0]?.error === 'InvalidRegistration') {
        invalidTokens.push(deviceToken);
        results.push({ token: deviceToken, success: false, error: parsed.results[0].error });
      } else {
        results.push({ token: deviceToken, success: true });
      }
    } catch (err) {
      console.error('[Push] FCM failed:', err.message);
      results.push({ token: deviceToken, success: false, error: err.message });
    }
  }
  return { success: results.some((r) => r.success), provider: 'fcm-legacy', results, invalidTokens };
}

async function sendPushNotification({ userId, title, body, data = {} }) {
  const provider = String(process.env.PUSH_PROVIDER || 'fcm').trim().toLowerCase();
  const tokens = [];
  if (Array.isArray(data.deviceTokens)) {
    tokens.push(...data.deviceTokens.filter(Boolean).map(String));
  } else if (data.deviceToken) {
    tokens.push(String(data.deviceToken));
  }

  const realTokens = collectTokens(data);
  const skipFcm = provider === 'mock' || provider === 'disabled';
  const adminReady = !skipFcm && initFirebaseAdmin();
  const serverKey = process.env.FIREBASE_SERVER_KEY;

  console.log(
    `[Push] user=${userId || 'anonymous'} title="${title}" body="${body}" tokens=${tokens.length} fcm=${realTokens.length} admin=${adminReady}`,
  );

  if (skipFcm || realTokens.length === 0) {
    return {
      success: true,
      provider: skipFcm ? provider : 'console',
      tokenCount: tokens.length,
      fcmTokenCount: realTokens.length,
      invalidTokens: [],
    };
  }

  if (adminReady) {
    return sendWithAdminSdk(title, body, data, realTokens);
  }
  if (serverKey) {
    return sendWithLegacyServerKey(title, body, data, realTokens, serverKey);
  }

  return {
    success: true,
    provider: 'console',
    tokenCount: tokens.length,
    fcmTokenCount: realTokens.length,
    invalidTokens: [],
  };
}

module.exports = { sendPushNotification, initFirebaseAdmin };
