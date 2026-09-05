const mongoose = require('mongoose');

const ambulanceReviewSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    bookingId: { type: String, required: true, unique: true, index: true },
    patientId: { type: String, required: true, index: true },
    ambulanceId: { type: String, required: true, index: true },
    vehicleId: String,
    driverId: String,
    ambulanceRating: { type: Number, min: 1, max: 5 },
    driverRating: { type: Number, min: 1, max: 5 },
    providerRating: { type: Number, min: 1, max: 5 },
    review: { type: String, maxlength: 2000 },
    reportIssue: { type: String, maxlength: 2000 },
  },
  { timestamps: true },
);

module.exports = mongoose.model('AmbulanceReview', ambulanceReviewSchema);
