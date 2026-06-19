const mongoose = require('mongoose');

const emailVerificationSchema = new mongoose.Schema(
  {
    doctorId: { type: String, required: true, index: true },
    email: { type: String, required: true, lowercase: true, trim: true },
    otpHash: { type: String, default: '' },
    provider: { type: String, default: 'mock' },
    expiresAt: { type: Date, required: true, index: true },
    attempts: { type: Number, default: 0 },
    verified: { type: Boolean, default: false },
  },
  { timestamps: true },
);

emailVerificationSchema.index({ doctorId: 1, email: 1 });

module.exports = mongoose.model('EmailVerification', emailVerificationSchema);
