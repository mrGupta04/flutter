const mongoose = require('mongoose');

const documentSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true },
    doctorId: { type: String, index: true },
    nurseId: { type: String, index: true },
    ambulanceId: { type: String, index: true },
    vehicleId: String,
    driverId: String,
    documentType: { type: String, required: true },
    fileUrl: { type: String, required: true },
    fileName: String,
    fileSize: Number,
    mimeType: String,
    status: { type: String, default: 'pending' },
    rejectionReason: String,
    verifiedAt: Date,
    verifiedBy: String,
  },
  { timestamps: { createdAt: 'uploadedAt', updatedAt: false } },
);

module.exports = mongoose.model('Document', documentSchema);
