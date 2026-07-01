const mongoose = require('mongoose');

const bloodReviewSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    bloodBankId: { type: String, required: true, index: true },
    patientId: String,
    patientName: String,
    rating: { type: Number, required: true, min: 1, max: 5 },
    comment: String,
    orderId: String,
  },
  { timestamps: true },
);

module.exports = mongoose.model('BloodReview', bloodReviewSchema);
