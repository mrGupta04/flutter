const mongoose = require('mongoose');

const donorProfileSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    patientId: { type: String, required: true, unique: true, index: true },
    displayName: String,
    bloodGroup: { type: String, required: true, index: true },
    dateOfBirth: Date,
    gender: String,
    city: String,
    state: String,
    pincode: String,
    latitude: Number,
    longitude: Number,
    contactPreference: {
      type: String,
      enum: ['in_app', 'phone', 'both'],
      default: 'in_app',
    },
    lastDonationDate: Date,
    nextEligibleDate: Date,
    eligibilityStatus: {
      type: String,
      enum: ['pending_screening', 'opted_in', 'paused', 'deferred', 'inactive'],
      default: 'pending_screening',
    },
    preferredRadiusKm: { type: Number, default: 15 },
    availableForEmergency: { type: Boolean, default: false },
    emergencyConsentAt: Date,
    consentToShareMaskedContact: { type: Boolean, default: false },
    availabilityNotes: String,
    active: { type: Boolean, default: true },
  },
  { timestamps: true },
);

donorProfileSchema.index({ bloodGroup: 1, availableForEmergency: 1, active: 1 });
donorProfileSchema.index({ city: 1, bloodGroup: 1 });

module.exports = mongoose.model('DonorProfile', donorProfileSchema);
