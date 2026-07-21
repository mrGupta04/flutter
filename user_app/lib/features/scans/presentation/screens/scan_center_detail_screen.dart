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
import '../../../../shared/widgets/diagnostic_sticky_cart_bar.dart';
import '../../provider/scan_cart_provider.dart';
import '../widgets/scan_booking_sheet.dart';

class ScanCenterDetailScreen extends ConsumerWidget {
  const ScanCenterDetailScreen({
    super.key,
    required this.centerId,
    this.scanId,
  });

  final String centerId;
  final String? scanId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCenter = ref.watch(scanCenterDetailProvider(centerId));

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: DiagnosticStickyCartBar(centerId: centerId),
      body: asyncCenter.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (center) => _DetailBody(center: center, scanId: scanId),
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.center, this.scanId});

  final ScanCenterModel center;
  final String? scanId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scans = center.offeredScans?.where((s) => s.enabled).toList() ?? [];
    final highlighted = scanId != null ? center.offeredScan(scanId!) : null;
    final distance = formatNearbyDistanceLabel(center.distanceKm);
    final offer = center.activeOffer;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => context.pop(),
          ),
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              center.displayName,
              style: AppTextStyles.titleSmall.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            background: Stack(
              fit: StackFit.expand,
              children: [
                if (center.centerImages != null && center.centerImages!.isNotEmpty)
                  Image.network(center.centerImages!.first, fit: BoxFit.cover)
                else
                  Container(color: AppColors.primary),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.55),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '${center.averageRating?.toStringAsFixed(1) ?? '4.5'} '
                      '(${center.reviewCount ?? 0} reviews)',
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (distance != null) ...[
                      const Spacer(),
                      Icon(Icons.near_me_outlined, size: 16, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(distance, style: AppTextStyles.labelSmall),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                if (offer != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.offerLight,
                      borderRadius: AppDecorations.borderRadiusMd,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          offer.offerTitle ?? 'Special offer',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.offer,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (offer.offerDescription != null)
                          Text(
                            offer.offerDescription!,
                            style: AppTextStyles.bodySmall,
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                _InfoSection(
                  title: 'Center information',
                  children: [
                    if (center.address != null)
                      _InfoRow(Icons.location_on_outlined, center.address!),
                    if (center.city != null)
                      _InfoRow(
                        Icons.map_outlined,
                        '${center.city}, ${center.state ?? ''} ${center.pincode ?? ''}',
                      ),
                    if (center.operatingHours != null)
                      _InfoRow(Icons.schedule_rounded, center.operatingHours!),
                    if (center.homeVisitAvailable == true)
                      const _InfoRow(Icons.home_rounded, 'Home visit available'),
                    if (center.mobileNumber != null)
                      _InfoRow(Icons.phone_outlined, center.mobileNumber!),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Available scans',
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                ...scans.map((scan) {
                  final isHighlighted = highlighted?.scanId == scan.scanId;
                  final cart = ref.watch(scanCartProvider);
                  final inCart = cart.contains(scan.scanId);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: AppDecorations.borderRadiusMd,
                      border: Border.all(
                        color: isHighlighted ? AppColors.primary : AppColors.grey200,
                        width: isHighlighted ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                scan.scanName,
                                style: AppTextStyles.labelLarge.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (scan.reportDeliveryTime != null)
                                Text(
                                  'Report: ${scan.reportDeliveryTime}',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (scan.discountedPriceInr != null &&
                                scan.discountedPriceInr! < scan.priceInr)
                              Text(
                                '₹${scan.priceInr}',
                                style: AppTextStyles.labelSmall.copyWith(
                                  decoration: TextDecoration.lineThrough,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            Text(
                              '₹${scan.effectivePrice}',
                              style: AppTextStyles.titleSmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 32,
                              child: FilledButton(
                                onPressed: () {
                                  final added = ref
                                      .read(scanCartProvider.notifier)
                                      .addItem(
                                        center: center,
                                        item: ScanCartItem.fromOffered(scan),
                                      );
                                  if (!added && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Clear cart from another center before adding scans.',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: inCart
                                      ? AppColors.success
                                      : AppColors.primary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  minimumSize: const Size(64, 32),
                                ),
                                child: Text(inCart ? 'Added' : 'Add'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
                if (center.centerImages != null && center.centerImages!.length > 1) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Gallery',
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 90,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: center.centerImages!.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) => ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          center.centerImages![i],
                          width: 120,
                          height: 90,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                CustomButton(
                  label: 'Proceed to cart',
                  icon: Icons.shopping_cart_outlined,
                  onPressed: () => context.push(AppConstants.routeLabCart),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    final target = highlighted ??
                        (scans.isNotEmpty ? scans.first : null);
                    if (target == null) return;
                    showScanBookingSheet(
                      context,
                      center: center,
                      procedure: ScanProcedure(
                        id: target.scanId,
                        name: target.scanName,
                        description: target.description ?? '',
                        priceInr: target.priceInr,
                        discountedPriceInr: target.discountedPriceInr,
                        reportDeliveryTime: target.reportDeliveryTime ?? '24 hours',
                        category: ScanCategory.other,
                        preparationInstructions: target.preparationInstructions,
                        fastingRequired: target.fastingRequired,
                        homeVisitAvailable: target.homeVisitAvailable,
                        onsiteOnly: target.onsiteOnly,
                        prescriptionRequired: target.prescriptionRequired,
                      ),
                    );
                  },
                  icon: const Icon(Icons.calendar_month_rounded, size: 18),
                  label: const Text('Book single scan'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppDecorations.borderRadiusMd,
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppTextStyles.bodySmall)),
        ],
      ),
    );
  }
}
