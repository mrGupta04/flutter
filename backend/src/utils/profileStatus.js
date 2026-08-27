const { isAdminPayload, isApproverPayload } = require('../middleware/auth');

const PROFILE_STATUS = {
  ACTIVE: 'ACTIVE',
  DISABLED: 'DISABLED',
};

function normalizeProfileStatus(value) {
  return String(value || '').toUpperCase() === PROFILE_STATUS.DISABLED
    ? PROFILE_STATUS.DISABLED
    : PROFILE_STATUS.ACTIVE;
}

function isProfileDisabled(entity) {
  return normalizeProfileStatus(entity?.profileStatus) === PROFILE_STATUS.DISABLED;
}

function activeProfileFilter() {
  return { profileStatus: { $ne: PROFILE_STATUS.DISABLED } };
}

function canAccessDisabledProvider(auth, providerId, role) {
  if (!auth) return false;
  if (isAdminPayload(auth) || isApproverPayload(auth)) return true;
  if (role === 'doctor' && auth.doctorId && auth.doctorId === providerId) {
    return true;
  }
  if (role === 'nurse' && auth.nurseId && auth.nurseId === providerId) {
    return true;
  }
  return false;
}

function shouldHideDisabledProvider(provider, auth, providerId, role) {
  return (
    isProfileDisabled(provider) &&
    !canAccessDisabledProvider(auth, providerId, role)
  );
}

function disabledBookingError(label = 'provider') {
  const err = new Error(
    `This ${label} is currently not accepting new bookings`,
  );
  err.statusCode = 403;
  return err;
}

function assertProfileActive(entity, label = 'provider') {
  if (isProfileDisabled(entity)) {
    throw disabledBookingError(label);
  }
}

module.exports = {
  PROFILE_STATUS,
  normalizeProfileStatus,
  isProfileDisabled,
  activeProfileFilter,
  canAccessDisabledProvider,
  shouldHideDisabledProvider,
  disabledBookingError,
  assertProfileActive,
};
