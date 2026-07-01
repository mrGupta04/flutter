import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../shared/widgets/healthcare_ui.dart';

/// Provider registration — ambulance and blood bank onboarding.
class ProviderLandingScreen extends StatelessWidget {
  const ProviderLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Provider registration'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: OfferPromoCard(
                title: 'Join the 1mg Care network',
                subtitle:
                    'Register with a profile photo · admin verifies · go live in the app',
                badge: 'PARTNER',
              ),
            ),
            const SizedBox(height: 20),
            const MarketplaceSectionTitle(title: 'Register as'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _RegistrationCard(
                    title: 'Ambulance',
                    subtitle: 'Fleet details, license & service area',
                    icon: Icons.local_shipping_rounded,
                    color: AppColors.primary,
                    onTap: () =>
                        context.push(AppConstants.routeAmbulanceRegistration),
                  ),
                  const SizedBox(height: 10),
                  _RegistrationCard(
                    title: 'Blood Bank',
                    subtitle: 'License, blood groups & facility details',
                    icon: Icons.bloodtype_rounded,
                    color: AppColors.secondary,
                    onTap: () =>
                        context.push(AppConstants.routeBloodBankRegistration),
                  ),
                  const SizedBox(height: 10),
                  _RegistrationCard(
                    title: 'Diagnostic Lab',
                    subtitle: 'Configure tests, documents & home collection',
                    icon: Icons.biotech_rounded,
                    color: AppColors.primary,
                    onTap: () => context.push(AppConstants.routeLabRegistration),
                  ),
                  const SizedBox(height: 10),
                  _RegistrationCard(
                    title: 'Scan Center',
                    subtitle: 'MRI, CT, X-Ray, ultrasound & imaging services',
                    icon: Icons.radar_rounded,
                    color: AppColors.secondary,
                    onTap: () => context.push(AppConstants.routeScanRegistration),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const MarketplaceSectionTitle(title: 'How verification works'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  children: const [
                    _StepRow(
                      step: '1',
                      title: 'Submit application',
                      subtitle: 'Complete registration with a profile photo',
                    ),
                    _StepRow(
                      step: '2',
                      title: 'Admin review',
                      subtitle: 'Our team verifies your credentials',
                    ),
                    _StepRow(
                      step: '3',
                      title: 'Go live',
                      subtitle:
                          'Your profile appears in the patient marketplace',
                      isLast: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CustomOutlineButton(
                label: 'Back to home',
                icon: Icons.home_outlined,
                onPressed: () => context.go(AppConstants.routeUserHome),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _RegistrationCard extends StatelessWidget {
  const _RegistrationCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.step,
    required this.title,
    required this.subtitle,
    this.isLast = false,
  });

  final String step;
  final String title;
  final String subtitle;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.primary,
            child: Text(
              step,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
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
