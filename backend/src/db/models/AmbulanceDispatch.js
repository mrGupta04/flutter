const mongoose = require('mongoose');

const ambulanceDispatchSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    bookingId: { type: String, required: true, index: true },
    ambulanceId: { type: String, required: true, index: true },
    vehicleId: { type: String, required: true },
    driverId: String,
    round: { type: Number, default: 1 },
    status: {
      type: String,
      enum: ['offered', 'accepted', 'rejected', 'timeout', 'superseded', 'cancelled'],
      default: 'offered',
      index: true,
    },
    distanceKm: Number,
    etaMinutes: Number,
    offeredAt: { type: Date, default: Date.now },
    respondedAt: Date,
    expiresAt: Date,
    rejectReason: String,
  },
  { timestamps: true },
);

ambulanceDispatchSchema.index({ bookingId: 1, status: 1 });
ambulanceDispatchSchema.index({ ambulanceId: 1, status: 1, expiresAt: 1 });
ambulanceDispatchSchema.index(
  { bookingId: 1, vehicleId: 1, status: 1 },
  { unique: true, partialFilterExpression: { status: 'offered' } },
);

module.exports = mongoose.model('AmbulanceDispatch', ambulanceDispatchSchema);
