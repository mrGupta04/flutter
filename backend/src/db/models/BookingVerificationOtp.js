const mongoose = require('mongoose');

const bookingVerificationOtpSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    bookingId: { type: String, required: true, index: true },
    otpHash: { type: String, required: true },
    expiresAt: { type: Date, required: true, index: true },
    attemptCount: { type: Number, default: 0 },
    lockedUntil: Date,
    isUsed: { type: Boolean, default: false, index: true },
    lastGeneratedAt: { type: Date, default: Date.now },
    verifiedAt: Date,
  },
  { timestamps: true },
);

bookingVerificationOtpSchema.index({ bookingId: 1, isUsed: 1, createdAt: -1 });

module.exports = mongoose.model(
  'BookingVerificationOtp',
  bookingVerificationOtpSchema,
);
