const mongoose = require('mongoose');

const couponSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    code: {
      type: String,
      required: true,
      unique: true,
      uppercase: true,
      trim: true,
      index: true,
    },
    description: String,
    discountType: {
      type: String,
      enum: ['percentage', 'flat'],
      required: true,
    },
    discountValue: { type: Number, required: true, min: 0 },
    maxDiscountInr: Number,
    minOrderInr: { type: Number, default: 0 },
    applicableTo: {
      type: [String],
      default: ['consultation', 'lab', 'scan', 'blood'],
    },
    active: { type: Boolean, default: true },
    usageCount: { type: Number, default: 0 },
    maxUses: Number,
    expiresAt: Date,
  },
  { timestamps: true },
);

module.exports = mongoose.model('Coupon', couponSchema);
