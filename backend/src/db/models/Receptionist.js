const mongoose = require('mongoose');

const receptionistSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    doctorId: { type: String, required: true, index: true },
    clinicId: { type: String, index: true },
    name: { type: String, required: true, trim: true },
    email: {
      type: String,
      required: true,
      unique: true,
      index: true,
      lowercase: true,
      trim: true,
    },
    passwordHash: { type: String, required: true },
    phone: String,
    status: {
      type: String,
      enum: ['active', 'disabled'],
      default: 'active',
      index: true,
    },
    lastLoginAt: Date,
  },
  { timestamps: true },
);

receptionistSchema.index({ doctorId: 1, status: 1 });

module.exports = mongoose.model('Receptionist', receptionistSchema);
