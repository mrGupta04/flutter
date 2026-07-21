import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/media_url_utils.dart';
import '../../../../core/utils/provider_location_utils.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/models/doctor_model.dart';
import '../../../../data/models/nurse_model.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../../../shared/widgets/blinking_online_badge.dart';
import '../../../../shared/widgets/doctor_feedback_carousel.dart';
import '../../../../shared/widgets/favorite_toggle_button.dart';
import '../../../../shared/widgets/healthcare_ui.dart';
import '../../../../shared/widgets/nurse_feedback_carousel.dart';
import '../../../../shared/widgets/provider_profile_widgets.dart';
import '../../../nurse_home_visit/nurse_home_visit_navigation.dart';
import '../../provider/nurse_feedback_provider.dart';
import '../../provider/nurse_profile_provider.dart';

class NurseProfileScreen extends ConsumerWidget {
  const NurseProfileScreen({super.key, required this.nurseId});

  final String nurseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncNurse = ref.watch(nurseProfileProvider(nurseId));

    return asyncNurse.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Nurse profile')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Nurse profile')),
        body: AppErrorWidget(
          message: error.toString().replaceFirst('Exception: ', ''),
          onRetry: () => ref.invalidate(nurseProfileProvider(nurseId)),
        ),
      ),
      data: (nurse) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Nurse profile'),
          actions: [
            FavoriteToggleButton(
              providerType: 'nurse',
              providerId: nurse.id ?? nurseId,
            ),
            IconButton(
              tooltip: 'Share profile',
              icon: const Icon(Icons.share_outlined),
              onPressed: () => _shareNurseProfile(context, nurse),
            ),
          ],
        ),
        bottomNavigationBar: ProviderStickyActionBar(
          children: [
            if (nurse.mobileNumber != null && nurse.mobileNumber!.isNotEmpty)
              SizedBox(
                height: 54,
                child: CustomOutlineButton(
                  label: 'Call',
                  icon: Icons.phone_rounded,
                  onPressed: () => _call(nurse.mobileNumber!),
                ),
              ),
            SizedBox(
              height: 54,
              child: CustomButton(
                label: nurse.effectiveHomeVisitFee != null
                    ? 'Book visit · ₹${nurse.effectiveHomeVisitFee}'
                    : 'Book home visit',
                icon: Icons.home_rounded,
                isEnabled: nurse.availableForHomeVisit != false,
                onPressed: () => openNurseHomeVisitBooking(context, nurse),
              ),
            ),
          ],
        ),
        body: _NurseProfileBody(nurse: nurse),
      ),
    );
  }
}

Future<void> _shareNurseProfile(BuildContext context, NurseModel nurse) async {
  final lines = <String>[
    'Check out ${nurse.displayName} on 1mg Care',
    if (nurse.profileHeroSubtitle != null)
      nurse.profileHeroSubtitle!,
    if (nurse.hasRating)
      'Rating: ${nurse.averageRating!.toStringAsFixed(1)}'
          '${(nurse.ratingCount ?? 0) > 0 ? ' (${nurse.ratingCount} reviews)' : ''}',
    if (nurse.effectiveHomeVisitFee != null)
      'Home visit fee: ₹${nurse.effectiveHomeVisitFee}',
  ];

  final location = _locationLine(nurse);
  if (location.isNotEmpty) {
    lines.add('Location: $location');
  }

  if (nurse.id != null && nurse.id!.isNotEmpty) {
    lines.add('');
    lines.add(
      'View profile: ${AppConstants.routeNurseProfile}?id=${Uri.encodeComponent(nurse.id!)}',
    );
  }

  final box = context.findRenderObject() as RenderBox?;
  final origin =
      box != null ? box.localToGlobal(Offset.zero) & box.size : null;

  await Share.share(
    lines.join('\n'),
    subject: '${nurse.displayName} — 1mg Care',
    sharePositionOrigin: origin,
  );
}

String _locationLine(NurseModel nurse) {
  final parts = [
    if (nurse.address != null && nurse.address!.trim().isNotEmpty)
      nurse.address!.trim(),
    if (nurse.city != null && nurse.city!.trim().isNotEmpty) nurse.city!.trim(),
    if (nurse.state != null && nurse.state!.trim().isNotEmpty) nurse.state!.trim(),
    if (nurse.pincode != null && nurse.pincode!.trim().isNotEmpty)
      nurse.pincode!.trim(),
  ];
  return parts.join(', ');
}

Future<void> _call(String number) async {
  final digits = number.replaceAll(RegExp(r'\D'), '');
  final uri = Uri.parse('tel:$digits');
  if (!await launchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _NurseProfileBody extends ConsumerWidget {
  const _NurseProfileBody({required this.nurse});

  final NurseModel nurse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageUrl = MediaUrlUtils.resolve(nurse.profilePicture);
    final isVerified =
        nurse.verificationStatus == VerificationStatus.verified;
    final available = nurse.availableForHomeVisit != false;
    final location = _locationLine(nurse);
    final skills = nurse.nursingSkills
            ?.where((s) => s.trim().isNotEmpty)
            .map((s) => s.trim())
            .toList() ??
        const <String>[];
    final languages = nurse.languagesSpoken
            ?.where((s) => s.trim().isNotEmpty)
            .map((s) => s.trim())
            .toList() ??
        const <String>[];
    final feedbackAsync = nurse.id != null && nurse.id!.isNotEmpty
        ? ref.watch(nurseFeedbackProvider(nurse.id!))
        : null;

    final professionalRows = <Widget>[
      if (nurse.qualification != null &&
          nurse.qualification!.trim().isNotEmpty)
        ProviderInfoRow(
          icon: Icons.school_outlined,
          label: 'Qualification',
          value: nurse.qualification!.trim(),
          iconColor: AppColors.primary,
        ),
      if (nurse.yearsOfExperience != null)
        ProviderInfoRow(
          icon: Icons.work_history_outlined,
          label: 'Experience',
          value: '${nurse.yearsOfExperience}+ years',
          iconColor: AppColors.primary,
        ),
      if (nurse.specialization != null &&
          nurse.specialization!.trim().isNotEmpty)
        ProviderInfoRow(
          icon: Icons.medical_information_outlined,
          label: 'Specialization',
          value: nurse.specialization!.trim(),
          iconColor: AppColors.primary,
        ),
      if (languages.isNotEmpty)
        ProviderInfoRow(
          icon: Icons.translate_rounded,
          label: 'Languages',
          value: languages.join(', '),
          iconColor: AppColors.primary,
        ),
      if (nurse.registrationNumber != null &&
          nurse.registrationNumber!.trim().isNotEmpty)
        ProviderInfoRow(
          icon: Icons.badge_outlined,
          label: 'Registration no.',
          value: nurse.registrationNumber!.trim(),
          iconColor: AppColors.primary,
        ),
      if (nurse.nuid != null && nurse.nuid!.trim().isNotEmpty)
        ProviderInfoRow(
          icon: Icons.fingerprint_outlined,
          label: 'NUID',
          value: nurse.nuid!.trim(),
          iconColor: AppColors.primary,
        ),
      if (nurse.nursingCouncil != null &&
          nurse.nursingCouncil!.trim().isNotEmpty)
        ProviderInfoRow(
          icon: Icons.account_balance_outlined,
          label: 'Nursing council',
          value: nurse.nursingCouncil!.trim(),
          iconColor: AppColors.primary,
        ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProviderProfileHero(
            name: nurse.displayName,
            subtitle: nurse.profileHeroSubtitle,
            imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
            avatarSize: 148,
            placeholderIcon: Icons.health_and_safety_rounded,
            gradientColors: AppColors.gradientNurse,
            badges: [
              DoctorOverallRatingChip(
                rating: nurse.cardDisplayRating,
                count: nurse.hasRating ? nurse.ratingCount : null,
              ),
              VerificationBadge(
                status: isVerified ? 'Verified nurse' : 'Pending verification',
                backgroundColor: AppColors.white,
                textColor: isVerified ? AppColors.success : AppColors.warning,
                solid: true,
              ),
              _AvailabilityChip(available: available),
            ],
          ),
          if (nurse.isLiveNow) ...[
            const SizedBox(height: 10),
            const Center(child: LiveAvailableBadge()),
          ],
          const SizedBox(height: 16),
          _NurseQuickStats(
            rating: nurse.cardDisplayRating,
            ratingCount: nurse.hasRating ? nurse.ratingCount : null,
            experienceYears: nurse.yearsOfExperience,
            fee: nurse.effectiveHomeVisitFee,
            originalFee: nurse.originalHomeVisitFee,
          ),
          if (skills.isNotEmpty) ...[
            const SizedBox(height: 20),
            const MarketplaceSectionTitle(title: 'Clinical skills'),
            ProviderInfoCard(
              children: [
                ProviderInfoRow(
                  icon: Icons.medical_services_outlined,
                  label: 'Services & skills',
                  value: skills.join(' · '),
                  iconColor: AppColors.primary,
                ),
              ],
            ),
          ],
          if (professionalRows.isNotEmpty) ...[
            const SizedBox(height: 20),
            const MarketplaceSectionTitle(title: 'Professional details'),
            ProviderInfoCard(children: professionalRows),
          ],
          if (location.isNotEmpty || nurse.serviceRadiusKm != null) ...[
            const SizedBox(height: 16),
            const MarketplaceSectionTitle(title: 'Service area'),
            ProviderInfoCard(
              children: [
                if (location.isNotEmpty)
                  ProviderInfoRow(
                    icon: Icons.location_on_outlined,
                    label: 'Base location',
                    value: location,
                    iconColor: AppColors.primary,
                  ),
                if (nurse.serviceRadiusKm != null)
                  ProviderInfoRow(
                    icon: Icons.radar_outlined,
                    label: 'Service radius',
                    value: '${nurse.serviceRadiusKm} km',
                    iconColor: AppColors.primary,
                  ),
              ],
            ),
            if (nurseHasMapLocation(nurse)) ...[
              const SizedBox(height: 12),
              CustomOutlineButton(
                label: 'View on map',
                icon: Icons.map_rounded,
                onPressed: () => openNurseInGoogleMaps(context, nurse),
              ),
            ],
          ],
          if (feedbackAsync != null) ...[
            const SizedBox(height: 20),
            feedbackAsync.when(
              loading: () => const SizedBox(
                height: 148,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const SizedBox.shrink(),
              data: (feedback) {
                if (!feedback.hasReviews) return const SizedBox.shrink();
                return NurseFeedbackCarousel(
                  reviews: feedback.reviews,
                  averageRating: feedback.averageRating ?? nurse.averageRating,
                  ratingCount: feedback.ratingCount > 0
                      ? feedback.ratingCount
                      : (nurse.ratingCount ?? 0),
                );
              },
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _AvailabilityChip extends StatelessWidget {
  const _AvailabilityChip({required this.available});

  final bool available;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            available ? Icons.check_circle_rounded : Icons.cancel_outlined,
            size: 14,
            color: available ? AppColors.success : AppColors.grey500,
          ),
          const SizedBox(width: 4),
          Text(
            available ? 'Home visit available' : 'Unavailable',
            style: AppTextStyles.labelSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: available ? AppColors.success : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _NurseQuickStats extends StatelessWidget {
  const _NurseQuickStats({
    required this.rating,
    this.ratingCount,
    this.experienceYears,
    this.fee,
    this.originalFee,
  });

  final double rating;
  final int? ratingCount;
  final int? experienceYears;
  final int? fee;
  final int? originalFee;

  @override
  Widget build(BuildContext context) {
    final items = <({IconData icon, String label, String value, String? strikeValue})>[
      (
        icon: Icons.star_rounded,
        label: 'Rating',
        value: ratingCount != null && ratingCount! > 0
            ? '${rating.toStringAsFixed(1)} ($ratingCount)'
            : rating.toStringAsFixed(1),
        strikeValue: null,
      ),
      if (experienceYears != null)
        (
          icon: Icons.work_outline_rounded,
          label: 'Experience',
          value: '$experienceYears+ yrs',
          strikeValue: null,
        ),
      if (fee != null)
        (
          icon: Icons.currency_rupee_rounded,
          label: 'Visit fee',
          value: '₹$fee',
          strikeValue: originalFee != null ? '₹$originalFee' : null,
        ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              Container(
                width: 1,
                height: 36,
                color: AppColors.divider,
              ),
            Expanded(
              child: Column(
                children: [
                  Icon(items[i].icon, size: 18, color: AppColors.primary),
                  const SizedBox(height: 6),
                  if (items[i].strikeValue != null) ...[
                    Text(
                      items[i].strikeValue!,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.grey400,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    items[i].value,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    items[i].label,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Navigate to nurse profile from listings.
void openNurseProfile(BuildContext context, NurseModel nurse) {
  final id = nurse.id;
  if (id == null || id.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This nurse profile is not available yet.')),
    );
    return;
  }
  context.push(
    '${AppConstants.routeNurseProfile}?id=${Uri.encodeComponent(id)}',
  );
}
