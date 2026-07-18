const mongoose = require('mongoose');

const scanBookingSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    scanCenterId: { type: String, required: true, index: true },
    scanCenterName: String,
    patientId: { type: String, index: true },
    patientName: { type: String, required: true },
    patientMobile: { type: String, required: true },
    patientEmail: String,
    familyMemberId: String,
    familyMemberName: String,
    scanId: String,
    scanName: { type: String, required: true },
    categoryId: String,
    contrastRequired: { type: Boolean, default: false },
    preparationNotes: String,
    prescriptionUrl: String,
    prescriptionFileName: String,
    scheduledDate: { type: Date, required: true },
    timeSlot: { type: String, required: true },
    totalAmount: { type: Number, default: 0 },
    paymentStatus: {
      type: String,
      enum: ['pending', 'paid', 'failed', 'refunded', 'pay_at_center'],
      default: 'pending',
    },
    razorpayOrderId: String,
    razorpayPaymentId: String,
    paymentExpiresAt: Date,
    status: {
      type: String,
      enum: [
        'requested',
        'confirmed',
        'in_progress',
        'report_ready',
        'completed',
        'cancelled',
        'rejected',
      ],
      default: 'requested',
      index: true,
    },
    notes: String,
    rejectionReason: String,
    reportUrl: String,
  },
  { timestamps: true },
);

module.exports = mongoose.model('ScanBooking', scanBookingSchema);
