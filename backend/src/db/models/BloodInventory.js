const mongoose = require('mongoose');

const expiryEntrySchema = new mongoose.Schema(
  {
    units: Number,
    expiryDate: Date,
  },
  { _id: false },
);

const bloodInventorySchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    bloodBankId: { type: String, required: true, index: true },
    bloodGroup: { type: String, required: true },
    componentType: { type: String, default: 'whole_blood', index: true },
    availableUnits: { type: Number, default: 0 },
    reservedUnits: { type: Number, default: 0 },
    expiredUnits: { type: Number, default: 0 },
    unavailableUnits: { type: Number, default: 0 },
    totalUnits: { type: Number, default: 0 },
    expiryDates: { type: [expiryEntrySchema], default: [] },
    storageLocation: String,
    publicVisibility: {
      type: String,
      enum: ['inherit', 'states', 'counts', 'hidden'],
      default: 'inherit',
    },
    lowStockThreshold: Number,
    criticalStockThreshold: Number,
    lastUpdated: { type: Date, default: Date.now },
  },
  { timestamps: true },
);

bloodInventorySchema.index({ bloodBankId: 1, bloodGroup: 1, componentType: 1 }, { unique: true });

module.exports = mongoose.model('BloodInventory', bloodInventorySchema);
