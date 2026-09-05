const mongoose = require('mongoose');

const donorRequestSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    donorProfileId: { type: String, required: true, index: true },
    patientId: { type: String, required: true, index: true },
    bloodRequestId: { type: String, index: true },
    emergencyRequestId: { type: String, index: true },
    bloodBankId: { type: String, index: true },
    bloodGroup: { type: String, required: true },
    componentType: String,
    units: { type: Number, default: 1 },
    hospitalName: String,
    hospitalAddress: String,
    city: String,
    latitude: Number,
    longitude: Number,
    distanceKm: Number,
    status: {
      type: String,
      enum: [
        'notified',
        'accepted',
        'declined',
        'coordinating',
        'confirmed',
        'completed',
        'cancelled',
        'expired',
      ],
      default: 'notified',
      index: true,
    },
    donorResponseAt: Date,
    donorNotes: String,
    bloodBankConfirmedAt: Date,
    expiresAt: Date,
  },
  { timestamps: true },
);

donorRequestSchema.index({ donorProfileId: 1, createdAt: -1 });
donorRequestSchema.index({ bloodRequestId: 1, status: 1 });
donorRequestSchema.index(
  { donorProfileId: 1, emergencyRequestId: 1 },
  { unique: true, sparse: true },
);

module.exports = mongoose.model('DonorRequest', donorRequestSchema);
