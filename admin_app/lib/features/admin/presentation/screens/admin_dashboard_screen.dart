import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../shared/widgets/admin_adaptive_shell.dart';
import '../../../../shared/widgets/healthcare_ui.dart';
import '../../provider/admin_auth_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(adminAuthProvider);

    final cards = <_DashboardCardData>[
      _DashboardCardData(
        icon: Icons.rule_folder_rounded,
        title: 'Approval Management',
        subtitle: 'Approvers · workflow · SLA · audit logs',
        color: AppColors.primary,
        onTap: () => context.push(AppConstants.routeApprovalManagement),
      ),
      _DashboardCardData(
        icon: Icons.manage_accounts_rounded,
        title: 'Service provider management',
        subtitle: 'Online / home / hospital doctors · nurses · labs · MRI',
        color: AppColors.secondary,
        onTap: () =>
            context.push(AppConstants.routeAdminServiceProviderManagement),
      ),
      _DashboardCardData(
        icon: Icons.people_outline_rounded,
        title: 'Patients',
        subtitle: 'Search registered patient accounts',
        color: AppColors.secondary,
        onTap: () => context.push(AppConstants.routeAdminPatients),
      ),
      _DashboardCardData(
        icon: Icons.emergency_outlined,
        title: 'Ambulance operations',
        subtitle: 'Live map · dispatch · pricing · analytics',
        color: const Color(0xFFB71C1C),
        onTap: () => context.push(AppConstants.routeAdminAmbulanceOps),
      ),
      _DashboardCardData(
        icon: Icons.analytics_rounded,
        title: 'Marketplace overview',
        subtitle: 'Bookings · revenue · pending KYC',
        color: AppColors.primary,
        onTap: () => context.push(AppConstants.routeAdminOverview),
      ),
      _DashboardCardData(
        icon: Icons.support_agent_rounded,
        title: 'Support tickets',
        subtitle: 'Patient help desk · status updates',
        color: AppColors.primary,
        onTap: () => context.push(AppConstants.routeAdminSupportTickets),
      ),
      _DashboardCardData(
        icon: Icons.local_offer_outlined,
        title: 'Coupons',
        subtitle: 'Discount codes for marketplace',
        color: AppColors.secondary,
        onTap: () => context.push(AppConstants.routeAdminCoupons),
      ),
      _DashboardCardData(
        icon: Icons.view_carousel_outlined,
        title: 'CMS banners',
        subtitle: 'Home hero slides for user app',
        color: AppColors.primary,
        onTap: () => context.push(AppConstants.routeAdminCmsBanners),
      ),
      _DashboardCardData(
        icon: Icons.currency_exchange_rounded,
        title: 'Refunds',
        subtitle: 'Record refunds on paid bookings',
        color: AppColors.primary,
        onTap: () => context.push(AppConstants.routeAdminRefunds),
      ),
    ];

    return AdminAdaptiveShell(
      section: AdminNavSection.dashboard,
      constrainBody: false,
      header: OneMgHeader(
        locationLabel: 'Admin panel',
        locationValue: auth.email ?? 'Provider verification',
        searchHint: 'Review pending applications...',
        trailing: const Icon(Icons.logout_rounded, size: 20),
        onTrailingTap: () async {
          await ref.read(adminAuthProvider.notifier).logout();
          if (context.mounted) {
            context.go(AppConstants.routeAdminLogin);
          }
        },
      ),
      body: SingleChildScrollView(
        padding: ResponsiveUtils.pagePadding(context),
        child: ResponsivePage(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              const OfferPromoCard(
                title: 'Provider verification',
                subtitle:
                    'Review registrations · approve to publish on user app',
                badge: 'ADMIN',
              ),
              const SizedBox(height: 16),
              _DashboardCardGrid(cards: cards),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardCardData {
  const _DashboardCardData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
}

class _DashboardCardGrid extends StatelessWidget {
  const _DashboardCardGrid({required this.cards});

  final List<_DashboardCardData> cards;

  @override
  Widget build(BuildContext context) {
    final columns = ResponsiveUtils.gridColumns(
      context,
      mobile: 1,
      tablet: 2,
      laptop: 2,
      desktop: 3,
      largeDesktop: 3,
    );
    const gap = 12.0;

    return Column(
      children: [
        for (var row = 0; row < cards.length; row += columns) ...[
          if (row > 0) const SizedBox(height: gap),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var col = 0; col < columns; col++) ...[
                  if (col > 0) const SizedBox(width: gap),
                  Expanded(
                    child: row + col < cards.length
                        ? ServiceBenefitCard(
                            icon: cards[row + col].icon,
                            title: cards[row + col].title,
                            subtitle: cards[row + col].subtitle,
                            color: cards[row + col].color,
                            onTap: cards[row + col].onTap,
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
