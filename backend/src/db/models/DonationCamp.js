const mongoose = require('mongoose');

const donationCampSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    bloodBankId: { type: String, required: true, index: true },
    title: { type: String, required: true },
    description: String,
    organizer: String,
    contact: String,
    date: { type: Date, required: true, index: true },
    startTime: String,
    endTime: String,
    address: String,
    city: String,
    state: String,
    pincode: String,
    latitude: Number,
    longitude: Number,
    capacity: { type: Number, default: 50 },
    registeredCount: { type: Number, default: 0 },
    requiredBloodGroups: { type: [String], default: [] },
    images: { type: [String], default: [] },
    registrationRequired: { type: Boolean, default: true },
    status: {
      type: String,
      enum: ['draft', 'published', 'cancelled', 'completed'],
      default: 'published',
      index: true,
    },
  },
  { timestamps: true },
);

donationCampSchema.index({ date: 1, status: 1, city: 1 });

module.exports = mongoose.model('DonationCamp', donationCampSchema);
