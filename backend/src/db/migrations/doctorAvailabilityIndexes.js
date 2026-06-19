const DoctorAvailability = require('../models/DoctorAvailability');

/**
 * Drops legacy unique indexes on (doctorId, weekStartDate) that block separate
 * online_consult / visit_site rows, then syncs the current schema indexes.
 */
async function syncDoctorAvailabilityIndexes() {
  const collection = DoctorAvailability.collection;
  const indexes = await collection.indexes();

  for (const idx of indexes) {
    if (idx.name === '_id_') continue;
    const keys = Object.keys(idx.key || {});
    const isLegacyDoctorWeekIndex =
      keys.length === 2 &&
      keys.includes('doctorId') &&
      keys.includes('weekStartDate') &&
      !keys.includes('consultationType');

    if (isLegacyDoctorWeekIndex && idx.unique) {
      await collection.dropIndex(idx.name);
      console.log(`Dropped stale DoctorAvailability index: ${idx.name}`);
    }
  }

  await DoctorAvailability.syncIndexes();

  const legacy = await DoctorAvailability.updateMany(
    { $or: [{ consultationType: { $exists: false } }, { consultationType: null }] },
    { $set: { consultationType: 'online_consult' } },
  );
  if (legacy.modifiedCount > 0) {
    console.log(
      `Backfilled consultationType on ${legacy.modifiedCount} legacy availability record(s)`,
    );
  }
}

module.exports = { syncDoctorAvailabilityIndexes };
