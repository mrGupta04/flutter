const mongoose = require('mongoose');

const bloodInventoryUnitSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    bloodBankId: { type: String, required: true, index: true },
    inventoryId: { type: String, index: true },
    bloodGroup: { type: String, required: true, index: true },
    componentType: { type: String, required: true, index: true },
    unitIdentifier: { type: String, required: true },
    batchIdentifier: String,
    storageLocation: String,
    collectionDate: Date,
    expiryDate: Date,
    status: {
      type: String,
      enum: [
        'available',
        'reserved',
        'unavailable',
        'expired',
        'disposed',
        'transferred',
        'issued',
      ],
      default: 'available',
      index: true,
    },
    reservedForRequestId: String,
    reservedUntil: Date,
    notes: String,
    version: { type: Number, default: 0 },
  },
  { timestamps: true },
);

bloodInventoryUnitSchema.index(
  { bloodBankId: 1, unitIdentifier: 1 },
  { unique: true },
);
bloodInventoryUnitSchema.index({ bloodBankId: 1, bloodGroup: 1, componentType: 1, status: 1 });
bloodInventoryUnitSchema.index({ expiryDate: 1, status: 1 });

module.exports = mongoose.model('BloodInventoryUnit', bloodInventoryUnitSchema);
