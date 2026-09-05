const BloodBank = require('../db/models/BloodBank');
const BloodInventory = require('../db/models/BloodInventory');
const BloodInventoryUnit = require('../db/models/BloodInventoryUnit');
const { createAndPushNotification } = require('../db/notificationRepositories');
const { emitBloodEvent } = require('./bloodRealtime');

const alertCache = new Map();
const ALERT_TTL_MS = 6 * 60 * 60 * 1000;

function shouldAlert(key) {
  const last = alertCache.get(key);
  if (last && Date.now() - last < ALERT_TTL_MS) return false;
  alertCache.set(key, Date.now());
  return true;
}

async function emitInventoryAlerts() {
  const banks = await BloodBank.find({
    verificationStatus: 'verified',
    isDisabled: { $ne: true },
    isSuspended: { $ne: true },
  })
    .select('id institutionName lowStockThreshold criticalStockThreshold nearExpiryDays notificationPreferences')
    .lean();

  for (const bank of banks) {
    if (bank.notificationPreferences?.inventory === false) continue;
    const low = bank.lowStockThreshold ?? 5;
    const critical = bank.criticalStockThreshold ?? 2;
    const nearDays = bank.nearExpiryDays ?? 7;

    const entries = await BloodInventory.find({ bloodBankId: bank.id }).lean();
    for (const entry of entries) {
      const available = entry.availableUnits || 0;
      if (available <= critical && available > 0) {
        const key = `critical:${bank.id}:${entry.bloodGroup}:${entry.componentType || 'all'}`;
        if (shouldAlert(key)) {
          const body = `${entry.bloodGroup} blood stock is critically low.`;
          await createAndPushNotification({
            userId: bank.id,
            userType: 'bloodbank',
            title: 'Critical blood stock',
            body,
            type: 'blood_inventory',
            data: { bloodGroup: entry.bloodGroup, level: 'critical' },
          });
          emitBloodEvent('inventory_critical', {
            bloodBankId: bank.id,
            bloodGroup: entry.bloodGroup,
            availableUnits: available,
          });
        }
      } else if (available <= low && available > 0) {
        const key = `low:${bank.id}:${entry.bloodGroup}:${entry.componentType || 'all'}`;
        if (shouldAlert(key)) {
          await createAndPushNotification({
            userId: bank.id,
            userType: 'bloodbank',
            title: 'Low blood stock',
            body: `${entry.bloodGroup} blood stock is running low.`,
            type: 'blood_inventory',
            data: { bloodGroup: entry.bloodGroup, level: 'low' },
          });
          emitBloodEvent('inventory_low', {
            bloodBankId: bank.id,
            bloodGroup: entry.bloodGroup,
            availableUnits: available,
          });
        }
      }
    }

    const soon = new Date(Date.now() + nearDays * 24 * 60 * 60 * 1000);
    const nearExpiry = await BloodInventoryUnit.countDocuments({
      bloodBankId: bank.id,
      status: 'available',
      expiryDate: { $lte: soon, $gt: new Date() },
    });
    if (nearExpiry > 0) {
      const key = `expiry:${bank.id}`;
      if (shouldAlert(key)) {
        await createAndPushNotification({
          userId: bank.id,
          userType: 'bloodbank',
          title: 'Units approaching expiry',
          body: `${nearExpiry} unit(s) are approaching expiry.`,
          type: 'blood_inventory',
          data: { nearExpiry },
        });
      }
    }
  }
}

module.exports = { emitInventoryAlerts };
