const ConsultationBooking = require('./models/ConsultationBooking');

/**
 * Earnings for a doctor or nurse from paid consultation bookings.
 */
async function getProviderEarnings({ doctorId, nurseId, from, to }) {
  const filter = {
    paymentStatus: { $in: ['paid', 'refunded'] },
    status: { $in: ['confirmed', 'cancelled'] },
  };
  if (doctorId) filter.doctorId = doctorId;
  if (nurseId) filter.nurseId = nurseId;

  if (from || to) {
    filter.paidAt = {};
    if (from) filter.paidAt.$gte = new Date(from);
    if (to) filter.paidAt.$lte = new Date(to);
  }

  const bookings = await ConsultationBooking.find(filter)
    .sort({ paidAt: -1 })
    .lean();

  let collected = 0;
  let refunded = 0;
  let pendingSettlement = 0;

  const items = bookings.map((b) => {
    const amount = Number(b.amountPaid || b.consultationFee || 0);
    const isRefunded = b.paymentStatus === 'refunded';
    if (isRefunded) {
      const pct = Number(b.refundPercent ?? 100);
      const refundAmt = Math.round((amount * pct) / 100);
      refunded += refundAmt;
      collected += amount - refundAmt;
    } else {
      collected += amount;
      // Simple rule: paid in last 7 days still "pending settlement"
      const paidAt = b.paidAt ? new Date(b.paidAt) : null;
      if (paidAt && Date.now() - paidAt.getTime() < 7 * 24 * 60 * 60 * 1000) {
        pendingSettlement += amount;
      }
    }

    return {
      bookingId: b.id,
      patientName: b.patientName,
      consultationType: b.consultationType,
      slotStart: b.slotStart,
      amountPaid: amount,
      paymentStatus: b.paymentStatus,
      refundPercent: b.refundPercent ?? null,
      paidAt: b.paidAt,
      status: b.status,
    };
  });

  return {
    summary: {
      collected: Math.round(collected),
      refunded: Math.round(refunded),
      pendingSettlement: Math.round(pendingSettlement),
      net: Math.round(collected),
      bookingCount: items.length,
    },
    bookings: items,
  };
}

module.exports = { getProviderEarnings };
