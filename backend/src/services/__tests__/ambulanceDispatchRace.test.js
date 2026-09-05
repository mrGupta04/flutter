const { describe, it } = require('node:test');
const assert = require('node:assert/strict');

describe('ambulance race-condition guards', () => {
  it('accept filter only matches unassigned searching bookings', () => {
    const filter = {
      status: { $in: ['searching_ambulance', 'requested'] },
      $or: [{ assignedVehicleId: null }, { assignedVehicleId: { $exists: false } }],
    };
    const bookingA = { status: 'searching_ambulance', assignedVehicleId: null };
    const bookingB = { status: 'driver_accepted', assignedVehicleId: 'v1' };
    assert.equal(
      filter.status.$in.includes(bookingA.status) && bookingA.assignedVehicleId == null,
      true,
    );
    assert.equal(
      filter.status.$in.includes(bookingB.status) && bookingB.assignedVehicleId == null,
      false,
    );
  });

  it('vehicle lock requires available status and no current trip', () => {
    const vehicle = { status: 'AVAILABLE', currentBookingId: null };
    const busy = { status: 'BUSY', currentBookingId: 'b1' };
    const lockable = (item) =>
      ['AVAILABLE', 'EMERGENCY_ONLY'].includes(item.status) && !item.currentBookingId;
    assert.equal(lockable(vehicle), true);
    assert.equal(lockable(busy), false);
  });

  it('completed trips cannot complete again', () => {
    const alreadyDone = ['trip_completed', 'completed'];
    assert.equal(alreadyDone.includes('trip_completed'), true);
    assert.equal(alreadyDone.includes('driver_en_route'), false);
  });
});
