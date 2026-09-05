const mongoose = require('mongoose');

const bloodDonationSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    bloodBankId: { type: String, required: true, index: true },
    donorProfileId: { type: String, index: true },
    patientId: { type: String, index: true },
    donorRequestId: String,
    donorDisplayName: String,
    bloodGroup: { type: String, required: true },
    componentType: { type: String, required: true },
    units: { type: Number, required: true, min: 1 },
    donationDate: { type: Date, required: true },
    status: {
      type: String,
      enum: ['scheduled', 'collected', 'screened', 'accepted', 'rejected', 'cancelled'],
      default: 'scheduled',
      index: true,
    },
    nextEligibleDate: Date,
    screeningNotes: String,
    recordedBy: String,
    recordedByRole: String,
    inventoryUnitIds: { type: [String], default: [] },
  },
  { timestamps: true },
);

bloodDonationSchema.index({ bloodBankId: 1, donationDate: -1 });
bloodDonationSchema.index({ patientId: 1, donationDate: -1 });

module.exports = mongoose.model('BloodDonation', bloodDonationSchema);
