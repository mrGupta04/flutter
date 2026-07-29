const mongoose = require('mongoose');

const approvalSessionSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    userId: { type: String, required: true, index: true },
    userRole: {
      type: String,
      enum: ['super_admin', 'admin', 'approver'],
      required: true,
      index: true,
    },
    refreshTokenHash: { type: String, required: true },
    ip: String,
    device: String,
    userAgent: String,
    lastSeenAt: Date,
    expiresAt: { type: Date, required: true, index: true },
    revokedAt: Date,
    revokedReason: String,
  },
  { timestamps: true },
);

approvalSessionSchema.index({ userId: 1, revokedAt: 1, expiresAt: 1 });

module.exports = mongoose.model('ApprovalSession', approvalSessionSchema);
