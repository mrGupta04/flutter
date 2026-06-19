const bcrypt = require('bcryptjs');

function hashPassword(password) {
  return bcrypt.hashSync(password, 10);
}

function verifyPassword(password, passwordHash) {
  if (!password || !passwordHash) return false;
  return bcrypt.compareSync(password, passwordHash);
}

/**
 * Shared email/password login for healthcare providers.
 */
async function loginProvider({ email, password, findByEmail, buildTokenPayload, toPublic }) {
  const normalized = String(email || '').trim().toLowerCase();
  if (!normalized || !password) {
    return { ok: false, status: 400, error: 'Email and password are required' };
  }

  const doc = await findByEmail(normalized);
  if (!doc) {
    return { ok: false, status: 401, error: 'Invalid email or password' };
  }

  if (!verifyPassword(password, doc.passwordHash)) {
    return { ok: false, status: 401, error: 'Invalid email or password' };
  }

  const profile = toPublic(doc);
  return { ok: true, profile, tokenPayload: buildTokenPayload(profile, doc) };
}

module.exports = {
  hashPassword,
  verifyPassword,
  loginProvider,
};
