const CATEGORY_MAP = {
  ambulance_emergency: 'emergency',
  emergency_blood: 'emergency',
  blood_request: 'emergency',
  payment_due: 'payment',
  payment_expired: 'payment',
  payment_failed: 'payment',
  prescription_paid: 'payment',
  chat_message: 'provider',
  booking_approved: 'booking',
  booking_rejected: 'booking',
  booking_cancelled: 'booking',
  booking_rescheduled: 'booking',
  booking_confirmed: 'booking',
  visit_reminder: 'booking',
  home_visit_request: 'booking',
  en_route: 'booking',
  arrived: 'booking',
  visit_started: 'booking',
  visit_completed: 'booking',
  visit_completion_otp: 'booking',
  visit_note_ready: 'booking',
  nursing_report_ready: 'booking',
  prescription_ready: 'booking',
  prescription_request: 'booking',
  prescription_quotation: 'booking',
  prescription_selected: 'booking',
  prescription_quote: 'booking',
  ambulance_assigned: 'booking',
  ambulance_update: 'booking',
  blood_inventory: 'system',
  blood_donor: 'system',
  general: 'system',
};

function notificationCategory(type) {
  const value = String(type || 'general').trim();
  if (CATEGORY_MAP[value]) return CATEGORY_MAP[value];
  if (value.startsWith('payment_')) return 'payment';
  if (value.startsWith('ambulance_') && value.includes('emergency')) {
    return 'emergency';
  }
  if (
    value.startsWith('booking_') ||
    value.startsWith('visit_') ||
    value.startsWith('ambulance_') ||
    value.startsWith('prescription_')
  ) {
    return 'booking';
  }
  return 'system';
}

const DEFAULT_NOTIFICATION_SETTINGS = {
  booking: true,
  payment: true,
  provider: true,
  emergency: true,
  system: true,
};

function normalizeNotificationSettings(input = {}) {
  return {
    booking: input.booking !== false,
    payment: input.payment !== false,
    provider: input.provider !== false,
    emergency: true,
    system: input.system !== false,
  };
}

function isNotificationCategoryEnabled(settings, category) {
  const normalized = normalizeNotificationSettings(settings);
  if (category === 'emergency') return true;
  return normalized[category] !== false;
}

module.exports = {
  notificationCategory,
  DEFAULT_NOTIFICATION_SETTINGS,
  normalizeNotificationSettings,
  isNotificationCategoryEnabled,
};
