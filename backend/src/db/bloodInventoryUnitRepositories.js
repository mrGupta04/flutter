const { v4: uuidv4 } = require('uuid');
const BloodInventoryUnit = require('./models/BloodInventoryUnit');
const BloodInventory = require('./models/BloodInventory');
const { writeAudit } = require('./bloodAuditRepositories');
const { toBloodInventory } = require('./bloodBankModuleMappers');

function httpError(message, statusCode = 400) {
  const err = new Error(message);
  err.statusCode = statusCode;
  return err;
}

async function recountInventory(bloodBankId, bloodGroup, componentType) {
  const [available, reserved, expired, unavailable, total] = await Promise.all([
    BloodInventoryUnit.countDocuments({
      bloodBankId,
      bloodGroup,
      componentType,
      status: 'available',
    }),
    BloodInventoryUnit.countDocuments({
      bloodBankId,
      bloodGroup,
      componentType,
      status: 'reserved',
    }),
    BloodInventoryUnit.countDocuments({
      bloodBankId,
      bloodGroup,
      componentType,
      status: 'expired',
    }),
    BloodInventoryUnit.countDocuments({
      bloodBankId,
      bloodGroup,
      componentType,
      status: 'unavailable',
    }),
    BloodInventoryUnit.countDocuments({
      bloodBankId,
      bloodGroup,
      componentType,
      status: { $nin: ['disposed', 'transferred', 'issued'] },
    }),
  ]);

  const existing = await BloodInventory.findOne({
    bloodBankId,
    bloodGroup,
    $or: [{ componentType }, { componentType: { $exists: false } }],
  });

  const payload = {
    id: existing?.id || uuidv4(),
    bloodBankId,
    bloodGroup,
    componentType,
    availableUnits: available,
    reservedUnits: reserved,
    expiredUnits: expired,
    unavailableUnits: unavailable,
    totalUnits: total,
    lastUpdated: new Date(),
  };

  if (existing) {
    await BloodInventory.updateOne({ id: existing.id }, { $set: payload });
  } else {
    await BloodInventory.create(payload);
  }
  return toBloodInventory(await BloodInventory.findOne({ id: payload.id }));
}

async function listUnits(bloodBankId, { bloodGroup, componentType, status, page = 1, pageSize = 30 } = {}) {
  const filter = { bloodBankId };
  if (bloodGroup) filter.bloodGroup = bloodGroup;
  if (componentType) filter.componentType = componentType;
  if (status) filter.status = status;

  const totalCount = await BloodInventoryUnit.countDocuments(filter);
  const totalPages = Math.max(1, Math.ceil(totalCount / pageSize));
  const units = await BloodInventoryUnit.find(filter)
    .sort({ expiryDate: 1, createdAt: -1 })
    .skip((page - 1) * pageSize)
    .limit(pageSize)
    .lean();

  return {
    units,
    pagination: {
      currentPage: page,
      totalPages,
      pageSize,
      totalCount,
      hasNextPage: page < totalPages,
    },
  };
}

async function addUnits({
  bloodBankId,
  bloodGroup,
  componentType = 'whole_blood',
  units,
  collectionDate,
  expiryDate,
  storageLocation,
  batchIdentifier,
  actorId,
  actorRole,
}) {
  const count = Number(units);
  if (!count || count < 1) throw httpError('Units must be greater than zero');
  if (!bloodGroup) throw httpError('Invalid blood group');

  const created = [];
  for (let i = 0; i < count; i += 1) {
    const unit = await BloodInventoryUnit.create({
      id: uuidv4(),
      bloodBankId,
      bloodGroup,
      componentType,
      unitIdentifier: `${bloodGroup}-${componentType}-${Date.now()}-${i + 1}-${uuidv4().slice(0, 6)}`,
      batchIdentifier: batchIdentifier || null,
      storageLocation: storageLocation || null,
      collectionDate: collectionDate ? new Date(collectionDate) : new Date(),
      expiryDate: expiryDate ? new Date(expiryDate) : null,
      status: 'available',
    });
    created.push(unit.toObject());
  }

  const inventory = await recountInventory(bloodBankId, bloodGroup, componentType);
  await writeAudit({
    actorId: actorId || 'system',
    actorRole: actorRole || 'blood_bank',
    action: 'inventory_created',
    entityType: 'BloodInventory',
    entityId: inventory.id,
    bloodBankId,
    newValue: { bloodGroup, componentType, units: count },
  });
  return { units: created, inventory };
}

async function updateUnit(unitId, patch, { actorId, actorRole } = {}) {
  const existing = await BloodInventoryUnit.findOne({ id: unitId });
  if (!existing) throw httpError('Inventory unit not found', 404);

  const allowed = [
    'status',
    'storageLocation',
    'expiryDate',
    'collectionDate',
    'notes',
    'batchIdentifier',
  ];
  const updates = {};
  for (const key of allowed) {
    if (patch[key] !== undefined) updates[key] = patch[key];
  }
  updates.version = (existing.version || 0) + 1;

  await BloodInventoryUnit.updateOne({ id: unitId }, { $set: updates });
  const updated = await BloodInventoryUnit.findOne({ id: unitId }).lean();
  await recountInventory(existing.bloodBankId, existing.bloodGroup, existing.componentType);
  await writeAudit({
    actorId: actorId || 'system',
    actorRole: actorRole || 'blood_bank',
    action: 'inventory_modified',
    entityType: 'BloodInventoryUnit',
    entityId: unitId,
    bloodBankId: existing.bloodBankId,
    previousValue: { status: existing.status },
    newValue: updates,
  });
  return updated;
}

async function markExpiredUnits() {
  const now = new Date();
  const due = await BloodInventoryUnit.find({
    status: { $in: ['available', 'reserved'] },
    expiryDate: { $lte: now },
  }).lean();

  let marked = 0;
  const affected = new Map();
  for (const unit of due) {
    const updated = await BloodInventoryUnit.findOneAndUpdate(
      { id: unit.id, status: { $in: ['available', 'reserved'] } },
      { $set: { status: 'expired' }, $inc: { version: 1 } },
      { new: true },
    );
    if (!updated) continue;
    marked += 1;
    affected.set(
      `${updated.bloodBankId}:${updated.bloodGroup}:${updated.componentType}`,
      updated,
    );
  }

  for (const item of affected.values()) {
    await recountInventory(item.bloodBankId, item.bloodGroup, item.componentType);
  }
  return marked;
}

function publicAvailabilityState(available, { low = 5, critical = 2 } = {}) {
  if (available <= 0) return 'not_available';
  if (available <= critical) return 'critical';
  if (available <= low) return 'low_stock';
  return 'available';
}

function toPublicInventory(entries, bank) {
  const visibility = bank?.publicInventoryVisibility || 'states';
  if (visibility === 'hidden') return [];

  const low = bank?.lowStockThreshold ?? 5;
  const critical = bank?.criticalStockThreshold ?? 2;

  return (entries || []).map((entry) => {
    const available = Math.max(
      0,
      (entry.availableUnits || 0) - (entry.unavailableUnits || 0),
    );
    const state = publicAvailabilityState(available, {
      low: entry.lowStockThreshold ?? low,
      critical: entry.criticalStockThreshold ?? critical,
    });
    const itemVisibility = entry.publicVisibility === 'inherit'
      ? visibility
      : entry.publicVisibility || visibility;

    const publicEntry = {
      bloodGroup: entry.bloodGroup,
      componentType: entry.componentType || 'whole_blood',
      availability: state,
      lastUpdated: entry.lastUpdated,
    };
    if (itemVisibility === 'counts') {
      publicEntry.availableUnits = available;
    }
    return publicEntry;
  });
}

module.exports = {
  recountInventory,
  listUnits,
  addUnits,
  updateUnit,
  markExpiredUnits,
  publicAvailabilityState,
  toPublicInventory,
};
