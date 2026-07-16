const { v4: uuidv4 } = require('uuid');
const NurseVisitNote = require('./models/NurseVisitNote');
const ConsultationBooking = require('./models/ConsultationBooking');
const { createAndPushNotification } = require('./notificationRepositories');
const { appendStatusHistory } = require('./bookingLifecycleHelpers');

async function saveNurseVisitNote({
  bookingId,
  nurseId,
  careSummary,
  vitals,
  proceduresDone,
  advice,
  followUpNeeded,
}) {
  const booking = await ConsultationBooking.findOne({ id: bookingId });
  if (!booking) {
    const err = new Error('Booking not found');
    err.statusCode = 404;
    throw err;
  }
  if (booking.nurseId !== nurseId) {
    const err = new Error('You are not allowed to write notes for this visit');
    err.statusCode = 403;
    throw err;
  }
  if (booking.status !== 'confirmed') {
    const err = new Error('Visit notes can only be written for confirmed visits');
    err.statusCode = 400;
    throw err;
  }

  const summary = String(careSummary || '').trim();
  if (!summary) {
    const err = new Error('Care summary is required');
    err.statusCode = 400;
    throw err;
  }

  let note = await NurseVisitNote.findOne({ bookingId });
  if (note) {
    note.careSummary = summary;
    note.vitals = vitals?.trim() || undefined;
    note.proceduresDone = proceduresDone?.trim() || undefined;
    note.advice = advice?.trim() || undefined;
    note.followUpNeeded = Boolean(followUpNeeded);
    note.status = 'finalized';
    await note.save();
  } else {
    note = await NurseVisitNote.create({
      id: uuidv4(),
      bookingId,
      nurseId,
      patientId: booking.patientId,
      patientName: booking.patientName,
      careSummary: summary,
      vitals: vitals?.trim() || undefined,
      proceduresDone: proceduresDone?.trim() || undefined,
      advice: advice?.trim() || undefined,
      followUpNeeded: Boolean(followUpNeeded),
      status: 'finalized',
    });
  }

  booking.visitProgress = 'completed';
  appendStatusHistory(booking, 'completed', 'nurse');
  await booking.save();

  if (booking.patientId) {
    try {
      await createAndPushNotification({
        userId: booking.patientId,
        userType: 'patient',
        title: 'Visit care summary ready',
        body: 'Your nurse has shared a care summary for your home visit.',
        type: 'visit_note_ready',
        data: { bookingId },
      });
    } catch (err) {
      console.error('[NurseVisitNote] notify failed:', err.message);
    }
  }

  return note.toObject ? note.toObject() : note;
}

async function getNurseVisitNote(bookingId, auth) {
  const booking = await ConsultationBooking.findOne({ id: bookingId }).lean();
  if (!booking) {
    const err = new Error('Booking not found');
    err.statusCode = 404;
    throw err;
  }

  const allowed =
    (auth?.type === 'patient' && auth.patientId === booking.patientId) ||
    (auth?.type === 'nurse' && auth.nurseId === booking.nurseId);
  if (!allowed) {
    const err = new Error('Not allowed to view this visit note');
    err.statusCode = 403;
    throw err;
  }

  const note = await NurseVisitNote.findOne({ bookingId }).lean();
  if (!note) {
    const err = new Error('Visit note not found');
    err.statusCode = 404;
    throw err;
  }
  return note;
}

function nurseVisitNoteFieldsForBooking(booking, noteMap) {
  const note = noteMap?.get(booking.id);
  return {
    hasVisitNote: Boolean(note && note.status === 'finalized'),
    visitNoteId: note?.id ?? null,
  };
}

async function findVisitNotesByBookingIds(bookingIds) {
  if (!bookingIds.length) return new Map();
  const rows = await NurseVisitNote.find({
    bookingId: { $in: bookingIds },
    status: 'finalized',
  }).lean();
  return new Map(rows.map((r) => [r.bookingId, r]));
}

module.exports = {
  saveNurseVisitNote,
  getNurseVisitNote,
  nurseVisitNoteFieldsForBooking,
  findVisitNotesByBookingIds,
};
