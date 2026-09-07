import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/media_url_utils.dart';
import '../../../../data/models/patient_booking_model.dart';
import '../../../../shared/widgets/full_screen_image_viewer.dart';
import '../../data/booking_status_config.dart';
import 'booking_status_badge.dart';

class UnifiedBookingCard extends StatelessWidget {
  const UnifiedBookingCard({
    super.key,
    required this.booking,
    this.onTap,
  });

  final PatientBookingModel booking;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final status = BookingStatusView.of(booking);
    final imageUrl = MediaUrlUtils.resolve(booking.doctorProfilePicture);
    final dateLabel = DateFormat('d MMM yyyy').format(booking.slotStart.toLocal());
    final timeLabel = DateFormat('h:mm a').format(booking.slotStart.toLocal());
    final category = PatientBookingCategory.resolve(booking);
    final icon = switch (category) {
      PatientBookingCategory.nurse => Icons.health_and_safety_rounded,
      PatientBookingCategory.lab => Icons.biotech_rounded,
      PatientBookingCategory.scan => Icons.radar_rounded,
      PatientBookingCategory.bloodBank => Icons.bloodtype_rounded,
      PatientBookingCategory.ambulance => Icons.emergency_rounded,
      PatientBookingCategory.hospitalVisit => Icons.local_hospital_rounded,
      PatientBookingCategory.homeVisit => Icons.home_rounded,
      _ => Icons.videocam_rounded,
    };

    return Material(
      color: AppColors.white,
      borderRadius: AppDecorations.borderRadiusLg,
      child: InkWell(
        borderRadius: AppDecorations.borderRadiusLg,
        onTap: onTap ??
            () => context.push(
                  '${AppConstants.routeBookingDetails}?bookingId=${Uri.encodeComponent(booking.id)}',
                ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: AppDecorations.borderRadiusLg,
            border: Border.all(
              color: booking.isLiveNow ? AppColors.error.withValues(alpha: 0.35) : AppColors.grey200,
            ),
            boxShadow: AppDecorations.softShadow(opacity: 0.04),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TappableProfilePhoto(
                imageUrl: imageUrl,
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.primaryLight,
                  backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                  child: imageUrl.isEmpty
                      ? Icon(icon, color: AppColors.primary)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.doctorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      booking.typeLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$dateLabel  •  $timeLabel',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (booking.patientAddress != null &&
                        booking.patientAddress!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        booking.patientAddress!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Flexible(child: BookingStatusBadge(status: status)),
                        if (booking.consultationFee != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '₹${booking.consultationFee}',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.grey400),
            ],
          ),
        ),
      ),
    );
  }
}
