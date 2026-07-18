const mongoose = require('mongoose');

const labBookingItemSchema = new mongoose.Schema(
  {
    testId: String,
    testName: { type: String, required: true },
    price: { type: Number, default: 0 },
  },
  { _id: false },
);

const labBookingSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    labId: { type: String, required: true, index: true },
    labName: String,
    patientId: { type: String, index: true },
    patientName: { type: String, required: true },
    patientMobile: { type: String, required: true },
    patientEmail: String,
    familyMemberId: String,
    familyMemberName: String,
    collectionType: {
      type: String,
      enum: ['home_collection', 'lab_visit'],
      required: true,
    },
    collectionAddress: String,
    collectionCity: String,
    collectionPincode: String,
    scheduledDate: { type: Date, required: true },
    timeSlot: { type: String, required: true },
    items: { type: [labBookingItemSchema], default: [] },
    subtotal: { type: Number, default: 0 },
    totalAmount: { type: Number, default: 0 },
    paymentStatus: {
      type: String,
      enum: ['pending', 'paid', 'failed', 'refunded', 'pay_at_lab'],
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
        'sample_collected',
        'processing',
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
    reportFileName: String,
  },
  { timestamps: true },
);

module.exports = mongoose.model('LabBooking', labBookingSchema);
