import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/patient_booking_model.dart';
import '../../../../router/user_router.dart';
import '../../../user_auth/provider/patient_auth_provider.dart';
import '../../provider/upcoming_meeting_timer_provider.dart';

/// Global floating countdown for the patient's next upcoming consultation.
class FloatingMeetingTimerOverlay extends ConsumerStatefulWidget {
  const FloatingMeetingTimerOverlay({super.key});

  @override
  ConsumerState<FloatingMeetingTimerOverlay> createState() =>
      _FloatingMeetingTimerOverlayState();
}

class _FloatingMeetingTimerOverlayState
    extends ConsumerState<FloatingMeetingTimerOverlay>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(upcomingMeetingTimerProvider.notifier).bootstrap();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(upcomingMeetingTimerProvider.notifier).restoreOnAppResume();
    }
  }

  bool _shouldHideForRoute(String location) {
    const hiddenPrefixes = [
      AppConstants.routeUserLogin,
      AppConstants.routeUserRegister,
      AppConstants.routeVideoConsult,
      AppConstants.routeOnlineConsultBooking,
      AppConstants.routeHospitalVisitBooking,
    ];
    return hiddenPrefixes.any((prefix) => location.startsWith(prefix));
  }

  String _currentRoute(WidgetRef ref) {
    final router = ref.watch(userRouterProvider);
    final matches = router.routerDelegate.currentConfiguration.matches;
    if (matches.isEmpty) return AppConstants.routeUserHome;
    return matches.last.matchedLocation;
  }

  Future<void> _joinVideo(PatientBookingModel meeting) async {
    final refreshed = await context.push<bool>(
      AppConstants.routeVideoConsult,
      extra: {
        'bookingId': meeting.id,
        'peerName': meeting.doctorName,
      },
    );
    if (refreshed == true && mounted) {
      await ref.read(upcomingMeetingTimerProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(patientAuthProvider);
    if (!auth.isLoggedIn) return const SizedBox.shrink();

    final location = _currentRoute(ref);
    if (_shouldHideForRoute(location)) {
      return const SizedBox.shrink();
    }

    final timerState = ref.watch(upcomingMeetingTimerProvider);
    final meeting = timerState.meeting;
    if (!timerState.isVisible || meeting == null) {
      return const SizedBox.shrink();
    }

    final now = timerState.now ?? DateTime.now();
    final phase = meetingTimerPhase(meeting, now);
    final countdown = phase == MeetingTimerPhase.inProgress ||
            phase == MeetingTimerPhase.ending
        ? timeUntilMeetingEnd(meeting, now)
        : timeUntilMeetingStart(meeting, now);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        12,
        0,
        12,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Material(
        elevation: 10,
        shadowColor: AppColors.primary.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: phase == MeetingTimerPhase.joinNow
                  ? [AppColors.success, AppColors.primaryDark]
                  : [AppColors.primary, AppColors.headerGreen],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.28),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _MeetingTypeIcon(meeting: meeting, phase: phase),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _phaseLabel(phase, meeting),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.white.withValues(alpha: 0.88),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          meeting.doctorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          meeting.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.white.withValues(alpha: 0.82),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    fit: FlexFit.loose,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            formatMeetingCountdown(countdown),
                            style: AppTextStyles.titleMedium.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w800,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                        if (phase == MeetingTimerPhase.joinNow) ...[
                          const SizedBox(height: 4),
                          FilledButton(
                            onPressed: () => _joinVideo(meeting),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.white,
                              foregroundColor: AppColors.primary,
                              minimumSize: const Size(64, 32),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              textStyle: AppTextStyles.labelSmall.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            child: const Text('Join'),
                          ),
                        ] else if (phase == MeetingTimerPhase.opensSoon)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '~${meeting.videoStartsInMinutes} min',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => ref
                        .read(upcomingMeetingTimerProvider.notifier)
                        .dismiss(),
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.close_rounded,
                        color: AppColors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _phaseLabel(MeetingTimerPhase phase, PatientBookingModel meeting) {
    switch (phase) {
      case MeetingTimerPhase.joinNow:
        return 'Join your consultation';
      case MeetingTimerPhase.opensSoon:
        return 'Video opens soon';
      case MeetingTimerPhase.inProgress:
        return meeting.isOnlineConsult
            ? 'Consultation in progress'
            : 'Appointment in progress';
      case MeetingTimerPhase.ending:
        return 'Wrapping up';
      case MeetingTimerPhase.upcoming:
        return 'Upcoming consultation';
    }
  }
}

class _MeetingTypeIcon extends StatelessWidget {
  const _MeetingTypeIcon({
    required this.meeting,
    required this.phase,
  });

  final PatientBookingModel meeting;
  final MeetingTimerPhase phase;

  @override
  Widget build(BuildContext context) {
    IconData icon;
    if (meeting.isOnlineConsult) {
      icon = Icons.videocam_rounded;
    } else if (meeting.isClinicVisit) {
      icon = Icons.local_hospital_rounded;
    } else {
      icon = Icons.home_rounded;
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.18),
        shape: BoxShape.circle,
      ),
      child: Icon(
        phase == MeetingTimerPhase.joinNow ? Icons.play_circle_fill : icon,
        color: AppColors.white,
        size: 24,
      ),
    );
  }
}
