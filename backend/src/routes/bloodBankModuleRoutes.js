const express = require('express');
const bcrypt = require('bcryptjs');
const { sendSuccess, sendError } = require('../utils/response');
const { authOptional, authRequired, adminRequired, signToken } = require('../middleware/auth');
const {
  bloodBankRequired,
  requireBloodPermission,
  patientRequired,
  actorFromAuth,
} = require('../middleware/bloodBankAuth');
const { listCompatibilityRules, upsertCompatibilityRule } = require('../services/bloodCompatibilityService');
const {
  findDonorByPatientId,
  upsertDonorProfile,
  listDonorRequestsForPatient,
  respondToDonorRequest,
  recordDonation,
  listDonationsByPatient,
  listDonationsByBloodBank,
  listDonorsForBloodBank,
  listAllDonors,
} = require('../db/donorRepositories');
const {
  addUnits,
  listUnits,
  updateUnit,
  toPublicInventory,
} = require('../db/bloodInventoryUnitRepositories');
const { listInventoryByBloodBank } = require('../db/bloodInventoryRepositories');
const {
  cancelBloodOrder,
  getOrderWithHistory,
  updateOrderStatus,
  listOrdersByPatient,
  listAllOrders,
  findOrderById,
} = require('../db/bloodOrderRepositories');
const {
  listEmergencyRequestsForPatient,
  respondToEmergencyRequest,
  findEmergencyRequestById,
  maybeNotifyDonors,
  listAllEmergencyRequests,
} = require('../db/emergencyBloodRequestRepositories');
const { listAuditLogs, listStatusHistory } = require('../db/bloodAuditRepositories');
const { findStaffByEmail } = require('../db/bloodBankStaffRepositories');
const { findBloodBankById, disableBloodBank, enableBloodBank } = require('../db/bloodBankRepositories');
const { createAndPushNotification } = require('../db/notificationRepositories');
const { emitBloodEvent } = require('../services/bloodRealtime');
const BloodOrder = require('../db/models/BloodOrder');
const BloodBank = require('../db/models/BloodBank');
const BloodInventory = require('../db/models/BloodInventory');
const DonorProfile = require('../db/models/DonorProfile');
const EmergencyBloodRequest = require('../db/models/EmergencyBloodRequest');
const BloodDonation = require('../db/models/BloodDonation');

const router = express.Router();

function handle(res, err, fallback) {
  console.error(err);
  return sendError(res, err.message || fallback, err.statusCode || 500);
}

router.get('/compatibility', async (_req, res) => {
  try {
    const rules = await listCompatibilityRules();
    return sendSuccess(res, {
      data: {
        rules,
        disclaimer:
          'This information is for search and matching only and never replaces professional blood typing or crossmatching.',
      },
    });
  } catch (err) {
    return handle(res, err, 'Failed to load compatibility');
  }
});

router.put('/admin/compatibility', adminRequired, async (req, res) => {
  try {
    const rule = await upsertCompatibilityRule(req.body || {}, req.auth?.adminId || 'admin');
    return sendSuccess(res, { message: 'Compatibility rule saved', data: rule });
  } catch (err) {
    return handle(res, err, 'Failed to save compatibility');
  }
});

router.post('/staff/login', async (req, res) => {
  try {
    const { email, password } = req.body || {};
    const staff = await findStaffByEmail(email);
    if (!staff || !staff.passwordHash || !bcrypt.compareSync(password || '', staff.passwordHash)) {
      return sendError(res, 'Invalid staff credentials', 401);
    }
    const token = signToken(
      {
        type: 'blood_bank_staff',
        bloodBankId: staff.bloodBankId,
        staffId: staff.id,
        staffRole: staff.role,
      },
      '30d',
    );
    return sendSuccess(res, {
      message: 'Login successful',
      token,
      data: {
        id: staff.id,
        name: staff.name,
        role: staff.role,
        bloodBankId: staff.bloodBankId,
      },
    });
  } catch (err) {
    return handle(res, err, 'Staff login failed');
  }
});

router.post('/donor/profile', patientRequired, async (req, res) => {
  try {
    const profile = await upsertDonorProfile(req.auth.patientId, req.body || {});
    return sendSuccess(res, { message: 'Donor profile saved', data: profile });
  } catch (err) {
    return handle(res, err, 'Failed to save donor profile');
  }
});

router.get('/donor/profile', patientRequired, async (req, res) => {
  try {
    const profile = await findDonorByPatientId(req.auth.patientId);
    return sendSuccess(res, { data: profile });
  } catch (err) {
    return handle(res, err, 'Failed to load donor profile');
  }
});

router.get('/donor/history', patientRequired, async (req, res) => {
  try {
    const donations = await listDonationsByPatient(req.auth.patientId);
    return sendSuccess(res, { data: donations });
  } catch (err) {
    return handle(res, err, 'Failed to load donation history');
  }
});

router.get('/donor/requests', patientRequired, async (req, res) => {
  try {
    const requests = await listDonorRequestsForPatient(req.auth.patientId);
    return sendSuccess(res, { data: requests });
  } catch (err) {
    return handle(res, err, 'Failed to load donor requests');
  }
});

router.post('/donor/requests/:id/respond', patientRequired, async (req, res) => {
  try {
    const accept = req.body?.accept !== false && req.body?.available !== false;
    const request = await respondToDonorRequest(req.params.id, req.auth.patientId, {
      accept,
      notes: req.body?.notes,
    });
    if (request.bloodBankId) {
      await createAndPushNotification({
        userId: request.bloodBankId,
        userType: 'bloodbank',
        title: accept ? 'Donor can donate' : 'Donor not available',
        body: `A consented donor responded for ${request.bloodGroup}.`,
        type: 'blood_donor',
        data: { donorRequestId: request.id, emergencyRequestId: request.emergencyRequestId },
      });
      emitBloodEvent('donor_response', {
        bloodBankId: request.bloodBankId,
        requestId: request.emergencyRequestId,
        donorPatientId: req.auth.patientId,
      });
    }
    return sendSuccess(res, { message: accept ? 'Response recorded' : 'Marked unavailable', data: request });
  } catch (err) {
    return handle(res, err, 'Failed to respond');
  }
});

router.get('/requests', authRequired, async (req, res) => {
  try {
    const page = Math.max(1, parseInt(req.query.page || '1', 10));
    const pageSize = Math.min(50, parseInt(req.query.pageSize || '20', 10));
    if (req.auth.type === 'patient') {
      const { orders, pagination } = await listOrdersByPatient(req.auth.patientId, { page, pageSize });
      return sendSuccess(res, { data: orders, pagination });
    }
    return sendError(res, 'Use provider bookings endpoint', 400);
  } catch (err) {
    return handle(res, err, 'Failed to list requests');
  }
});

router.get('/requests/:id', authRequired, async (req, res) => {
  try {
    const order = await getOrderWithHistory(req.params.id);
    if (!order) return sendError(res, 'Request not found', 404);
    const isOwner = req.auth.patientId && req.auth.patientId === order.patientId;
    const isBank = req.auth.bloodBankId && req.auth.bloodBankId === order.bloodBankId;
    const isAdmin = req.auth.type === 'admin';
    if (!isOwner && !isBank && !isAdmin) {
      return sendError(res, 'Unauthorized access', 403);
    }
    return sendSuccess(res, { data: order });
  } catch (err) {
    return handle(res, err, 'Failed to load request');
  }
});

router.post('/requests/:id/cancel', patientRequired, async (req, res) => {
  try {
    const order = await cancelBloodOrder(req.params.id, req.auth.patientId, req.body?.reason);
    if (!order) return sendError(res, 'Request not found', 404);
    return sendSuccess(res, { message: 'Request cancelled', data: order });
  } catch (err) {
    return handle(res, err, 'Failed to cancel request');
  }
});

router.get('/emergency/mine', patientRequired, async (req, res) => {
  try {
    const result = await listEmergencyRequestsForPatient(req.auth.patientId, {
      page: Math.max(1, parseInt(req.query.page || '1', 10)),
      pageSize: Math.min(50, parseInt(req.query.pageSize || '20', 10)),
    });
    return sendSuccess(res, { data: result.requests, pagination: result.pagination });
  } catch (err) {
    return handle(res, err, 'Failed to load emergency requests');
  }
});

router.get('/emergency/:requestId/timeline', authRequired, async (req, res) => {
  try {
    const request = await findEmergencyRequestById(req.params.requestId);
    if (!request) return sendError(res, 'Request not found', 404);
    const history = await listStatusHistory(req.params.requestId);
    return sendSuccess(res, { data: { ...request, statusHistory: history } });
  } catch (err) {
    return handle(res, err, 'Failed to load timeline');
  }
});

router.post('/emergency/:requestId/respond', bloodBankRequired, requireBloodPermission('emergency.write'), async (req, res) => {
  try {
    const request = await respondToEmergencyRequest(req.params.requestId, req.bloodBankId, {
      action: req.body?.action || 'accepted',
      availableUnits: req.body?.availableUnits,
      notes: req.body?.notes,
    });
    if (!request.assignedBloodBankId) {
      const full = await EmergencyBloodRequest.findOne({ id: request.id });
      const donorRequests = await maybeNotifyDonors(full);
      for (const donorRequest of donorRequests) {
        const donor = await DonorProfile.findOne({ id: donorRequest.donorProfileId }).lean();
        if (donor?.patientId) {
          await createAndPushNotification({
            userId: donor.patientId,
            userType: 'patient',
            title: 'Emergency donation request',
            body: `${request.bloodGroup} needed at ${request.hospitalName || 'a nearby hospital'}.`,
            type: 'emergency_blood',
            data: { donorRequestId: donorRequest.id, requestId: request.id },
          });
        }
      }
    }
    return sendSuccess(res, { message: 'Response recorded', data: request });
  } catch (err) {
    return handle(res, err, 'Failed to respond');
  }
});

const lifecycle = [
  ['accept', 'accepted'],
  ['reject', 'rejected'],
  ['reserve', 'blood_reserved'],
  ['ready', 'ready_for_collection'],
  ['collected', 'collected'],
  ['complete', 'completed'],
];

for (const [action, status] of lifecycle) {
  router.post(
    `/provider/requests/:id/${action}`,
    bloodBankRequired,
    requireBloodPermission('requests.write'),
    async (req, res) => {
      try {
        const existing = await findOrderById(req.params.id);
        if (!existing) return sendError(res, 'Request not found', 404);
        if (existing.bloodBankId !== req.bloodBankId) {
          return sendError(res, 'Unauthorized access', 403);
        }
        if (action === 'reject' && !req.body?.rejectionReasonCode && !req.body?.rejectionReason) {
          return sendError(res, 'A rejection reason is required', 400);
        }
        const order = await updateOrderStatus(
          req.params.id,
          status,
          {
            rejectionReason: req.body?.rejectionReason,
            rejectionReasonCode: req.body?.rejectionReasonCode,
            estimatedDeliveryTime: req.body?.estimatedDeliveryTime,
            assignedStaffId: req.body?.assignedStaffId,
            deliveryStatus: req.body?.deliveryStatus,
          },
          req.auth,
        );
        return sendSuccess(res, { message: `Request ${action}ed`, data: order });
      } catch (err) {
        return handle(res, err, `Failed to ${action} request`);
      }
    },
  );
}

router.get('/provider/inventory/units', bloodBankRequired, requireBloodPermission('inventory.read'), async (req, res) => {
  try {
    const result = await listUnits(req.bloodBankId, {
      bloodGroup: req.query.bloodGroup,
      componentType: req.query.componentType,
      status: req.query.status,
      page: Math.max(1, parseInt(req.query.page || '1', 10)),
      pageSize: Math.min(50, parseInt(req.query.pageSize || '20', 10)),
    });
    return sendSuccess(res, { data: result.units, pagination: result.pagination });
  } catch (err) {
    return handle(res, err, 'Failed to list units');
  }
});

router.post('/provider/inventory/units', bloodBankRequired, requireBloodPermission('inventory.write'), async (req, res) => {
  try {
    const result = await addUnits({
      ...req.body,
      bloodBankId: req.bloodBankId,
      ...actorFromAuth(req.auth),
    });
    emitBloodEvent('inventory_updated', { bloodBankId: req.bloodBankId });
    return sendSuccess(res, { message: 'Inventory added', data: result });
  } catch (err) {
    return handle(res, err, 'Failed to add inventory');
  }
});

router.patch('/provider/inventory/units/:id', bloodBankRequired, requireBloodPermission('inventory.write'), async (req, res) => {
  try {
    const unit = await updateUnit(req.params.id, req.body || {}, actorFromAuth(req.auth));
    emitBloodEvent('inventory_updated', { bloodBankId: req.bloodBankId });
    return sendSuccess(res, { message: 'Unit updated', data: unit });
  } catch (err) {
    return handle(res, err, 'Failed to update unit');
  }
});

router.get('/provider/donations', bloodBankRequired, async (req, res) => {
  try {
    const result = await listDonationsByBloodBank(req.bloodBankId, {
      page: Math.max(1, parseInt(req.query.page || '1', 10)),
      pageSize: Math.min(50, parseInt(req.query.pageSize || '20', 10)),
    });
    return sendSuccess(res, { data: result.donations, pagination: result.pagination });
  } catch (err) {
    return handle(res, err, 'Failed to list donations');
  }
});

router.post('/provider/donations', bloodBankRequired, requireBloodPermission('donations.write'), async (req, res) => {
  try {
    const donation = await recordDonation(
      { ...req.body, bloodBankId: req.bloodBankId },
      actorFromAuth(req.auth),
    );
    return sendSuccess(res, { message: 'Donation recorded', data: donation });
  } catch (err) {
    return handle(res, err, 'Failed to record donation');
  }
});

router.get('/provider/donors', bloodBankRequired, async (req, res) => {
  try {
    const result = await listDonorsForBloodBank({
      bloodGroup: req.query.bloodGroup,
      city: req.query.city,
      page: Math.max(1, parseInt(req.query.page || '1', 10)),
      pageSize: Math.min(50, parseInt(req.query.pageSize || '20', 10)),
    });
    return sendSuccess(res, { data: result.donors, pagination: result.pagination });
  } catch (err) {
    return handle(res, err, 'Failed to list donors');
  }
});

router.get('/provider/audit', bloodBankRequired, async (req, res) => {
  try {
    const result = await listAuditLogs({
      bloodBankId: req.bloodBankId,
      entityType: req.query.entityType,
      action: req.query.action,
      page: Math.max(1, parseInt(req.query.page || '1', 10)),
      pageSize: Math.min(50, parseInt(req.query.pageSize || '20', 10)),
    });
    return sendSuccess(res, { data: result.logs, pagination: result.pagination });
  } catch (err) {
    return handle(res, err, 'Failed to load audit log');
  }
});

router.get('/:id/availability', authOptional, async (req, res) => {
  try {
    const bank = await findBloodBankById(req.params.id);
    if (!bank) return sendError(res, 'Blood bank not found', 404);
    const inventory = await listInventoryByBloodBank(req.params.id);
    const isOwner = req.auth?.bloodBankId === req.params.id || req.auth?.type === 'admin';
    return sendSuccess(res, {
      data: isOwner ? inventory : toPublicInventory(inventory, bank),
    });
  } catch (err) {
    return handle(res, err, 'Failed to load availability');
  }
});

router.get('/bookings/:orderId/chat', authRequired, async (req, res) => {
  try {
    const { listChatMessages } = require('../db/chatRepositories');
    const messages = await listChatMessages(req.params.orderId, req.auth, {
      after: req.query.after,
    });
    return sendSuccess(res, { data: messages });
  } catch (err) {
    return handle(res, err, 'Failed to load chat');
  }
});

router.post('/bookings/:orderId/chat', authRequired, async (req, res) => {
  try {
    const { sendChatMessage } = require('../db/chatRepositories');
    const message = await sendChatMessage(req.params.orderId, req.auth, req.body?.body);
    emitBloodEvent('chat_message', {
      requestId: req.params.orderId,
      bookingId: req.params.orderId,
      patientId: req.auth.patientId,
      bloodBankId: req.auth.bloodBankId,
    });
    return sendSuccess(res, { data: message });
  } catch (err) {
    return handle(res, err, 'Failed to send message');
  }
});

router.get('/admin/analytics', adminRequired, async (_req, res) => {
  try {
    const start = new Date();
    start.setDate(start.getDate() - 30);
    const [
      totalBanks,
      verifiedBanks,
      pendingBanks,
      activeBanks,
      inventory,
      emergencyOpen,
      pendingRequests,
      completedRequests,
      donors,
      activeDonors,
      requestsOverTime,
      donationsOverTime,
      demand,
    ] = await Promise.all([
      BloodBank.countDocuments(),
      BloodBank.countDocuments({ verificationStatus: 'verified' }),
      BloodBank.countDocuments({
        verificationStatus: { $in: ['pending', 'under_review', 'verifier_approved'] },
      }),
      BloodBank.countDocuments({
        verificationStatus: 'verified',
        isDisabled: { $ne: true },
        isSuspended: { $ne: true },
      }),
      BloodInventory.aggregate([{ $group: { _id: null, total: { $sum: '$availableUnits' } } }]),
      EmergencyBloodRequest.countDocuments({
        status: { $in: ['open', 'emergency_requested', 'blood_bank_alerted', 'response_received'] },
      }),
      BloodOrder.countDocuments({
        status: { $in: ['pending', 'blood_bank_notified', 'under_review'] },
      }),
      BloodOrder.countDocuments({ status: { $in: ['completed', 'delivered', 'collected'] } }),
      DonorProfile.countDocuments(),
      DonorProfile.countDocuments({ active: true, availableForEmergency: true }),
      BloodOrder.aggregate([
        { $match: { createdAt: { $gte: start } } },
        {
          $group: {
            _id: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } },
            count: { $sum: 1 },
          },
        },
        { $sort: { _id: 1 } },
      ]),
      BloodDonation.aggregate([
        { $match: { createdAt: { $gte: start } } },
        {
          $group: {
            _id: { $dateToString: { format: '%Y-%m-%d', date: '$donationDate' } },
            count: { $sum: 1 },
          },
        },
        { $sort: { _id: 1 } },
      ]),
      BloodOrder.aggregate([
        { $group: { _id: '$bloodGroup', count: { $sum: 1 } } },
        { $sort: { count: -1 } },
      ]),
    ]);

    const availability = await BloodInventory.aggregate([
      { $group: { _id: '$bloodGroup', available: { $sum: '$availableUnits' } } },
      { $sort: { _id: 1 } },
    ]);
    const critical = availability.filter((g) => (g.available || 0) <= 2).map((g) => g._id);
    const completionRate =
      pendingRequests + completedRequests === 0
        ? 0
        : Math.round((completedRequests / (pendingRequests + completedRequests)) * 100);

    return sendSuccess(res, {
      data: {
        totals: {
          totalBloodBanks: totalBanks,
          verifiedBloodBanks: verifiedBanks,
          pendingVerification: pendingBanks,
          activeBloodBanks: activeBanks,
          totalInventory: inventory[0]?.total ?? 0,
          emergencyRequests: emergencyOpen,
          pendingRequests,
          completedRequests,
          registeredDonors: donors,
          activeDonors,
          criticalBloodGroups: critical,
          completionRate,
        },
        charts: {
          requestsOverTime,
          donationsOverTime,
          bloodGroupDemand: demand,
          bloodGroupAvailability: availability,
        },
      },
    });
  } catch (err) {
    return handle(res, err, 'Failed to load analytics');
  }
});

router.get('/admin/requests', adminRequired, async (req, res) => {
  try {
    const result = await listAllOrders({
      status: req.query.status,
      page: Math.max(1, parseInt(req.query.page || '1', 10)),
      pageSize: Math.min(50, parseInt(req.query.pageSize || '20', 10)),
    });
    return sendSuccess(res, { data: result.orders, pagination: result.pagination });
  } catch (err) {
    return handle(res, err, 'Failed to list requests');
  }
});

router.get('/admin/inventory', adminRequired, async (req, res) => {
  try {
    const filter = {};
    if (req.query.bloodGroup) filter.bloodGroup = req.query.bloodGroup;
    const page = Math.max(1, parseInt(req.query.page || '1', 10));
    const pageSize = Math.min(50, parseInt(req.query.pageSize || '20', 10));
    const totalCount = await BloodInventory.countDocuments(filter);
    const items = await BloodInventory.find(filter)
      .sort({ availableUnits: 1 })
      .skip((page - 1) * pageSize)
      .limit(pageSize)
      .lean();
    return sendSuccess(res, {
      data: items,
      pagination: {
        currentPage: page,
        totalPages: Math.max(1, Math.ceil(totalCount / pageSize)),
        pageSize,
        totalCount,
        hasNextPage: page * pageSize < totalCount,
      },
    });
  } catch (err) {
    return handle(res, err, 'Failed to list inventory');
  }
});

router.get('/admin/donors', adminRequired, async (req, res) => {
  try {
    const result = await listAllDonors({
      bloodGroup: req.query.bloodGroup,
      status: req.query.status,
      page: Math.max(1, parseInt(req.query.page || '1', 10)),
      pageSize: Math.min(50, parseInt(req.query.pageSize || '20', 10)),
    });
    return sendSuccess(res, { data: result.donors, pagination: result.pagination });
  } catch (err) {
    return handle(res, err, 'Failed to list donors');
  }
});

router.get('/admin/emergencies', adminRequired, async (req, res) => {
  try {
    const result = await listAllEmergencyRequests({
      status: req.query.status,
      page: Math.max(1, parseInt(req.query.page || '1', 10)),
      pageSize: Math.min(50, parseInt(req.query.pageSize || '20', 10)),
    });
    return sendSuccess(res, { data: result.requests, pagination: result.pagination });
  } catch (err) {
    return handle(res, err, 'Failed to list emergencies');
  }
});

router.post('/admin/:id/disable', adminRequired, async (req, res) => {
  try {
    const bank = await disableBloodBank(req.params.id, req.body?.reason);
    return sendSuccess(res, { message: 'Blood bank disabled', data: bank });
  } catch (err) {
    return handle(res, err, 'Failed to disable blood bank');
  }
});

router.post('/admin/:id/enable', adminRequired, async (req, res) => {
  try {
    const bank = await enableBloodBank(req.params.id);
    return sendSuccess(res, { message: 'Blood bank enabled', data: bank });
  } catch (err) {
    return handle(res, err, 'Failed to enable blood bank');
  }
});

module.exports = router;
