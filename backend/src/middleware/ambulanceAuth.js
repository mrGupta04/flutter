const { sendError } = require('../utils/response');
const { authRequired, adminRequired } = require('./auth');
const Ambulance = require('../db/models/Ambulance');

function ambulanceRequired(req, res, next) {
  return authRequired(req, res, () => {
    const ambulanceId = req.auth?.ambulanceId;
    if (
      !ambulanceId ||
      !['ambulance', 'ambulance_driver'].includes(req.auth?.type)
    ) {
      return sendError(res, 'Ambulance authentication required', 403);
    }
    req.ambulanceId = ambulanceId;
    req.driverId = req.auth?.driverId || null;
    next();
  });
}

function ambulanceProviderRequired(req, res, next) {
  return authRequired(req, res, () => {
    if (req.auth?.type !== 'ambulance' || !req.auth?.ambulanceId) {
      return sendError(res, 'Ambulance provider authentication required', 403);
    }
    req.ambulanceId = req.auth.ambulanceId;
    next();
  });
}

function ambulanceDriverRequired(req, res, next) {
  return authRequired(req, res, () => {
    if (req.auth?.type !== 'ambulance_driver' || !req.auth?.driverId) {
      return sendError(res, 'Ambulance driver authentication required', 403);
    }
    req.ambulanceId = req.auth.ambulanceId;
    req.driverId = req.auth.driverId;
    next();
  });
}

function patientRequired(req, res, next) {
  return authRequired(req, res, () => {
    if (req.auth?.type !== 'patient' || !req.auth?.patientId) {
      return sendError(res, 'Patient authentication required', 403);
    }
    next();
  });
}

async function assertAmbulanceActive(ambulanceId) {
  const doc = await Ambulance.findOne({ id: ambulanceId }).lean();
  if (!doc) {
    const err = new Error('Ambulance provider not found');
    err.statusCode = 404;
    throw err;
  }
  if (doc.isDisabled || doc.isSuspended) {
    const err = new Error('Ambulance provider is currently unavailable');
    err.statusCode = 403;
    throw err;
  }
  return doc;
}

function actorFromAuth(auth = {}) {
  if (auth.type === 'admin') {
    return { actorId: auth.adminId || auth.id || 'admin', actorRole: 'admin' };
  }
  if (auth.type === 'ambulance_driver') {
    return { actorId: auth.driverId, actorRole: 'driver' };
  }
  if (auth.ambulanceId) {
    return { actorId: auth.ambulanceId, actorRole: 'ambulance_provider' };
  }
  if (auth.patientId) {
    return { actorId: auth.patientId, actorRole: 'patient' };
  }
  return { actorId: 'system', actorRole: 'system' };
}

function adminOrAmbulance(req, res, next) {
  return authRequired(req, res, () => {
    if (req.auth?.type === 'admin') return next();
    return adminRequired(req, res, () => next());
  });
}

module.exports = {
  ambulanceRequired,
  ambulanceProviderRequired,
  ambulanceDriverRequired,
  patientRequired,
  assertAmbulanceActive,
  actorFromAuth,
  adminOrAmbulance,
};
