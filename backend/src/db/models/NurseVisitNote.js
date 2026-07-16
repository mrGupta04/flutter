const mongoose = require('mongoose');

const nurseVisitNoteSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    bookingId: { type: String, required: true, unique: true, index: true },
    nurseId: { type: String, required: true, index: true },
    patientId: String,
    patientName: { type: String, required: true },
    careSummary: { type: String, required: true, maxlength: 2000 },
    vitals: String,
    proceduresDone: String,
    advice: String,
    followUpNeeded: { type: Boolean, default: false },
    status: {
      type: String,
      enum: ['draft', 'finalized'],
      default: 'finalized',
      index: true,
    },
  },
  { timestamps: true },
);

module.exports = mongoose.model('NurseVisitNote', nurseVisitNoteSchema);
