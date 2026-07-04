import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/provider_type.dart';
import '../../../auth/presentation/screens/provider_auth_gate_screen.dart';
import '../../../auth/provider/provider_auth_provider.dart';
import '../../provider/provider_status_sync.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../shared/widgets/healthcare_ui.dart';
import '../../../../data/models/doctor_model.dart';
import '../../../../shared/widgets/provider_header_avatar.dart';

/// Provider registration portal — doctor, nurse, ambulance, blood bank onboarding.
class ProviderLandingScreen extends ConsumerStatefulWidget {
  const ProviderLandingScreen({super.key});

  @override
  ConsumerState<ProviderLandingScreen> createState() =>
      _ProviderLandingScreenState();
}

class _ProviderLandingScreenState extends ConsumerState<ProviderLandingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(providerAuthProvider.notifier).refreshSession();
      await refreshProviderApplicationStatus(ref, silent: true);
    });
  }

  Future<void> _openDashboard() => openProviderDashboard(context, ref);

  String _applicationStatusRoute(ProviderType type) {
    switch (type) {
      case ProviderType.doctor:
        return AppConstants.routeApplicationSubmitted;
      case ProviderType.nurse:
        return AppConstants.routeNurseApplicationSubmitted;
      case ProviderType.ambulance:
        return AppConstants.routeAmbulanceApplicationSubmitted;
      case ProviderType.bloodBank:
        return AppConstants.routeBloodBankApplicationSubmitted;
      case ProviderType.lab:
        return AppConstants.routeLabApplicationSubmitted;
      case ProviderType.scanCenter:
        return AppConstants.routeScanApplicationSubmitted;
    }
  }

  Future<void> _signOut() async {
    await ref.read(providerAuthProvider.notifier).logout();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signed out')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(providerAuthProvider);
    final isLoggedIn = auth.isAuthenticated && auth.providerType != null;
    final type = auth.providerType;
    final verification = isLoggedIn ? readProviderVerificationStatus(ref) : null;
    final isVerified = verification == VerificationStatus.verified;

    final Widget headerTrailing = isLoggedIn
        ? ProviderHeaderAvatar(
            profilePictureUrl: auth.profilePicture,
            displayName: auth.displayName,
            onTap: _openDashboard,
          )
        : const Icon(Icons.track_changes_outlined, size: 22);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OneMgHeader(
              locationLabel: isLoggedIn
                  ? '${type!.label} account'
                  : 'Partner program',
              locationValue: isLoggedIn
                  ? (auth.displayName ?? 'Your profile')
                  : 'Register as healthcare provider',
              searchHint: isLoggedIn
                  ? 'Tap your photo for dashboard'
                  : 'Track application status',
              trailing: headerTrailing,
              onTrailingTap: isLoggedIn
                  ? null
                  : () => context.push(AppConstants.routeApplicationSubmitted),
            ),
            const SizedBox(height: 16),
            if (isLoggedIn) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: OfferPromoCard(
                  title: 'Welcome back, ${auth.displayName ?? type!.label}',
                  subtitle: isVerified
                      ? 'You are verified — open your dashboard to manage practice'
                      : 'Manage your ${type!.label.toLowerCase()} profile and track verification',
                  badge: isVerified ? 'VERIFIED' : type!.label.toUpperCase(),
                  icon: isVerified
                      ? Icons.verified_rounded
                      : Icons.verified_user_outlined,
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CustomButton(
                  label: 'Open my dashboard',
                  icon: Icons.dashboard_rounded,
                  onPressed: _openDashboard,
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CustomOutlineButton(
                  label: 'Application status',
                  icon: Icons.hourglass_top_rounded,
                  onPressed: () => context.push(_applicationStatusRoute(type!)),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CustomOutlineButton(
                  label: 'Sign out',
                  icon: Icons.logout_rounded,
                  onPressed: _signOut,
                ),
              ),
            ] else ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: OfferPromoCard(
                  title: 'Join the 1mg provider network',
                  subtitle:
                      'Submit once · admin verifies · then go live on the user app',
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
                      title: 'Doctor',
                      subtitle: 'Login or register · manage practice & bookings',
                      icon: Icons.medical_services_rounded,
                      color: AppColors.primary,
                      onTap: () => openProviderFlow(
                        context,
                        ref,
                        ProviderType.doctor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _RegistrationCard(
                      title: 'Nurse',
                      subtitle: 'Login or register · profile & bookings',
                      icon: Icons.health_and_safety_rounded,
                      color: AppColors.secondary,
                      onTap: () => openProviderFlow(
                        context,
                        ref,
                        ProviderType.nurse,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _RegistrationCard(
                      title: 'Lab test',
                      subtitle: 'Register · configure tests & home collection',
                      icon: Icons.biotech_rounded,
                      color: AppColors.primary,
                      onTap: () => openProviderFlow(
                        context,
                        ref,
                        ProviderType.lab,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _RegistrationCard(
                      title: 'Scanning',
                      subtitle: 'Register · configure imaging services & offers',
                      icon: Icons.radar_rounded,
                      color: AppColors.secondary,
                      onTap: () => openProviderFlow(
                        context,
                        ref,
                        ProviderType.scanCenter,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _RegistrationCard(
                      title: 'Ambulance',
                      subtitle: 'Login or register · fleet profile & bookings',
                      icon: Icons.local_shipping_rounded,
                      color: AppColors.primary,
                      onTap: () => openProviderFlow(
                        context,
                        ref,
                        ProviderType.ambulance,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _RegistrationCard(
                      title: 'Blood Bank',
                      subtitle: 'Login or register · facility profile & bookings',
                      icon: Icons.bloodtype_rounded,
                      color: AppColors.secondary,
                      onTap: () => openProviderFlow(
                        context,
                        ref,
                        ProviderType.bloodBank,
                      ),
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
                        subtitle: 'Complete registration in this app',
                      ),
                      _StepRow(
                        step: '2',
                        title: 'Admin review',
                        subtitle: 'Admin approves in the partner app',
                      ),
                      _StepRow(
                        step: '3',
                        title: 'Go live on user app',
                        subtitle:
                            'Verified profiles appear in the patient marketplace',
                        isLast: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const OneMgTrustStrip(),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CustomOutlineButton(
                  label: 'Check application status',
                  icon: Icons.hourglass_top_rounded,
                  onPressed: () =>
                      context.push(AppConstants.routeApplicationSubmitted),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextButton.icon(
                  onPressed: () => context.push(AppConstants.routeAdminLogin),
                  icon: const Icon(
                    Icons.admin_panel_settings_outlined,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  label: Text(
                    'Admin portal — sign in',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
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
