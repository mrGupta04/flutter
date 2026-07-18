import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/models/doctor_model.dart';
import '../../../../data/models/lab_model.dart';
import '../../../../shared/widgets/healthcare_ui.dart';
import '../../../../shared/widgets/shimmer_widgets.dart';
import '../../../auth/provider/provider_auth_provider.dart';
import '../../provider/lab_dashboard_provider.dart';

class LabDashboardScreen extends ConsumerStatefulWidget {
  const LabDashboardScreen({super.key});

  @override
  ConsumerState<LabDashboardScreen> createState() =>
      _LabDashboardScreenState();
}

class _LabDashboardScreenState extends ConsumerState<LabDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(labDashboardProvider.notifier).refreshAll();
    });
  }

  Future<void> _logout() async {
    await ref.read(providerAuthProvider.notifier).logout();
    if (mounted) context.go(AppConstants.routeProviderLanding);
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = ref.watch(labDashboardProvider);
    final lab = dashboard.lab;
    final isVerified =
        lab?.verificationStatus == VerificationStatus.verified ||
            lab?.isApproved == true;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Laboratory dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: dashboard.isLoading
                ? null
                : () => ref.read(labDashboardProvider.notifier).refreshAll(),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign out',
            onPressed: _logout,
          ),
        ],
      ),
      body: dashboard.isLoading && lab == null
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
          : dashboard.error != null && lab == null
              ? AppErrorWidget(
                  message: dashboard.error!,
                  onRetry: () =>
                      ref.read(labDashboardProvider.notifier).loadProfile(),
                )
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(labDashboardProvider.notifier).refreshAll(),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    children: [
                      if (lab != null && !isVerified)
                        const OfferPromoCard(
                          title: 'Verification pending',
                          subtitle:
                              'Your laboratory will go live after admin approval.',
                          icon: Icons.hourglass_top_rounded,
                        ),
                      if (lab != null) ...[
                        const SizedBox(height: 8),
                        _ProfileHeader(lab: lab),
                      ],
                      const SizedBox(height: 20),
                      const MarketplaceSectionTitle(title: 'Today\'s overview'),
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
                            label: 'Today\'s bookings',
                            value: '${dashboard.todaysBookings}',
                            color: AppColors.primary,
                          ),
                          _StatCard(
                            icon: Icons.home_outlined,
                            label: 'Home collections',
                            value: '${dashboard.homeCollections}',
                            color: AppColors.secondary,
                          ),
                          _StatCard(
                            icon: Icons.pending_actions_outlined,
                            label: 'Pending reports',
                            value: '${dashboard.pendingReports}',
                            color: AppColors.primary,
                          ),
                          _StatCard(
                            icon: Icons.payments_outlined,
                            label: 'Revenue',
                            value: '₹${dashboard.revenueInr}',
                            color: AppColors.secondary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const MarketplaceSectionTitle(title: 'Catalog'),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.35,
                        children: [
                          _StatCard(
                            icon: Icons.biotech_outlined,
                            label: 'Active tests',
                            value: '${dashboard.testsCount}',
                            color: AppColors.primary,
                          ),
                          _StatCard(
                            icon: Icons.medical_information_outlined,
                            label: 'Health packages',
                            value: '${dashboard.packagesCount}',
                            color: AppColors.secondary,
                          ),
                          _StatCard(
                            icon: Icons.calendar_month_outlined,
                            label: 'Upcoming',
                            value: '${dashboard.upcomingBookings}',
                            color: AppColors.primary,
                          ),
                          _StatCard(
                            icon: Icons.star_outline_rounded,
                            label: 'Rating',
                            value: lab?.averageRating != null
                                ? lab!.averageRating!.toStringAsFixed(1)
                                : '—',
                            color: AppColors.secondary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const MarketplaceSectionTitle(title: 'Manage'),
                      ServiceBenefitCard(
                        icon: Icons.person_outline_rounded,
                        title: 'Lab profile',
                        subtitle: 'View verification status & contact details',
                        color: AppColors.primary,
                        onTap: () => context.push(AppConstants.routeProviderProfile),
                      ),
                      const SizedBox(height: 10),
                      ServiceBenefitCard(
                        icon: Icons.science_outlined,
                        title: 'Tests & packages',
                        subtitle:
                            '${dashboard.testsCount} test(s) in your catalog',
                        color: AppColors.secondary,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Test catalog management will be available in a future update.',
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      ServiceBenefitCard(
                        icon: Icons.assignment_outlined,
                        title: 'Booking management',
                        subtitle:
                            '${dashboard.upcomingBookings} open · ₹${dashboard.revenueInr} paid',
                        color: AppColors.primary,
                        onTap: () => _showBookingsSheet(context, ref, dashboard),
                      ),
                      const SizedBox(height: 10),
                      ServiceBenefitCard(
                        icon: Icons.hourglass_top_rounded,
                        title: 'Application status',
                        subtitle: 'Track admin verification progress',
                        color: AppColors.secondary,
                        onTap: () =>
                            context.push(AppConstants.routeLabApplicationSubmitted),
                      ),
                    ],
                  ),
                ),
    );
  }

  void _showBookingsSheet(
    BuildContext context,
    WidgetRef ref,
    LabDashboardState dashboard,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final bookings = dashboard.bookings;
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(ctx).height * 0.7,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Lab bookings',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                ),
                Expanded(
                  child: bookings.isEmpty
                      ? const Center(child: Text('No bookings yet'))
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: bookings.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final b = bookings[i];
                            return ListTile(
                              tileColor: AppColors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: AppColors.divider),
                              ),
                              title: Text(b.patientName),
                              subtitle: Text(
                                '${b.label}\n${b.status} · ${b.paymentStatus} · ₹${b.amount}',
                              ),
                              isThreeLine: true,
                              trailing: PopupMenuButton<String>(
                                onSelected: (status) async {
                                  final ok = await ref
                                      .read(labDashboardProvider.notifier)
                                      .updateBookingStatus(
                                        bookingId: b.id,
                                        status: status,
                                      );
                                  if (ctx.mounted) {
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          ok
                                              ? 'Updated to $status'
                                              : 'Update failed',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'confirmed',
                                    child: Text('Confirm'),
                                  ),
                                  PopupMenuItem(
                                    value: 'sample_collected',
                                    child: Text('Sample collected'),
                                  ),
                                  PopupMenuItem(
                                    value: 'processing',
                                    child: Text('Processing'),
                                  ),
                                  PopupMenuItem(
                                    value: 'report_ready',
                                    child: Text('Report ready'),
                                  ),
                                  PopupMenuItem(
                                    value: 'completed',
                                    child: Text('Complete'),
                                  ),
                                  PopupMenuItem(
                                    value: 'rejected',
                                    child: Text('Reject'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.lab});

  final LabModel lab;

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
            backgroundImage: lab.profilePicture != null
                ? NetworkImage(lab.profilePicture!)
                : null,
            child: lab.profilePicture == null
                ? const Icon(Icons.biotech_rounded, color: AppColors.primary)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lab.labName ?? 'Laboratory',
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (lab.city != null)
                  Text(
                    lab.city!,
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 22),
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
