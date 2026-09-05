const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const {
  vehicleHasEquipment,
  vehicleTypeMatches,
  isProviderDispatchable,
  isVehicleDispatchable,
  isDriverDispatchable,
  findMatchingCandidates,
  nextDispatchBatch,
} = require('../ambulanceMatching');

describe('ambulance matching', () => {
  it('rejects vehicles missing required equipment', () => {
    assert.equal(
      vehicleHasEquipment({ hasOxygen: false }, { oxygen: true }),
      false,
    );
    assert.equal(
      vehicleHasEquipment({ hasOxygen: true, hasVentilator: true }, { oxygen: true }),
      true,
    );
  });

  it('matches vehicle types by alias', () => {
    assert.equal(vehicleTypeMatches('ALS', 'Advanced Life Support'), true);
    assert.equal(vehicleTypeMatches('icu', 'ICU Ambulance'), true);
    assert.equal(vehicleTypeMatches('als', 'Basic Life Support'), false);
  });

  it('does not dispatch unverified or disabled providers', () => {
    assert.equal(
      isProviderDispatchable({ verificationStatus: 'pending' }),
      false,
    );
    assert.equal(
      isProviderDispatchable({ verificationStatus: 'verified', isDisabled: true }),
      false,
    );
    assert.equal(
      isProviderDispatchable({ verificationStatus: 'verified', emergencyAvailable: false }, { emergency: true }),
      false,
    );
  });

  it('keeps busy vehicles out of matching', () => {
    assert.equal(isVehicleDispatchable({ status: 'BUSY' }), false);
    assert.equal(
      isVehicleDispatchable({ status: 'AVAILABLE', currentBookingId: 'trip-1' }),
      false,
    );
    assert.equal(isVehicleDispatchable({ status: 'EMERGENCY_ONLY' }, { emergency: true }), true);
    assert.equal(isVehicleDispatchable({ status: 'EMERGENCY_ONLY' }, { emergency: false }), false);
  });

  it('requires an online or available driver', () => {
    assert.equal(isDriverDispatchable({ status: 'SUSPENDED', isOnline: true }), false);
    assert.equal(isDriverDispatchable({ status: 'AVAILABLE', isOnline: true }), true);
    assert.equal(isDriverDispatchable({ status: 'OFFLINE', isOnline: false }), false);
  });

  it('ranks suitable nearby ambulances and ignores requirement mismatches', () => {
    const providers = [
      {
        id: 'p1',
        serviceName: 'Near ALS',
        verificationStatus: 'verified',
        latitude: 12.97,
        longitude: 77.59,
        serviceRadiusKm: 20,
        vehicles: [
          {
            id: 'v-far-basic',
            vehicleType: 'Basic Ambulance',
            status: 'AVAILABLE',
            hasOxygen: false,
            assignedDriverId: 'd1',
            currentLatitude: 12.99,
            currentLongitude: 77.61,
          },
          {
            id: 'v-als',
            vehicleType: 'Advanced Life Support',
            status: 'AVAILABLE',
            hasOxygen: true,
            hasVentilator: true,
            assignedDriverId: 'd2',
            currentLatitude: 12.971,
            currentLongitude: 77.591,
          },
        ],
        drivers: [
          { id: 'd1', fullName: 'Asha', isOnline: true, status: 'AVAILABLE' },
          { id: 'd2', fullName: 'Rahul', isOnline: true, status: 'AVAILABLE' },
        ],
      },
    ];

    const matches = findMatchingCandidates({
      providers,
      pickupLatitude: 12.97,
      pickupLongitude: 77.59,
      requestedType: 'als',
      requirements: { oxygen: true, ventilator: true },
      emergency: true,
      radiusKm: 15,
    });

    assert.equal(matches.length, 1);
    assert.equal(matches[0].vehicleId, 'v-als');
    assert.ok(matches[0].etaMinutes >= 1);
  });

  it('batches dispatch offers instead of notifying everyone at once', () => {
    const candidates = [
      { vehicleId: 'a' },
      { vehicleId: 'b' },
      { vehicleId: 'c' },
    ];
    const first = nextDispatchBatch(candidates, { batchSize: 2, alreadyOffered: [] });
    assert.deepEqual(first.map((item) => item.vehicleId), ['a', 'b']);
    const second = nextDispatchBatch(candidates, { batchSize: 2, alreadyOffered: ['a', 'b'] });
    assert.deepEqual(second.map((item) => item.vehicleId), ['c']);
  });
});
