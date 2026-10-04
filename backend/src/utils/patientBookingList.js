function parseBookingListQuery(query = {}) {
  const page = Math.max(1, parseInt(query.page, 10) || 1);
  const rawLimit = parseInt(query.limit, 10);
  const limit = Number.isFinite(rawLimit)
    ? Math.min(50, Math.max(1, rawLimit))
    : query.scope
      ? 20
      : 100;
  const scope = ['current', 'history', 'all'].includes(String(query.scope || ''))
    ? String(query.scope)
    : 'all';
  const status = ['all', 'completed', 'cancelled', 'failed'].includes(
    String(query.status || ''),
  )
    ? String(query.status)
    : 'all';
  const q = String(query.q || query.search || '').trim();
  const serviceType = String(query.serviceType || query.service || '').trim();
  const consultationType = String(query.consultationType || '').trim();
  return { page, limit, scope, status, q, serviceType, consultationType };
}

const TERMINAL_BOOKING_STATUSES = new Set([
  'cancelled',
  'rejected',
  'nurse_rejected',
  'payment_expired',
  'failed',
  'expired',
  'no_answer',
  'completed',
  'trip_completed',
  'report_ready',
  'delivered',
  'collected',
  'closed',
]);

const CURRENT_WORKFLOW_STATUSES = new Set([
  'held',
  'pending',
  'requested',
  'awaiting_doctor_approval',
  'pending_nurse_approval',
  'approved_pending_payment',
  'payment_pending',
  'searching_ambulance',
  'ambulance_assigned',
  'driver_accepted',
  'accepted',
  'dispatched',
  'driver_en_route',
  'en_route',
  'arrived_at_pickup',
  'arrived',
  'patient_picked_up',
  'en_route_to_destination',
  'arrived_at_destination',
  'sample_collected',
  'processing',
  'in_progress',
  'under_review',
  'reserved',
  'blood_reserved',
  'ready',
  'emergency_requested',
  'response_received',
]);

const LIVE_VISIT_PROGRESS = new Set(['en_route', 'arrived', 'visit_started']);

function asDate(value) {
  if (value instanceof Date && !Number.isNaN(value.getTime())) return value;
  if (typeof value === 'string' || typeof value === 'number') {
    const date = new Date(value);
    if (!Number.isNaN(date.getTime())) return date;
  }
  return null;
}

function isCurrentPatientBooking(booking, now = new Date()) {
  if (!booking) return false;
  const status = String(booking.status || '');
  const progress = String(booking.visitProgress || '');

  if (progress === 'completed' || TERMINAL_BOOKING_STATUSES.has(status)) {
    return false;
  }
  if (CURRENT_WORKFLOW_STATUSES.has(status) || LIVE_VISIT_PROGRESS.has(progress)) {
    return true;
  }
  if (typeof booking.isUpcoming === 'boolean') {
    return booking.isUpcoming;
  }

  const slotEnd = asDate(booking.slotEnd || booking.slotStart || booking.createdAt);
  return Boolean(slotEnd && slotEnd >= now);
}

function paymentFieldsForPatient(record = {}) {
  const paymentStatus = String(record.paymentStatus || 'pending');
  const amount =
    record.amountPaid ??
    record.consultationFee ??
    record.totalAmount ??
    record.amount ??
    record.fareBreakdown?.total ??
    0;
  const paymentReference =
    record.razorpayPaymentId ||
    record.mockTransactionId ||
    record.paymentReference ||
    null;
  const paidLike = ['paid', 'success', 'refunded'].includes(paymentStatus);
  const completedPaid =
    ['completed', 'trip_completed', 'report_ready', 'delivered', 'collected'].includes(record.status) &&
    Number(amount) > 0;
  return {
    paymentStatus,
    amountPaid: record.amountPaid != null ? Number(record.amountPaid) : null,
    paymentMethod: record.paymentMethod || record.paymentProvider || null,
    paymentReference,
    paidAt: record.paidAt || null,
    currency: record.currency || 'INR',
    canViewReceipt: Boolean(record.invoiceUrl) || paidLike || completedPaid,
    invoiceUrl: record.invoiceUrl || null,
  };
}

function matchesHistoryStatus(booking, status) {
  const wanted = String(status || 'all');
  if (!wanted || wanted === 'all') return true;
  const value = String(booking?.status || '');
  const progress = String(booking?.visitProgress || '');
  if (wanted === 'completed') {
    return (
      ['completed', 'trip_completed', 'report_ready', 'delivered', 'collected'].includes(value) ||
      progress === 'completed'
    );
  }
  if (wanted === 'cancelled') {
    return ['cancelled', 'rejected', 'nurse_rejected'].includes(value);
  }
  if (wanted === 'failed') {
    return ['payment_expired', 'failed', 'expired', 'no_answer'].includes(value);
  }
  return true;
}

function applyBookingFilters(results, { scope = 'all', status, q, serviceType, consultationType } = {}) {
  let list = Array.isArray(results) ? [...results] : [];
  if (scope === 'current') list = list.filter((b) => isCurrentPatientBooking(b));
  if (scope === 'history') list = list.filter((b) => !isCurrentPatientBooking(b));
  if (status && status !== 'all') {
    list = list.filter((b) => matchesHistoryStatus(b, status));
  }
  const service = String(serviceType || '').trim();
  if (service && service !== 'all') {
    list = list.filter((b) => String(b.serviceType || '') === service);
  }
  const consult = String(consultationType || '').trim();
  if (consult) {
    list = list.filter((b) => String(b.consultationType || '') === consult);
  }
  const query = String(q || '').trim().toLowerCase();
  if (query) {
    list = list.filter((b) => {
      const hay = [
        b.doctorName,
        b.typeLabel,
        b.id,
        b.clinicName,
        b.label,
      ]
        .filter(Boolean)
        .join(' ')
        .toLowerCase();
      return hay.includes(query);
    });
  }
  return list;
}

function paginateMergedBookings(
  results,
  { page = 1, limit = 20, scope = 'all', status, q, serviceType, consultationType } = {},
) {
  const list = Array.isArray(results) ? results : [];
  const current = list.filter((b) => isCurrentPatientBooking(b));
  const history = list.filter((b) => !isCurrentPatientBooking(b));
  const filtered = applyBookingFilters(list, {
    scope,
    status,
    q,
    serviceType,
    consultationType,
  });

  const total = filtered.length;
  const start = (Math.max(1, page) - 1) * Math.max(1, limit);
  const bookings = filtered.slice(start, start + Math.max(1, limit));

  return {
    bookings,
    stats: {
      total: list.length,
      upcoming: current.length,
      past: history.length,
    },
    pagination: {
      page: Math.max(1, page),
      limit: Math.max(1, limit),
      total,
      totalPages: Math.max(1, Math.ceil(total / Math.max(1, limit)) || 1),
      hasMore: start + bookings.length < total,
    },
  };
}

function isValidEmail(email) {
  return /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/.test(
    String(email || '').trim(),
  );
}

function isValidIndianPincode(pincode) {
  return /^[0-9]{6}$/.test(String(pincode || '').trim());
}

function parseDateOfBirth(value) {
  if (value == null || value === '') return null;
  const date = value instanceof Date ? value : new Date(value);
  if (Number.isNaN(date.getTime())) {
    const err = new Error('Enter a valid date of birth');
    err.statusCode = 400;
    throw err;
  }
  const now = new Date();
  if (date > now) {
    const err = new Error('Date of birth cannot be in the future');
    err.statusCode = 400;
    throw err;
  }
  let age = now.getFullYear() - date.getFullYear();
  const monthDiff = now.getMonth() - date.getMonth();
  if (monthDiff < 0 || (monthDiff === 0 && now.getDate() < date.getDate())) {
    age -= 1;
  }
  if (age < 1 || age > 120) {
    const err = new Error('Date of birth must be between 1 and 120 years ago');
    err.statusCode = 400;
    throw err;
  }
  return { dateOfBirth: date, age };
}

module.exports = {
  parseBookingListQuery,
  paymentFieldsForPatient,
  isCurrentPatientBooking,
  paginateMergedBookings,
  applyBookingFilters,
  matchesHistoryStatus,
  isValidEmail,
  isValidIndianPincode,
  parseDateOfBirth,
};
