async function applyBloodBankIndexes(mongoose) {
  const db = mongoose.connection.db;
  if (!db) return;

  try {
    await db.collection('bloodinventories').dropIndex('bloodBankId_1_bloodGroup_1');
  } catch (_) {
    // Index may already have been replaced.
  }

  const collections = [
    'bloodinventories',
    'bloodinventoryunits',
    'bloodreservations',
    'bloodorders',
    'emergencybloodrequests',
    'donorprofiles',
    'donorrequests',
    'blooddonations',
    'bloodbankauditlogs',
    'bloodrequeststatushistories',
    'bloodcompatibilities',
  ];
  for (const name of collections) {
    try {
      await db.collection(name).createIndex({ createdAt: -1 });
    } catch (_) {
      // Best-effort; schema indexes still apply on first use.
    }
  }
}

module.exports = { applyBloodBankIndexes };
