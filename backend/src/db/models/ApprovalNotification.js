const mongoose = require('mongoose');

const approvalNotificationSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    recipientId: { type: String, required: true, index: true },
    recipientRole: {
      type: String,
      enum: ['super_admin', 'admin', 'approver', 'provider'],
      required: true,
      index: true,
    },
    channels: {
      type: [String],
      enum: ['in_app', 'email', 'sms', 'push'],
      default: ['in_app'],
    },
    title: { type: String, required: true },
    body: { type: String, required: true },
    type: { type: String, default: 'approval_workflow', index: true },
    data: { type: mongoose.Schema.Types.Mixed, default: {} },
    readAt: Date,
  },
  { timestamps: true },
);

approvalNotificationSchema.index({ recipientId: 1, createdAt: -1 });

module.exports = mongoose.model(
  'ApprovalNotification',
  approvalNotificationSchema,
);
