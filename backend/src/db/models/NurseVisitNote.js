const mongoose = require('mongoose');

const medicineSchema = new mongoose.Schema(
  {
    name: { type: String, required: true },
    dosage: String,
    quantity: String,
    route: { type: String, enum: ['IV', 'IM', 'Oral', 'Topical', 'Other'] },
    timeGiven: String,
  },
  { _id: false },
);

const attachmentSchema = new mongoose.Schema(
  {
    id: { type: String, required: true },
    fileUrl: { type: String, required: true },
    fileName: String,
    mimeType: String,
    category: {
      type: String,
      enum: ['wound', 'report', 'medical_image', 'other'],
      default: 'other',
    },
    uploadedAt: { type: Date, default: Date.now },
  },
  { _id: false },
);

const vitalsSchema = new mongoose.Schema(
  {
    bloodPressureSystolic: Number,
    bloodPressureDiastolic: Number,
    pulseRate: Number,
    oxygenSaturation: Number,
    bodyTemperature: Number,
    bloodSugar: Number,
    bloodSugarType: { type: String, enum: ['random', 'fasting', ''] },
    respiratoryRate: Number,
    heightCm: Number,
    weightKg: Number,
    bmi: Number,
  },
  { _id: false },
);

const assessmentSchema = new mongoose.Schema(
  {
    patientCondition: String,
    painLevel: { type: Number, min: 1, max: 10 },
    mentalStatus: String,
    mobilityStatus: String,
    hydrationStatus: String,
  },
  { _id: false },
);

const nurseVisitNoteSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    bookingId: { type: String, required: true, unique: true, index: true },
    nurseId: { type: String, required: true, index: true },
    patientId: String,
    patientName: { type: String, required: true },
    /** Legacy plain-text fields (kept for backward compatibility). */
    careSummary: String,
    vitals: String,
    proceduresDone: String,
    advice: String,
    followUpNeeded: { type: Boolean, default: false },
    /** Structured nursing assessment. */
    vitalsData: vitalsSchema,
    generalAssessment: assessmentSchema,
    symptoms: [String],
    symptomsOther: String,
    proceduresPerformed: [String],
    proceduresOther: String,
    medicinesAdministered: [medicineSchema],
    nurseNotes: String,
    followUpRecommendation: {
      type: String,
      enum: [
        'continue_medication',
        'consult_doctor',
        'emergency_visit',
        'follow_up_home_visit',
        'hospital_admission',
      ],
    },
    attachments: [attachmentSchema],
    visitStartedAt: Date,
    visitEndedAt: Date,
    visitDurationMinutes: Number,
    pdfUrl: String,
    pdfGeneratedAt: Date,
    verificationCode: String,
    status: {
      type: String,
      enum: ['draft', 'submitted', 'finalized', 'locked'],
      default: 'draft',
      index: true,
    },
    submittedAt: Date,
    lockedAt: Date,
  },
  { timestamps: true },
);

module.exports = mongoose.model('NurseVisitNote', nurseVisitNoteSchema);
