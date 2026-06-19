import 'package:flutter/material.dart';
import '../../../../data/models/patient_booking_model.dart';
import '../widgets/post_session_feedback_sheet.dart';

final Set<String> _promptedBookingIds = <String>{};

void resetFeedbackPromptSession() {
  _promptedBookingIds.clear();
}

bool isBookingSlotEnded(PatientBookingModel booking, [DateTime? now]) {
  final current = now ?? DateTime.now();
  return !current.isBefore(booking.slotEnd);
}

Future<void> maybeShowPendingFeedbackPrompt(
  BuildContext context,
  List<PatientBookingModel> bookings,
) async {
  if (!context.mounted) return;

  final now = DateTime.now();
  final pending = bookings
      .where((b) => b.canRequestFeedback && isBookingSlotEnded(b, now))
      .toList();
  if (pending.isEmpty) return;

  pending.sort((a, b) => b.slotStart.compareTo(a.slotStart));

  for (final booking in pending) {
    if (_promptedBookingIds.contains(booking.id)) continue;
    _promptedBookingIds.add(booking.id);

    await showPostSessionFeedbackSheet(
      context,
      PostSessionFeedbackInfo(
        bookingId: booking.id,
        doctorId: booking.doctorId,
        doctorName: booking.doctorName,
        doctorProfilePicture: booking.doctorProfilePicture,
        consultationType: booking.consultationType,
        sessionLabel: booking.label,
      ),
    );
    return;
  }
}

Future<void> showFeedbackAfterSession(
  BuildContext context,
  PostSessionFeedbackInfo info,
) async {
  _promptedBookingIds.add(info.bookingId);
  await showPostSessionFeedbackSheet(context, info);
}
