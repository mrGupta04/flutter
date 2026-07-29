const mongoose = require('mongoose');

const approvalLevelSchema = new mongoose.Schema(
  {
    id: String,
    name: String,
    role: String,
    required: { type: Boolean, default: true },
    order: Number,
  },
  { _id: false },
);

const approvalRuleSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    providerCategory: { type: String, required: true, unique: true, index: true },
    assignmentStrategy: {
      type: String,
      enum: ['round_robin', 'least_busy', 'manual', 'region_based', 'category_based'],
      default: 'least_busy',
    },
    slaHours: { type: Number, default: 24 },
    approvalLevels: { type: [approvalLevelSchema], default: [] },
    escalationHours: { type: Number, default: 4 },
    active: { type: Boolean, default: true },
    aiBalancingReady: { type: Boolean, default: true },
  },
  { timestamps: true },
);

module.exports = mongoose.model('ApprovalRule', approvalRuleSchema);
