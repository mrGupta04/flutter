const mongoose = require('mongoose');

const bloodCompatibilitySchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    recipientGroup: { type: String, required: true },
    compatibleDonorGroups: { type: [String], default: [] },
    compatibleComponents: { type: [String], default: [] },
    notes: String,
    active: { type: Boolean, default: true },
    updatedBy: String,
  },
  { timestamps: true },
);

bloodCompatibilitySchema.index({ recipientGroup: 1 }, { unique: true });

module.exports = mongoose.model('BloodCompatibility', bloodCompatibilitySchema);
