const mongoose = require('mongoose');

const approverRegionSchema = new mongoose.Schema(
  {
    country: String,
    state: String,
    district: String,
    city: String,
    pincode: String,
  },
  { _id: false },
);

const approverSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    firstName: { type: String, required: true, trim: true },
    lastName: { type: String, required: true, trim: true },
    employeeId: { type: String, required: true, unique: true, index: true },
    email: {
      type: String,
      required: true,
      unique: true,
      index: true,
      lowercase: true,
      trim: true,
    },
    phone: String,
    passwordHash: { type: String, required: true },
    department: String,
    designation: String,
    profilePicture: String,
    status: {
      type: String,
      enum: ['active', 'inactive'],
      default: 'active',
      index: true,
    },
    role: { type: String, default: 'approver', immutable: true },
    permissions: { type: [String], default: [], index: true },
    regions: { type: [approverRegionSchema], default: [] },
    canReassign: { type: Boolean, default: false },
    twoFactorReady: { type: Boolean, default: true },
    lastLoginAt: Date,
    lastLoginIp: String,
    loginCount: { type: Number, default: 0 },
    deactivatedAt: Date,
    deletedAt: Date,
  },
  { timestamps: true },
);

approverSchema.index({ status: 1, permissions: 1 });

module.exports = mongoose.model('Approver', approverSchema);
