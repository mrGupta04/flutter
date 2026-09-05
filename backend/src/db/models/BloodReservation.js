const mongoose = require('mongoose');

const reservedUnitSchema = new mongoose.Schema(
  {
    unitId: String,
    unitIdentifier: String,
  },
  { _id: false },
);

const bloodReservationSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    bloodBankId: { type: String, required: true, index: true },
    requestId: { type: String, required: true, index: true },
    bloodGroup: { type: String, required: true },
    componentType: { type: String, required: true },
    units: { type: Number, required: true, min: 1 },
    reservedUnits: { type: [reservedUnitSchema], default: [] },
    status: {
      type: String,
      enum: ['active', 'fulfilled', 'released', 'expired', 'cancelled'],
      default: 'active',
      index: true,
    },
    expiresAt: { type: Date, required: true, index: true },
    releasedAt: Date,
    fulfilledAt: Date,
    createdBy: String,
    createdByRole: String,
  },
  { timestamps: true },
);

bloodReservationSchema.index({ requestId: 1, status: 1 });
bloodReservationSchema.index({ bloodBankId: 1, status: 1, expiresAt: 1 });

module.exports = mongoose.model('BloodReservation', bloodReservationSchema);
