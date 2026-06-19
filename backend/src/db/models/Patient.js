const mongoose = require('mongoose');

const patientSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    firstName: { type: String, required: true },
    lastName: String,
    email: { type: String, required: true, unique: true, index: true },
    mobileNumber: { type: String, required: true, index: true },
    passwordHash: { type: String, required: true },
    age: { type: Number, required: true, min: 1, max: 120 },
    gender: { type: String, required: true },
    aadhaarNumber: { type: String, required: true, unique: true, index: true },
    aadhaarLast4: { type: String, required: true },
    profilePicture: { type: String, required: true },
    aadhaarCardUrl: { type: String, required: true },
  },
  { timestamps: true },
);

module.exports = mongoose.model('Patient', patientSchema);
