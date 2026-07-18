const { v4: uuidv4 } = require('uuid');
const SupportTicket = require('./models/SupportTicket');
const ConsultationBooking = require('./models/ConsultationBooking');
const LabBooking = require('./models/LabBooking');
const ScanBooking = require('./models/ScanBooking');
const BloodOrder = require('./models/BloodOrder');

function toTicket(doc) {
  if (!doc) return null;
  const d = doc.toObject ? doc.toObject() : doc;
  return {
    id: d.id,
    patientId: d.patientId,
    patientName: d.patientName,
    patientEmail: d.patientEmail,
    patientMobile: d.patientMobile,
    category: d.category,
    subject: d.subject,
    message: d.message,
    bookingId: d.bookingId,
    status: d.status,
    adminReply: d.adminReply,
    resolvedAt: d.resolvedAt,
    createdAt: d.createdAt,
    updatedAt: d.updatedAt,
  };
}

async function createSupportTicket(input) {
  const subject = String(input.subject || '').trim();
  const message = String(input.message || '').trim();
  if (subject.length < 3) {
    const err = new Error('Subject is required');
    err.statusCode = 400;
    throw err;
  }
  if (message.length < 5) {
    const err = new Error('Message is required');
    err.statusCode = 400;
    throw err;
  }

  const ticket = await SupportTicket.create({
    id: uuidv4(),
    patientId: input.patientId,
    patientName: input.patientName,
    patientEmail: input.patientEmail,
    patientMobile: input.patientMobile,
    category: input.category || 'other',
    subject,
    message,
    bookingId: input.bookingId,
    status: 'open',
  });
  return toTicket(ticket);
}

async function listTicketsForPatient(patientId) {
  const docs = await SupportTicket.find({ patientId })
    .sort({ createdAt: -1 })
    .limit(50)
    .lean();
  return docs.map(toTicket);
}

async function listTicketsForAdmin({ status, page = 1, pageSize = 30 } = {}) {
  const filter = {};
  if (status) filter.status = status;
  const totalCount = await SupportTicket.countDocuments(filter);
  const docs = await SupportTicket.find(filter)
    .sort({ createdAt: -1 })
    .skip((page - 1) * pageSize)
    .limit(pageSize)
    .lean();
  return {
    tickets: docs.map(toTicket),
    pagination: {
      currentPage: page,
      pageSize,
      totalCount,
      totalPages: Math.max(1, Math.ceil(totalCount / pageSize)),
    },
  };
}

async function updateTicketStatus({
  ticketId,
  status,
  adminReply,
}) {
  const ticket = await SupportTicket.findOne({ id: ticketId });
  if (!ticket) {
    const err = new Error('Ticket not found');
    err.statusCode = 404;
    throw err;
  }
  if (status) ticket.status = status;
  if (adminReply != null) ticket.adminReply = String(adminReply).trim();
  if (status === 'resolved' || status === 'closed') {
    ticket.resolvedAt = new Date();
  }
  await ticket.save();
  return toTicket(ticket);
}

async function refundBooking({ category, bookingId, reason }) {
  const id = String(bookingId || '').trim();
  if (!id) {
    const err = new Error('bookingId is required');
    err.statusCode = 400;
    throw err;
  }

  const type = String(category || 'consultation').toLowerCase();
  let booking;
  let previousPaymentStatus;

  if (type === 'lab') {
    booking = await LabBooking.findOne({ id });
    if (!booking) {
      const err = new Error('Lab booking not found');
      err.statusCode = 404;
      throw err;
    }
    previousPaymentStatus = booking.paymentStatus;
    booking.paymentStatus = 'refunded';
    if (booking.status !== 'cancelled') booking.status = 'cancelled';
    booking.rejectionReason = reason || booking.rejectionReason || 'Refunded by admin';
    await booking.save();
  } else if (type === 'scan') {
    booking = await ScanBooking.findOne({ id });
    if (!booking) {
      const err = new Error('Scan booking not found');
      err.statusCode = 404;
      throw err;
    }
    previousPaymentStatus = booking.paymentStatus;
    booking.paymentStatus = 'refunded';
    if (booking.status !== 'cancelled') booking.status = 'cancelled';
    booking.rejectionReason = reason || booking.rejectionReason || 'Refunded by admin';
    await booking.save();
  } else if (type === 'blood') {
    booking = await BloodOrder.findOne({ id });
    if (!booking) {
      const err = new Error('Blood order not found');
      err.statusCode = 404;
      throw err;
    }
    previousPaymentStatus = booking.paymentStatus;
    booking.paymentStatus = 'refunded';
    booking.status = 'cancelled';
    booking.notes = reason || booking.notes;
    await booking.save();
  } else {
    booking = await ConsultationBooking.findOne({ id });
    if (!booking) {
      const err = new Error('Booking not found');
      err.statusCode = 404;
      throw err;
    }
    previousPaymentStatus = booking.paymentStatus;
    booking.paymentStatus = 'refunded';
    booking.status = 'cancelled';
    booking.cancellationReason = reason || 'Refunded by admin';
    await booking.save();
  }

  return {
    bookingId: id,
    category: type,
    previousPaymentStatus,
    paymentStatus: 'refunded',
    status: booking.status,
    reason: reason || null,
  };
}

module.exports = {
  createSupportTicket,
  listTicketsForPatient,
  listTicketsForAdmin,
  updateTicketStatus,
  refundBooking,
  toTicket,
};
