async function applyAmbulanceIndexes(mongoose) {
  const db = mongoose.connection.db;
  if (!db) return;

  const collections = [
    'ambulancebookings',
    'ambulancedispatches',
    'ambulancelocations',
    'ambulancetrips',
    'ambulanceaudits',
    'ambulancestatushistories',
    'ambulancereviews',
  ];
  for (const name of collections) {
    try {
      await db.collection(name).createIndex({ createdAt: -1 });
    } catch (_) {
      // Best-effort; schema indexes still apply on first use.
    }
  }
}

module.exports = { applyAmbulanceIndexes };
