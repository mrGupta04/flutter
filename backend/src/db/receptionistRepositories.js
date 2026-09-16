const { v4: uuidv4 } = require('uuid');
const Receptionist = require('./models/Receptionist');
const Doctor = require('./models/Doctor');
const { hashPassword, loginProvider } = require('../utils/providerAuth');

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const OWNER_TYPES = ['doctor', 'lab', 'scan', 'blood_bank'];

function ownerTypeOf(doc) {
  return doc?.ownerType || 'doctor';
}

function ownerIdOf(doc) {
  return doc?.ownerId || doc?.doctorId;
}

function toPublicReceptionist(doc) {
  if (!doc) return null;
  const d = doc.toObject ? doc.toObject() : doc;
  const ownerType = ownerTypeOf(d);
  const ownerId = ownerIdOf(d);
  return {
    id: d.id,
    ownerType,
    ownerId,
    doctorId: ownerType === 'doctor' ? ownerId : d.doctorId || null,
    clinicId: d.clinicId || (ownerType === 'doctor' ? ownerId : null),
    name: d.name,
    email: d.email,
    phone: d.phone || null,
    status: d.status || 'active',
    lastLoginAt: d.lastLoginAt || null,
    createdAt: d.createdAt,
    updatedAt: d.updatedAt,
  };
}

function normalizeEmail(email) {
  return String(email || '').trim().toLowerCase();
}

function assertPassword(password) {
  const value = String(password || '');
  if (value.length < 8) {
    const err = new Error('Password must be at least 8 characters');
    err.statusCode = 400;
    throw err;
  }
}

function normalizeOwner(owner) {
  if (typeof owner === 'string') {
    return { ownerType: 'doctor', ownerId: owner };
  }
  const ownerType = String(owner?.ownerType || 'doctor');
  const ownerId = String(owner?.ownerId || '');
  if (!OWNER_TYPES.includes(ownerType) || !ownerId) {
    const err = new Error('A valid facility is required');
    err.statusCode = 400;
    throw err;
  }
  return { ownerType, ownerId };
}

function ownerQuery({ ownerType, ownerId }) {
  if (ownerType === 'doctor') {
    return {
      $or: [
        { ownerType: 'doctor', ownerId },
        {
          doctorId: ownerId,
          $or: [{ ownerType: { $exists: false } }, { ownerType: 'doctor' }],
        },
      ],
    };
  }
  return { ownerType, ownerId };
}

function matchesOwner(doc, { ownerType, ownerId }) {
  return ownerTypeOf(doc) === ownerType && ownerIdOf(doc) === ownerId;
}

async function assertOwnerExists(ownerType, ownerId) {
  if (ownerType === 'doctor') {
    const doctor = await Doctor.findOne({ id: ownerId }).lean();
    if (!doctor) {
      const err = new Error('Doctor not found');
      err.statusCode = 404;
      throw err;
    }
    return;
  }
  if (ownerType === 'lab') {
    const { findLabById } = require('./labRepositories');
    const lab = await findLabById(ownerId);
    if (!lab) {
      const err = new Error('Lab not found');
      err.statusCode = 404;
      throw err;
    }
    return;
  }
  if (ownerType === 'scan') {
    const { findScanCenterById } = require('./scanCenterRepositories');
    const center = await findScanCenterById(ownerId);
    if (!center) {
      const err = new Error('Scan center not found');
      err.statusCode = 404;
      throw err;
    }
    return;
  }
  if (ownerType === 'blood_bank') {
    const { findBloodBankById } = require('./bloodBankRepositories');
    const bank = await findBloodBankById(ownerId);
    if (!bank) {
      const err = new Error('Blood bank not found');
      err.statusCode = 404;
      throw err;
    }
  }
}

async function assertOwnerOwnsReceptionist(owner, receptionistId) {
  const normalized = normalizeOwner(owner);
  const receptionist = await Receptionist.findOne({ id: receptionistId });
  if (!receptionist) {
    const err = new Error('Receptionist not found');
    err.statusCode = 404;
    throw err;
  }
  if (!matchesOwner(receptionist, normalized)) {
    const err = new Error('This receptionist is not assigned to your facility');
    err.statusCode = 403;
    throw err;
  }
  return receptionist;
}

async function assertDoctorOwnsReceptionist(doctorId, receptionistId) {
  return assertOwnerOwnsReceptionist(
    { ownerType: 'doctor', ownerId: doctorId },
    receptionistId,
  );
}

function loginTokenPayload(profile) {
  const ownerType = profile.ownerType || 'doctor';
  const ownerId = profile.ownerId || profile.doctorId;
  const payload = {
    type: 'receptionist',
    receptionistId: profile.id,
    ownerType,
    ownerId,
  };
  if (ownerType === 'doctor') {
    payload.doctorId = ownerId;
    payload.clinicId = profile.clinicId || ownerId;
  } else if (ownerType === 'lab') {
    payload.labId = ownerId;
  } else if (ownerType === 'scan') {
    payload.scanCenterId = ownerId;
  } else if (ownerType === 'blood_bank') {
    payload.bloodBankId = ownerId;
  }
  return payload;
}

async function createReceptionist(owner, payload = {}) {
  const { ownerType, ownerId } = normalizeOwner(owner);
  await assertOwnerExists(ownerType, ownerId);

  const name = String(payload.name || '').trim();
  const email = normalizeEmail(payload.email);
  const phone = String(payload.phone || '').trim();
  const password = payload.password;

  if (!name) {
    const err = new Error('Receptionist name is required');
    err.statusCode = 400;
    throw err;
  }
  if (!EMAIL_RE.test(email)) {
    const err = new Error('A valid email is required');
    err.statusCode = 400;
    throw err;
  }
  assertPassword(password);

  const existing = await Receptionist.findOne({ email }).lean();
  if (existing) {
    const err = new Error('A receptionist with this email already exists');
    err.statusCode = 409;
    throw err;
  }

  const doc = await Receptionist.create({
    id: uuidv4(),
    ownerType,
    ownerId,
    doctorId: ownerType === 'doctor' ? ownerId : undefined,
    clinicId: ownerType === 'doctor' ? ownerId : undefined,
    name,
    email,
    phone: phone || undefined,
    passwordHash: hashPassword(password),
    status: 'active',
  });

  return toPublicReceptionist(doc);
}

async function listReceptionistsForOwner(owner) {
  const normalized = normalizeOwner(owner);
  const rows = await Receptionist.find(ownerQuery(normalized))
    .sort({ createdAt: -1 })
    .lean();
  return rows.map(toPublicReceptionist);
}

async function listReceptionistsForDoctor(doctorId) {
  return listReceptionistsForOwner({ ownerType: 'doctor', ownerId: doctorId });
}

async function updateReceptionist(owner, receptionistId, payload = {}) {
  const receptionist = await assertOwnerOwnsReceptionist(owner, receptionistId);
  if (payload.name != null) {
    const name = String(payload.name).trim();
    if (!name) {
      const err = new Error('Receptionist name is required');
      err.statusCode = 400;
      throw err;
    }
    receptionist.name = name;
  }
  if (payload.email != null) {
    const email = normalizeEmail(payload.email);
    if (!EMAIL_RE.test(email)) {
      const err = new Error('A valid email is required');
      err.statusCode = 400;
      throw err;
    }
    const clash = await Receptionist.findOne({
      email,
      id: { $ne: receptionist.id },
    }).lean();
    if (clash) {
      const err = new Error('A receptionist with this email already exists');
      err.statusCode = 409;
      throw err;
    }
    receptionist.email = email;
  }
  if (payload.phone != null) {
    receptionist.phone = String(payload.phone).trim() || undefined;
  }
  await receptionist.save();
  return toPublicReceptionist(receptionist);
}

async function setReceptionistStatus(owner, receptionistId, status) {
  const next = String(status || '').toLowerCase() === 'disabled' ? 'disabled' : 'active';
  const receptionist = await assertOwnerOwnsReceptionist(owner, receptionistId);
  receptionist.status = next;
  await receptionist.save();
  return toPublicReceptionist(receptionist);
}

async function deleteReceptionist(owner, receptionistId) {
  const receptionist = await assertOwnerOwnsReceptionist(owner, receptionistId);
  await Receptionist.deleteOne({ id: receptionist.id });
  return { deleted: true, id: receptionist.id };
}

async function resetReceptionistPassword(owner, receptionistId, password) {
  assertPassword(password);
  const receptionist = await assertOwnerOwnsReceptionist(owner, receptionistId);
  receptionist.passwordHash = hashPassword(password);
  await receptionist.save();
  return { updated: true, id: receptionist.id };
}

async function loginReceptionist({ email, password }) {
  const result = await loginProvider({
    email,
    password,
    findByEmail: (normalized) => Receptionist.findOne({ email: normalized }),
    toPublic: toPublicReceptionist,
    buildTokenPayload: loginTokenPayload,
  });

  if (!result.ok) return result;

  if (result.profile.status === 'disabled') {
    return {
      ok: false,
      status: 403,
      error: 'This receptionist account is disabled',
    };
  }

  await Receptionist.updateOne(
    { id: result.profile.id },
    { $set: { lastLoginAt: new Date() } },
  );

  return result;
}

async function getReceptionistById(id) {
  const doc = await Receptionist.findOne({ id }).lean();
  return toPublicReceptionist(doc);
}

module.exports = {
  toPublicReceptionist,
  createReceptionist,
  listReceptionistsForDoctor,
  listReceptionistsForOwner,
  updateReceptionist,
  setReceptionistStatus,
  deleteReceptionist,
  resetReceptionistPassword,
  loginReceptionist,
  getReceptionistById,
};
