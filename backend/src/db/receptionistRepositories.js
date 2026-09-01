const { v4: uuidv4 } = require('uuid');
const Receptionist = require('./models/Receptionist');
const Doctor = require('./models/Doctor');
const { hashPassword, verifyPassword, loginProvider } = require('../utils/providerAuth');

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

function toPublicReceptionist(doc) {
  if (!doc) return null;
  const d = doc.toObject ? doc.toObject() : doc;
  return {
    id: d.id,
    doctorId: d.doctorId,
    clinicId: d.clinicId || d.doctorId,
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

async function assertDoctorOwnsReceptionist(doctorId, receptionistId) {
  const receptionist = await Receptionist.findOne({ id: receptionistId });
  if (!receptionist) {
    const err = new Error('Receptionist not found');
    err.statusCode = 404;
    throw err;
  }
  if (receptionist.doctorId !== doctorId) {
    const err = new Error('This receptionist is not assigned to your clinic');
    err.statusCode = 403;
    throw err;
  }
  return receptionist;
}

async function createReceptionist(doctorId, payload = {}) {
  const doctor = await Doctor.findOne({ id: doctorId }).lean();
  if (!doctor) {
    const err = new Error('Doctor not found');
    err.statusCode = 404;
    throw err;
  }

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
    doctorId,
    clinicId: doctorId,
    name,
    email,
    phone: phone || undefined,
    passwordHash: hashPassword(password),
    status: 'active',
  });

  return toPublicReceptionist(doc);
}

async function listReceptionistsForDoctor(doctorId) {
  const rows = await Receptionist.find({ doctorId }).sort({ createdAt: -1 }).lean();
  return rows.map(toPublicReceptionist);
}

async function updateReceptionist(doctorId, receptionistId, payload = {}) {
  const receptionist = await assertDoctorOwnsReceptionist(doctorId, receptionistId);
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

async function setReceptionistStatus(doctorId, receptionistId, status) {
  const next = String(status || '').toLowerCase() === 'disabled' ? 'disabled' : 'active';
  const receptionist = await assertDoctorOwnsReceptionist(doctorId, receptionistId);
  receptionist.status = next;
  await receptionist.save();
  return toPublicReceptionist(receptionist);
}

async function deleteReceptionist(doctorId, receptionistId) {
  const receptionist = await assertDoctorOwnsReceptionist(doctorId, receptionistId);
  await Receptionist.deleteOne({ id: receptionist.id });
  return { deleted: true, id: receptionist.id };
}

async function resetReceptionistPassword(doctorId, receptionistId, password) {
  assertPassword(password);
  const receptionist = await assertDoctorOwnsReceptionist(doctorId, receptionistId);
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
    buildTokenPayload: (profile) => ({
      type: 'receptionist',
      receptionistId: profile.id,
      doctorId: profile.doctorId,
      clinicId: profile.clinicId || profile.doctorId,
    }),
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
  updateReceptionist,
  setReceptionistStatus,
  deleteReceptionist,
  resetReceptionistPassword,
  loginReceptionist,
  getReceptionistById,
};
