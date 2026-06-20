const mongoose = require('mongoose');

const medicineSchema = new mongoose.Schema(
  {
    name: { type: String, required: true },
    dosage: String,
    frequency: String,
    duration: String,
    instructions: String,
  },
  { _id: false },
);

const testSchema = new mongoose.Schema(
  {
    name: { type: String, required: true },
    notes: String,
  },
  { _id: false },
);

const prescriptionSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    bookingId: { type: String, required: true, unique: true, index: true },
    doctorId: { type: String, required: true, index: true },
    patientId: String,
    patientName: { type: String, required: true },
    patientEmail: String,
    symptoms: String,
    diagnosis: String,
    medicines: { type: [medicineSchema], default: [] },
    tests: { type: [testSchema], default: [] },
    advice: String,
    pdfUrl: String,
    pdfFileName: String,
    status: {
      type: String,
      enum: ['draft', 'finalized'],
      default: 'draft',
      index: true,
    },
    emailedAt: Date,
  },
  { timestamps: true },
);

module.exports = mongoose.model('Prescription', prescriptionSchema);
