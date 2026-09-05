const mongoose = require('mongoose');

const bloodBankAuditLogSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    actorId: { type: String, required: true, index: true },
    actorRole: { type: String, required: true },
    action: { type: String, required: true, index: true },
    entityType: { type: String, required: true, index: true },
    entityId: { type: String, required: true, index: true },
    bloodBankId: { type: String, index: true },
    previousValue: { type: mongoose.Schema.Types.Mixed },
    newValue: { type: mongoose.Schema.Types.Mixed },
    metadata: { type: mongoose.Schema.Types.Mixed, default: {} },
  },
  { timestamps: true },
);

bloodBankAuditLogSchema.index({ bloodBankId: 1, createdAt: -1 });
bloodBankAuditLogSchema.index({ entityType: 1, entityId: 1, createdAt: -1 });

module.exports = mongoose.model('BloodBankAuditLog', bloodBankAuditLogSchema);
