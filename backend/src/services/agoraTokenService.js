const { RtcTokenBuilder, RtcRole } = require('agora-token');

const AGORA_APP_ID = String(process.env.AGORA_APP_ID || '').trim();
const AGORA_APP_CERTIFICATE = String(process.env.AGORA_APP_CERTIFICATE || '').trim();
const TOKEN_TTL_SECONDS = parseInt(process.env.AGORA_TOKEN_TTL_SECONDS || '3600', 10);

/** Stable numeric UIDs per role (Agora requires uint32). */
const ROLE_UID = {
  doctor: 1001,
  patient: 1002,
};

function getAgoraConfig() {
  return {
    appId: AGORA_APP_ID || null,
    hasCertificate: Boolean(AGORA_APP_CERTIFICATE),
    configured: Boolean(AGORA_APP_ID),
    tokenTtlSeconds: TOKEN_TTL_SECONDS,
  };
}

function uidForRole(role) {
  return ROLE_UID[role] || ROLE_UID.patient;
}

function buildRtcToken(channelName, role) {
  if (!AGORA_APP_ID) {
    const err = new Error('Agora is not configured. Set AGORA_APP_ID in .env');
    err.statusCode = 503;
    throw err;
  }

  const uid = uidForRole(role);
  const now = Math.floor(Date.now() / 1000);
  const expire = now + TOKEN_TTL_SECONDS;

  if (!AGORA_APP_CERTIFICATE) {
    return {
      appId: AGORA_APP_ID,
      token: '',
      channelName,
      uid,
      tokenExpiresAt: new Date(expire * 1000).toISOString(),
      testingMode: true,
    };
  }

  const token = RtcTokenBuilder.buildTokenWithUid(
    AGORA_APP_ID,
    AGORA_APP_CERTIFICATE,
    channelName,
    uid,
    RtcRole.PUBLISHER,
    expire,
    expire,
  );

  return {
    appId: AGORA_APP_ID,
    token,
    channelName,
    uid,
    tokenExpiresAt: new Date(expire * 1000).toISOString(),
    testingMode: false,
  };
}

module.exports = {
  getAgoraConfig,
  uidForRole,
  buildRtcToken,
};
