const mongoose = require('mongoose');

const aadhaarOtpSchema = new mongoose.Schema(
  {
    doctorId: { type: String, required: true, index: true },
    aadhaarNumber: { type: String, required: true },
    mobileNumber: { type: String, required: true },
    otpHash: { type: String, default: '' },
    clientId: { type: String, default: null },
    provider: { type: String, default: 'mock' },
    expiresAt: { type: Date, required: true, index: true },
    attempts: { type: Number, default: 0 },
    verified: { type: Boolean, default: false },
  },
  { timestamps: true },
);

aadhaarOtpSchema.index({ doctorId: 1, aadhaarNumber: 1 });

module.exports = mongoose.model('AadhaarOtp', aadhaarOtpSchema);
