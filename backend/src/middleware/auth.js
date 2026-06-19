const jwt = require('jsonwebtoken');

const { sendError } = require('../utils/response');



const JWT_SECRET = process.env.JWT_SECRET || 'medconnect-dev-secret';



function signToken(payload, expiresIn = '7d') {

  return jwt.sign(payload, JWT_SECRET, { expiresIn });

}



function verifyToken(token) {

  return jwt.verify(token, JWT_SECRET);

}



function authOptional(req, res, next) {

  const header = req.headers.authorization;

  if (header?.startsWith('Bearer ')) {

    try {

      req.auth = verifyToken(header.slice(7));

    } catch {

      req.auth = null;

    }

  }

  next();

}



function authRequired(req, res, next) {

  const header = req.headers.authorization;

  if (!header?.startsWith('Bearer ')) {

    return sendError(res, 'Authentication required', 401);

  }

  try {

    req.auth = verifyToken(header.slice(7));

    next();

  } catch {

    return sendError(res, 'Invalid or expired token', 401);

  }

}



function tryBearerAuth(req) {

  const header = req.headers.authorization;

  if (!header?.startsWith('Bearer ')) return null;

  try {

    return verifyToken(header.slice(7));

  } catch {

    return null;

  }

}



function isAdminPayload(payload) {

  return payload?.type === 'admin' || payload?.role === 'admin';

}



/** Main admin only — review and approve applications */

function adminRequired(req, res, next) {

  const payload = tryBearerAuth(req);

  if (payload && isAdminPayload(payload)) {

    req.auth = payload;

    return next();

  }



  const key = req.headers['x-admin-key'] || req.query.adminKey;

  const expected = process.env.ADMIN_API_KEY;

  if (expected && key === expected) {

    req.auth = { type: 'admin', role: 'admin' };

    return next();

  }



  return sendError(res, 'Admin authentication required', 403);

}



module.exports = {

  signToken,

  verifyToken,

  authOptional,

  authRequired,

  adminRequired,

  isAdminPayload,

};


