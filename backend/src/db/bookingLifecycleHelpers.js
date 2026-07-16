/** Shared helpers for booking status history / timeline. */

function appendStatusHistory(booking, status, by) {
  if (!Array.isArray(booking.statusHistory)) {
    booking.statusHistory = [];
  }
  booking.statusHistory.push({
    status,
    at: new Date(),
    by: by || undefined,
  });
}

/**
 * Build a patient-facing visit timeline from booking fields.
 */
function buildVisitTimeline(booking) {
  const history = Array.isArray(booking.statusHistory)
    ? booking.statusHistory
    : [];
  const byStatus = new Map(history.map((h) => [h.status, h.at]));

  const isHome = booking.consultationType === 'book_home';
  const isNurse = booking.providerType === 'nurse' || Boolean(booking.nurseId);

  const steps = [];

  const push = (key, label, done, at) => {
    steps.push({
      key,
      label,
      done: Boolean(done),
      at: at || null,
    });
  };

  push(
    'requested',
    'Requested',
    true,
    byStatus.get('awaiting_doctor_approval') ||
      byStatus.get('requested') ||
      booking.createdAt,
  );

  if (isHome) {
    const approved =
      Boolean(booking.doctorApprovedAt) ||
      ['approved_pending_payment', 'pending', 'confirmed'].includes(
        booking.status,
      );
    push(
      'approved',
      'Approved',
      approved,
      booking.doctorApprovedAt || byStatus.get('approved_pending_payment'),
    );
    if (booking.doctorRejectedAt) {
      push('rejected', 'Rejected', true, booking.doctorRejectedAt);
    }
  }

  const paid =
    booking.paymentStatus === 'paid' ||
    booking.status === 'confirmed' ||
    Boolean(booking.paidAt);
  push('paid', 'Paid', paid, booking.paidAt || byStatus.get('confirmed'));

  if (isHome) {
    const enRoute =
      booking.visitProgress === 'en_route' ||
      booking.visitProgress === 'arrived' ||
      booking.visitProgress === 'completed' ||
      byStatus.has('en_route');
    push(
      'en_route',
      isNurse ? 'Nurse on the way' : 'Doctor on the way',
      enRoute,
      byStatus.get('en_route'),
    );

    const arrived =
      booking.visitProgress === 'arrived' ||
      booking.visitProgress === 'completed' ||
      byStatus.has('arrived');
    push('arrived', 'Arrived', arrived, byStatus.get('arrived'));
  }

  if (booking.consultationType === 'visit_site') {
    push(
      'verified',
      'Checked in',
      Boolean(booking.appointmentVerifiedAt),
      booking.appointmentVerifiedAt,
    );
  }

  const completed =
    booking.visitProgress === 'completed' ||
    byStatus.has('completed') ||
    (booking.status === 'confirmed' &&
      new Date(booking.slotEnd) <= new Date() &&
      !isHome);
  push('completed', 'Completed', completed, byStatus.get('completed'));

  if (booking.status === 'cancelled') {
    push(
      'cancelled',
      'Cancelled',
      true,
      booking.cancelledAt || booking.doctorRejectedAt || byStatus.get('cancelled'),
    );
  }

  return steps;
}

module.exports = {
  appendStatusHistory,
  buildVisitTimeline,
};
