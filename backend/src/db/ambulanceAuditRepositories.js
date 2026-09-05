const { v4: uuidv4 } = require('uuid');
const AmbulanceAuditLog = require('./models/AmbulanceAuditLog');
const AmbulanceStatusHistory = require('./models/AmbulanceStatusHistory');

async function writeAmbulanceAudit({
  actorId,
  actorRole,
  action,
  entityType,
  entityId,
  ambulanceId,
  previousValue,
  newValue,
  metadata,
}) {
  if (!actorId || !action || !entityType || !entityId) return null;
  return AmbulanceAuditLog.create({
    id: uuidv4(),
    actorId,
    actorRole: actorRole || 'unknown',
    action,
    entityType,
    entityId,
    ambulanceId,
    previousValue,
    newValue,
    metadata: metadata || {},
  });
}

async function appendAmbulanceStatusHistory({
  bookingId,
  fromStatus,
  toStatus,
  actorId,
  actorRole,
  note,
  metadata,
}) {
  if (!bookingId || !toStatus) return null;
  return AmbulanceStatusHistory.create({
    id: uuidv4(),
    bookingId,
    fromStatus,
    toStatus,
    actorId,
    actorRole,
    note,
    metadata: metadata || {},
  });
}

async function listAmbulanceAuditLogs({
  ambulanceId,
  entityType,
  entityId,
  action,
  page = 1,
  pageSize = 30,
} = {}) {
  const filter = {};
  if (ambulanceId) filter.ambulanceId = ambulanceId;
  if (entityType) filter.entityType = entityType;
  if (entityId) filter.entityId = entityId;
  if (action) filter.action = action;

  const totalCount = await AmbulanceAuditLog.countDocuments(filter);
  const totalPages = Math.max(1, Math.ceil(totalCount / pageSize));
  const logs = await AmbulanceAuditLog.find(filter)
    .sort({ createdAt: -1 })
    .skip((page - 1) * pageSize)
    .limit(pageSize)
    .lean();

  return {
    logs,
    pagination: {
      currentPage: page,
      totalPages,
      pageSize,
      totalCount,
      hasNextPage: page < totalPages,
    },
  };
}

async function listAmbulanceStatusHistory(bookingId) {
  return AmbulanceStatusHistory.find({ bookingId }).sort({ createdAt: 1 }).lean();
}

module.exports = {
  writeAmbulanceAudit,
  appendAmbulanceStatusHistory,
  listAmbulanceAuditLogs,
  listAmbulanceStatusHistory,
};
