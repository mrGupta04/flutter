const { v4: uuidv4 } = require('uuid');
const EmergencyBloodRequest = require('./models/EmergencyBloodRequest');
const { toEmergencyBloodRequest } = require('./bloodBankModuleMappers');
const { findEligibleBloodBanks } = require('../services/bloodMatchingService');
const {
  findEligibleDonors,
  createDonorRequests,
} = require('./donorRepositories');
const { appendStatusHistory } = require('./bloodAuditRepositories');
const { emitBloodEvent } = require('../services/bloodRealtime');
const {
  reserveUnitsAtomically,
} = require('./bloodReservationRepositories');

function httpError(message, statusCode = 400) {
  const err = new Error(message);
  err.statusCode = statusCode;
  return err;
}

async function createEmergencyRequest(data) {
  if (!Number(data.units) || Number(data.units) < 1) {
    throw httpError('Units must be greater than zero');
  }

  const request = await EmergencyBloodRequest.create({
    id: data.id || uuidv4(),
    patientId: data.patientId,
    bloodGroup: data.bloodGroup,
    componentType: data.componentType || 'whole_blood',
    units: data.units,
    patientName: data.patientName,
    hospitalName: data.hospitalName,
    hospitalAddress: data.hospitalAddress,
    contactNumber: data.contactNumber,
    requiredWithin: data.requiredWithin,
    additionalNotes: data.additionalNotes,
    latitude: data.latitude,
    longitude: data.longitude,
    city: data.city,
    status: 'emergency_requested',
  });

  const eligible = await findEligibleBloodBanks({
    bloodGroup: data.bloodGroup,
    componentType: data.componentType || 'whole_blood',
    units: data.units,
    city: data.city,
    latitude: data.latitude,
    longitude: data.longitude,
    emergencyOnly: true,
    limit: 15,
  });

  request.notifiedBloodBankIds = eligible.map((b) => b.id);
  request.status = eligible.length ? 'blood_bank_alerted' : 'emergency_requested';
  await request.save();

  await appendStatusHistory({
    requestId: request.id,
    requestKind: 'emergency',
    toStatus: request.status,
    actorId: data.patientId || 'patient',
    actorRole: 'patient',
    note: 'Emergency request created',
  });

  emitBloodEvent('emergency_request_created', {
    patientId: request.patientId,
    requestId: request.id,
    bloodGroup: request.bloodGroup,
    units: request.units,
  });

  return {
    request: toEmergencyBloodRequest(request),
    notifiedBloodBanks: eligible,
  };
}

async function listEmergencyRequestsForBloodBank(bloodBankId, { status } = {}) {
  const filter = {
    $or: [{ assignedBloodBankId: bloodBankId }, { notifiedBloodBankIds: bloodBankId }],
  };
  if (status) {
    filter.status = status === 'open'
      ? { $in: ['open', 'emergency_requested', 'blood_bank_alerted', 'response_received'] }
      : status;
  }

  const docs = await EmergencyBloodRequest.find(filter).sort({ createdAt: -1 }).limit(50);
  return docs.map(toEmergencyBloodRequest);
}

async function listEmergencyRequestsForPatient(patientId, { page = 1, pageSize = 20 } = {}) {
  const filter = { patientId };
  const totalCount = await EmergencyBloodRequest.countDocuments(filter);
  const totalPages = Math.max(1, Math.ceil(totalCount / pageSize));
  const docs = await EmergencyBloodRequest.find(filter)
    .sort({ createdAt: -1 })
    .skip((page - 1) * pageSize)
    .limit(pageSize);
  return {
    requests: docs.map(toEmergencyBloodRequest),
    pagination: {
      currentPage: page,
      totalPages,
      pageSize,
      totalCount,
      hasNextPage: page < totalPages,
    },
  };
}

async function listAllEmergencyRequests({ status, page = 1, pageSize = 20 } = {}) {
  const filter = {};
  if (status) filter.status = status;

  const totalCount = await EmergencyBloodRequest.countDocuments(filter);
  const totalPages = Math.max(1, Math.ceil(totalCount / pageSize));
  const skip = (page - 1) * pageSize;

  const docs = await EmergencyBloodRequest.find(filter)
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(pageSize);

  return {
    requests: docs.map(toEmergencyBloodRequest),
    pagination: {
      currentPage: page,
      totalPages,
      pageSize,
      totalCount,
      hasNextPage: page < totalPages,
    },
  };
}

async function respondToEmergencyRequest(requestId, bloodBankId, { action, availableUnits, notes }) {
  const request = await EmergencyBloodRequest.findOne({ id: requestId });
  if (!request) throw httpError('Emergency request not found', 404);
  if (['fulfilled', 'cancelled', 'expired', 'collected'].includes(request.status)) {
    throw httpError('Request expired or already closed', 400);
  }
  if (request.assignedBloodBankId && request.assignedBloodBankId !== bloodBankId) {
    throw httpError('This requirement is already reserved by another provider', 409);
  }

  const already = (request.responses || []).some((r) => r.bloodBankId === bloodBankId);
  if (already && action === 'accepted') {
    throw httpError('This request was already handled by your blood bank', 409);
  }

  request.responses = [
    ...(request.responses || []),
    {
      bloodBankId,
      action,
      availableUnits: Number(availableUnits || 0),
      respondedAt: new Date(),
      notes,
    },
  ];

  if (action === 'rejected') {
    request.status = 'response_received';
    await request.save();
    emitBloodEvent('blood_request_rejected', {
      patientId: request.patientId,
      bloodBankId,
      requestId: request.id,
    });
    return toEmergencyBloodRequest(request);
  }

  const offered = Number(availableUnits || request.units || 0);
  if (offered < 1) throw httpError('Insufficient units');

  if (action === 'accepted' && offered >= request.units && !request.assignedBloodBankId) {
    const reservation = await reserveUnitsAtomically({
      bloodBankId,
      bloodGroup: request.bloodGroup,
      componentType: request.componentType || 'whole_blood',
      units: request.units,
      requestId: request.id,
      actorId: bloodBankId,
      actorRole: 'blood_bank',
    });
    request.assignedBloodBankId = bloodBankId;
    request.acceptedAt = new Date();
    request.confirmedUnits = request.units;
    request.reservationId = reservation.id;
    request.status = 'blood_reserved';
  } else {
    request.confirmedUnits = (request.confirmedUnits || 0) + offered;
    request.status = request.confirmedUnits >= request.units ? 'response_received' : 'response_received';
    if (request.confirmedUnits >= request.units && !request.assignedBloodBankId) {
      request.assignedBloodBankId = bloodBankId;
      request.acceptedAt = new Date();
      request.status = 'accepted';
    }
  }

  await request.save();
  await appendStatusHistory({
    requestId: request.id,
    requestKind: 'emergency',
    toStatus: request.status,
    actorId: bloodBankId,
    actorRole: 'blood_bank',
    note: action,
  });
  emitBloodEvent(
    action === 'accepted' ? 'blood_request_accepted' : 'emergency_request_created',
    {
      patientId: request.patientId,
      bloodBankId,
      requestId: request.id,
      status: request.status,
    },
  );
  return toEmergencyBloodRequest(request);
}

async function acceptEmergencyRequest(requestId, bloodBankId) {
  return respondToEmergencyRequest(requestId, bloodBankId, {
    action: 'accepted',
    availableUnits: undefined,
  });
}

async function maybeNotifyDonors(request) {
  if (request.donorFallbackTriggered) return [];
  if (request.assignedBloodBankId && request.confirmedUnits >= request.units) return [];

  const donors = await findEligibleDonors({
    bloodGroup: request.bloodGroup,
    city: request.city,
    latitude: request.latitude,
    longitude: request.longitude,
    componentType: request.componentType,
    limit: 15,
  });
  if (!donors.length) return [];

  const created = await createDonorRequests({
    donors,
    emergencyRequestId: request.id,
    payload: {
      patientId: request.patientId,
      bloodGroup: request.bloodGroup,
      componentType: request.componentType,
      units: request.units,
      hospitalName: request.hospitalName,
      hospitalAddress: request.hospitalAddress,
      city: request.city,
      latitude: request.latitude,
      longitude: request.longitude,
    },
  });

  await EmergencyBloodRequest.updateOne(
    { id: request.id },
    { $set: { donorFallbackTriggered: true } },
  );
  return created;
}

async function findEmergencyRequestById(id) {
  const doc = await EmergencyBloodRequest.findOne({ id });
  return toEmergencyBloodRequest(doc);
}

async function updateEmergencyStatus(requestId, status, extra = {}, actor = {}) {
  const request = await EmergencyBloodRequest.findOne({ id: requestId });
  if (!request) return null;
  const fromStatus = request.status;
  Object.assign(request, extra, { status });
  await request.save();
  await appendStatusHistory({
    requestId,
    requestKind: 'emergency',
    fromStatus,
    toStatus: status,
    actorId: actor.actorId,
    actorRole: actor.actorRole,
  });
  return toEmergencyBloodRequest(request);
}

module.exports = {
  createEmergencyRequest,
  listEmergencyRequestsForBloodBank,
  listEmergencyRequestsForPatient,
  listAllEmergencyRequests,
  acceptEmergencyRequest,
  respondToEmergencyRequest,
  findEmergencyRequestById,
  maybeNotifyDonors,
  updateEmergencyStatus,
};
