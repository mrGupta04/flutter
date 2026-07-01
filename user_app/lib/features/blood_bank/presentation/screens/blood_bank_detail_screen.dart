import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/geo_distance_utils.dart';
import '../../../../core/utils/media_url_utils.dart';
import '../../../../data/models/blood_bank_model.dart';
import '../../provider/blood_bank_search_provider.dart';
import '../widgets/blood_bank_booking_sheet.dart';
import '../widgets/blood_inventory_indicator.dart';

class BloodBankDetailScreen extends ConsumerWidget {
  const BloodBankDetailScreen({
    super.key,
    required this.bloodBankId,
    this.bloodGroup,
  });

  final String bloodBankId;
  final String? bloodGroup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncBank = ref.watch(bloodBankDetailProvider(bloodBankId));
    final asyncReviews = ref.watch(bloodBankReviewsProvider(bloodBankId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: asyncBank.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (bank) => _DetailBody(
          bank: bank,
          bloodGroup: bloodGroup,
          reviews: asyncReviews.valueOrNull ?? const [],
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.bank,
    this.bloodGroup,
    required this.reviews,
  });

  final BloodBankModel bank;
  final String? bloodGroup;
  final List<BloodReviewModel> reviews;

  Future<void> _call(String? number) async {
    if (number == null || number.isEmpty) return;
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _whatsapp(String? number) async {
    if (number == null || number.isEmpty) return;
    final uri = Uri.parse('https://wa.me/$number');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _directions() async {
    if (bank.latitude == null || bank.longitude == null) return;
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${bank.latitude},${bank.longitude}',
    );
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final distance = formatNearbyDistanceLabel(bank.distanceKm);
    final offer = bank.activeOffer;
    final imageUrl = MediaUrlUtils.resolve(
      bank.galleryImages?.isNotEmpty == true
          ? bank.galleryImages!.first
          : bank.logoUrl ?? bank.profilePicture,
    );

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
              bank.displayName,
              style: AppTextStyles.titleSmall.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            background: Stack(
              fit: StackFit.expand,
              children: [
                if (imageUrl != null)
                  Image.network(imageUrl, fit: BoxFit.cover)
                else
                  Container(color: const Color(0xFFB71C1C)),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.55)],
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
                    Text(
                      ' ${bank.averageRating?.toStringAsFixed(1) ?? '4.5'} '
                      '(${bank.reviewCount ?? 0})',
                      style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: bank.isOpenNow
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        bank.isOpenNow ? 'Open now' : 'Closed',
                        style: TextStyle(
                          color: bank.isOpenNow
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFFC62828),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (distance != null) ...[
                      const SizedBox(width: 8),
                      Text(distance, style: AppTextStyles.labelSmall),
                    ],
                  ],
                ),
                if (offer != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.offerLight,
                      borderRadius: AppDecorations.borderRadiusMd,
                    ),
                    child: Text(
                      offer.offerTitle ?? 'Special offer available',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.offer,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _Section(
                  title: 'About',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (bank.description != null) Text(bank.description!),
                      if (bank.licenseNumber != null)
                        Text('License: ${bank.licenseNumber}'),
                      if (bank.address != null) Text(bank.address!),
                      if (bank.openingTime != null)
                        Text('Hours: ${bank.openingTime} – ${bank.closingTime ?? ''}'),
                    ],
                  ),
                ),
                _Section(
                  title: 'Blood inventory',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (bank.inventory ?? [])
                        .map((e) => BloodGroupChip(
                              group: e.bloodGroup,
                              availableUnits: e.availableUnits,
                            ))
                        .toList(),
                  ),
                ),
                _Section(
                  title: 'Components & pricing',
                  child: Column(
                    children: (bank.bloodComponents ?? [])
                        .where((c) => c.enabled)
                        .map((c) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(c.componentName),
                              trailing: Text(
                                '₹${c.effectivePrice}',
                                style: AppTextStyles.labelLarge.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
                if ((bank.facilities ?? []).isNotEmpty)
                  _Section(
                    title: 'Facilities',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: bank.facilities!
                          .map((f) => Chip(label: Text(f)))
                          .toList(),
                    ),
                  ),
                if (reviews.isNotEmpty)
                  _Section(
                    title: 'Reviews',
                    child: Column(
                      children: reviews
                          .take(5)
                          .map((r) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  child: Text('${r.rating}'),
                                ),
                                title: Text(r.patientName ?? 'Patient'),
                                subtitle: Text(r.comment ?? ''),
                              ))
                          .toList(),
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _directions(),
                        icon: const Icon(Icons.directions_rounded),
                        label: const Text('Directions'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _call(bank.mobileNumber),
                        icon: const Icon(Icons.call_rounded),
                        label: const Text('Call'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _whatsapp(bank.whatsappNumber ?? bank.mobileNumber),
                        icon: const Icon(Icons.chat_rounded),
                        label: const Text('WhatsApp'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => showBloodBankBookingSheet(
                          context,
                          bloodBank: bank,
                          initialBloodGroup: bloodGroup,
                        ),
                        child: const Text('Order blood'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
