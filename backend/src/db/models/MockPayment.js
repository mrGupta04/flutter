const mongoose = require('mongoose');

const mockPaymentSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    bookingId: { type: String, required: true, index: true },
    userId: { type: String, required: true, index: true },
    amount: { type: Number, required: true },
    paymentMethod: { type: String, default: 'MOCK' },
    transactionId: { type: String, required: true, unique: true, index: true },
    status: {
      type: String,
      enum: ['SUCCESS', 'FAILED'],
      required: true,
      index: true,
    },
  },
  { timestamps: true },
);

mockPaymentSchema.index({ bookingId: 1, createdAt: -1 });

module.exports = mongoose.model('MockPayment', mockPaymentSchema);
