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
import '../../../../shared/widgets/healthcare_ui.dart';
import '../../../../shared/widgets/provider_profile_widgets.dart';
import '../../../nurse_home_visit/nurse_home_visit_navigation.dart';
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
              CustomOutlineButton(
                label: 'Call',
                icon: Icons.phone_rounded,
                onPressed: () => _call(nurse.mobileNumber!),
              ),
            CustomButton(
              label: nurse.homeVisitFee != null
                  ? 'Book visit · ₹${nurse.homeVisitFee}'
                  : 'Book home visit',
              icon: Icons.home_rounded,
              isEnabled: nurse.availableForHomeVisit != false,
              onPressed: () => openNurseHomeVisitBooking(context, nurse),
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
    if (nurse.specialization != null && nurse.specialization!.trim().isNotEmpty)
      'Specialization: ${nurse.specialization!.trim()}',
    if (nurse.homeVisitFee != null)
      'Home visit fee: ₹${nurse.homeVisitFee}',
    if (nurse.shiftAvailability != null &&
        nurse.shiftAvailability!.trim().isNotEmpty)
      'Availability: ${nurse.shiftAvailability!.trim()}',
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
  final origin = box != null
      ? box.localToGlobal(Offset.zero) & box.size
      : null;

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

class _NurseProfileBody extends StatelessWidget {
  const _NurseProfileBody({required this.nurse});

  final NurseModel nurse;

  @override
  Widget build(BuildContext context) {
    final imageUrl = MediaUrlUtils.resolve(nurse.profilePicture);
    final isVerified =
        nurse.verificationStatus == VerificationStatus.verified;
    final available = nurse.availableForHomeVisit != false;
    final location = _locationLine(nurse);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProviderProfileHero(
            name: nurse.displayName,
            subtitle: nurse.specialization?.trim(),
            imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
            placeholderIcon: Icons.health_and_safety_rounded,
            gradientColors: AppColors.gradientNurse,
            badges: [
              VerificationBadge(
                status: isVerified ? 'Verified nurse' : 'Admin verified listing',
                backgroundColor: AppColors.white,
                textColor: isVerified ? AppColors.success : AppColors.warning,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: available
                      ? AppColors.white
                      : AppColors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      available
                          ? Icons.check_circle_rounded
                          : Icons.cancel_outlined,
                      size: 14,
                      color: available ? AppColors.secondary : AppColors.grey500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      available ? 'Home visit available' : 'Unavailable',
                      style: AppTextStyles.labelSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: available
                            ? AppColors.secondaryDark
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const MarketplaceSectionTitle(title: 'Services offered'),
          ProviderInfoCard(
            children: [
              ProviderServiceChips(
                accentColor: AppColors.secondary,
                services: [
                  (
                    label: 'Home visit nursing',
                    icon: Icons.home_rounded,
                    available: available,
                  ),
                  if (nurse.shiftAvailability != null &&
                      nurse.shiftAvailability!.trim().isNotEmpty)
                    (
                      label: nurse.shiftAvailability!.trim(),
                      icon: Icons.schedule_rounded,
                      available: true,
                    ),
                ],
              ),
            ],
          ),
          if (nurse.homeVisitFee != null) ...[
            const SizedBox(height: 16),
            ProviderFeeBanner(
              title: 'Home visit nursing',
              fee: nurse.homeVisitFee!,
              subtitle: 'Professional care at your doorstep',
              icon: Icons.home_rounded,
              gradientColors: AppColors.gradientNurse,
            ),
          ],
          const SizedBox(height: 20),
          const MarketplaceSectionTitle(title: 'Professional details'),
          ProviderInfoCard(
            children: [
              if (nurse.gender != null && nurse.gender!.trim().isNotEmpty)
                ProviderInfoRow(
                  icon: Icons.wc_outlined,
                  label: 'Gender',
                  value: nurse.gender!.trim(),
                  iconColor: AppColors.secondary,
                ),
              if (nurse.qualification != null &&
                  nurse.qualification!.trim().isNotEmpty)
                ProviderInfoRow(
                  icon: Icons.school_outlined,
                  label: 'Qualification',
                  value: nurse.qualification!.trim(),
                  iconColor: AppColors.secondary,
                ),
              if (nurse.yearsOfExperience != null)
                ProviderInfoRow(
                  icon: Icons.work_history_outlined,
                  label: 'Experience',
                  value: '${nurse.yearsOfExperience} years',
                  iconColor: AppColors.secondary,
                ),
              if (nurse.registrationNumber != null &&
                  nurse.registrationNumber!.trim().isNotEmpty)
                ProviderInfoRow(
                  icon: Icons.badge_outlined,
                  label: 'Registration no.',
                  value: nurse.registrationNumber!.trim(),
                  iconColor: AppColors.secondary,
                ),
              if (nurse.nursingCouncil != null &&
                  nurse.nursingCouncil!.trim().isNotEmpty)
                ProviderInfoRow(
                  icon: Icons.account_balance_outlined,
                  label: 'Nursing council',
                  value: nurse.nursingCouncil!.trim(),
                  iconColor: AppColors.secondary,
                ),
            ],
          ),
          if (location.isNotEmpty) ...[
            const SizedBox(height: 16),
            const MarketplaceSectionTitle(title: 'Service area'),
            ProviderInfoCard(
              children: [
                ProviderInfoRow(
                  icon: Icons.location_on_outlined,
                  label: 'Base location',
                  value: location,
                  iconColor: AppColors.secondary,
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
