const mongoose = require('mongoose');

const emergencyBloodRequestSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    patientId: String,
    bloodGroup: { type: String, required: true },
    units: { type: Number, required: true, min: 1 },
    patientName: String,
    hospitalName: String,
    contactNumber: String,
    requiredWithin: String,
    additionalNotes: String,
    latitude: Number,
    longitude: Number,
    city: String,
    status: {
      type: String,
      enum: ['open', 'accepted', 'fulfilled', 'cancelled', 'expired'],
      default: 'open',
      index: true,
    },
    assignedBloodBankId: String,
    acceptedAt: Date,
    fulfilledAt: Date,
  },
  { timestamps: true },
);

module.exports = mongoose.model('EmergencyBloodRequest', emergencyBloodRequestSchema);
