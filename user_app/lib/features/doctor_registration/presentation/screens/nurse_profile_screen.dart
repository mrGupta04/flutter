import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/media_url_utils.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/models/doctor_model.dart';
import '../../../../data/models/nurse_model.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../../../shared/widgets/healthcare_ui.dart';
import '../../../nurse_home_visit/nurse_home_visit_navigation.dart';
import '../../provider/nurse_profile_provider.dart';

class NurseProfileScreen extends ConsumerWidget {
  const NurseProfileScreen({super.key, required this.nurseId});

  final String nurseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncNurse = ref.watch(nurseProfileProvider(nurseId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Nurse profile'),
      ),
      body: asyncNurse.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppErrorWidget(
          message: error.toString().replaceFirst('Exception: ', ''),
          onRetry: () => ref.invalidate(nurseProfileProvider(nurseId)),
        ),
        data: (nurse) => _NurseProfileBody(nurse: nurse),
      ),
    );
  }
}

class _NurseProfileBody extends StatelessWidget {
  const _NurseProfileBody({required this.nurse});

  final NurseModel nurse;

  @override
  Widget build(BuildContext context) {
    final imageUrl = MediaUrlUtils.resolve(nurse.profilePicture);
    final hasImage = imageUrl.isNotEmpty;
    final isVerified =
        nurse.verificationStatus == VerificationStatus.verified;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: AppColors.gradientHero),
              borderRadius: AppDecorations.borderRadiusXl,
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.white,
                  backgroundImage:
                      hasImage ? CachedNetworkImageProvider(imageUrl) : null,
                  child: !hasImage
                      ? const Icon(
                          Icons.health_and_safety_rounded,
                          size: 48,
                          color: AppColors.primary,
                        )
                      : null,
                ),
                const SizedBox(height: 14),
                Text(
                  nurse.displayName,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (nurse.specialization != null &&
                    nurse.specialization!.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    nurse.specialization!.trim(),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.white.withValues(alpha: 0.92),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                VerificationBadge(
                  status: isVerified ? 'Verified nurse' : 'Admin verified listing',
                  backgroundColor: AppColors.white,
                  textColor: isVerified ? AppColors.success : AppColors.warning,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const MarketplaceSectionTitle(title: 'Professional details'),
          _InfoCard(
            children: [
              if (nurse.gender != null && nurse.gender!.trim().isNotEmpty)
                _InfoRow(
                  icon: Icons.wc_outlined,
                  label: 'Gender',
                  value: nurse.gender!.trim(),
                ),
              if (nurse.qualification != null &&
                  nurse.qualification!.trim().isNotEmpty)
                _InfoRow(
                  icon: Icons.school_outlined,
                  label: 'Qualification',
                  value: nurse.qualification!.trim(),
                ),
              if (nurse.yearsOfExperience != null)
                _InfoRow(
                  icon: Icons.work_history_outlined,
                  label: 'Experience',
                  value: '${nurse.yearsOfExperience} years',
                ),
              if (nurse.registrationNumber != null &&
                  nurse.registrationNumber!.trim().isNotEmpty)
                _InfoRow(
                  icon: Icons.badge_outlined,
                  label: 'Registration no.',
                  value: nurse.registrationNumber!.trim(),
                ),
              if (nurse.nursingCouncil != null &&
                  nurse.nursingCouncil!.trim().isNotEmpty)
                _InfoRow(
                  icon: Icons.account_balance_outlined,
                  label: 'Nursing council',
                  value: nurse.nursingCouncil!.trim(),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const MarketplaceSectionTitle(title: 'Home visit nursing'),
          _InfoCard(
            children: [
              if (_locationLine(nurse).isNotEmpty)
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  label: 'Base location',
                  value: _locationLine(nurse),
                ),
              if (nurse.homeVisitFee != null)
                _InfoRow(
                  icon: Icons.currency_rupee_rounded,
                  label: 'Home visit fee',
                  value: '₹${nurse.homeVisitFee}',
                ),
            ],
          ),
          const SizedBox(height: 24),
          CustomButton(
            label: nurse.homeVisitFee != null
                ? 'Book home visit • ₹${nurse.homeVisitFee}'
                : 'Book home visit',
            icon: Icons.home_rounded,
            onPressed: () => openNurseHomeVisitBooking(context, nurse),
          ),
          if (nurse.mobileNumber != null && nurse.mobileNumber!.isNotEmpty) ...[
            const SizedBox(height: 12),
            CustomButton(
              label: 'Call ${nurse.mobileNumber}',
              icon: Icons.phone_rounded,
              onPressed: () => _call(nurse.mobileNumber!),
            ),
          ],
        ],
      ),
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
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Text(
          'No additional details provided.',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
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
