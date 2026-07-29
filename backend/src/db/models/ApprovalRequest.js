const mongoose = require('mongoose');

const auditActorSchema = new mongoose.Schema(
  {
    id: String,
    name: String,
    role: String,
  },
  { _id: false },
);

const requestTimelineSchema = new mongoose.Schema(
  {
    id: String,
    actor: auditActorSchema,
    action: { type: String, required: true },
    remarks: String,
    ip: String,
    device: String,
    createdAt: { type: Date, default: Date.now, immutable: true },
    metadata: { type: mongoose.Schema.Types.Mixed, default: {} },
  },
  { _id: false },
);

const assignmentHistorySchema = new mongoose.Schema(
  {
    id: String,
    fromApproverId: String,
    fromApproverName: String,
    toApproverId: String,
    toApproverName: String,
    strategy: String,
    assignedBy: auditActorSchema,
    remarks: String,
    createdAt: { type: Date, default: Date.now, immutable: true },
  },
  { _id: false },
);

const approvalHistorySchema = new mongoose.Schema(
  {
    id: String,
    actor: auditActorSchema,
    action: String,
    statusBefore: String,
    statusAfter: String,
    remarks: String,
    durationMinutes: Number,
    createdAt: { type: Date, default: Date.now, immutable: true },
  },
  { _id: false },
);

const levelDecisionSchema = new mongoose.Schema(
  {
    id: String,
    levelId: String,
    levelName: String,
    levelOrder: Number,
    role: String,
    required: { type: Boolean, default: true },
    status: {
      type: String,
      enum: ['pending', 'approved', 'rejected', 'skipped'],
      default: 'pending',
    },
    decidedBy: auditActorSchema,
    remarks: String,
    decidedAt: Date,
  },
  { _id: false },
);

const internalNoteSchema = new mongoose.Schema(
  {
    id: String,
    actor: auditActorSchema,
    note: String,
    createdAt: { type: Date, default: Date.now, immutable: true },
  },
  { _id: false },
);

const providerSnapshotSchema = new mongoose.Schema(
  {
    name: String,
    email: String,
    phone: String,
    country: String,
    state: String,
    district: String,
    city: String,
    pincode: String,
    registrationDate: Date,
    rawStatus: String,
  },
  { _id: false },
);

const approvalRequestSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    providerId: { type: String, required: true, index: true },
    providerType: { type: String, required: true, index: true },
    providerCategory: { type: String, required: true, index: true },
    provider: providerSnapshotSchema,
    priority: {
      type: String,
      enum: ['low', 'normal', 'high', 'urgent'],
      default: 'normal',
      index: true,
    },
    status: {
      type: String,
      enum: [
        'pending',
        'approved',
        'rejected',
        'on_hold',
        'needs_documents',
        'escalated',
      ],
      default: 'pending',
      index: true,
    },
    currentAssigneeId: { type: String, default: null, index: true },
    currentAssigneeName: String,
    assignedBy: auditActorSchema,
    assignedAt: Date,
    assignmentStrategy: String,
    currentApprovalLevel: { type: Number, default: 1, index: true },
    approvalLevels: { type: [levelDecisionSchema], default: [] },
    slaHours: Number,
    slaDueAt: { type: Date, index: true },
    viewedAt: Date,
    firstDecisionAt: Date,
    completedAt: Date,
    approvalDurationMinutes: Number,
    lastActionAt: Date,
    lastActionBy: auditActorSchema,
    lastRemarks: String,
    internalNotes: { type: [internalNoteSchema], default: [] },
    assignmentHistory: { type: [assignmentHistorySchema], default: [] },
    approvalHistory: { type: [approvalHistorySchema], default: [] },
    timeline: { type: [requestTimelineSchema], default: [] },
    intelligence: { type: mongoose.Schema.Types.Mixed, default: {} },
    metadata: { type: mongoose.Schema.Types.Mixed, default: {} },
  },
  { timestamps: true },
);

approvalRequestSchema.index({ providerType: 1, providerId: 1 }, { unique: true });
approvalRequestSchema.index({ status: 1, currentAssigneeId: 1, slaDueAt: 1 });

module.exports = mongoose.model('ApprovalRequest', approvalRequestSchema);
