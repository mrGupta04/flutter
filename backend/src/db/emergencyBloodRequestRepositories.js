const { v4: uuidv4 } = require('uuid');
const EmergencyBloodRequest = require('./models/EmergencyBloodRequest');
const BloodBank = require('./models/BloodBank');
const { toEmergencyBloodRequest } = require('./bloodBankModuleMappers');

function escapeRegex(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

async function createEmergencyRequest(data) {
  const request = await EmergencyBloodRequest.create({
    id: data.id || uuidv4(),
    patientId: data.patientId,
    bloodGroup: data.bloodGroup,
    units: data.units,
    patientName: data.patientName,
    hospitalName: data.hospitalName,
    contactNumber: data.contactNumber,
    requiredWithin: data.requiredWithin,
    additionalNotes: data.additionalNotes,
    latitude: data.latitude,
    longitude: data.longitude,
    city: data.city,
    status: 'open',
  });

  return toEmergencyBloodRequest(request);
}

async function listEmergencyRequestsForBloodBank(bloodBankId, { status = 'open' } = {}) {
  const bank = await BloodBank.findOne({ id: bloodBankId });
  if (!bank) return [];

  const filter = { status };
  if (bank.city) {
    filter.$or = [
      { city: new RegExp(escapeRegex(bank.city), 'i') },
      { city: { $exists: false } },
      { city: null },
      { city: '' },
    ];
  }

  const docs = await EmergencyBloodRequest.find(filter).sort({ createdAt: -1 }).limit(50);
  return docs.map(toEmergencyBloodRequest);
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

async function acceptEmergencyRequest(requestId, bloodBankId) {
  const request = await EmergencyBloodRequest.findOne({ id: requestId, status: 'open' });
  if (!request) {
    const err = new Error('Emergency request not found or already handled');
    err.statusCode = 404;
    throw err;
  }

  await EmergencyBloodRequest.updateOne(
    { id: requestId },
    {
      $set: {
        status: 'accepted',
        assignedBloodBankId: bloodBankId,
        acceptedAt: new Date(),
      },
    },
  );

  return toEmergencyBloodRequest(
    await EmergencyBloodRequest.findOne({ id: requestId }),
  );
}

async function findEmergencyRequestById(id) {
  const doc = await EmergencyBloodRequest.findOne({ id });
  return toEmergencyBloodRequest(doc);
}

module.exports = {
  createEmergencyRequest,
  listEmergencyRequestsForBloodBank,
  listAllEmergencyRequests,
  acceptEmergencyRequest,
  findEmergencyRequestById,
};
