const mongoose = require('mongoose');

const ambulanceStatusHistorySchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    bookingId: { type: String, required: true, index: true },
    fromStatus: String,
    toStatus: { type: String, required: true },
    actorId: String,
    actorRole: String,
    note: String,
    metadata: { type: mongoose.Schema.Types.Mixed, default: {} },
  },
  { timestamps: true },
);

ambulanceStatusHistorySchema.index({ bookingId: 1, createdAt: 1 });

module.exports = mongoose.model('AmbulanceStatusHistory', ambulanceStatusHistorySchema);
