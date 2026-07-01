import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/geo_distance_utils.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/models/scan_center_model.dart';
import '../../data/models/scan_procedure_model.dart';
import '../../provider/scan_search_provider.dart';
import '../widgets/scan_booking_sheet.dart';

class ScanSearchScreen extends ConsumerStatefulWidget {
  const ScanSearchScreen({
    super.key,
    required this.scanId,
    required this.scanName,
    this.categoryId,
  });

  final String scanId;
  final String scanName;
  final String? categoryId;

  @override
  ConsumerState<ScanSearchScreen> createState() => _ScanSearchScreenState();
}

class _ScanSearchScreenState extends ConsumerState<ScanSearchScreen> {
  final _searchController = TextEditingController();
  bool _homeVisitOnly = false;
  bool _discountOnly = false;
  bool _openNowOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  ScanSearchParams get _params => ScanSearchParams(
        query: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        scanId: widget.scanId,
        categoryId: widget.categoryId,
        homeVisit: _homeVisitOnly ? true : null,
        hasOffer: _discountOnly ? true : null,
        openNow: _openNowOnly ? true : null,
      );

  @override
  Widget build(BuildContext context) {
    final asyncCenters = ref.watch(scanSearchProvider(_params));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.scanName),
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
                    hintText: 'Search scan centers, city or area...',
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
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('Home visit'),
                        selected: _homeVisitOnly,
                        onSelected: (v) => setState(() => _homeVisitOnly = v),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Discount'),
                        selected: _discountOnly,
                        onSelected: (v) => setState(() => _discountOnly = v),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Open now'),
                        selected: _openNowOnly,
                        onSelected: (v) => setState(() => _openNowOnly = v),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: asyncCenters.when(
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
              data: (centers) {
                if (centers.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.radar_outlined,
                            size: 48,
                            color: AppColors.grey400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No approved scan centers offer this scan yet',
                            style: AppTextStyles.titleSmall.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: centers.length,
                  itemBuilder: (context, index) {
                    return _VerifiedScanCenterCard(
                      center: centers[index],
                      scanId: widget.scanId,
                      scanName: widget.scanName,
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

class _VerifiedScanCenterCard extends StatelessWidget {
  const _VerifiedScanCenterCard({
    required this.center,
    required this.scanId,
    required this.scanName,
  });

  final ScanCenterModel center;
  final String scanId;
  final String scanName;

  @override
  Widget build(BuildContext context) {
    final offered = center.offeredScan(scanId);
    final price = offered?.effectivePrice;
    final originalPrice = offered?.priceInr;
    final distance = formatNearbyDistanceLabel(center.distanceKm);
    final offer = center.activeOffer;

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
                backgroundColor: AppColors.secondaryLight,
                backgroundImage: center.profilePicture != null
                    ? NetworkImage(center.profilePicture!)
                    : null,
                child: center.profilePicture == null
                    ? const Icon(Icons.radar_rounded, color: AppColors.secondary)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      center.centerName ?? 'Imaging center',
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(
                          '${center.averageRating?.toStringAsFixed(1) ?? '4.5'} '
                          '(${center.reviewCount ?? 0} reviews)',
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (offered?.discountedPriceInr != null &&
                        offered!.discountedPriceInr! < originalPrice!)
                      Text(
                        '₹$originalPrice',
                        style: AppTextStyles.labelSmall.copyWith(
                          decoration: TextDecoration.lineThrough,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    Text(
                      '₹$price',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (offer != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.offerLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                offer.offerTitle ?? 'Special offer available',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.offer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (distance != null)
                _Chip(icon: Icons.near_me_outlined, label: distance),
              if (center.city != null && center.city!.isNotEmpty)
                _Chip(icon: Icons.location_on_outlined, label: center.city!),
              if (offered?.homeVisitAvailable == true)
                const _Chip(icon: Icons.home_rounded, label: 'Home visit'),
              if (offered?.onsiteOnly == true)
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
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.push(
                    '${AppConstants.routeScanCenterDetail}/${center.id}?scanId=$scanId',
                  ),
                  child: const Text('View details'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CustomButton(
                  label: 'Book now',
                  icon: Icons.calendar_month_rounded,
                  height: 44,
                  onPressed: offered == null
                      ? () {}
                      : () {
                          showScanBookingSheet(
                            context,
                            center: center,
                            procedure: ScanProcedure(
                              id: offered!.scanId,
                              name: offered!.scanName.isNotEmpty
                                  ? offered!.scanName
                                  : scanName,
                              description: offered!.description ?? '',
                              priceInr: offered!.priceInr,
                              discountedPriceInr: offered!.discountedPriceInr,
                              reportDeliveryTime:
                                  offered!.reportDeliveryTime ?? '24 hours',
                              category: ScanCategory.other,
                              preparationInstructions:
                                  offered!.preparationInstructions,
                              fastingRequired: offered!.fastingRequired,
                              homeVisitAvailable: offered!.homeVisitAvailable,
                              onsiteOnly: offered!.onsiteOnly,
                              prescriptionRequired:
                                  offered!.prescriptionRequired,
                            ),
                          );
                        },
                ),
              ),
            ],
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
