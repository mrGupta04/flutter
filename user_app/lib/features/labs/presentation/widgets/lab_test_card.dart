import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_text_styles.dart';
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
    final price = test.effectivePrice;
    final original = test.displayOriginalPrice;
    final discount = test.discountPercent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppDecorations.borderRadiusLg,
        border: Border.all(color: AppColors.grey200),
        boxShadow: AppDecorations.softShadow(opacity: 0.04),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onBookNow,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LabTestThumbnail(test: test),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            test.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.titleSmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            test.subtitleLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.labelMedium.copyWith(
                              color: const Color(0xFF2F80C4),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.medication_outlined,
                                size: 14,
                                color: AppColors.grey600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                test.testsCountLabel,
                                style: AppTextStyles.labelSmall.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.grey700,
                                  letterSpacing: 0.2,
                                  decoration: TextDecoration.underline,
                                  decorationStyle: TextDecorationStyle.dotted,
                                  decorationColor: AppColors.grey400,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Icon(
                                Icons.description_outlined,
                                size: 14,
                                color: AppColors.grey600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                test.reportTimeCompact,
                                style: AppTextStyles.labelSmall.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.grey700,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F7FA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹$price',
                                  style: AppTextStyles.titleMedium.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                    height: 1,
                                  ),
                                ),
                                if (original > price) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    '₹$original',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      decoration: TextDecoration.lineThrough,
                                      color: AppColors.grey500,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (discount != null && discount > 0) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      '$discount% OFF',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: const Color(0xFFE91E63),
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ],
                              ],
                            ),
                            if (original > price) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.local_offer_outlined,
                                    size: 12,
                                    color: AppColors.grey500,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'with coupon',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.grey500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 36,
                        child: FilledButton(
                          onPressed: onBookNow,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            minimumSize: const Size(72, 36),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                            textStyle: AppTextStyles.labelLarge.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: const Text('Add'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                color: const Color(0xFFE8F2FB),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: Color(0xFF1A4B7A),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        test.footerHighlight,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: const Color(0xFF1A4B7A),
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        color: Color(0xFF5BA3D9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
