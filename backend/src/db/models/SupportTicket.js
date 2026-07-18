const mongoose = require('mongoose');

const supportTicketSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    patientId: { type: String, index: true },
    patientName: String,
    patientEmail: String,
    patientMobile: String,
    category: {
      type: String,
      enum: [
        'booking',
        'payment',
        'refund',
        'technical',
        'provider',
        'other',
      ],
      default: 'other',
    },
    subject: { type: String, required: true },
    message: { type: String, required: true },
    bookingId: String,
    status: {
      type: String,
      enum: ['open', 'in_progress', 'resolved', 'closed'],
      default: 'open',
      index: true,
    },
    adminReply: String,
    resolvedAt: Date,
  },
  { timestamps: true },
);

module.exports = mongoose.model('SupportTicket', supportTicketSchema);
