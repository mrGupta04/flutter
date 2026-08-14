const mongoose = require('mongoose');

const REQUEST_STATUSES = [
  'PENDING',
  'SENT_TO_LABS',
  'QUOTATIONS_RECEIVED',
  'LAB_SELECTED',
  'PAYMENT_PENDING',
  'PAID',
  'BOOKING_CONFIRMED',
  'COMPLETED',
  'CANCELLED',
  'EXPIRED',
];

const requestedTestSchema = new mongoose.Schema(
  {
    name: { type: String, required: true },
    notes: String,
  },
  { _id: false },
);

const prescriptionRequestSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    userId: { type: String, required: true, index: true },
    patientName: String,
    patientMobile: String,
    patientEmail: String,
    prescriptionFileUrl: { type: String, required: true },
    prescriptionFileType: {
      type: String,
      enum: ['jpg', 'jpeg', 'png', 'pdf'],
      required: true,
    },
    prescriptionFileName: String,
    requestedTests: { type: [requestedTestSchema], default: [] },
    notes: String,
    status: {
      type: String,
      enum: REQUEST_STATUSES,
      default: 'PENDING',
      index: true,
    },
    selectedLabId: { type: String, index: true },
    selectedQuotationId: String,
    paymentStatus: {
      type: String,
      enum: ['PENDING', 'PAID', 'FAILED', 'REFUNDED'],
      default: 'PENDING',
      index: true,
    },
    chatEnabled: { type: Boolean, default: false },
    bookingId: String,
    razorpayOrderId: String,
    razorpayPaymentId: String,
    paymentExpiresAt: Date,
    expiresAt: Date,
  },
  { timestamps: true },
);

prescriptionRequestSchema.index({ userId: 1, createdAt: -1 });
prescriptionRequestSchema.index({ status: 1, createdAt: -1 });

module.exports = mongoose.model('PrescriptionRequest', prescriptionRequestSchema);
module.exports.REQUEST_STATUSES = REQUEST_STATUSES;
