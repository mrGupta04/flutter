const BloodBank = require('../db/models/BloodBank');
const BloodInventory = require('../db/models/BloodInventory');
const { getCompatibleDonorGroups } = require('./bloodCompatibilityService');

function haversineKm(lat1, lon1, lat2, lon2) {
  if ([lat1, lon1, lat2, lon2].some((v) => v == null)) return null;
  const R = 6371;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLng = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLng / 2) ** 2;
  return Math.round(R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a)) * 10) / 10;
}

async function findEligibleBloodBanks({
  bloodGroup,
  componentType,
  units = 1,
  city,
  latitude,
  longitude,
  emergencyOnly = false,
  limit = 20,
}) {
  const compatible = await getCompatibleDonorGroups(bloodGroup);
  const filter = {
    verificationStatus: 'verified',
    isSuspended: { $ne: true },
    isDisabled: { $ne: true },
  };
  if (emergencyOnly) {
    filter.emergencyBloodSupply = true;
    filter.emergencyRequestEnabled = { $ne: false };
  }
  if (city) {
    filter.city = new RegExp(String(city).replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'i');
  }

  const banks = await BloodBank.find(filter).lean();
  const inventory = await BloodInventory.find({
    bloodBankId: { $in: banks.map((b) => b.id) },
    bloodGroup: { $in: compatible },
  }).lean();

  const inventoryByBank = new Map();
  for (const entry of inventory) {
    const key = entry.bloodBankId;
    const list = inventoryByBank.get(key) || [];
    list.push(entry);
    inventoryByBank.set(key, list);
  }

  return banks
    .map((bank) => {
      const entries = (inventoryByBank.get(bank.id) || []).filter((entry) => {
        if (componentType && entry.componentType && entry.componentType !== componentType) {
          return false;
        }
        return compatible.includes(entry.bloodGroup);
      });
      const available = entries.reduce((sum, e) => sum + (e.availableUnits || 0), 0);
      const distanceKm = haversineKm(latitude, longitude, bank.latitude, bank.longitude);
      const radius = bank.serviceRadiusKm || 25;
      return {
        id: bank.id,
        institutionName: bank.institutionName,
        city: bank.city,
        address: bank.address,
        emergencyBloodSupply: Boolean(bank.emergencyBloodSupply),
        availableUnits: available,
        distanceKm,
        withinRadius: distanceKm == null || distanceKm <= radius,
        verificationStatus: bank.verificationStatus,
      };
    })
    .filter((bank) => bank.withinRadius)
    .sort((a, b) => {
      const availDiff = (b.availableUnits >= units) - (a.availableUnits >= units);
      if (availDiff !== 0) return availDiff;
      return (a.distanceKm ?? 999) - (b.distanceKm ?? 999);
    })
    .slice(0, limit);
}

module.exports = {
  findEligibleBloodBanks,
  haversineKm,
};
