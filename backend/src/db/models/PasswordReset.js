const mongoose = require('mongoose');

const passwordResetSchema = new mongoose.Schema(
  {
    email: { type: String, required: true, lowercase: true, trim: true, index: true },
    purpose: {
      type: String,
      enum: ['patient_password_reset'],
      default: 'patient_password_reset',
      index: true,
    },
    patientId: { type: String, index: true },
    otpHash: { type: String, default: '' },
    provider: { type: String, default: 'mock' },
    expiresAt: { type: Date, required: true, index: true },
    attempts: { type: Number, default: 0 },
    verified: { type: Boolean, default: false },
    consumed: { type: Boolean, default: false },
  },
  { timestamps: true },
);

passwordResetSchema.index({ email: 1, purpose: 1, createdAt: -1 });

module.exports = mongoose.model('PasswordReset', passwordResetSchema);
