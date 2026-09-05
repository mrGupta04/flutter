const mongoose = require('mongoose');

const ambulanceLocationSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    bookingId: { type: String, index: true },
    ambulanceId: { type: String, required: true, index: true },
    vehicleId: String,
    driverId: String,
    latitude: { type: Number, required: true },
    longitude: { type: Number, required: true },
    accuracy: Number,
    heading: Number,
    speed: Number,
    recordedAt: { type: Date, default: Date.now, index: true },
  },
  { timestamps: true },
);

ambulanceLocationSchema.index({ bookingId: 1, recordedAt: -1 });
ambulanceLocationSchema.index(
  { recordedAt: 1 },
  { expireAfterSeconds: Number(process.env.AMBULANCE_LOCATION_RETENTION_HOURS || 48) * 3600 },
);

module.exports = mongoose.model('AmbulanceLocation', ambulanceLocationSchema);
