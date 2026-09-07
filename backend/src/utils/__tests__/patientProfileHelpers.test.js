const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const {
  paginateMergedBookings,
  parseBookingListQuery,
  paymentFieldsForPatient,
  isValidEmail,
  isValidIndianPincode,
  parseDateOfBirth,
} = require('../patientBookingList');
const {
  notificationCategory,
  normalizeNotificationSettings,
  isNotificationCategoryEnabled,
} = require('../notificationCategory');

describe('paginateMergedBookings', () => {
  const rows = [
    { id: 'a', isUpcoming: true },
    { id: 'b', isUpcoming: false },
    { id: 'c', isUpcoming: false },
    { id: 'd', isUpcoming: true },
  ];

  it('splits current vs history and paginates history', () => {
    const page1 = paginateMergedBookings(rows, {
      page: 1,
      limit: 1,
      scope: 'history',
    });
    assert.equal(page1.bookings.length, 1);
    assert.equal(page1.bookings[0].id, 'b');
    assert.equal(page1.pagination.hasMore, true);
    assert.equal(page1.stats.past, 2);
    assert.equal(page1.stats.upcoming, 2);

    const page2 = paginateMergedBookings(rows, {
      page: 2,
      limit: 1,
      scope: 'history',
    });
    assert.equal(page2.bookings[0].id, 'c');
    assert.equal(page2.pagination.hasMore, false);
  });

  it('filters cancelled history before paginating', () => {
    const mixed = [
      { id: '1', isUpcoming: false, status: 'cancelled', doctorName: 'Dr A' },
      { id: '2', isUpcoming: false, status: 'completed', doctorName: 'Dr B' },
    ];
    const result = paginateMergedBookings(mixed, {
      scope: 'history',
      status: 'cancelled',
      limit: 20,
    });
    assert.deepEqual(result.bookings.map((b) => b.id), ['1']);
  });

  it('returns only current bookings for scope=current', () => {
    const result = paginateMergedBookings(rows, { scope: 'current', limit: 20 });
    assert.deepEqual(
      result.bookings.map((b) => b.id),
      ['a', 'd'],
    );
    assert.equal(result.pagination.hasMore, false);
  });
});

describe('parseBookingListQuery', () => {
  it('clamps limit and defaults scope to all', () => {
    const parsed = parseBookingListQuery({ page: '0', limit: '999', scope: 'nope' });
    assert.equal(parsed.page, 1);
    assert.equal(parsed.limit, 50);
    assert.equal(parsed.scope, 'all');
  });
});

describe('paymentFieldsForPatient', () => {
  it('allows receipt for paid bookings', () => {
    const fields = paymentFieldsForPatient({
      paymentStatus: 'paid',
      razorpayPaymentId: 'pay_123',
      amountPaid: 500,
    });
    assert.equal(fields.canViewReceipt, true);
    assert.equal(fields.paymentReference, 'pay_123');
  });

  it('hides receipt when unpaid and not completed', () => {
    const fields = paymentFieldsForPatient({
      paymentStatus: 'pending',
      status: 'confirmed',
      consultationFee: 500,
    });
    assert.equal(fields.canViewReceipt, false);
  });
});

describe('validation helpers', () => {
  it('validates email and pincode', () => {
    assert.equal(isValidEmail('aditya@email.com'), true);
    assert.equal(isValidEmail('bad'), false);
    assert.equal(isValidIndianPincode('560037'), true);
    assert.equal(isValidIndianPincode('56'), false);
  });

  it('parses date of birth into age', () => {
    const dob = new Date();
    dob.setFullYear(dob.getFullYear() - 28);
    const parsed = parseDateOfBirth(dob.toISOString());
    assert.equal(parsed.age, 28);
  });
});

describe('notificationCategory', () => {
  it('maps types into profile categories', () => {
    assert.equal(notificationCategory('ambulance_emergency'), 'emergency');
    assert.equal(notificationCategory('payment_due'), 'payment');
    assert.equal(notificationCategory('booking_confirmed'), 'booking');
    assert.equal(notificationCategory('chat_message'), 'provider');
    assert.equal(notificationCategory('general'), 'system');
  });

  it('never disables emergency notifications', () => {
    const settings = normalizeNotificationSettings({ emergency: false, booking: false });
    assert.equal(settings.emergency, true);
    assert.equal(isNotificationCategoryEnabled(settings, 'emergency'), true);
    assert.equal(isNotificationCategoryEnabled(settings, 'booking'), false);
  });
});
