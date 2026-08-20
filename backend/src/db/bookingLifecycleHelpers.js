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
      byStatus.get('pending_nurse_approval') ||
      byStatus.get('requested') ||
      booking.createdAt,
  );

  if (isHome) {
    const approved =
      Boolean(booking.doctorApprovedAt) ||
      ['approved_pending_payment', 'payment_pending', 'pending', 'confirmed'].includes(
        booking.status,
      );
    push(
      'approved',
      'Approved',
      approved,
      booking.doctorApprovedAt ||
        byStatus.get('approved_pending_payment') ||
        byStatus.get('payment_pending') ||
        byStatus.get('nurse_verified'),
    );
    if (booking.doctorRejectedAt || booking.status === 'nurse_rejected') {
      push(
        'rejected',
        'Rejected',
        true,
        booking.doctorRejectedAt || byStatus.get('nurse_rejected'),
      );
    }
    if (booking.status === 'payment_expired') {
      push(
        'payment_expired',
        'Payment expired',
        true,
        booking.cancelledAt || byStatus.get('payment_expired'),
      );
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
      booking.visitProgress === 'visit_started' ||
      booking.visitProgress === 'completed' ||
      byStatus.has('arrived');
    push('arrived', 'Arrived', arrived, byStatus.get('arrived'));

    const visitStarted =
      booking.visitProgress === 'visit_started' ||
      booking.visitProgress === 'completed' ||
      byStatus.has('visit_started') ||
      Boolean(booking.visitStartedAt);
    push(
      'visit_started',
      'Visit started',
      visitStarted,
      booking.visitStartedAt || byStatus.get('visit_started'),
    );

    const reportSubmitted = byStatus.has('report_submitted');
    push(
      'report_submitted',
      'Report submitted',
      reportSubmitted,
      byStatus.get('report_submitted'),
    );

    const otpGenerated = byStatus.has('otp_generated');
    push(
      'otp_generated',
      'OTP generated',
      otpGenerated,
      byStatus.get('otp_generated'),
    );

    const otpVerified =
      Boolean(booking.completionOtpVerifiedAt) || byStatus.has('otp_verified');
    push(
      'otp_verified',
      'OTP verified',
      otpVerified,
      booking.completionOtpVerifiedAt || byStatus.get('otp_verified'),
    );
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
