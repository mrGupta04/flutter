const { v4: uuidv4 } = require('uuid');
const PatientFavorite = require('./models/PatientFavorite');
const Doctor = require('./models/Doctor');
const Nurse = require('./models/Nurse');
const { toDoctor } = require('./mappers');
const { toNurse } = require('./nurseMappers');

async function addFavorite(patientId, providerType, providerId) {
  if (!['doctor', 'nurse'].includes(providerType)) {
    const err = new Error('providerType must be doctor or nurse');
    err.statusCode = 400;
    throw err;
  }

  if (providerType === 'doctor') {
    const doctor = await Doctor.findOne({ id: providerId }).lean();
    if (!doctor) {
      const err = new Error('Doctor not found');
      err.statusCode = 404;
      throw err;
    }
  } else {
    const nurse = await Nurse.findOne({ id: providerId }).lean();
    if (!nurse) {
      const err = new Error('Nurse not found');
      err.statusCode = 404;
      throw err;
    }
  }

  try {
    const fav = await PatientFavorite.create({
      id: uuidv4(),
      patientId,
      providerType,
      providerId,
    });
    return fav.toObject();
  } catch (err) {
    if (err.code === 11000) {
      const existing = await PatientFavorite.findOne({
        patientId,
        providerType,
        providerId,
      }).lean();
      return existing;
    }
    throw err;
  }
}

async function removeFavorite(patientId, providerType, providerId) {
  await PatientFavorite.deleteOne({ patientId, providerType, providerId });
  return { success: true };
}

async function listFavorites(patientId) {
  const rows = await PatientFavorite.find({ patientId })
    .sort({ createdAt: -1 })
    .lean();

  const doctorIds = rows.filter((r) => r.providerType === 'doctor').map((r) => r.providerId);
  const nurseIds = rows.filter((r) => r.providerType === 'nurse').map((r) => r.providerId);

  const [doctors, nurses] = await Promise.all([
    doctorIds.length ? Doctor.find({ id: { $in: doctorIds } }).lean() : [],
    nurseIds.length ? Nurse.find({ id: { $in: nurseIds } }).lean() : [],
  ]);

  const doctorMap = new Map(doctors.map((d) => [d.id, toDoctor(d)]));
  const nurseMap = new Map(nurses.map((n) => [n.id, toNurse(n)]));

  return rows
    .map((row) => {
      const provider =
        row.providerType === 'doctor'
          ? doctorMap.get(row.providerId)
          : nurseMap.get(row.providerId);
      if (!provider) return null;
      return {
        id: row.id,
        providerType: row.providerType,
        providerId: row.providerId,
        createdAt: row.createdAt,
        provider,
      };
    })
    .filter(Boolean);
}

async function isFavorite(patientId, providerType, providerId) {
  const row = await PatientFavorite.findOne({
    patientId,
    providerType,
    providerId,
  }).lean();
  return Boolean(row);
}

module.exports = {
  addFavorite,
  removeFavorite,
  listFavorites,
  isFavorite,
};
