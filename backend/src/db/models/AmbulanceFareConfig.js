const mongoose = require('mongoose');

const ambulanceFareConfigSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    rules: { type: mongoose.Schema.Types.Mixed, required: true },
    updatedBy: String,
  },
  { timestamps: true },
);

module.exports = mongoose.model('AmbulanceFareConfig', ambulanceFareConfigSchema);
