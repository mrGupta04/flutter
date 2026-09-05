const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { calculateFare } = require('../ambulanceFareService');
const { DEFAULT_FARE_RULES } = require('../../db/ambulanceConstants');

describe('ambulance fare engine', () => {
  it('builds an estimate from configured components', () => {
    const fare = calculateFare({
      rules: DEFAULT_FARE_RULES,
      vehicleType: 'als',
      distanceKm: 10,
      durationMinutes: 20,
      requirements: { oxygen: true, ventilator: true },
      isEmergency: true,
      at: new Date('2026-01-01T10:00:00'),
      estimated: true,
    });

    assert.equal(fare.baseFare, 800);
    assert.equal(fare.distanceCharge, 280);
    assert.equal(fare.timeCharge, 80);
    assert.equal(fare.typeCharge, 150);
    assert.equal(fare.equipmentCharge, 330);
    assert.equal(fare.emergencySurcharge, 150);
    assert.equal(fare.estimated, true);
    assert.ok(fare.total > 1000);
  });

  it('does not invent emergency surcharge when disabled', () => {
    const fare = calculateFare({
      rules: { ...DEFAULT_FARE_RULES, emergencySurchargeEnabled: false },
      vehicleType: 'basic',
      isEmergency: true,
      at: new Date('2026-01-01T10:00:00'),
    });
    assert.equal(fare.emergencySurcharge, 0);
  });
});
