const mongoose = require('mongoose');

const bookingChatMessageSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    bookingId: { type: String, required: true, index: true },
    senderType: {
      type: String,
      enum: ['patient', 'doctor', 'nurse'],
      required: true,
    },
    senderId: { type: String, required: true },
    body: { type: String, required: true, maxlength: 2000 },
  },
  { timestamps: true },
);

bookingChatMessageSchema.index({ bookingId: 1, createdAt: 1 });

module.exports = mongoose.model('BookingChatMessage', bookingChatMessageSchema);
