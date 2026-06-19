const mongoose = require('mongoose');

const consultationFeedbackSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    bookingId: { type: String, required: true, unique: true, index: true },
    patientId: { type: String, required: true, index: true },
    doctorId: { type: String, required: true, index: true },
    consultationType: {
      type: String,
      enum: ['online_consult', 'book_home', 'visit_site'],
      required: true,
    },
    rating: { type: Number, min: 1, max: 5 },
    comment: { type: String, maxlength: 500 },
    status: {
      type: String,
      enum: ['submitted', 'dismissed'],
      default: 'submitted',
      index: true,
    },
  },
  { timestamps: true },
);

module.exports = mongoose.model('ConsultationFeedback', consultationFeedbackSchema);
