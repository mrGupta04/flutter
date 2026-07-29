const mongoose = require('mongoose');

const auditLogSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true, immutable: true },
    actorId: { type: String, index: true, immutable: true },
    actorName: { type: String, immutable: true },
    actorRole: { type: String, index: true, immutable: true },
    action: { type: String, required: true, index: true, immutable: true },
    entityType: { type: String, required: true, index: true, immutable: true },
    entityId: { type: String, index: true, immutable: true },
    entityLabel: { type: String, immutable: true },
    ip: { type: String, immutable: true },
    device: { type: String, immutable: true },
    metadata: { type: mongoose.Schema.Types.Mixed, default: {}, immutable: true },
    createdAt: { type: Date, default: Date.now, immutable: true, index: true },
  },
  {
    timestamps: false,
  },
);

module.exports = mongoose.model('AuditLog', auditLogSchema);
