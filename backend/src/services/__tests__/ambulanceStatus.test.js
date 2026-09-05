const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const {
  canTransition,
  assertTransition,
  canUserCancel,
  canonicalStatus,
  userFacingLabel,
} = require('../ambulanceStatus');

describe('ambulance status machine', () => {
  it('allows the emergency lifecycle and blocks jumps', () => {
    assert.equal(canTransition('searching_ambulance', 'ambulance_assigned'), true);
    assert.equal(canTransition('driver_accepted', 'driver_en_route'), true);
    assert.equal(canTransition('patient_picked_up', 'trip_completed'), false);
    assert.throws(
      () => assertTransition('arrived_at_destination', 'searching_ambulance'),
      /Cannot change booking/,
    );
  });

  it('maps legacy statuses and user-facing copy', () => {
    assert.equal(canonicalStatus('accepted'), 'driver_accepted');
    assert.equal(canonicalStatus('completed'), 'trip_completed');
    assert.equal(userFacingLabel('driver_en_route'), 'Ambulance is on the way');
  });

  it('restricts cancellation after pickup', () => {
    assert.equal(canUserCancel('searching_ambulance'), true);
    assert.equal(canUserCancel('patient_picked_up'), false);
    assert.equal(canUserCancel('trip_completed'), false);
  });
});
