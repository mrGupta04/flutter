const mongoose = require('mongoose');

const providerCategorySchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    slug: { type: String, required: true, unique: true, index: true },
    name: { type: String, required: true },
    description: String,
    active: { type: Boolean, default: true, index: true },
    slaHours: { type: Number, default: 24 },
    sortOrder: { type: Number, default: 0 },
  },
  { timestamps: true },
);

module.exports = mongoose.model('ProviderCategory', providerCategorySchema);
