const mongoose = require('mongoose');

const QUOTATION_STATUSES = [
  'PENDING',
  'QUOTED',
  'SELECTED',
  'REJECTED',
  'EXPIRED',
];

const prescriptionQuotationSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    prescriptionRequestId: { type: String, required: true, index: true },
    labId: { type: String, required: true, index: true },
    labName: String,
    providerType: {
      type: String,
      enum: ['lab', 'scan_center'],
      default: 'lab',
    },
    quotedAmount: { type: Number, default: null },
    estimatedCompletionTime: String,
    availableServices: { type: [String], default: [] },
    labNotes: String,
    rating: { type: Number, default: null },
    distanceKm: { type: Number, default: null },
    status: {
      type: String,
      enum: QUOTATION_STATUSES,
      default: 'PENDING',
      index: true,
    },
    paymentStatus: {
      type: String,
      enum: ['PENDING', 'PAID', 'FAILED', 'REFUNDED'],
      default: 'PENDING',
    },
    submittedAt: Date,
    rejectionReason: String,
  },
  { timestamps: true },
);

prescriptionQuotationSchema.index(
  { prescriptionRequestId: 1, labId: 1 },
  { unique: true },
);
prescriptionQuotationSchema.index({ labId: 1, status: 1, createdAt: -1 });

module.exports = mongoose.model(
  'PrescriptionQuotation',
  prescriptionQuotationSchema,
);
module.exports.QUOTATION_STATUSES = QUOTATION_STATUSES;
