const { v4: uuidv4 } = require('uuid');
const mongoose = require('mongoose');
const BloodInventory = require('./models/BloodInventory');
const BloodInventoryUnit = require('./models/BloodInventoryUnit');
const BloodReservation = require('./models/BloodReservation');
const BloodBank = require('./models/BloodBank');
const { writeAudit } = require('./bloodAuditRepositories');

function httpError(message, statusCode = 400) {
  const err = new Error(message);
  err.statusCode = statusCode;
  return err;
}

async function getHoldMinutes(bloodBankId) {
  const bank = await BloodBank.findOne({ id: bloodBankId })
    .select('reservationHoldMinutes')
    .lean();
  return bank?.reservationHoldMinutes || 120;
}

async function reserveUnitsAtomically({
  bloodBankId,
  bloodGroup,
  componentType = 'whole_blood',
  units,
  requestId,
  actorId,
  actorRole,
}) {
  const needed = Number(units);
  if (!bloodBankId || !bloodGroup || !needed || needed < 1) {
    throw httpError('Blood group and a positive unit count are required');
  }

  const existing = await BloodReservation.findOne({
    requestId,
    bloodBankId,
    status: 'active',
  }).lean();
  if (existing) {
    throw httpError('Duplicate request reservation already exists');
  }

  const holdMinutes = await getHoldMinutes(bloodBankId);
  const expiresAt = new Date(Date.now() + holdMinutes * 60 * 1000);
  const reservedUnitDocs = [];

  const session = await mongoose.startSession().catch(() => null);
  const run = async () => {
    const filter = {
      bloodBankId,
      bloodGroup,
      availableUnits: { $gte: needed },
    };
    if (componentType) {
      filter.$or = [{ componentType }, { componentType: { $exists: false } }];
    }

    const inventory = await BloodInventory.findOneAndUpdate(
      filter,
      {
        $inc: { availableUnits: -needed, reservedUnits: needed },
        $set: { lastUpdated: new Date() },
      },
      { new: true, ...(session ? { session } : {}) },
    );

    if (!inventory) {
      throw httpError('Insufficient units', 409);
    }

    const availableUnits = await BloodInventoryUnit.find({
      bloodBankId,
      bloodGroup,
      componentType,
      status: 'available',
      $or: [{ expiryDate: { $gt: new Date() } }, { expiryDate: { $exists: false } }],
    })
      .sort({ expiryDate: 1 })
      .limit(needed)
      .select('id unitIdentifier version')
      .lean();

    if (availableUnits.length >= needed) {
      for (const unit of availableUnits) {
        const updated = await BloodInventoryUnit.findOneAndUpdate(
          { id: unit.id, status: 'available', version: unit.version ?? 0 },
          {
            $set: {
              status: 'reserved',
              reservedForRequestId: requestId,
              reservedUntil: expiresAt,
            },
            $inc: { version: 1 },
          },
          { new: true, ...(session ? { session } : {}) },
        );
        if (!updated) {
          throw httpError('Unable to reserve the same blood units. Please retry.');
        }
        reservedUnitDocs.push({
          unitId: updated.id,
          unitIdentifier: updated.unitIdentifier,
        });
      }
    }

    const reservation = await BloodReservation.create(
      [
        {
          id: uuidv4(),
          bloodBankId,
          requestId,
          bloodGroup,
          componentType,
          units: needed,
          reservedUnits: reservedUnitDocs,
          status: 'active',
          expiresAt,
          createdBy: actorId,
          createdByRole: actorRole,
        },
      ],
      session ? { session } : {},
    );

    return reservation[0] || reservation;
  };

  let reservation;
  try {
    if (session) {
      await session.withTransaction(run);
      reservation = await BloodReservation.findOne({ requestId, status: 'active' });
    } else {
      reservation = await run();
    }
  } catch (err) {
    if (session) await session.abortTransaction().catch(() => {});
    throw err;
  } finally {
    if (session) await session.endSession();
  }

  await writeAudit({
    actorId: actorId || 'system',
    actorRole: actorRole || 'system',
    action: 'inventory_reserved',
    entityType: 'BloodReservation',
    entityId: reservation.id,
    bloodBankId,
    newValue: { bloodGroup, componentType, units: needed, requestId },
  });

  return reservation.toObject ? reservation.toObject() : reservation;
}

async function releaseReservation(reservationId, { actorId, actorRole, reason } = {}) {
  const reservation = await BloodReservation.findOneAndUpdate(
    { id: reservationId, status: 'active' },
    { $set: { status: 'released', releasedAt: new Date() } },
    { new: true },
  );
  if (!reservation) return null;

  await BloodInventory.findOneAndUpdate(
    { bloodBankId: reservation.bloodBankId, bloodGroup: reservation.bloodGroup },
    {
      $inc: {
        availableUnits: reservation.units,
        reservedUnits: -reservation.units,
      },
      $set: { lastUpdated: new Date() },
    },
  );

  if (reservation.reservedUnits?.length) {
    await BloodInventoryUnit.updateMany(
      { id: { $in: reservation.reservedUnits.map((u) => u.unitId).filter(Boolean) } },
      {
        $set: { status: 'available', reservedForRequestId: null, reservedUntil: null },
        $inc: { version: 1 },
      },
    );
  }

  await writeAudit({
    actorId: actorId || 'system',
    actorRole: actorRole || 'system',
    action: 'inventory_released',
    entityType: 'BloodReservation',
    entityId: reservation.id,
    bloodBankId: reservation.bloodBankId,
    newValue: { reason },
  });

  return reservation.toObject();
}

async function fulfillReservation(reservationId, { actorId, actorRole } = {}) {
  const reservation = await BloodReservation.findOneAndUpdate(
    { id: reservationId, status: 'active' },
    { $set: { status: 'fulfilled', fulfilledAt: new Date() } },
    { new: true },
  );
  if (!reservation) return null;

  await BloodInventory.findOneAndUpdate(
    { bloodBankId: reservation.bloodBankId, bloodGroup: reservation.bloodGroup },
    {
      $inc: {
        reservedUnits: -reservation.units,
        totalUnits: -reservation.units,
      },
      $set: { lastUpdated: new Date() },
    },
  );

  if (reservation.reservedUnits?.length) {
    await BloodInventoryUnit.updateMany(
      { id: { $in: reservation.reservedUnits.map((u) => u.unitId).filter(Boolean) } },
      {
        $set: { status: 'issued', reservedForRequestId: reservation.requestId },
        $inc: { version: 1 },
      },
    );
  }

  await writeAudit({
    actorId: actorId || 'system',
    actorRole: actorRole || 'system',
    action: 'inventory_fulfilled',
    entityType: 'BloodReservation',
    entityId: reservation.id,
    bloodBankId: reservation.bloodBankId,
  });

  return reservation.toObject();
}

async function expireDueReservations() {
  const due = await BloodReservation.find({
    status: 'active',
    expiresAt: { $lte: new Date() },
  }).lean();

  let released = 0;
  for (const item of due) {
    const updated = await BloodReservation.findOneAndUpdate(
      { id: item.id, status: 'active' },
      { $set: { status: 'expired', releasedAt: new Date() } },
      { new: true },
    );
    if (!updated) continue;

    await BloodInventory.findOneAndUpdate(
      { bloodBankId: item.bloodBankId, bloodGroup: item.bloodGroup },
      {
        $inc: { availableUnits: item.units, reservedUnits: -item.units },
        $set: { lastUpdated: new Date() },
      },
    );
    if (item.reservedUnits?.length) {
      await BloodInventoryUnit.updateMany(
        { id: { $in: item.reservedUnits.map((u) => u.unitId).filter(Boolean) } },
        {
          $set: { status: 'available', reservedForRequestId: null, reservedUntil: null },
          $inc: { version: 1 },
        },
      );
    }
    released += 1;
  }
  return released;
}

async function findActiveReservation(requestId) {
  return BloodReservation.findOne({ requestId, status: 'active' }).lean();
}

module.exports = {
  reserveUnitsAtomically,
  releaseReservation,
  fulfillReservation,
  expireDueReservations,
  findActiveReservation,
};
