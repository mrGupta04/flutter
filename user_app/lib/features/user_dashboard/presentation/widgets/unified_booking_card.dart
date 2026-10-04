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
import '../../../nurse_home_visit/nurse_home_visit_navigation.dart';
import '../../data/booking_status_config.dart';
import 'booking_status_badge.dart';

class UnifiedBookingCard extends StatelessWidget {
  const UnifiedBookingCard({
    super.key,
    required this.booking,
    this.onTap,
    this.showCategoryTag = true,
  });

  final PatientBookingModel booking;
  final VoidCallback? onTap;
  final bool showCategoryTag;

  @override
  Widget build(BuildContext context) {
    final status = BookingStatusView.of(booking);
    final imageUrl = MediaUrlUtils.resolve(booking.doctorProfilePicture);
    final dateLabel =
        DateFormat('d MMM yyyy').format(booking.slotStart.toLocal());
    final timeLabel = DateFormat('h:mm a').format(booking.slotStart.toLocal());
    final category = booking.category;
    final categoryColor = category.color;

    final hasSpecificLabel = booking.label.trim().isNotEmpty &&
        booking.label.trim().toLowerCase() !=
            booking.typeLabel.trim().toLowerCase() &&
        booking.label.trim().toLowerCase() !=
            booking.doctorName.trim().toLowerCase() &&
        !booking.label.trim().contains(dateLabel);

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
              color: booking.isLiveNow
                  ? AppColors.error.withValues(alpha: 0.45)
                  : AppColors.grey200,
              width: booking.isLiveNow ? 1.5 : 1.0,
            ),
            boxShadow: AppDecorations.softShadow(opacity: 0.04),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showCategoryTag) ...[
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: categoryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(category.icon, size: 13, color: categoryColor),
                          const SizedBox(width: 4),
                          Text(
                            category.label,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: categoryColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    BookingStatusBadge(status: status),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TappableProfilePhoto(
                    imageUrl: imageUrl,
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: categoryColor.withValues(alpha: 0.12),
                      backgroundImage:
                          imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                      child: imageUrl.isEmpty
                          ? Icon(category.icon, color: categoryColor, size: 22)
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
                        if (hasSpecificLabel) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.grey50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.grey200),
                            ),
                            child: Text(
                              booking.label,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 13,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              dateLabel,
                              style: AppTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.access_time_rounded,
                              size: 13,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              timeLabel,
                              style: AppTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        if (booking.patientAddress != null &&
                            booking.patientAddress!.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 13,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  booking.patientAddress!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (booking.clinicName != null &&
                            booking.clinicName!.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.apartment_rounded,
                                size: 13,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  booking.clinicName!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (booking.isClinicVisit &&
                            booking.appointmentCode != null &&
                            booking.appointmentCode!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.qr_code_rounded,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Clinic Code: ${booking.appointmentCode}',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: AppColors.grey100),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (booking.consultationFee != null) ...[
                    Text(
                      '₹${booking.consultationFee}',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (!showCategoryTag) ...[
                    BookingStatusBadge(status: status),
                  ],
                  const Spacer(),
                  if (booking.canTrackAmbulanceLive) ...[
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.error,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => context.push(
                        '${AppConstants.routeAmbulanceTracking}?bookingId=${Uri.encodeComponent(booking.id)}',
                      ),
                      icon: const Icon(Icons.navigation_rounded, size: 14),
                      label: const Text('Track', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 6),
                  ] else if (booking.canTrackHomeVisitLive) ...[
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: categoryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () =>
                          context.push(nurseLiveTrackRoute(booking.id)),
                      icon: const Icon(Icons.directions_run_rounded, size: 14),
                      label: const Text('Track', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 6),
                  ] else if (booking.canJoinVideo) ...[
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => context.push(
                        '${AppConstants.routeVideoConsult}?bookingId=${Uri.encodeComponent(booking.id)}',
                      ),
                      icon: const Icon(Icons.videocam_rounded, size: 14),
                      label: const Text('Join Call', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 6),
                  ] else if (booking.needsHomeVisitPayment) ...[
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () =>
                          context.push(nursePaymentRoute(booking.id)),
                      icon: const Icon(Icons.payment_rounded, size: 14),
                      label: const Text('Pay now', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 6),
                  ],
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: onTap ??
                        () => context.push(
                              '${AppConstants.routeBookingDetails}?bookingId=${Uri.encodeComponent(booking.id)}',
                            ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Details',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
