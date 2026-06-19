import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class JoinVideoConsultButton extends StatelessWidget {
  const JoinVideoConsultButton({
    super.key,
    required this.bookingId,
    required this.canJoinVideo,
    required this.peerName,
    this.doctorId,
    this.doctorProfilePicture,
    this.consultationType = 'online_consult',
    this.sessionLabel,
    this.videoStartsInMinutes,
    this.compact = false,
    this.onReturned,
  });

  final String bookingId;
  final bool canJoinVideo;
  final String peerName;
  final String? doctorId;
  final String? doctorProfilePicture;
  final String consultationType;
  final String? sessionLabel;
  final int? videoStartsInMinutes;
  final bool compact;
  final Future<void> Function()? onReturned;

  Future<void> _join(BuildContext context) async {
    final refreshed = await context.push<bool>(
      AppConstants.routeVideoConsult,
      extra: {
        'bookingId': bookingId,
        'peerName': peerName,
      },
    );
    if (refreshed == true && onReturned != null) {
      await onReturned!();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (canJoinVideo) {
      if (compact) {
        return FilledButton.icon(
          onPressed: () => _join(context),
          icon: const Icon(Icons.videocam_rounded, size: 18),
          label: const Text('Join video call'),
        );
      }
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () => _join(context),
          icon: const Icon(Icons.videocam_rounded),
          label: const Text('Join video call'),
        ),
      );
    }

    if (videoStartsInMinutes != null && videoStartsInMinutes! > 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.schedule_rounded,
                size: 18, color: AppColors.primaryDark),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Video opens in ~$videoStartsInMinutes min',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
