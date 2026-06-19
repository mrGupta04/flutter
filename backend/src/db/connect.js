const mongoose = require('mongoose');

let isConnected = false;

function buildUris() {
  const uris = [];
  if (process.env.MONGODB_URI) uris.push(process.env.MONGODB_URI);
  if (process.env.MONGODB_URI_DIRECT) uris.push(process.env.MONGODB_URI_DIRECT);
  return uris;
}

function connectionHelp(err) {
  const msg = err?.message || String(err);
  if (msg.includes('querySrv') || msg.includes('ECONNREFUSED')) {
    return [
      'MongoDB DNS (SRV) lookup failed. Try one of these:',
      '  1. Atlas → Network Access → Add IP Address → "Allow Access from Anywhere" (0.0.0.0/0) for dev',
      '  2. Atlas → Connect → Drivers → copy URI with database name: ...mongodb.net/1mg_doctors?...',
      '  3. If SRV still fails: Connect → "Drivers" → choose "Standard connection string" (mongodb:// not mongodb+srv)',
      '     Put it in .env as MONGODB_URI_DIRECT=...',
      '  4. Turn off VPN; or set PC DNS to 8.8.8.8 (Google DNS)',
    ].join('\n');
  }
  if (msg.includes('not primary') || msg.includes('NotWritablePrimary')) {
    return [
      'MongoDB "not primary" — your URI points at a secondary shard.',
      'In .env use the PRIMARY host in MONGODB_URI_DIRECT (often ...-shard-00-02...).',
    ].join('\n');
  }
  if (msg.includes('authentication failed') || msg.includes('bad auth')) {
    return 'MongoDB auth failed. Check username/password in MONGODB_URI (URL-encode special chars in password).';
  }
  return msg;
}

async function connectDB() {
  if (isConnected) return mongoose.connection;

  const uris = buildUris();
  if (uris.length === 0) {
    throw new Error(
      'MONGODB_URI is required. Add your MongoDB Atlas connection string to backend/.env',
    );
  }

  let lastErr = null;
  for (let i = 0; i < uris.length; i += 1) {
    const uri = uris[i];
    try {
      await mongoose.connect(uri, {
        serverSelectionTimeoutMS: 30000,
        retryWrites: true,
      });
      isConnected = true;
      console.log(`MongoDB connected: ${mongoose.connection.name}`);
      if (i > 0) {
        console.log('MongoDB fallback URI used after primary URI failed.');
      }
      const { syncDoctorAvailabilityIndexes } = require('./migrations/doctorAvailabilityIndexes');
      await syncDoctorAvailabilityIndexes();
      return mongoose.connection;
    } catch (err) {
      lastErr = err;
      // Ensure next connect attempt starts clean.
      try {
        await mongoose.disconnect();
      } catch {}
    }
  }

  const help = connectionHelp(lastErr);
  console.error(help);
  throw new Error(help);
}

module.exports = { connectDB, mongoose };
