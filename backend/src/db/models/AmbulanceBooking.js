const mongoose = require('mongoose');

const ambulanceBookingSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    ambulanceId: { type: String, required: true, index: true },
    ambulanceServiceName: String,
    patientId: { type: String, index: true },
    patientName: { type: String, required: true },
    patientMobile: { type: String, required: true },
    patientEmail: String,
    pickupAddress: { type: String, required: true },
    pickupCity: String,
    pickupPincode: String,
    pickupLatitude: Number,
    pickupLongitude: Number,
    dropAddress: String,
    notes: String,
    vehicleTypeRequested: String,
    isEmergency: { type: Boolean, default: true },
    status: {
      type: String,
      enum: [
        'requested',
        'accepted',
        'dispatched',
        'en_route',
        'arrived',
        'completed',
        'cancelled',
        'rejected',
      ],
      default: 'requested',
      index: true,
    },
    rejectionReason: String,
    estimatedArrivalMinutes: Number,
    liveLatitude: Number,
    liveLongitude: Number,
    liveLocationUpdatedAt: Date,
  },
  { timestamps: true },
);

module.exports = mongoose.model('AmbulanceBooking', ambulanceBookingSchema);
