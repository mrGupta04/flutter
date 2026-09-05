const mongoose = require('mongoose');

const emergencyResponseSchema = new mongoose.Schema(
  {
    bloodBankId: String,
    action: { type: String, enum: ['accepted', 'rejected', 'partial'] },
    availableUnits: Number,
    respondedAt: Date,
    notes: String,
  },
  { _id: false },
);

const emergencyBloodRequestSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    patientId: String,
    bloodGroup: { type: String, required: true },
    componentType: { type: String, default: 'whole_blood' },
    units: { type: Number, required: true, min: 1 },
    patientName: String,
    hospitalName: String,
    hospitalAddress: String,
    contactNumber: String,
    requiredWithin: String,
    additionalNotes: String,
    latitude: Number,
    longitude: Number,
    city: String,
    status: {
      type: String,
      enum: [
        'open',
        'emergency_requested',
        'blood_bank_alerted',
        'response_received',
        'accepted',
        'blood_reserved',
        'ready',
        'collected',
        'fulfilled',
        'cancelled',
        'expired',
      ],
      default: 'emergency_requested',
      index: true,
    },
    notifiedBloodBankIds: { type: [String], default: [] },
    assignedBloodBankId: String,
    confirmedUnits: { type: Number, default: 0 },
    reservationId: String,
    acceptedAt: Date,
    fulfilledAt: Date,
    donorFallbackTriggered: { type: Boolean, default: false },
    responses: { type: [emergencyResponseSchema], default: [] },
  },
  { timestamps: true },
);

emergencyBloodRequestSchema.index({ status: 1, createdAt: -1 });
emergencyBloodRequestSchema.index({ patientId: 1, createdAt: -1 });

module.exports = mongoose.model('EmergencyBloodRequest', emergencyBloodRequestSchema);
