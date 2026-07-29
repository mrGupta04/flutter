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

async function hydrateApprover(payload) {

  if (!isApproverPayload(payload)) return payload;

  const Approver = require('../db/models/Approver');

  const ApprovalSession = require('../db/models/ApprovalSession');

  const approverId = payload.approverId || payload.id || payload.sub;

  if (!approverId) return null;

  const approver = await Approver.findOne({

    id: approverId,

    status: 'active',

    deletedAt: null,

  }).lean();

  if (!approver) return null;

  if (payload.sessionId) {

    const session = await ApprovalSession.findOne({

      id: payload.sessionId,

      userId: approverId,

      revokedAt: null,

      expiresAt: { $gt: new Date() },

    }).lean();

    if (!session) return null;

  }

  return {

    ...payload,

    approverId,

    role: 'approver',

    type: 'approver',

    name: `${approver.firstName} ${approver.lastName}`.trim(),

    email: approver.email,

    permissions: approver.permissions || [],

    canReassign: Boolean(approver.canReassign),

  };

}



function isAdminPayload(payload) {

  return (
    payload?.type === 'admin' ||
    payload?.role === 'admin' ||
    payload?.role === 'super_admin'
  );

}



function isApproverPayload(payload) {

  return payload?.type === 'approver' || payload?.role === 'approver';

}



/** Main admin only — review and approve applications */

function adminRequired(req, res, next) {

  const payload = tryBearerAuth(req);

  if (payload && isAdminPayload(payload)) {

    req.auth = payload;

    return next();

  }



  const key = req.headers['x-admin-key'];

  const expected = process.env.ADMIN_API_KEY;

  if (expected && key === expected) {

    req.auth = { type: 'admin', role: 'admin' };

    return next();

  }



  return sendError(res, 'Admin authentication required', 403);

}



async function approvalUserRequired(req, res, next) {

  const payload = tryBearerAuth(req);

  if (payload && isAdminPayload(payload)) {

    req.auth = payload;

    return next();

  }

  if (payload && isApproverPayload(payload)) {

    try {

      const currentApprover = await hydrateApprover(payload);

      if (currentApprover) {

        req.auth = currentApprover;

        return next();

      }

    } catch (err) {

      console.error('Failed to validate approver session:', err);

      return sendError(res, 'Unable to validate approval workflow session', 503);

    }

  }

  const key = req.headers['x-admin-key'];

  const expected = process.env.ADMIN_API_KEY;

  if (expected && key === expected) {

    req.auth = { type: 'admin', role: 'admin' };

    return next();

  }

  return sendError(res, 'Approval workflow authentication required', 401);

}



function approvalAdminRequired(req, res, next) {

  const payload = tryBearerAuth(req);

  if (payload && isAdminPayload(payload)) {

    req.auth = payload;

    return next();

  }

  const key = req.headers['x-admin-key'];

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

  approvalAdminRequired,

  approvalUserRequired,

  isAdminPayload,

  isApproverPayload,

};


