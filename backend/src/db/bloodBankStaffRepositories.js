const { v4: uuidv4 } = require('uuid');
const BloodBankStaff = require('./models/BloodBankStaff');
const { toBloodBankStaff } = require('./bloodBankModuleMappers');

async function listStaffByBloodBank(bloodBankId) {
  const docs = await BloodBankStaff.find({ bloodBankId, active: true }).sort({ name: 1 });
  return docs.map(toBloodBankStaff);
}

async function upsertStaff(data) {
  const id = data.id || uuidv4();
  const existing = await BloodBankStaff.findOne({ id });

  const payload = {
    id,
    bloodBankId: data.bloodBankId,
    name: data.name,
    role: data.role,
    mobileNumber: data.mobileNumber,
    email: data.email,
    active: data.active !== false,
  };

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
  upsertStaff,
  removeStaff,
};
