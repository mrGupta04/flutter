const {
  submitConsultationFeedback,
  dismissConsultationFeedback,
} = require('../db/feedbackRepositories');

function requirePatientAuth(auth) {
  if (auth?.type === 'patient' && auth?.patientId) {
    return auth.patientId;
  }
  const err = new Error('Patient authentication required');
  err.statusCode = 401;
  throw err;
}

async function submitFeedback(bookingId, auth, body) {
  const patientId = requirePatientAuth(auth);
  const rating = Number(body?.rating);
  if (!Number.isInteger(rating) || rating < 1 || rating > 5) {
    const err = new Error('Rating must be between 1 and 5');
    err.statusCode = 400;
    throw err;
  }

  const comment = typeof body?.comment === 'string' ? body.comment.trim() : '';
  if (comment.length > 500) {
    const err = new Error('Comment must be 500 characters or less');
    err.statusCode = 400;
    throw err;
  }

  return submitConsultationFeedback({
    bookingId,
    patientId,
    rating,
    comment: comment || undefined,
  });
}

async function dismissFeedback(bookingId, auth) {
  const patientId = requirePatientAuth(auth);
  return dismissConsultationFeedback({ bookingId, patientId });
}

module.exports = {
  submitFeedback,
  dismissFeedback,
};
