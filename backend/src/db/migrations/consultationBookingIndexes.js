const ConsultationBooking = require('../models/ConsultationBooking');

async function syncConsultationBookingIndexes() {
  const collection = ConsultationBooking.collection;
  try {
    const indexes = await collection.indexes();
    for (const idx of indexes) {
      const keys = Object.keys(idx.key || {});
      if (
        idx.unique &&
        keys.length === 2 &&
        keys.includes('nurseId') &&
        keys.includes('slotStart')
      ) {
        await collection.dropIndex(idx.name);
        console.log(`Dropped stale ConsultationBooking index: ${idx.name}`);
      }
    }
  } catch (err) {
    if (!String(err.message || '').includes('index not found')) {
      console.warn('[ConsultationBooking] index sync:', err.message);
    }
  }

  await ConsultationBooking.syncIndexes();
}

module.exports = { syncConsultationBookingIndexes };
