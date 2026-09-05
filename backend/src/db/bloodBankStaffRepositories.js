const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const BloodBankStaff = require('./models/BloodBankStaff');
const { toBloodBankStaff } = require('./bloodBankModuleMappers');
const { ROLE_PERMISSIONS } = require('../middleware/bloodBankAuth');

async function listStaffByBloodBank(bloodBankId) {
  const docs = await BloodBankStaff.find({ bloodBankId, active: true }).sort({ name: 1 });
  return docs.map(toBloodBankStaff);
}

async function findStaffByEmail(email) {
  if (!email) return null;
  return BloodBankStaff.findOne({
    email: String(email).trim().toLowerCase(),
    active: true,
  });
}

async function upsertStaff(data) {
  const id = data.id || uuidv4();
  const existing = await BloodBankStaff.findOne({ id });
  const role = data.role || existing?.role || 'staff';

  const payload = {
    id,
    bloodBankId: data.bloodBankId,
    name: data.name,
    role,
    mobileNumber: data.mobileNumber,
    email: data.email ? String(data.email).trim().toLowerCase() : existing?.email,
    permissions: data.permissions || ROLE_PERMISSIONS[role] || ROLE_PERMISSIONS.staff,
    active: data.active !== false,
  };

  if (data.password) {
    payload.passwordHash = bcrypt.hashSync(data.password, 10);
  } else if (existing?.passwordHash) {
    payload.passwordHash = existing.passwordHash;
  }

  if (existing) {
    await BloodBankStaff.updateOne({ id }, { $set: payload });
  } else {
    await BloodBankStaff.create(payload);
  }

  const doc = await BloodBankStaff.findOne({ id });
  return toBloodBankStaff(doc);
}

async function removeStaff(id) {
  await BloodBankStaff.updateOne({ id }, { $set: { active: false } });
  return toBloodBankStaff(await BloodBankStaff.findOne({ id }));
}

module.exports = {
  listStaffByBloodBank,
  findStaffByEmail,
  upsertStaff,
  removeStaff,
};
