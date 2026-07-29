import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/geo_distance_utils.dart';
import '../../../../core/utils/media_url_utils.dart';
import '../../../../data/models/scan_center_model.dart';
import '../../data/scan_model_utils.dart';

class ScanExploreCard extends StatelessWidget {
  const ScanExploreCard({
    super.key,
    required this.center,
    required this.onViewDetails,
  });

  final ScanCenterModel center;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    final logoUrl = MediaUrlUtils.resolve(center.profilePicture);
    final coverUrl = (center.centerImages != null &&
            center.centerImages!.isNotEmpty)
        ? MediaUrlUtils.resolve(center.centerImages!.first)
        : '';
    final imageUrl = coverUrl.isNotEmpty ? coverUrl : logoUrl;
    final distance = formatNearbyDistanceLabel(center.distanceKm);
    final startingPrice = center.startingPriceInr;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onViewDetails,
        borderRadius: AppDecorations.borderRadiusMd,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 72,
                      height: 72,
                      color: AppColors.grey100,
                      child: imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Image.asset(
                                'assets/images/home_cards/diagnostic_scans.png',
                                fit: BoxFit.cover,
                              ),
                              errorWidget: (_, __, ___) => Image.asset(
                                'assets/images/home_cards/scan_card-removebg-preview.png',
                                fit: BoxFit.contain,
                              ),
                            )
                          : Image.asset(
                              'assets/images/home_cards/scan_card-removebg-preview.png',
                              fit: BoxFit.contain,
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          center.displayName,
                          style: AppTextStyles.titleSmall.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${center.ratingValue.toStringAsFixed(1)} '
                              '(${center.reviewsCount} reviews)',
                              style: AppTextStyles.labelSmall.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (center.hasActiveOfferBadge)
                              const _Badge(
                                label: 'Offer',
                                color: AppColors.offer,
                              ),
                            if (center.supportsHomeVisit)
                              const _Badge(
                                label: 'Home visit',
                                color: AppColors.primary,
                              ),
                            _Badge(
                              label: center.openStatusLabel,
                              color: center.isOpenNow
                                  ? AppColors.success
                                  : AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                center.fullAddress,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (distance != null) ...[
                    const Icon(
                      Icons.near_me_outlined,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(distance, style: AppTextStyles.labelSmall),
                    const SizedBox(width: 12),
                  ],
                  const Icon(
                    Icons.schedule_rounded,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Reports in ${center.reportDeliverySummary}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (startingPrice != null)
                          Text(
                            'From ₹$startingPrice',
                            style: AppTextStyles.titleSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        Text(
                          '${center.enabledScanCount} scans available',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: onViewDetails,
                    child: const Text('View Details'),
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

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}
