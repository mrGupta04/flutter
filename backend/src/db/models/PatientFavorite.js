const mongoose = require('mongoose');

const patientFavoriteSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    patientId: { type: String, required: true, index: true },
    providerType: {
      type: String,
      enum: ['doctor', 'nurse'],
      required: true,
    },
    providerId: { type: String, required: true, index: true },
  },
  { timestamps: true },
);

patientFavoriteSchema.index(
  { patientId: 1, providerType: 1, providerId: 1 },
  { unique: true },
);

module.exports = mongoose.model('PatientFavorite', patientFavoriteSchema);
