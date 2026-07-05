import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../data/lab_test_icons.dart';
import '../../data/models/lab_test_model.dart';

class LabTestCard extends StatelessWidget {
  const LabTestCard({
    super.key,
    required this.test,
    required this.onBookNow,
  });

  final LabTest test;
  final VoidCallback onBookNow;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppDecorations.borderRadiusLg,
        border: Border.all(color: AppColors.grey200),
        boxShadow: AppDecorations.softShadow(opacity: 0.04),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LabTestIconAvatar(test: test),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        test.name,
                        style: AppTextStyles.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        test.description,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _InfoChip(
                  icon: Icons.currency_rupee_rounded,
                  label: '₹${test.priceInr}',
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                _InfoChip(
                  icon: Icons.schedule_rounded,
                  label: test.reportDeliveryTime,
                  color: AppColors.info,
                ),
              ],
            ),
            if (test.preparationInstructions != null &&
                test.preparationInstructions!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.offerLight,
                  borderRadius: AppDecorations.borderRadiusSm,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: AppColors.offer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        test.preparationInstructions!,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textPrimary,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            Text(
              'Sample collection',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (test.homeVisitAvailable)
                  const _CollectionOptionChip(
                    icon: Icons.home_rounded,
                    label: 'Home Visit',
                    subtitle: 'Technician at your door',
                  ),
                if (test.onsiteAvailable)
                  const _CollectionOptionChip(
                    icon: Icons.local_hospital_outlined,
                    label: 'Onsite',
                    subtitle: 'Visit diagnostic center',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            CustomButton(
              label: 'Book Now',
              icon: Icons.calendar_month_rounded,
              height: 46,
              onPressed: onBookNow,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppDecorations.borderRadiusSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CollectionOptionChip extends StatelessWidget {
  const _CollectionOptionChip({
    required this.icon,
    required this.label,
    required this.subtitle,
  });

  final IconData icon;
  final String label;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: AppDecorations.borderRadiusSm,
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                subtitle,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
