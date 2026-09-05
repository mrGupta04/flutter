const mongoose = require('mongoose');

const ambulanceAuditLogSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    actorId: { type: String, required: true, index: true },
    actorRole: { type: String, required: true },
    action: { type: String, required: true, index: true },
    entityType: { type: String, required: true, index: true },
    entityId: { type: String, required: true, index: true },
    ambulanceId: { type: String, index: true },
    previousValue: mongoose.Schema.Types.Mixed,
    newValue: mongoose.Schema.Types.Mixed,
    metadata: { type: mongoose.Schema.Types.Mixed, default: {} },
  },
  { timestamps: true },
);

ambulanceAuditLogSchema.index({ ambulanceId: 1, createdAt: -1 });
ambulanceAuditLogSchema.index({ action: 1, createdAt: -1 });

module.exports = mongoose.model('AmbulanceAuditLog', ambulanceAuditLogSchema);
