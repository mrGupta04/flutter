import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/models/doctor_model.dart';
import '../../../../data/models/scan_center_model.dart';
import '../../../../shared/widgets/healthcare_ui.dart';
import '../../../../shared/widgets/shimmer_widgets.dart';
import '../../../auth/provider/provider_auth_provider.dart';
import '../../provider/scan_dashboard_provider.dart';

class ScanDashboardScreen extends ConsumerStatefulWidget {
  const ScanDashboardScreen({super.key});

  @override
  ConsumerState<ScanDashboardScreen> createState() =>
      _ScanDashboardScreenState();
}

class _ScanDashboardScreenState extends ConsumerState<ScanDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(scanDashboardProvider.notifier).refreshAll();
    });
  }

  Future<void> _logout() async {
    await ref.read(providerAuthProvider.notifier).logout();
    if (mounted) context.go(AppConstants.routeProviderLanding);
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = ref.watch(scanDashboardProvider);
    final center = dashboard.center;
    final isVerified =
        center?.verificationStatus == VerificationStatus.verified ||
            center?.isApproved == true;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Scan center dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: dashboard.isLoading
                ? null
                : () => ref.read(scanDashboardProvider.notifier).refreshAll(),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign out',
            onPressed: _logout,
          ),
        ],
      ),
      body: dashboard.isLoading && center == null
          ? const SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  ShimmerProfileHeader(),
                  SizedBox(height: 24),
                  ShimmerStatCard(),
                ],
              ),
            )
          : dashboard.error != null && center == null
              ? AppErrorWidget(
                  message: dashboard.error!,
                  onRetry: () =>
                      ref.read(scanDashboardProvider.notifier).loadProfile(),
                )
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(scanDashboardProvider.notifier).refreshAll(),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    children: [
                      if (center != null && !isVerified)
                        const OfferPromoCard(
                          title: 'Verification pending',
                          subtitle:
                              'Your center will go live after admin approval.',
                          icon: Icons.hourglass_top_rounded,
                        ),
                      if (center != null) ...[
                        const SizedBox(height: 8),
                        _ProfileHeader(center: center),
                      ],
                      const SizedBox(height: 20),
                      const MarketplaceSectionTitle(title: 'Overview'),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.35,
                        children: [
                          _StatCard(
                            icon: Icons.event_available_rounded,
                            label: 'Bookings',
                            value: '${dashboard.bookingsCount}',
                            color: AppColors.primary,
                          ),
                          _StatCard(
                            icon: Icons.payments_outlined,
                            label: 'Revenue',
                            value: '₹${dashboard.revenueInr}',
                            color: AppColors.secondary,
                          ),
                          _StatCard(
                            icon: Icons.local_offer_outlined,
                            label: 'Active offers',
                            value: '${dashboard.activeOffersCount}',
                            color: AppColors.primary,
                          ),
                          _StatCard(
                            icon: Icons.radar_rounded,
                            label: 'Services',
                            value: '${dashboard.servicesCount}',
                            color: AppColors.secondary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const MarketplaceSectionTitle(title: 'Manage'),
                      ServiceBenefitCard(
                        icon: Icons.person_outline_rounded,
                        title: 'Center profile',
                        subtitle: 'View verification status & contact details',
                        color: AppColors.primary,
                        onTap: () => context.push(AppConstants.routeProviderProfile),
                      ),
                      const SizedBox(height: 10),
                      ServiceBenefitCard(
                        icon: Icons.medical_services_outlined,
                        title: 'Manage scan services',
                        subtitle:
                            '${dashboard.servicesCount} procedure(s) configured',
                        color: AppColors.secondary,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Service management will be available after profile update API.',
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      ServiceBenefitCard(
                        icon: Icons.hourglass_top_rounded,
                        title: 'Application status',
                        subtitle: 'Track admin verification progress',
                        color: AppColors.primary,
                        onTap: () =>
                            context.push(AppConstants.routeScanApplicationSubmitted),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.center});

  final ScanCenterModel center;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: const Icon(Icons.radar_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  center.displayName,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (center.city != null)
                  Text(
                    center.city!,
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
