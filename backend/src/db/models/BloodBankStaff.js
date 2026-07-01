const mongoose = require('mongoose');

const bloodBankStaffSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    bloodBankId: { type: String, required: true, index: true },
    name: { type: String, required: true },
    role: String,
    mobileNumber: String,
    email: String,
    active: { type: Boolean, default: true },
  },
  { timestamps: true },
);

module.exports = mongoose.model('BloodBankStaff', bloodBankStaffSchema);
