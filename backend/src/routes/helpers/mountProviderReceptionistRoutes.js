const { sendSuccess, sendError } = require('../../utils/response');
const { authRequired } = require('../../middleware/auth');
const {
  createReceptionist,
  listReceptionistsForOwner,
  updateReceptionist,
  setReceptionistStatus,
  deleteReceptionist,
  resetReceptionistPassword,
} = require('../../db/receptionistRepositories');

/**
 * Mounts receptionist CRUD on a provider router (lab / scan / blood bank).
 * @param {import('express').Router} router
 * @param {{
 *   ownerType: 'lab'|'scan'|'blood_bank',
 *   authType: string,
 *   ownerIdFromAuth: (auth: object|null|undefined) => string|undefined,
 *   authLabel: string,
 * }} options
 */
function mountProviderReceptionistRoutes(router, {
  ownerType,
  authType,
  ownerIdFromAuth,
  authLabel,
}) {
  function requireOwner(req, res) {
    const ownerId = ownerIdFromAuth(req.auth);
    if (req.auth?.type !== authType || !ownerId) {
      sendError(res, `${authLabel} authentication required`, 403);
      return null;
    }
    return { ownerType, ownerId };
  }

  router.get('/receptionists', authRequired, async (req, res) => {
    try {
      const owner = requireOwner(req, res);
      if (!owner) return;
      const data = await listReceptionistsForOwner(owner);
      return sendSuccess(res, { data });
    } catch (err) {
      console.error(err);
      return sendError(res, err.message || 'Failed to load receptionists', 500);
    }
  });

  router.post('/receptionists', authRequired, async (req, res) => {
    try {
      const owner = requireOwner(req, res);
      if (!owner) return;
      const data = await createReceptionist(owner, req.body || {});
      return sendSuccess(res, {
        statusCode: 201,
        message: 'Receptionist created',
        data,
      });
    } catch (err) {
      console.error(err);
      return sendError(
        res,
        err.message || 'Could not create receptionist',
        err.statusCode || 500,
      );
    }
  });

  router.patch('/receptionists/:receptionistId', authRequired, async (req, res) => {
    try {
      const owner = requireOwner(req, res);
      if (!owner) return;
      const data = await updateReceptionist(
        owner,
        req.params.receptionistId,
        req.body || {},
      );
      return sendSuccess(res, { message: 'Receptionist updated', data });
    } catch (err) {
      console.error(err);
      return sendError(
        res,
        err.message || 'Could not update receptionist',
        err.statusCode || 500,
      );
    }
  });

  router.patch(
    '/receptionists/:receptionistId/status',
    authRequired,
    async (req, res) => {
      try {
        const owner = requireOwner(req, res);
        if (!owner) return;
        const data = await setReceptionistStatus(
          owner,
          req.params.receptionistId,
          req.body?.status,
        );
        return sendSuccess(res, { message: 'Receptionist status updated', data });
      } catch (err) {
        console.error(err);
        return sendError(
          res,
          err.message || 'Could not update status',
          err.statusCode || 500,
        );
      }
    },
  );

  router.post(
    '/receptionists/:receptionistId/reset-password',
    authRequired,
    async (req, res) => {
      try {
        const owner = requireOwner(req, res);
        if (!owner) return;
        const data = await resetReceptionistPassword(
          owner,
          req.params.receptionistId,
          req.body?.password,
        );
        return sendSuccess(res, { message: 'Password updated', data });
      } catch (err) {
        console.error(err);
        return sendError(
          res,
          err.message || 'Could not reset password',
          err.statusCode || 500,
        );
      }
    },
  );

  router.delete('/receptionists/:receptionistId', authRequired, async (req, res) => {
    try {
      const owner = requireOwner(req, res);
      if (!owner) return;
      const data = await deleteReceptionist(owner, req.params.receptionistId);
      return sendSuccess(res, { message: 'Receptionist deleted', data });
    } catch (err) {
      console.error(err);
      return sendError(
        res,
        err.message || 'Could not delete receptionist',
        err.statusCode || 500,
      );
    }
  });
}

module.exports = { mountProviderReceptionistRoutes };
