const mongoose = require('mongoose');

const consultationBookingSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    doctorId: { type: String, index: true },
    nurseId: { type: String, index: true },
    providerType: {
      type: String,
      enum: ['doctor', 'nurse'],
      default: 'doctor',
    },
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
    patientLatitude: Number,
    patientLongitude: Number,
    distanceKm: Number,
    doctorApprovedAt: Date,
    doctorRejectedAt: Date,
    approvalExpiresAt: { type: Date, index: true },
    dayOfWeek: { type: Number, required: true, min: 0, max: 6 },
    startHour: { type: Number, required: true, min: 8, max: 17 },
    slotStart: { type: Date, required: true, index: true },
    slotEnd: { type: Date, required: true },
    weekStartDate: { type: Date, required: true },
    consultationFee: Number,
    status: {
      type: String,
      default: 'pending',
      enum: [
        'held',
        'pending',
        'awaiting_doctor_approval',
        'approved_pending_payment',
        'confirmed',
        'cancelled',
      ],
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
    razorpayRefundId: String,
    refundedAt: Date,
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
    /** Home-visit progress after confirmation. */
    visitProgress: {
      type: String,
      enum: ['en_route', 'arrived', 'completed'],
      default: undefined,
    },
    statusHistory: [
      {
        status: { type: String, required: true },
        at: { type: Date, default: Date.now },
        by: String,
      },
    ],
    cancelledAt: Date,
    cancelledBy: {
      type: String,
      enum: ['patient', 'doctor', 'nurse', 'system'],
    },
    cancellationReason: String,
    refundEligible: Boolean,
    refundPercent: Number,
    noShowMarkedAt: Date,
    noShowFeePercent: Number,
    reminderSentAt: { type: Date, default: null, index: true },
  },
  { timestamps: true },
);

const activeBookingStatuses = {
  $in: [
    'confirmed',
    'pending',
    'held',
    'awaiting_doctor_approval',
    'approved_pending_payment',
  ],
};

consultationBookingSchema.index(
  { doctorId: 1, slotStart: 1 },
  {
    unique: true,
    partialFilterExpression: {
      doctorId: { $exists: true, $type: 'string', $ne: '' },
      status: activeBookingStatuses,
    },
  },
);

consultationBookingSchema.index(
  { nurseId: 1, slotStart: 1 },
  {
    unique: true,
    partialFilterExpression: {
      nurseId: { $exists: true, $type: 'string', $ne: '' },
      status: activeBookingStatuses,
    },
  },
);

module.exports = mongoose.model('ConsultationBooking', consultationBookingSchema);
