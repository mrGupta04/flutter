const mongoose = require('mongoose');

const donationRegistrationSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    campId: { type: String, required: true, index: true },
    bloodBankId: { type: String, index: true },
    userId: { type: String, required: true, index: true },
    patientName: String,
    patientMobile: String,
    bloodGroup: String,
    appointmentTime: String,
    status: {
      type: String,
      enum: ['registered', 'cancelled', 'completed', 'no_show'],
      default: 'registered',
      index: true,
    },
  },
  { timestamps: true },
);

donationRegistrationSchema.index({ campId: 1, userId: 1 }, { unique: true });

module.exports = mongoose.model('DonationRegistration', donationRegistrationSchema);
