const { sendError } = require('../utils/response');
const { authRequired } = require('./auth');
const BloodBank = require('../db/models/BloodBank');
const BloodBankStaff = require('../db/models/BloodBankStaff');

const ROLE_PERMISSIONS = {
  blood_bank_admin: ['*'],
  inventory_manager: [
    'inventory.read',
    'inventory.write',
    'donations.write',
    'donors.read',
  ],
  request_manager: [
    'requests.read',
    'requests.write',
    'emergency.write',
    'chat.write',
  ],
  staff: ['requests.read', 'inventory.read', 'chat.write'],
};

function hasPermission(role, permission) {
  const allowed = ROLE_PERMISSIONS[role] || ROLE_PERMISSIONS.staff;
  return allowed.includes('*') || allowed.includes(permission);
}

function bloodBankRequired(req, res, next) {
  return authRequired(req, res, () => {
    const bloodBankId = req.auth?.bloodBankId;
    if (!bloodBankId || !['bloodbank', 'blood_bank_staff'].includes(req.auth?.type)) {
      return sendError(res, 'Blood bank authentication required', 403);
    }
    req.bloodBankId = bloodBankId;
    req.staffRole = req.auth.staffRole || 'blood_bank_admin';
    next();
  });
}

function requireBloodPermission(permission) {
  return (req, res, next) => {
    if (req.auth?.type === 'bloodbank' && !req.auth?.staffId) {
      return next();
    }
    const role = req.auth?.staffRole || req.staffRole || 'staff';
    if (!hasPermission(role, permission)) {
      return sendError(res, 'You do not have permission for this action', 403);
    }
    next();
  };
}

async function assertBloodBankActive(bloodBankId) {
  const bank = await BloodBank.findOne({ id: bloodBankId }).lean();
  if (!bank) {
    const err = new Error('Blood bank not found');
    err.statusCode = 404;
    throw err;
  }
  if (bank.isDisabled || bank.isSuspended || bank.verificationStatus === 'suspended') {
    const err = new Error('Provider disabled');
    err.statusCode = 403;
    throw err;
  }
  return bank;
}

async function resolveStaff(staffId) {
  if (!staffId) return null;
  return BloodBankStaff.findOne({ id: staffId, active: true }).lean();
}

function patientRequired(req, res, next) {
  return authRequired(req, res, () => {
    if (req.auth?.type !== 'patient' || !req.auth?.patientId) {
      return sendError(res, 'Patient authentication required', 403);
    }
    next();
  });
}

function actorFromAuth(auth = {}) {
  if (auth.type === 'admin') {
    return { actorId: auth.adminId || auth.id || 'admin', actorRole: 'admin' };
  }
  if (auth.staffId) {
    return { actorId: auth.staffId, actorRole: auth.staffRole || 'staff' };
  }
  if (auth.bloodBankId) {
    return { actorId: auth.bloodBankId, actorRole: 'blood_bank_admin' };
  }
  if (auth.patientId) {
    return { actorId: auth.patientId, actorRole: 'patient' };
  }
  return { actorId: 'system', actorRole: 'system' };
}

module.exports = {
  bloodBankRequired,
  requireBloodPermission,
  patientRequired,
  assertBloodBankActive,
  resolveStaff,
  actorFromAuth,
  hasPermission,
  ROLE_PERMISSIONS,
};
