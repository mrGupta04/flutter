import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/bookable_slot_model.dart';
import '../../../data/models/patient_booking_model.dart';
import '../../../data/repositories/patient_dashboard_repository.dart';
import '../../user_auth/provider/patient_auth_provider.dart';
import '../../user_dashboard/provider/patient_dashboard_provider.dart';

const Duration _meetingGraceAfterEnd = Duration(minutes: 5);

class UpcomingMeetingTimerState {
  const UpcomingMeetingTimerState({
    this.meeting,
    this.now,
    this.isLoading = false,
    this.dismissedBookingId,
  });

  final PatientBookingModel? meeting;
  final DateTime? now;
  final bool isLoading;
  final String? dismissedBookingId;

  bool get isVisible =>
      meeting != null && meeting!.id != dismissedBookingId;

  UpcomingMeetingTimerState copyWith({
    PatientBookingModel? meeting,
    DateTime? now,
    bool? isLoading,
    String? dismissedBookingId,
    bool clearMeeting = false,
    bool clearDismissed = false,
  }) {
    return UpcomingMeetingTimerState(
      meeting: clearMeeting ? null : (meeting ?? this.meeting),
      now: now ?? this.now,
      isLoading: isLoading ?? this.isLoading,
      dismissedBookingId:
          clearDismissed ? null : (dismissedBookingId ?? this.dismissedBookingId),
    );
  }
}

PatientBookingModel patientBookingFromConsultationResult(
  ConsultationBookingResult result,
) {
  var typeLabel = 'Consultation';
  if (result.consultationType == 'online_consult') {
    typeLabel = 'Online consult';
  } else if (result.consultationType == 'visit_site') {
    typeLabel = 'Clinic visit';
  } else if (result.consultationType == 'book_home') {
    typeLabel = 'Home visit';
  }

  return PatientBookingModel(
    id: result.id,
    doctorId: result.doctorId,
    doctorName: result.doctorName ?? 'Doctor',
    consultationType: result.consultationType,
    typeLabel: typeLabel,
    slotStart: result.slotStart,
    slotEnd: result.slotEnd,
    label: result.label,
    consultationFee: result.consultationFee,
    status: result.status,
    clinicName: result.clinicName,
    clinicAddress: result.clinicAddress,
    isUpcoming: true,
    appointmentCode: result.appointmentCode,
    appointmentVerifiedAt: result.appointmentVerifiedAt,
  );
}

PatientBookingModel? pickNextUpcomingMeeting(
  List<PatientBookingModel> bookings,
  DateTime now,
) {
  final active = bookings.where((booking) {
    if (booking.status != 'confirmed') return false;
    final visibleUntil = booking.slotEnd.add(_meetingGraceAfterEnd);
    return visibleUntil.isAfter(now);
  }).toList();

  if (active.isEmpty) return null;
  active.sort((a, b) => a.slotStart.compareTo(b.slotStart));
  return active.first;
}

enum MeetingTimerPhase { upcoming, opensSoon, joinNow, inProgress, ending }

MeetingTimerPhase meetingTimerPhase(PatientBookingModel meeting, DateTime now) {
  if (meeting.canJoinVideo) return MeetingTimerPhase.joinNow;
  if (now.isBefore(meeting.slotStart)) {
    if (meeting.videoStartsInMinutes != null &&
        meeting.videoStartsInMinutes! > 0) {
      return MeetingTimerPhase.opensSoon;
    }
    return MeetingTimerPhase.upcoming;
  }
  if (now.isBefore(meeting.slotEnd)) return MeetingTimerPhase.inProgress;
  return MeetingTimerPhase.ending;
}

Duration timeUntilMeetingStart(PatientBookingModel meeting, DateTime now) {
  return meeting.slotStart.difference(now);
}

Duration timeUntilMeetingEnd(PatientBookingModel meeting, DateTime now) {
  return meeting.slotEnd.difference(now);
}

String formatMeetingCountdown(Duration duration) {
  if (duration.isNegative) return '00:00';
  if (duration.inDays > 0) {
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    if (hours == 0) return '${days}d';
    return '${days}d ${hours}h';
  }
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);
  final mm = minutes.toString().padLeft(2, '0');
  final ss = seconds.toString().padLeft(2, '0');
  if (hours > 0) {
    return '${hours.toString().padLeft(2, '0')}:$mm:$ss';
  }
  return '$mm:$ss';
}

class UpcomingMeetingTimerNotifier extends StateNotifier<UpcomingMeetingTimerState> {
  UpcomingMeetingTimerNotifier(this._ref, this._repo)
      : super(UpcomingMeetingTimerState(now: DateTime.now()));

  final Ref _ref;
  final PatientDashboardRepository _repo;
  Timer? _ticker;
  bool _bootstrapped = false;

  void bootstrap() {
    if (_bootstrapped) return;
    _bootstrapped = true;
    _startTicker();
    _refreshIfLoggedIn();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      final meeting = state.meeting;
      if (meeting != null) {
        final visibleUntil = meeting.slotEnd.add(_meetingGraceAfterEnd);
        if (!visibleUntil.isAfter(now)) {
          state = state.copyWith(now: now, clearMeeting: true);
          _refreshIfLoggedIn();
          return;
        }
      }
      state = state.copyWith(now: now);
    });
  }

  Future<void> _refreshIfLoggedIn() async {
    if (!_ref.read(patientAuthProvider).isLoggedIn) {
      state = state.copyWith(clearMeeting: true);
      return;
    }
    await refresh();
  }

  Future<void> refresh() async {
    if (!_ref.read(patientAuthProvider).isLoggedIn) return;

    state = state.copyWith(isLoading: true);
    try {
      final response = await _repo.fetchBookings();
      final now = DateTime.now();
      final next = pickNextUpcomingMeeting(response.bookings, now);
      state = state.copyWith(
        meeting: next,
        now: now,
        isLoading: false,
        clearDismissed: next?.id != state.dismissedBookingId,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void registerNewBooking(PatientBookingModel booking) {
    state = state.copyWith(
      meeting: booking,
      now: DateTime.now(),
      clearDismissed: true,
    );
    unawaited(refresh());
  }

  void registerConsultationResult(ConsultationBookingResult result) {
    registerNewBooking(patientBookingFromConsultationResult(result));
  }

  void dismiss() {
    final id = state.meeting?.id;
    if (id == null) return;
    state = state.copyWith(dismissedBookingId: id);
  }

  /// Re-show the upcoming consult banner after the app returns to foreground.
  Future<void> restoreOnAppResume() async {
    if (!_ref.read(patientAuthProvider).isLoggedIn) return;
    state = state.copyWith(clearDismissed: true);
    await refresh();
  }

  void clear() {
    state = UpcomingMeetingTimerState(now: DateTime.now());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

final upcomingMeetingTimerProvider =
    StateNotifierProvider<UpcomingMeetingTimerNotifier, UpcomingMeetingTimerState>(
  (ref) {
    final notifier = UpcomingMeetingTimerNotifier(
      ref,
      ref.watch(patientDashboardRepositoryProvider),
    );
    ref.listen<PatientAuthState>(patientAuthProvider, (previous, next) {
      if (next.isLoggedIn && !(previous?.isLoggedIn ?? false)) {
        notifier.refresh();
      } else if (!next.isLoggedIn && (previous?.isLoggedIn ?? false)) {
        notifier.clear();
      }
    });
    return notifier;
  },
);
