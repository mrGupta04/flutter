const mongoose = require('mongoose');

const bloodBankStaffSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    bloodBankId: { type: String, required: true, index: true },
    name: { type: String, required: true },
    role: {
      type: String,
      enum: ['blood_bank_admin', 'inventory_manager', 'request_manager', 'staff'],
      default: 'staff',
      index: true,
    },
    mobileNumber: String,
    email: String,
    passwordHash: String,
    permissions: { type: [String], default: [] },
    active: { type: Boolean, default: true },
  },
  { timestamps: true },
);

module.exports = mongoose.model('BloodBankStaff', bloodBankStaffSchema);
