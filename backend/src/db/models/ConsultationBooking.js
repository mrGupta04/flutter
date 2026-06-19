const mongoose = require('mongoose');

const consultationBookingSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    doctorId: { type: String, required: true, index: true },
    patientId: { type: String, index: true },
    consultationType: {
      type: String,
      default: 'online_consult',
      enum: ['online_consult', 'book_home', 'visit_site'],
    },
    patientName: { type: String, required: true },
    patientMobile: { type: String, required: true },
    patientEmail: String,
    patientNotes: String,
    patientAddress: String,
    patientCity: String,
    patientState: String,
    patientPincode: String,
    visitReason: String,
    dayOfWeek: { type: Number, required: true, min: 0, max: 6 },
    startHour: { type: Number, required: true, min: 8, max: 17 },
    slotStart: { type: Date, required: true, index: true },
    slotEnd: { type: Date, required: true },
    weekStartDate: { type: Date, required: true },
    consultationFee: Number,
    status: {
      type: String,
      default: 'pending',
      enum: ['pending', 'confirmed', 'cancelled'],
      index: true,
    },
    paymentStatus: {
      type: String,
      default: 'pending',
      enum: ['pending', 'paid', 'failed', 'refunded'],
      index: true,
    },
    paymentProvider: {
      type: String,
      default: 'razorpay',
      enum: ['razorpay'],
    },
    razorpayOrderId: { type: String, index: true },
    razorpayPaymentId: String,
    razorpaySignature: String,
    amountPaid: Number,
    currency: { type: String, default: 'INR' },
    paidAt: Date,
    paymentExpiresAt: { type: Date, index: true },
    /** 4-digit code for clinic visits — patient shows, doctor verifies. */
    appointmentCode: { type: String, index: true },
    appointmentVerifiedAt: Date,
    /** Stable room id for online consult video (Jitsi / Agora). */
    videoRoomId: String,
    videoCallStartedAt: Date,
    videoCallEndedAt: Date,
    /** Patient-uploaded lab reports, prescriptions, etc. for the doctor. */
    previousReports: [
      {
        id: { type: String, required: true },
        fileUrl: { type: String, required: true },
        fileName: String,
        mimeType: String,
        uploadedAt: { type: Date, default: Date.now },
      },
    ],
  },
  { timestamps: true },
);

consultationBookingSchema.index(
  { doctorId: 1, slotStart: 1 },
  {
    unique: true,
    partialFilterExpression: { status: { $in: ['confirmed', 'pending'] } },
  },
);

module.exports = mongoose.model('ConsultationBooking', consultationBookingSchema);
