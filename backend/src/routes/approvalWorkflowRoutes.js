const express = require('express');
const { rateLimit } = require('express-rate-limit');
const { signToken } = require('../middleware/auth');
const {
  approvalAdminRequired,
  approvalUserRequired,
} = require('../middleware/auth');
const { sendSuccess, sendError } = require('../utils/response');
const {
  actorFromRequest,
  listApprovers,
  createApprover,
  updateApprover,
  setApproverStatus,
  resetApproverPassword,
  deleteApprover,
  loginApprover,
  createApproverSession,
  refreshApproverSession,
  revokeApproverSession,
  listApprovalRequests,
  listEligibleApprovers,
  getApprovalRequestById,
  assignApprovalRequest,
  actionApprovalRequest,
  markApprovalRequestViewed,
  getApprovalDashboard,
  getApproverPerformance,
  listAuditLogs,
  getApprovalConfig,
  updateApprovalConfig,
  buildApprovalReport,
  listApprovalNotifications,
  markApprovalNotificationRead,
  markAllApprovalNotificationsRead,
  listSavedFilters,
  createSavedFilter,
  deleteSavedFilter,
} = require('../db/approvalWorkflowRepositories');

const router = express.Router();
const approverAuthLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 10,
  standardHeaders: 'draft-8',
  legacyHeaders: false,
  skipSuccessfulRequests: true,
  message: {
    success: false,
    error: 'Too many authentication attempts. Please try again later.',
    statusCode: 429,
  },
});

function pageParams(query, defaultPageSize = 50) {
  const requestedPage = Number.parseInt(query.page, 10);
  const requestedPageSize = Number.parseInt(query.pageSize, 10);
  return {
    page: Number.isFinite(requestedPage) ? Math.max(1, requestedPage) : 1,
    pageSize: Number.isFinite(requestedPageSize)
      ? Math.max(1, Math.min(200, requestedPageSize))
      : defaultPageSize,
  };
}

function routeError(res, err, fallback) {
  console.error(err);
  return sendError(res, err.message || fallback, err.statusCode || 500);
}

router.post(
  '/approval-management/approver-login',
  approverAuthLimiter,
  async (req, res) => {
  try {
    const { email, password } = req.body || {};
    if (!email || !password) {
      return sendError(res, 'Email and password are required', 400);
    }
    const approver = await loginApprover({ email, password }, { req });
    const session = await createApproverSession(approver, { req });
    const token = signToken(
      {
        type: 'approver',
        role: 'approver',
        approverId: approver.id,
        email: approver.email,
        name: approver.name,
        permissions: approver.permissions,
        sessionId: session.sessionId,
      },
      '15m',
    );
    return sendSuccess(res, {
      message: 'Login successful',
      data: {
        token,
        refreshToken: session.refreshToken,
        sessionId: session.sessionId,
        refreshTokenExpiresAt: session.expiresAt,
        approver,
      },
    });
  } catch (err) {
    return routeError(res, err, 'Failed to login approver');
  }
  },
);

router.post('/approval-management/approver-refresh', approverAuthLimiter, async (req, res) => {
  try {
    const session = await refreshApproverSession(req.body || {}, { req });
    const approver = session.approver;
    const token = signToken(
      {
        type: 'approver',
        role: 'approver',
        approverId: approver.id,
        email: approver.email,
        name: approver.name,
        permissions: approver.permissions,
        sessionId: session.sessionId,
      },
      '15m',
    );
    return sendSuccess(res, {
      message: 'Session refreshed',
      data: {
        token,
        refreshToken: session.refreshToken,
        sessionId: session.sessionId,
        refreshTokenExpiresAt: session.expiresAt,
        approver,
      },
    });
  } catch (err) {
    return routeError(res, err, 'Failed to refresh approver session');
  }
});

router.post(
  '/approval-management/approver-logout',
  approvalUserRequired,
  async (req, res) => {
    try {
      if (req.auth?.role !== 'approver' || !req.auth?.sessionId) {
        return sendError(res, 'Approver session required', 400);
      }
      await revokeApproverSession(req.auth.sessionId, { req });
      return sendSuccess(res, { message: 'Logout successful' });
    } catch (err) {
      return routeError(res, err, 'Failed to logout approver');
    }
  },
);

router.get('/approval-management/dashboard', approvalUserRequired, async (req, res) => {
  try {
    const data = await getApprovalDashboard(actorFromRequest(req));
    return sendSuccess(res, { data });
  } catch (err) {
    return routeError(res, err, 'Failed to load approval dashboard');
  }
});

router.get('/approval-management/approvers', approvalAdminRequired, async (req, res) => {
  try {
    const { page, pageSize } = pageParams(req.query);
    const data = await listApprovers({
      page,
      pageSize,
      status: req.query.status,
      search: req.query.q || req.query.search,
    });
    return sendSuccess(res, { data: data.approvers, pagination: data.pagination });
  } catch (err) {
    return routeError(res, err, 'Failed to list approvers');
  }
});

router.post('/approval-management/approvers', approvalAdminRequired, async (req, res) => {
  try {
    const approver = await createApprover(req.body || {}, { req });
    return sendSuccess(res, {
      message: 'Approver created',
      data: approver,
      statusCode: 201,
    });
  } catch (err) {
    return routeError(res, err, 'Failed to create approver');
  }
});

router.put('/approval-management/approvers/:id', approvalAdminRequired, async (req, res) => {
  try {
    const approver = await updateApprover(req.params.id, req.body || {}, { req });
    return sendSuccess(res, { message: 'Approver updated', data: approver });
  } catch (err) {
    return routeError(res, err, 'Failed to update approver');
  }
});

router.patch(
  '/approval-management/approvers/:id/status',
  approvalAdminRequired,
  async (req, res) => {
    try {
      const approver = await setApproverStatus(req.params.id, req.body?.status, {
        req,
        reason: req.body?.reason,
      });
      return sendSuccess(res, { message: 'Approver status updated', data: approver });
    } catch (err) {
      return routeError(res, err, 'Failed to update approver status');
    }
  },
);

router.post(
  '/approval-management/approvers/:id/reset-password',
  approvalAdminRequired,
  async (req, res) => {
    try {
      const data = await resetApproverPassword(req.params.id, req.body || {}, { req });
      return sendSuccess(res, { message: 'Approver password reset', data });
    } catch (err) {
      return routeError(res, err, 'Failed to reset approver password');
    }
  },
);

router.delete('/approval-management/approvers/:id', approvalAdminRequired, async (req, res) => {
  try {
    await deleteApprover(req.params.id, { req, reason: req.body?.reason });
    return sendSuccess(res, { message: 'Approver deleted' });
  } catch (err) {
    return routeError(res, err, 'Failed to delete approver');
  }
});

router.get(
  '/approval-management/approvers/:id/performance',
  approvalAdminRequired,
  async (req, res) => {
    try {
      const data = await getApproverPerformance(req.params.id);
      return sendSuccess(res, { data });
    } catch (err) {
      return routeError(res, err, 'Failed to load approver performance');
    }
  },
);

router.get('/approval-management/requests', approvalUserRequired, async (req, res) => {
  try {
    const { page, pageSize } = pageParams(req.query);
    const actor = actorFromRequest(req);
    const data = await listApprovalRequests({
      page,
      pageSize,
      status: req.query.status,
      providerType: req.query.providerType,
      category: req.query.category,
      approverId: req.query.approverId,
      city: req.query.city,
      state: req.query.state,
      priority: req.query.priority,
      search: req.query.q || req.query.search,
      registrationFrom: req.query.registrationFrom,
      registrationTo: req.query.registrationTo,
      sort: req.query.sort || '-updatedAt',
      actor,
    });
    return sendSuccess(res, { data: data.requests, pagination: data.pagination });
  } catch (err) {
    return routeError(res, err, 'Failed to list approval requests');
  }
});

router.get('/approval-management/requests/:id', approvalUserRequired, async (req, res) => {
  try {
    const request = await getApprovalRequestById(req.params.id, { req });
    return sendSuccess(res, { data: request });
  } catch (err) {
    return routeError(res, err, 'Failed to load approval request');
  }
});

router.get(
  '/approval-management/requests/:id/eligible-approvers',
  approvalUserRequired,
  async (req, res) => {
    try {
      const data = await listEligibleApprovers(req.params.id, { req });
      return sendSuccess(res, { data });
    } catch (err) {
      return routeError(res, err, 'Failed to list eligible approvers');
    }
  },
);

router.post(
  '/approval-management/requests/:id/view',
  approvalUserRequired,
  async (req, res) => {
    try {
      const request = await markApprovalRequestViewed(req.params.id, { req });
      return sendSuccess(res, { message: 'Provider viewed', data: request });
    } catch (err) {
      return routeError(res, err, 'Failed to mark request as viewed');
    }
  },
);

router.post(
  '/approval-management/requests/:id/assign',
  approvalUserRequired,
  async (req, res) => {
    try {
      const request = await assignApprovalRequest(
        req.params.id,
        {
          approverId: req.body?.approverId,
          strategy: req.body?.strategy || 'manual',
          remarks: req.body?.remarks,
        },
        { req },
      );
      return sendSuccess(res, { message: 'Approval request assigned', data: request });
    } catch (err) {
      return routeError(res, err, 'Failed to assign approval request');
    }
  },
);

router.post(
  '/approval-management/requests/:id/action',
  approvalUserRequired,
  async (req, res) => {
    try {
      const request = await actionApprovalRequest(
        req.params.id,
        {
          action: req.body?.action,
          remarks: req.body?.remarks,
          reassignToApproverId: req.body?.reassignToApproverId,
        },
        { req },
      );
      return sendSuccess(res, { message: 'Approval action recorded', data: request });
    } catch (err) {
      return routeError(res, err, 'Failed to record approval action');
    }
  },
);

router.get('/approval-management/audit-logs', approvalAdminRequired, async (req, res) => {
  try {
    const { page, pageSize } = pageParams(req.query);
    const data = await listAuditLogs({
      page,
      pageSize,
      action: req.query.action,
      actorRole: req.query.actorRole,
      entityType: req.query.entityType,
      search: req.query.q || req.query.search,
      dateFrom: req.query.dateFrom,
      dateTo: req.query.dateTo,
    });
    return sendSuccess(res, { data: data.logs, pagination: data.pagination });
  } catch (err) {
    return routeError(res, err, 'Failed to list audit logs');
  }
});

router.get('/approval-management/config', approvalAdminRequired, async (_req, res) => {
  try {
    const data = await getApprovalConfig();
    return sendSuccess(res, { data });
  } catch (err) {
    return routeError(res, err, 'Failed to load approval config');
  }
});

router.put('/approval-management/config', approvalAdminRequired, async (req, res) => {
  try {
    const data = await updateApprovalConfig(req.body || {}, { req });
    return sendSuccess(res, { message: 'Approval configuration updated', data });
  } catch (err) {
    return routeError(res, err, 'Failed to update approval config');
  }
});

router.get('/approval-management/reports', approvalAdminRequired, async (req, res) => {
  try {
    const data = await buildApprovalReport({
      period: req.query.period || 'monthly',
      format: req.query.format,
    });
    return sendSuccess(res, { data });
  } catch (err) {
    return routeError(res, err, 'Failed to generate approval report');
  }
});

router.get(
  '/approval-management/notifications',
  approvalUserRequired,
  async (req, res) => {
    try {
      const { page, pageSize } = pageParams(req.query, 30);
      const data = await listApprovalNotifications(actorFromRequest(req), {
        page,
        pageSize,
        unreadOnly:
          req.query.unreadOnly === 'true' || req.query.unreadOnly === '1',
      });
      return sendSuccess(res, {
        data: data.notifications,
        pagination: data.pagination,
        meta: { unreadCount: data.unreadCount },
      });
    } catch (err) {
      return routeError(res, err, 'Failed to list notifications');
    }
  },
);

router.post(
  '/approval-management/notifications/read-all',
  approvalUserRequired,
  async (req, res) => {
    try {
      const data = await markAllApprovalNotificationsRead(actorFromRequest(req));
      return sendSuccess(res, { message: 'Notifications marked as read', data });
    } catch (err) {
      return routeError(res, err, 'Failed to mark notifications as read');
    }
  },
);

router.post(
  '/approval-management/notifications/:id/read',
  approvalUserRequired,
  async (req, res) => {
    try {
      const data = await markApprovalNotificationRead(
        req.params.id,
        actorFromRequest(req),
      );
      return sendSuccess(res, { message: 'Notification marked as read', data });
    } catch (err) {
      return routeError(res, err, 'Failed to mark notification as read');
    }
  },
);

router.get(
  '/approval-management/saved-filters',
  approvalUserRequired,
  async (req, res) => {
    try {
      const data = await listSavedFilters(actorFromRequest(req), {
        scope: req.query.scope,
      });
      return sendSuccess(res, { data });
    } catch (err) {
      return routeError(res, err, 'Failed to list saved filters');
    }
  },
);

router.post(
  '/approval-management/saved-filters',
  approvalUserRequired,
  async (req, res) => {
    try {
      const data = await createSavedFilter(req.body || {}, { req });
      return sendSuccess(res, {
        message: 'Saved filter created',
        data,
        statusCode: 201,
      });
    } catch (err) {
      return routeError(res, err, 'Failed to create saved filter');
    }
  },
);

router.delete(
  '/approval-management/saved-filters/:id',
  approvalUserRequired,
  async (req, res) => {
    try {
      await deleteSavedFilter(req.params.id, { req });
      return sendSuccess(res, { message: 'Saved filter deleted' });
    } catch (err) {
      return routeError(res, err, 'Failed to delete saved filter');
    }
  },
);

module.exports = router;
