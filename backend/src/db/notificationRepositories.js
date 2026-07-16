const { v4: uuidv4 } = require('uuid');
const Notification = require('./models/Notification');
const Patient = require('./models/Patient');
const Doctor = require('./models/Doctor');
const Nurse = require('./models/Nurse');
const { sendPushNotification } = require('../services/pushNotificationService');

async function createAndPushNotification({
  userId,
  userType,
  title,
  body,
  type = 'general',
  data = {},
}) {
  const notification = await Notification.create({
    id: uuidv4(),
    userId,
    userType,
    title,
    body,
    type,
    data,
  });

  let deviceTokens = [];
  if (userType === 'patient') {
    const patient = await Patient.findOne({ id: userId }).lean();
    deviceTokens = patient?.fcmTokens || [];
  } else if (userType === 'doctor') {
    const doctor = await Doctor.findOne({ id: userId }).lean();
    deviceTokens = doctor?.fcmTokens || [];
  } else if (userType === 'nurse') {
    const nurse = await Nurse.findOne({ id: userId }).lean();
    deviceTokens = nurse?.fcmTokens || [];
  }

  await sendPushNotification({
    userId,
    title,
    body,
    data: {
      ...data,
      type,
      notificationId: notification.id,
      deviceTokens,
      deviceToken: deviceTokens[0],
    },
  });

  return notification.toObject();
}

async function listNotifications(userId, userType, { limit = 50, unreadOnly = false } = {}) {
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

  return {
    notifications: rows,
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

async function registerDeviceToken(userId, userType, token) {
  const clean = String(token || '').trim();
  if (!clean) {
    const err = new Error('Device token is required');
    err.statusCode = 400;
    throw err;
  }

  const Model =
    userType === 'patient' ? Patient : userType === 'doctor' ? Doctor : Nurse;
  const idField =
    userType === 'patient' ? 'id' : userType === 'doctor' ? 'id' : 'id';

  await Model.updateOne(
    { [idField]: userId },
    { $addToSet: { fcmTokens: clean } },
  );
  return { success: true };
}

module.exports = {
  createAndPushNotification,
  listNotifications,
  markNotificationRead,
  markAllNotificationsRead,
  registerDeviceToken,
};
