import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/lab_model.dart';
import '../../data/lab_tests_catalog.dart';
import '../../data/models/lab_test_model.dart';
import '../../data/lab_model_utils.dart';
import '../../provider/lab_cart_provider.dart';

class LabTestTile extends ConsumerWidget {
  const LabTestTile({
    super.key,
    required this.lab,
    required this.test,
    this.offered,
    this.onBookNow,
  });

  final LabModel lab;
  final LabTest test;
  final LabOfferedTest? offered;
  final VoidCallback? onBookNow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(labCartProvider);
    final inCart = cart.contains(test.id);
    final price = offered?.effectivePrice ?? test.effectivePrice;
    final original = offered?.priceInr ?? test.originalPriceInr ?? test.priceInr;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              test.name,
              style: AppTextStyles.titleSmall.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              test.description,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _Chip(label: test.sampleType, icon: Icons.science_outlined),
                _Chip(
                  label: test.requiresFasting ? 'Fasting required' : 'No fasting',
                  icon: Icons.restaurant_outlined,
                ),
                if (test.homeVisitAvailable)
                  const _Chip(
                    label: 'Home collection',
                    icon: Icons.home_outlined,
                  ),
                _Chip(
                  label: offered?.reportDeliveryTime ?? test.reportDeliveryTime,
                  icon: Icons.schedule_outlined,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (original > price) ...[
                  Text(
                    '₹$original',
                    style: AppTextStyles.bodySmall.copyWith(
                      decoration: TextDecoration.lineThrough,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  '₹$price',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                OutlinedButton(
                  onPressed: offered == null && lab.offeredTest(test.id) == null
                      ? null
                      : () {
                          final offer = offered ?? lab.offeredTest(test.id)!;
                          final added = ref.read(labCartProvider.notifier).addItem(
                                lab: lab,
                                item: LabCartItem.fromOfferedTest(offer),
                              );
                          if (!added && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Clear cart from another lab before adding tests.',
                                ),
                              ),
                            );
                          }
                        },
                  child: Text(inCart ? 'Added' : 'Add to Cart'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: onBookNow,
                  child: const Text('Book Now'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: AppDecorations.borderRadiusSm,
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(label, style: AppTextStyles.labelSmall),
        ],
      ),
    );
  }
}

List<LabTest> labTestsForLab(LabModel lab, {String? query}) {
  final offeredIds = lab.offeredTests
          ?.where((t) => t.enabled)
          .map((t) => t.testId)
          .toSet() ??
      {};
  var tests = LabTestsCatalog.tests
      .where((t) => offeredIds.isEmpty || offeredIds.contains(t.id))
      .toList();
  if (query != null && query.isNotEmpty) {
    tests = tests.where((t) => t.matchesQuery(query)).toList();
  }
  return tests;
}

LabOfferedTest? resolveOfferedTest(LabModel lab, LabTest test) {
  return lab.offeredTest(test.id) ??
      (lab.offeredTests?.isEmpty ?? true
          ? LabOfferedTest(
              testId: test.id,
              testName: test.name,
              categoryId: test.category.id,
              priceInr: test.priceInr,
              discountedPriceInr: test.discountedPriceInr,
              reportDeliveryTime: test.reportDeliveryTime,
              homeCollectionAvailable: test.homeVisitAvailable,
              onsiteCollectionAvailable: test.onsiteAvailable,
              description: test.description,
            )
          : null);
}
