const { v4: uuidv4 } = require('uuid');
const NurseVisitNote = require('./models/NurseVisitNote');
const ConsultationBooking = require('./models/ConsultationBooking');
const { notifyPatient } = require('./notificationRepositories');
const { saveNurseVisitReportDraft } = require('./nurseVisitWorkflowRepositories');

async function saveNurseVisitNote({
  bookingId,
  nurseId,
  careSummary,
  vitals,
  proceduresDone,
  advice,
  followUpNeeded,
}) {
  const note = await saveNurseVisitReportDraft({
    bookingId,
    nurseId,
    payload: {
      careSummary,
      nurseNotes: careSummary,
      vitalsData: typeof vitals === 'string' ? { notes: vitals } : vitals,
      proceduresPerformed: proceduresDone
        ? String(proceduresDone)
            .split(',')
            .map((s) => s.trim())
            .filter(Boolean)
        : [],
      followUpRecommendation: followUpNeeded ? 'follow_up_home_visit' : undefined,
      advice,
    },
  });

  if (note) {
    const booking = await ConsultationBooking.findOne({ id: bookingId });
    if (booking) {
      try {
        await notifyPatient(booking, {
          title: 'Visit care summary updated',
          body: 'Your nurse has updated the care summary for your home visit.',
          type: 'visit_note_ready',
        });
      } catch (err) {
        console.error('[NurseVisitNote] notify failed:', err.message);
      }
    }
  }

  return note;
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
    (auth?.type === 'nurse' && auth.nurseId === booking.nurseId) ||
    (auth?.type === 'doctor' && booking.patientId);
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
    hasVisitNote: Boolean(
      note && ['submitted', 'finalized', 'locked'].includes(note.status),
    ),
    visitNoteId: note?.id ?? null,
    nursingReportPdfUrl: note?.pdfUrl ?? null,
    nursingReportLocked: note?.status === 'locked',
  };
}

async function findVisitNotesByBookingIds(bookingIds) {
  if (!bookingIds.length) return new Map();
  const rows = await NurseVisitNote.find({
    bookingId: { $in: bookingIds },
    status: { $in: ['submitted', 'finalized', 'locked'] },
  }).lean();
  return new Map(rows.map((r) => [r.bookingId, r]));
}

module.exports = {
  saveNurseVisitNote,
  getNurseVisitNote,
  nurseVisitNoteFieldsForBooking,
  findVisitNotesByBookingIds,
};
