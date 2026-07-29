const mongoose = require('mongoose');

const approvalSavedFilterSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    ownerId: { type: String, required: true, index: true },
    ownerRole: { type: String, required: true, index: true },
    name: { type: String, required: true },
    scope: {
      type: String,
      enum: ['requests', 'audit_logs', 'approvers', 'reports'],
      default: 'requests',
      index: true,
    },
    filters: { type: mongoose.Schema.Types.Mixed, default: {} },
    sort: { type: String, default: '-updatedAt' },
    columns: { type: [String], default: [] },
    isDefault: { type: Boolean, default: false },
  },
  { timestamps: true },
);

approvalSavedFilterSchema.index({ ownerId: 1, scope: 1, name: 1 }, { unique: true });

module.exports = mongoose.model('ApprovalSavedFilter', approvalSavedFilterSchema);
