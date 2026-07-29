const mongoose = require('mongoose');

const approvalWebhookEventSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    source: { type: String, required: true, index: true },
    eventType: { type: String, required: true, index: true },
    providerId: { type: String, index: true },
    providerType: { type: String, index: true },
    requestId: { type: String, index: true },
    signatureValid: { type: Boolean, default: false },
    processedAt: Date,
    status: {
      type: String,
      enum: ['received', 'processed', 'failed'],
      default: 'received',
      index: true,
    },
    payload: { type: mongoose.Schema.Types.Mixed, default: {} },
    error: String,
  },
  { timestamps: true },
);

module.exports = mongoose.model(
  'ApprovalWebhookEvent',
  approvalWebhookEventSchema,
);
