const mongoose = require('mongoose');

const ambulanceTripSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    bookingId: { type: String, required: true, unique: true, index: true },
    ambulanceId: { type: String, required: true, index: true },
    vehicleId: String,
    driverId: String,
    startedAt: Date,
    pickupAt: Date,
    destinationAt: Date,
    completedAt: Date,
    distanceKm: Number,
    durationMinutes: Number,
    notes: String,
    fareTotal: Number,
    paymentStatus: String,
  },
  { timestamps: true },
);

module.exports = mongoose.model('AmbulanceTrip', ambulanceTripSchema);
