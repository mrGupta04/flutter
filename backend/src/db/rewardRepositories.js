const Patient = require('./models/Patient');

function normalizeReferralCode(code) {
  return String(code || '')
    .trim()
    .toUpperCase();
}

function buildReferralCodeFromId(patientId) {
  const cleaned = String(patientId || '').replace(/-/g, '');
  const suffix = cleaned.slice(-6).toUpperCase() || 'XXXXXX';
  return `CARE${suffix}`;
}

async function getRewardsSummary(patientId) {
  const doc = await Patient.findOne({ id: patientId });
  if (!doc) {
    const err = new Error('Patient not found');
    err.statusCode = 404;
    throw err;
  }
  if (!doc.referralCode) {
    doc.referralCode = buildReferralCodeFromId(doc.id);
    await doc.save();
  }
  return {
    rewardPoints: doc.rewardPoints || 0,
    referralCode: doc.referralCode || null,
    referredByCode: doc.referredByCode || null,
  };
}

async function applyReferralOnRegister(patientId, referralCodeInput) {
  const code = normalizeReferralCode(referralCodeInput);
  if (!code) return;

  const patient = await Patient.findOne({ id: patientId });
  if (!patient) return;

  if (patient.referredByCode) return;

  const referrer = await Patient.findOne({ referralCode: code });
  if (!referrer || referrer.id === patientId) {
    const err = new Error('Invalid referral code');
    err.statusCode = 400;
    throw err;
  }

  patient.referredByCode = code;
  patient.rewardPoints = (patient.rewardPoints || 0) + 50;
  await patient.save();

  referrer.rewardPoints = (referrer.rewardPoints || 0) + 100;
  await referrer.save();
}

async function awardBookingPoints(patientId, amount = 20) {
  if (!patientId) return null;
  const points = Number(amount) || 20;
  if (points <= 0) return null;

  const doc = await Patient.findOneAndUpdate(
    { id: patientId },
    { $inc: { rewardPoints: points } },
    { new: true },
  );
  return doc
    ? { patientId: doc.id, rewardPoints: doc.rewardPoints || 0 }
    : null;
}

async function redeemRewardPoints(patientId, points = 100) {
  const needed = Math.max(100, Number(points) || 100);
  const patient = await Patient.findOne({ id: patientId });
  if (!patient) {
    const err = new Error('Patient not found');
    err.statusCode = 404;
    throw err;
  }

  const current = patient.rewardPoints || 0;
  if (current < needed) {
    const err = new Error(`Need at least ${needed} points to redeem`);
    err.statusCode = 400;
    throw err;
  }

  patient.rewardPoints = current - needed;
  await patient.save();

  return {
    rewardPoints: patient.rewardPoints,
    message: `Redeemed ${needed} points. A care voucher will be emailed to you soon.`,
  };
}

module.exports = {
  buildReferralCodeFromId,
  getRewardsSummary,
  applyReferralOnRegister,
  awardBookingPoints,
  redeemRewardPoints,
  normalizeReferralCode,
};
