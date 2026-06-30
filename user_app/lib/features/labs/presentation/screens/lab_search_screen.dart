import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/geo_distance_utils.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/models/lab_model.dart';
import '../../provider/lab_search_provider.dart';
import '../../data/models/lab_test_model.dart';
import '../widgets/lab_booking_sheet.dart';

class LabSearchScreen extends ConsumerStatefulWidget {
  const LabSearchScreen({
    super.key,
    required this.testId,
    required this.testName,
  });

  final String testId;
  final String testName;

  @override
  ConsumerState<LabSearchScreen> createState() => _LabSearchScreenState();
}

class _LabSearchScreenState extends ConsumerState<LabSearchScreen> {
  final _searchController = TextEditingController();
  bool _homeOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  LabSearchParams get _params => LabSearchParams(
        query: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        testId: widget.testId,
        homeCollection: _homeOnly ? true : null,
      );

  @override
  Widget build(BuildContext context) {
    final asyncLabs = ref.watch(labSearchProvider(_params));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.testName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search labs by name or city...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: AppColors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilterChip(
                    label: const Text('Home collection only'),
                    selected: _homeOnly,
                    onSelected: (v) => setState(() => _homeOnly = v),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: asyncLabs.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    e.toString().replaceFirst('Exception: ', ''),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              data: (labs) {
                if (labs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.biotech_outlined,
                            size: 48,
                            color: AppColors.grey400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No approved labs offer this test yet',
                            style: AppTextStyles.titleSmall.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Check back after labs complete registration and admin approval.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: labs.length,
                  itemBuilder: (context, index) {
                    return _VerifiedLabCard(
                      lab: labs[index],
                      testId: widget.testId,
                      testName: widget.testName,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _VerifiedLabCard extends StatelessWidget {
  const _VerifiedLabCard({
    required this.lab,
    required this.testId,
    required this.testName,
  });

  final LabModel lab;
  final String testId;
  final String testName;

  @override
  Widget build(BuildContext context) {
    final offered = lab.offeredTest(testId);
    final price = offered?.discountedPriceInr ?? offered?.priceInr;
    final distance = formatNearbyDistanceLabel(lab.distanceKm);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppDecorations.borderRadiusLg,
        border: Border.all(color: AppColors.grey200),
        boxShadow: AppDecorations.softShadow(opacity: 0.04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primaryLight,
                child: const Icon(Icons.biotech_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lab.labName ?? 'Diagnostic lab',
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(
                          '${lab.averageRating?.toStringAsFixed(1) ?? '4.5'} '
                          '(${lab.reviewCount ?? 0} reviews)',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (price != null)
                Text(
                  '₹$price',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (distance != null)
                _Chip(icon: Icons.near_me_outlined, label: distance),
              if (lab.city != null && lab.city!.isNotEmpty)
                _Chip(icon: Icons.location_on_outlined, label: lab.city!),
              if (offered?.homeCollectionAvailable == true)
                const _Chip(icon: Icons.home_rounded, label: 'Home visit'),
              if (offered?.onsiteCollectionAvailable == true)
                const _Chip(
                  icon: Icons.local_hospital_outlined,
                  label: 'Onsite',
                ),
              if (offered?.reportDeliveryTime != null)
                _Chip(
                  icon: Icons.schedule_rounded,
                  label: offered!.reportDeliveryTime!,
                ),
            ],
          ),
          const SizedBox(height: 14),
          CustomButton(
            label: 'Book test',
            icon: Icons.calendar_month_rounded,
            height: 44,
            onPressed: offered == null
                ? () {}
                : () {
                    showLabBookingSheet(
                      context,
                      test: LabTest(
                        id: offered!.testId,
                        name: offered!.testName.isNotEmpty
                            ? offered!.testName
                            : testName,
                        description: offered!.description ?? '',
                        priceInr: offered!.discountedPriceInr ?? offered!.priceInr,
                        reportDeliveryTime:
                            offered!.reportDeliveryTime ?? '24 hours',
                        category: LabTestCategory.bloodTests,
                        preparationInstructions: offered!.preparationInstructions,
                        homeVisitAvailable: offered!.homeCollectionAvailable,
                        onsiteAvailable: offered!.onsiteCollectionAvailable,
                      ),
                    );
                  },
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(label, style: AppTextStyles.labelSmall),
        ],
      ),
    );
  }
}
