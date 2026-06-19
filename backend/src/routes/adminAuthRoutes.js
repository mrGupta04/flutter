const express = require('express');
const bcrypt = require('bcryptjs');
const { sendSuccess, sendError } = require('../utils/response');
const { signToken } = require('../middleware/auth');

const router = express.Router();

function checkPassword(password, plain, hash) {
  if (hash) return bcrypt.compareSync(password, hash);
  return password === plain;
}

/**
 * POST /admin/login — main admin authentication.
 */
router.post('/login', (req, res) => {
  const { email, password } = req.body || {};

  if (!email || !password) {
    return sendError(res, 'Email and password are required', 400);
  }

  const adminEmail = process.env.ADMIN_EMAIL || 'admin@1mgdoctors.com';
  const adminPassword = process.env.ADMIN_PASSWORD;
  const adminPasswordHash = process.env.ADMIN_PASSWORD_HASH;

  if (String(email).toLowerCase() !== adminEmail.toLowerCase()) {
    return sendError(res, 'Invalid credentials', 401);
  }

  if (!adminPassword && !adminPasswordHash) {
    return sendError(
      res,
      'Admin credentials not configured on server. Set ADMIN_PASSWORD in .env',
      503,
    );
  }

  const valid = checkPassword(password, adminPassword, adminPasswordHash);
  if (!valid) {
    return sendError(res, 'Invalid credentials', 401);
  }

  const token = signToken(
    {
      role: 'admin',
      type: 'admin',
      email: adminEmail,
      name: 'Main Admin',
    },
    '12h',
  );

  return sendSuccess(res, {
    message: 'Login successful',
    data: {
      token,
      email: adminEmail,
      role: 'admin',
      name: 'Main Admin',
    },
  });
});

module.exports = router;
