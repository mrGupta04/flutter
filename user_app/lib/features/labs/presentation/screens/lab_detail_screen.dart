import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/geo_distance_utils.dart';
import '../../../../core/utils/media_url_utils.dart';
import '../../../../data/models/lab_model.dart';
import '../../../../shared/widgets/healthcare_ui.dart';
import '../../data/lab_catalog_metadata.dart';
import '../../data/lab_model_utils.dart';
import '../../provider/lab_cart_provider.dart';
import '../../provider/lab_search_provider.dart';
import '../widgets/lab_sticky_cart_bar.dart';
import '../widgets/lab_test_tile.dart';
import 'lab_tests_list_screen.dart';

class LabDetailScreen extends ConsumerWidget {
  const LabDetailScreen({super.key, required this.labId});

  final String labId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncLab = ref.watch(labDetailProvider(labId));
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: LabStickyCartBar(labId: labId),
      body: asyncLab.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (lab) => _LabDetailBody(lab: lab),
      ),
    );
  }
}

class _LabDetailBody extends ConsumerWidget {
  const _LabDetailBody({required this.lab});

  final LabModel lab;

  Future<void> _callLab() async {
    final phone = lab.mobileNumber;
    if (phone == null || phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _openDirections() async {
    final lat = lab.latitude;
    final lng = lab.longitude;
    if (lat == null || lng == null) return;
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _shareLab() {
    Share.share(
      'Book lab tests at ${lab.displayName} — ${lab.fullAddress}',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bannerUrl = lab.labImages?.isNotEmpty == true
        ? MediaUrlUtils.resolve(lab.labImages!.first)
        : '';
    final logoUrl = MediaUrlUtils.resolve(lab.profilePicture);
    final distance = formatNearbyDistanceLabel(lab.distanceKm);
    final tests = labTestsForLab(lab);

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
              lab.displayName,
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            background: Stack(
              fit: StackFit.expand,
              children: [
                if (bannerUrl.isNotEmpty)
                  CachedNetworkImage(imageUrl: bannerUrl, fit: BoxFit.cover)
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 64,
                        height: 64,
                        color: AppColors.grey100,
                        child: logoUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: logoUrl,
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.biotech_rounded,
                                color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lab.displayName,
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  size: 16, color: Colors.amber),
                              Text(
                                ' ${lab.ratingValue.toStringAsFixed(1)} '
                                '(${lab.reviewsCount} reviews)',
                                style: AppTextStyles.labelMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          if (distance != null) ...[
                            const SizedBox(height: 4),
                            Text(distance,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.primary,
                                )),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
    spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (lab.isNablAccredited)
                      _Badge('NABL Accredited', AppColors.success),
                    if (lab.supportsHomeCollection)
                      _Badge('Home Collection', AppColors.primary),
                    if (lab.supportsLabVisit)
                      _Badge('Lab Visit', AppColors.secondary),
                    _Badge(lab.openStatusLabel,
                        lab.isOpenNow ? AppColors.success : AppColors.error),
                  ],
                ),
                const SizedBox(height: 8),
                Text(lab.fullAddress,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.35,
                    )),
                if (lab.operatingHours != null) ...[
                  const SizedBox(height: 4),
                  Text('Hours: ${lab.operatingHours}',
                      style: AppTextStyles.bodySmall),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => context.push(AppConstants.routeLabCart),
                        icon: const Icon(Icons.shopping_cart_outlined, size: 18),
                        label: const Text('Book Test'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      onPressed: _callLab,
                      icon: const Icon(Icons.call_rounded),
                    ),
                    IconButton.filledTonal(
                      onPressed: _openDirections,
                      icon: const Icon(Icons.directions_rounded),
                    ),
                    IconButton.filledTonal(
                      onPressed: _shareLab,
                      icon: const Icon(Icons.share_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _SectionHeader(
                  title: 'Health Packages',
                  onSeeAll: () => _openTests(context, title: 'Health Packages'),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 170,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: LabCatalogMetadata.healthPackages.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final pkg = LabCatalogMetadata.healthPackages[index];
                      return _PackageCard(
                        package: pkg,
                        onTap: () => _openGroupTests(
                          context,
                          title: pkg.name,
                          testIds: pkg.testIds,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                _SectionHeader(
                  title: 'Tests by Health Risk',
                  onSeeAll: () => _openBrowse(context, LabBrowseGroupType.healthRisk),
                ),
                const SizedBox(height: 8),
                _HorizontalBrowseGroups(
                  groups: LabCatalogMetadata.healthRisks,
                  onTap: (g) => _openGroupTests(
                    context,
                    title: g.name,
                    testIds: g.testIds,
                  ),
                ),
                const SizedBox(height: 20),
                _SectionHeader(
                  title: 'Tests by Health Condition',
                  onSeeAll: () =>
                      _openBrowse(context, LabBrowseGroupType.healthCondition),
                ),
                const SizedBox(height: 8),
                _HorizontalBrowseGroups(
                  groups: LabCatalogMetadata.healthConditions,
                  onTap: (g) => _openGroupTests(
                    context,
                    title: g.name,
                    testIds: g.testIds,
                  ),
                ),
                const SizedBox(height: 20),
                _SectionHeader(
                  title: 'Tests by Body Organ',
                  onSeeAll: () => _openBrowse(context, LabBrowseGroupType.bodyOrgan),
                ),
                const SizedBox(height: 8),
                _HorizontalBrowseGroups(
                  groups: LabCatalogMetadata.bodyOrgans,
                  onTap: (g) => _openGroupTests(
                    context,
                    title: g.name,
                    testIds: g.testIds,
                  ),
                ),
                const SizedBox(height: 20),
                _SectionHeader(
                  title: 'All Individual Tests',
                  onSeeAll: () => _openTests(context, title: 'All Tests'),
                ),
                const SizedBox(height: 8),
                ...tests.take(5).map(
                      (test) => LabTestTile(
                        lab: lab,
                        test: test,
                        offered: resolveOfferedTest(lab, test),
                        onBookNow: () => context.push(AppConstants.routeLabCart),
                      ),
                    ),
                if (tests.length > 5)
                  TextButton(
                    onPressed: () => _openTests(context, title: 'All Tests'),
                    child: Text('View all ${tests.length} tests'),
                  ),
                const SizedBox(height: 20),
                _InfoBlock(
                  title: 'About the Lab',
                  body: lab.accreditation != null
                      ? 'Accredited diagnostic laboratory offering ${lab.enabledTestCount} tests with ${lab.supportsHomeCollection ? 'home collection' : 'lab visit'} services.'
                      : 'Verified diagnostic laboratory with professional sample collection and digital reports.',
                ),
                if (lab.accreditation != null)
                  _InfoBlock(
                    title: 'Certifications',
                    body: lab.accreditation!,
                  ),
                _InfoBlock(
                  title: 'Home Collection',
                  body: lab.supportsHomeCollection
                      ? 'Certified phlebotomists collect samples at your doorstep in available time slots.'
                      : 'Visit the lab for sample collection.',
                ),
                _InfoBlock(
                  title: 'Report Delivery',
                  body:
                      'Digital reports delivered via app and email. Typical turnaround: ${lab.reportDeliverySummary}.',
                ),
                const SizedBox(height: 20),
                MarketplaceSectionTitle(title: 'Customer Reviews'),
                const SizedBox(height: 8),
                ...LabCatalogMetadata.mockReviews.map(
                  (r) => _ReviewTile(
                    name: r.$1,
                    rating: r.$2,
                    comment: r.$3,
                    time: r.$4,
                  ),
                ),
                const SizedBox(height: 20),
                MarketplaceSectionTitle(title: 'FAQs'),
                const SizedBox(height: 8),
                ...LabCatalogMetadata.labFaqs.map(
                  (faq) => _FaqTile(question: faq.$1, answer: faq.$2),
                ),
                const SizedBox(height: 20),
                MarketplaceSectionTitle(title: 'Similar Labs Nearby'),
                const SizedBox(height: 8),
                _SimilarLabsSection(currentLabId: lab.id ?? ''),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _openTests(BuildContext context, {required String title}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LabTestsListScreen(lab: lab, title: title),
      ),
    );
  }

  void _openGroupTests(
    BuildContext context, {
    required String title,
    required List<String> testIds,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LabTestsListScreen(
          lab: lab,
          title: title,
          testIds: testIds,
        ),
      ),
    );
  }

  void _openBrowse(BuildContext context, LabBrowseGroupType type) {
    final title = switch (type) {
      LabBrowseGroupType.healthRisk => 'Tests by Health Risk',
      LabBrowseGroupType.healthCondition => 'Tests by Health Condition',
      LabBrowseGroupType.bodyOrgan => 'Tests by Body Organ',
      LabBrowseGroupType.package => 'Health Packages',
    };
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LabTestsListScreen(
          lab: lab,
          title: title,
          browseType: type,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.onSeeAll});

  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        if (onSeeAll != null)
          TextButton(onPressed: onSeeAll, child: const Text('See all')),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({required this.package, required this.onTap});

  final LabHealthPackage package;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: AppDecorations.borderRadiusMd,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  package.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${package.testCount} tests',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  '₹${package.discountedPriceInr}',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '₹${package.originalPriceInr}',
                  style: AppTextStyles.labelSmall.copyWith(
                    decoration: TextDecoration.lineThrough,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '${package.discountPercent}% off • ${package.reportTime}',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HorizontalBrowseGroups extends StatelessWidget {
  const _HorizontalBrowseGroups({required this.groups, required this.onTap});

  final List<LabBrowseGroup> groups;
  final ValueChanged<LabBrowseGroup> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: groups.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final g = groups[index];
          return SizedBox(
            width: 120,
            child: Card(
              child: InkWell(
                onTap: () => onTap(g),
                borderRadius: AppDecorations.borderRadiusMd,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(g.icon, color: AppColors.primary, size: 22),
                      const SizedBox(height: 6),
                      Text(
                        g.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelSmall.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'From ₹${g.startingPriceInr}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppTextStyles.labelLarge.copyWith(
                fontWeight: FontWeight.w800,
              )),
          const SizedBox(height: 4),
          Text(body,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              )),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({
    required this.name,
    required this.rating,
    required this.comment,
    required this.time,
  });

  final String name;
  final int rating;
  final String comment;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(name,
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    )),
                const Spacer(),
                ...List.generate(
                  5,
                  (i) => Icon(
                    i < rating ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 14,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(comment, style: AppTextStyles.bodySmall),
            Text(time,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                )),
          ],
        ),
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(question,
            style: AppTextStyles.labelLarge.copyWith(
              fontWeight: FontWeight.w700,
            )),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(answer, style: AppTextStyles.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _SimilarLabsSection extends ConsumerWidget {
  const _SimilarLabsSection({required this.currentLabId});

  final String currentLabId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncLabs = ref.watch(
      labSearchProvider(const LabSearchParams(pageSize: 6)),
    );
    return asyncLabs.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
      data: (labs) {
        final similar =
            labs.where((l) => l.id != currentLabId).take(3).toList();
        if (similar.isEmpty) return const SizedBox.shrink();
        return Column(
          children: similar.map((l) {
            return ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.biotech_outlined),
              ),
              title: Text(l.displayName),
              subtitle: Text(
                '⭐ ${l.ratingValue.toStringAsFixed(1)} • '
                'From ₹${l.startingPriceInr ?? '—'}',
              ),
              trailing: TextButton(
                onPressed: () => context.push(
                  '${AppConstants.routeLabDetail}/${l.id}',
                ),
                child: const Text('View'),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
