const mongoose = require('mongoose');

const bloodRequestStatusHistorySchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    requestId: { type: String, required: true, index: true },
    requestKind: {
      type: String,
      enum: ['order', 'emergency'],
      default: 'order',
    },
    fromStatus: String,
    toStatus: { type: String, required: true },
    actorId: String,
    actorRole: String,
    note: String,
    metadata: { type: mongoose.Schema.Types.Mixed, default: {} },
  },
  { timestamps: true },
);

bloodRequestStatusHistorySchema.index({ requestId: 1, createdAt: 1 });

module.exports = mongoose.model(
  'BloodRequestStatusHistory',
  bloodRequestStatusHistorySchema,
);
