const mongoose = require('mongoose');

const cmsBannerSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    title: { type: String, required: true },
    subtitle: String,
    imageUrl: { type: String, required: true },
    linkUrl: String,
    sortOrder: { type: Number, default: 0 },
    active: { type: Boolean, default: true },
    placement: {
      type: String,
      enum: ['home_hero'],
      default: 'home_hero',
      index: true,
    },
  },
  { timestamps: true },
);

module.exports = mongoose.model('CmsBanner', cmsBannerSchema);
