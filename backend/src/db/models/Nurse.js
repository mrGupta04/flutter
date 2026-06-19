const mongoose = require('mongoose');

const nurseSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    firstName: String,
    lastName: String,
    email: { type: String, unique: true, sparse: true },
    mobileNumber: String,
    passwordHash: String,
    profilePicture: String,
    qualification: String,
    registrationNumber: String,
    nursingCouncil: String,
    yearsOfExperience: Number,
    specialization: String,
    address: String,
    city: String,
    state: String,
    pincode: String,
    latitude: Number,
    longitude: Number,
    availableForHomeVisit: { type: Boolean, default: false },
    shiftAvailability: String,
    verificationStatus: { type: String, default: 'pending', index: true },
    rejectionReason: String,
    isApproved: { type: Boolean, default: false },
    approvalNotes: String,
  },
  { timestamps: true },
);

module.exports = mongoose.model('Nurse', nurseSchema);
