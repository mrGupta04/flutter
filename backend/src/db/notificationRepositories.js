const { v4: uuidv4 } = require('uuid');
const Notification = require('./models/Notification');
const Patient = require('./models/Patient');
const Doctor = require('./models/Doctor');
const Nurse = require('./models/Nurse');
const { sendPushNotification } = require('../services/pushNotificationService');
const { normalizeMobile } = require('../utils/mobile');
const {
  notificationCategory,
  isNotificationCategoryEnabled,
} = require('../utils/notificationCategory');

const NOTIFICATION_TYPES = new Set([
  'booking_approved',
  'booking_rejected',
  'payment_due',
  'visit_reminder',
  'en_route',
  'prescription_ready',
  'visit_note_ready',
  'chat_message',
  'booking_cancelled',
  'booking_rescheduled',
  'home_visit_request',
  'arrived',
  'visit_started',
  'visit_completed',
  'visit_completion_otp',
  'nursing_report_ready',
  'prescription_request',
  'prescription_quotation',
  'prescription_selected',
  'prescription_quote',
  'prescription_paid',
  'payment_expired',
  'payment_failed',
  'booking_confirmed',
  'blood_request',
  'emergency_blood',
  'blood_inventory',
  'blood_donor',
  'ambulance_emergency',
  'ambulance_assigned',
  'ambulance_update',
  'general',
]);

function safeNotificationType(type) {
  const value = String(type || 'general').trim();
  return NOTIFICATION_TYPES.has(value) ? value : 'general';
}

async function resolvePatientId(booking = {}) {
  if (booking.patientId) {
    const existing = await Patient.findOne({ id: String(booking.patientId) })
      .select('id')
      .lean();
    if (existing?.id) return existing.id;
  }

  const mobile = normalizeMobile(booking.patientMobile);
  if (mobile.length === 10) {
    const byMobile = await Patient.findOne({ mobileNumber: mobile })
      .select('id')
      .lean();
    if (byMobile?.id) return byMobile.id;
  }

  const email = String(booking.patientEmail || '')
    .trim()
    .toLowerCase();
  if (email) {
    const byEmail = await Patient.findOne({ email }).select('id').lean();
    if (byEmail?.id) return byEmail.id;
  }

  return null;
}

async function attachPatientId(booking) {
  if (!booking) return null;
  const patientId = await resolvePatientId(booking);
  if (!patientId) return null;
  if (String(booking.patientId || '') !== patientId) {
    booking.patientId = patientId;
    if (typeof booking.save === 'function') {
      try {
        await booking.save();
      } catch (err) {
        console.warn('[Notify] persist patientId failed:', err.message);
      }
    }
  }
  return patientId;
}

function emitRealtime(userType, userId, payload) {
  try {
    const { emitToUser, emitToBooking } = require('../services/trackingSocket');
    emitToUser(userType, userId, 'app_notification', payload);
    emitToUser(userType, userId, 'booking-notification', payload);
    const bookingId = payload?.data?.bookingId;
    if (bookingId) {
      emitToBooking(bookingId, 'app_notification', payload);
      emitToBooking(bookingId, 'booking-notification', payload);
    }
  } catch (err) {
    console.warn('[Notify] realtime emit failed:', err.message);
  }
}

async function createAndPushNotification({
  userId,
  userType,
  title,
  body,
  type = 'general',
  data = {},
}) {
  if (!userId) {
    console.warn('[Notify] skipped — missing userId', { userType, title });
    return null;
  }

  const safeType = safeNotificationType(type);
  let notification;
  try {
    notification = await Notification.create({
      id: uuidv4(),
      userId,
      userType,
      title,
      body,
      type: safeType,
      data,
    });
  } catch (err) {
    if (err?.name === 'ValidationError' && safeType !== 'general') {
      notification = await Notification.create({
        id: uuidv4(),
        userId,
        userType,
        title,
        body,
        type: 'general',
        data,
      });
    } else {
      throw err;
    }
  }

  const payload = {
    id: notification.id,
    title,
    body,
    type: notification.type,
    category: notificationCategory(notification.type),
    data,
    createdAt: notification.createdAt,
  };
  emitRealtime(userType, userId, payload);

  let deviceTokens = [];
  let allowPush = true;
  if (userType === 'patient') {
    const patient = await Patient.findOne({ id: userId }).lean();
    deviceTokens = patient?.fcmTokens || [];
    allowPush = isNotificationCategoryEnabled(
      patient?.notificationSettings,
      payload.category,
    );
  } else if (userType === 'doctor') {
    const doctor = await Doctor.findOne({ id: userId }).lean();
    deviceTokens = doctor?.fcmTokens || [];
  } else if (userType === 'nurse') {
    const nurse = await Nurse.findOne({ id: userId }).lean();
    deviceTokens = nurse?.fcmTokens || [];
  } else if (userType === 'bloodbank') {
    const BloodBank = require('./models/BloodBank');
    const bank = await BloodBank.findOne({ id: userId }).lean();
    deviceTokens = bank?.fcmTokens || [];
  } else if (userType === 'ambulance' || userType === 'ambulance_driver') {
    const Ambulance = require('./models/Ambulance');
    const service = await Ambulance.findOne({ id: userId }).lean();
    deviceTokens = service?.fcmTokens || [];
  }

  try {
    if (allowPush && deviceTokens.length) {
      const pushResult = await sendPushNotification({
        userId,
        title,
        body,
        data: {
          ...data,
          type: notification.type,
          notificationId: notification.id,
          userType,
          deviceTokens,
          deviceToken: deviceTokens[0],
        },
      });

      if (pushResult?.invalidTokens?.length) {
        await removeDeviceTokens(userId, userType, pushResult.invalidTokens);
      }
    }
  } catch (err) {
    console.error('[Notify] FCM send failed:', err.message);
  }

  return notification.toObject();
}

async function notifyPatient(booking, { title, body, type, data = {} } = {}) {
  const userId = await attachPatientId(booking);
  if (!userId) {
    console.warn(
      '[Notify] no patient account for booking',
      booking?.id || booking?._id,
      booking?.patientMobile,
    );
    return null;
  }
  return createAndPushNotification({
    userId,
    userType: 'patient',
    title,
    body,
    type,
    data: {
      bookingId: booking.id,
      ...data,
    },
  });
}

async function listNotifications(
  userId,
  userType,
  { limit = 50, unreadOnly = false, category } = {},
) {
  const filter = { userId, userType };
  if (unreadOnly) filter.readAt = null;

  const rows = await Notification.find(filter)
    .sort({ createdAt: -1 })
    .limit(Math.min(100, Math.max(1, Number(limit) || 50)))
    .lean();

  const unreadCount = await Notification.countDocuments({
    userId,
    userType,
    readAt: null,
  });

  let notifications = rows.map((row) => ({
    id: row.id,
    title: row.title,
    body: row.body,
    type: row.type,
    category: notificationCategory(row.type),
    data: row.data || {},
    createdAt: row.createdAt,
    readAt: row.readAt,
  }));
  const wanted = String(category || '').trim();
  if (wanted && wanted !== 'all') {
    notifications = notifications.filter((item) => item.category === wanted);
  }

  return {
    notifications,
    unreadCount,
  };
}

async function markNotificationRead(notificationId, userId) {
  const row = await Notification.findOneAndUpdate(
    { id: notificationId, userId },
    { $set: { readAt: new Date() } },
    { new: true },
  ).lean();
  if (!row) {
    const err = new Error('Notification not found');
    err.statusCode = 404;
    throw err;
  }
  return row;
}

async function markAllNotificationsRead(userId, userType) {
  await Notification.updateMany(
    { userId, userType, readAt: null },
    { $set: { readAt: new Date() } },
  );
  return { success: true };
}

function modelForUserType(userType) {
  if (userType === 'patient') return Patient;
  if (userType === 'doctor') return Doctor;
  if (userType === 'nurse') return Nurse;
  if (userType === 'ambulance' || userType === 'ambulance_driver') {
    return require('./models/Ambulance');
  }
  if (userType === 'bloodbank') {
    return require('./models/BloodBank');
  }
  return null;
}

async function registerDeviceToken(userId, userType, token) {
  const clean = String(token || '').trim();
  if (!clean) {
    const err = new Error('Device token is required');
    err.statusCode = 400;
    throw err;
  }

  const Model = modelForUserType(userType);
  if (!Model) {
    const err = new Error('Unsupported user type for device token');
    err.statusCode = 400;
    throw err;
  }

  if (clean.startsWith('dev_') || clean.startsWith('dev:')) {
    return { success: true, placeholder: true };
  }

  const existing = await Model.findOne({ id: userId }).select('fcmTokens').lean();
  const next = [
    ...new Set(
      (existing?.fcmTokens || []).filter(
        (item) =>
          item &&
          !String(item).startsWith('dev_') &&
          !String(item).startsWith('dev:'),
      ),
    ),
    clean,
  ];
  await Model.updateOne({ id: userId }, { $set: { fcmTokens: next } });
  return { success: true };
}

async function removeDeviceTokens(userId, userType, tokens) {
  const Model = modelForUserType(userType);
  const list = (tokens || []).map(String).filter(Boolean);
  if (!Model || !userId || list.length === 0) return;
  await Model.updateOne({ id: userId }, { $pull: { fcmTokens: { $in: list } } });
}

module.exports = {
  createAndPushNotification,
  notifyPatient,
  resolvePatientId,
  attachPatientId,
  listNotifications,
  markNotificationRead,
  markAllNotificationsRead,
  registerDeviceToken,
  removeDeviceTokens,
};
