const { v4: uuidv4 } = require('uuid');
const BloodBankAuditLog = require('./models/BloodBankAuditLog');
const BloodRequestStatusHistory = require('./models/BloodRequestStatusHistory');

async function writeAudit({
  actorId,
  actorRole,
  action,
  entityType,
  entityId,
  bloodBankId,
  previousValue,
  newValue,
  metadata,
}) {
  if (!actorId || !action || !entityType || !entityId) return null;
  return BloodBankAuditLog.create({
    id: uuidv4(),
    actorId,
    actorRole: actorRole || 'unknown',
    action,
    entityType,
    entityId,
    bloodBankId,
    previousValue,
    newValue,
    metadata: metadata || {},
  });
}

async function listAuditLogs({
  bloodBankId,
  entityType,
  entityId,
  action,
  page = 1,
  pageSize = 30,
} = {}) {
  const filter = {};
  if (bloodBankId) filter.bloodBankId = bloodBankId;
  if (entityType) filter.entityType = entityType;
  if (entityId) filter.entityId = entityId;
  if (action) filter.action = action;

  const totalCount = await BloodBankAuditLog.countDocuments(filter);
  const totalPages = Math.max(1, Math.ceil(totalCount / pageSize));
  const docs = await BloodBankAuditLog.find(filter)
    .sort({ createdAt: -1 })
    .skip((page - 1) * pageSize)
    .limit(pageSize)
    .lean();

  return {
    logs: docs,
    pagination: {
      currentPage: page,
      totalPages,
      pageSize,
      totalCount,
      hasNextPage: page < totalPages,
    },
  };
}

async function appendStatusHistory({
  requestId,
  requestKind = 'order',
  fromStatus,
  toStatus,
  actorId,
  actorRole,
  note,
  metadata,
}) {
  if (!requestId || !toStatus) return null;
  return BloodRequestStatusHistory.create({
    id: uuidv4(),
    requestId,
    requestKind,
    fromStatus,
    toStatus,
    actorId,
    actorRole,
    note,
    metadata: metadata || {},
  });
}

async function listStatusHistory(requestId) {
  return BloodRequestStatusHistory.find({ requestId }).sort({ createdAt: 1 }).lean();
}

module.exports = {
  writeAudit,
  listAuditLogs,
  appendStatusHistory,
  listStatusHistory,
};
