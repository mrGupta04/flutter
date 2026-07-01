const { v4: uuidv4 } = require('uuid');
const BloodInventory = require('./models/BloodInventory');
const { toBloodInventory } = require('./bloodBankModuleMappers');
const DEFAULT_BLOOD_GROUPS = [
  'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'Bombay', 'Rare',
];

async function initializeBloodBankInventory(bloodBankId) {
  const existing = await BloodInventory.countDocuments({ bloodBankId });
  if (existing > 0) return listInventoryByBloodBank(bloodBankId);

  const entries = DEFAULT_BLOOD_GROUPS.map((bloodGroup) => ({
    id: uuidv4(),
    bloodBankId,
    bloodGroup,
    availableUnits: 0,
    reservedUnits: 0,
    totalUnits: 0,
    expiryDates: [],
    lastUpdated: new Date(),
  }));

  await BloodInventory.insertMany(entries);
  return listInventoryByBloodBank(bloodBankId);
}

async function listInventoryByBloodBank(bloodBankId) {
  const docs = await BloodInventory.find({ bloodBankId }).sort({ bloodGroup: 1 });
  return docs.map(toBloodInventory);
}

async function findInventoryById(id) {
  const doc = await BloodInventory.findOne({ id });
  return toBloodInventory(doc);
}

async function findInventoryByGroup(bloodBankId, bloodGroup) {
  const doc = await BloodInventory.findOne({ bloodBankId, bloodGroup });
  return toBloodInventory(doc);
}

async function upsertInventoryEntry(data) {
  const id = data.id || uuidv4();
  const existing = await BloodInventory.findOne({
    bloodBankId: data.bloodBankId,
    bloodGroup: data.bloodGroup,
  });

  const available = data.availableUnits ?? existing?.availableUnits ?? 0;
  const reserved = data.reservedUnits ?? existing?.reservedUnits ?? 0;
  const total = data.totalUnits ?? available + reserved;

  const payload = {
    id: existing?.id || id,
    bloodBankId: data.bloodBankId,
    bloodGroup: data.bloodGroup,
    availableUnits: available,
    reservedUnits: reserved,
    totalUnits: total,
    expiryDates: data.expiryDates ?? existing?.expiryDates ?? [],
    lastUpdated: new Date(),
  };

  if (existing) {
    await BloodInventory.updateOne({ id: existing.id }, { $set: payload });
    return findInventoryById(existing.id);
  }

  await BloodInventory.create(payload);
  return findInventoryById(payload.id);
}

async function addBloodUnits(bloodBankId, bloodGroup, units, expiryDate) {
  const entry = await findInventoryByGroup(bloodBankId, bloodGroup);
  if (!entry) {
    return upsertInventoryEntry({
      bloodBankId,
      bloodGroup,
      availableUnits: units,
      totalUnits: units,
      expiryDates: expiryDate ? [{ units, expiryDate }] : [],
    });
  }

  const expiryDates = [...(entry.expiryDates || [])];
  if (expiryDate) {
    expiryDates.push({ units, expiryDate });
  }

  return upsertInventoryEntry({
    id: entry.id,
    bloodBankId,
    bloodGroup,
    availableUnits: entry.availableUnits + units,
    reservedUnits: entry.reservedUnits,
    totalUnits: entry.totalUnits + units,
    expiryDates,
  });
}

async function removeExpiredUnits(bloodBankId) {
  const entries = await listInventoryByBloodBank(bloodBankId);
  const now = new Date();
  let removed = 0;

  for (const entry of entries) {
    const valid = [];
    let expiredUnits = 0;
    for (const e of entry.expiryDates || []) {
      if (new Date(e.expiryDate) < now) {
        expiredUnits += e.units || 0;
      } else {
        valid.push(e);
      }
    }
    if (expiredUnits > 0) {
      removed += expiredUnits;
      await upsertInventoryEntry({
        id: entry.id,
        bloodBankId,
        bloodGroup: entry.bloodGroup,
        availableUnits: Math.max(0, entry.availableUnits - expiredUnits),
        reservedUnits: entry.reservedUnits,
        totalUnits: Math.max(0, entry.totalUnits - expiredUnits),
        expiryDates: valid,
      });
    }
  }

  return { removed };
}

async function reserveInventory(bloodBankId, bloodGroup, units) {
  const entry = await findInventoryByGroup(bloodBankId, bloodGroup);
  if (!entry || entry.availableUnits < units) {
    const err = new Error('Insufficient blood units available');
    err.statusCode = 400;
    throw err;
  }

  return upsertInventoryEntry({
    id: entry.id,
    bloodBankId,
    bloodGroup,
    availableUnits: entry.availableUnits - units,
    reservedUnits: entry.reservedUnits + units,
    totalUnits: entry.totalUnits,
    expiryDates: entry.expiryDates,
  });
}

async function fulfillReservedUnits(bloodBankId, bloodGroup, units) {
  const entry = await findInventoryByGroup(bloodBankId, bloodGroup);
  if (!entry) return null;

  return upsertInventoryEntry({
    id: entry.id,
    bloodBankId,
    bloodGroup,
    availableUnits: entry.availableUnits,
    reservedUnits: Math.max(0, entry.reservedUnits - units),
    totalUnits: Math.max(0, entry.totalUnits - units),
    expiryDates: entry.expiryDates,
  });
}

async function releaseReservedUnits(bloodBankId, bloodGroup, units) {
  const entry = await findInventoryByGroup(bloodBankId, bloodGroup);
  if (!entry) return null;

  return upsertInventoryEntry({
    id: entry.id,
    bloodBankId,
    bloodGroup,
    availableUnits: entry.availableUnits + units,
    reservedUnits: Math.max(0, entry.reservedUnits - units),
    totalUnits: entry.totalUnits,
    expiryDates: entry.expiryDates,
  });
}

module.exports = {
  initializeBloodBankInventory,
  listInventoryByBloodBank,
  findInventoryById,
  findInventoryByGroup,
  upsertInventoryEntry,
  addBloodUnits,
  removeExpiredUnits,
  reserveInventory,
  fulfillReservedUnits,
  releaseReservedUnits,
};
