const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    userId: { type: String, required: true, index: true },
    userType: {
      type: String,
      enum: ['patient', 'doctor', 'nurse'],
      required: true,
      index: true,
    },
    title: { type: String, required: true },
    body: { type: String, required: true },
    type: {
      type: String,
      enum: [
        'booking_approved',
        'booking_rejected',
        'payment_due',
        'visit_reminder',
        'en_route',
        'prescription_ready',
        'visit_note_ready',
        'chat_message',
        'booking_cancelled',
        'booking_rescheduled',
        'home_visit_request',
        'arrived',
        'visit_started',
        'visit_completed',
        'visit_completion_otp',
        'nursing_report_ready',
        'prescription_request',
        'prescription_quotation',
        'prescription_selected',
        'prescription_quote',
        'prescription_paid',
        'payment_expired',
        'payment_failed',
        'booking_confirmed',
        'general',
      ],
      default: 'general',
      index: true,
    },
    data: { type: mongoose.Schema.Types.Mixed, default: {} },
    readAt: { type: Date, default: null },
  },
  { timestamps: true },
);

notificationSchema.index({ userId: 1, createdAt: -1 });

module.exports = mongoose.model('Notification', notificationSchema);
