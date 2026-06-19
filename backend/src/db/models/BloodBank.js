const mongoose = require('mongoose');

const bloodBankSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    institutionName: String,
    licenseNumber: String,
    contactPerson: String,
    email: { type: String, unique: true, sparse: true },
    mobileNumber: String,
    passwordHash: String,
    profilePicture: String,
    emergencyContact: String,
    address: String,
    city: String,
    state: String,
    pincode: String,
    latitude: Number,
    longitude: Number,
    bloodGroupsAvailable: [String],
    hasApheresis: { type: Boolean, default: false },
    hasComponentSeparation: { type: Boolean, default: false },
    available24x7: { type: Boolean, default: false },
    verificationStatus: { type: String, default: 'pending', index: true },
    rejectionReason: String,
    isApproved: { type: Boolean, default: false },
    approvalNotes: String,
  },
  { timestamps: true },
);

module.exports = mongoose.model('BloodBank', bloodBankSchema);
