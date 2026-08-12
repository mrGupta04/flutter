import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/responsive_utils.dart';

enum AdminNavSection {
  dashboard,
  approvals,
  providers,
  patients,
  overview,
  support,
  coupons,
  cms,
  refunds,
}

/// Adaptive shell for authenticated admin console screens.
///
/// Mobile: full-width stack (existing).
/// Tablet: navigation rail.
/// Laptop+: persistent sidebar + constrained main content.
class AdminAdaptiveShell extends StatelessWidget {
  const AdminAdaptiveShell({
    super.key,
    required this.section,
    required this.body,
    this.header,
    this.appBar,
    this.backgroundColor,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.constrainBody = true,
  });

  final AdminNavSection section;
  final Widget body;
  /// Full-bleed header content (e.g. OneMgHeader). Prefer [appBar] for AppBars.
  final Widget? header;
  final PreferredSizeWidget? appBar;
  final Color? backgroundColor;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool constrainBody;

  static AdminNavSection? sectionForLocation(String location) {
    if (location.startsWith(AppConstants.routeApprovalManagement)) {
      return AdminNavSection.approvals;
    }
    if (location.startsWith(AppConstants.routeAdminServiceProviderManagement) ||
        location.startsWith(AppConstants.routeAdminDoctorList) ||
        location.startsWith(AppConstants.routeAdminNurseList) ||
        location.startsWith(AppConstants.routeAdminAmbulanceList) ||
        location.startsWith(AppConstants.routeAdminBloodBankList) ||
        location.startsWith(AppConstants.routeAdminLabList) ||
        location.startsWith(AppConstants.routeAdminScanList) ||
        location.startsWith(AppConstants.routeAdminDoctorSessions) ||
        location.startsWith(AppConstants.routeAdminDiagnosticSessions)) {
      return AdminNavSection.providers;
    }
    if (location.startsWith(AppConstants.routeAdminPatients) ||
        location.startsWith(AppConstants.routeAdminPatientDetails)) {
      return AdminNavSection.patients;
    }
    if (location.startsWith(AppConstants.routeAdminOverview) ||
        location.startsWith(AppConstants.routeAdminBookings)) {
      return AdminNavSection.overview;
    }
    if (location.startsWith(AppConstants.routeAdminSupportTickets)) {
      return AdminNavSection.support;
    }
    if (location.startsWith(AppConstants.routeAdminCoupons)) {
      return AdminNavSection.coupons;
    }
    if (location.startsWith(AppConstants.routeAdminCmsBanners)) {
      return AdminNavSection.cms;
    }
    if (location.startsWith(AppConstants.routeAdminRefunds)) {
      return AdminNavSection.refunds;
    }
    if (location.startsWith(AppConstants.routeAdminDashboard)) {
      return AdminNavSection.dashboard;
    }
    return null;
  }

  void _go(BuildContext context, AdminNavSection target) {
    if (target == section) return;
    switch (target) {
      case AdminNavSection.dashboard:
        context.go(AppConstants.routeAdminDashboard);
      case AdminNavSection.approvals:
        context.go(AppConstants.routeApprovalManagement);
      case AdminNavSection.providers:
        context.go(AppConstants.routeAdminServiceProviderManagement);
      case AdminNavSection.patients:
        context.go(AppConstants.routeAdminPatients);
      case AdminNavSection.overview:
        context.go(AppConstants.routeAdminOverview);
      case AdminNavSection.support:
        context.go(AppConstants.routeAdminSupportTickets);
      case AdminNavSection.coupons:
        context.go(AppConstants.routeAdminCoupons);
      case AdminNavSection.cms:
        context.go(AppConstants.routeAdminCmsBanners);
      case AdminNavSection.refunds:
        context.go(AppConstants.routeAdminRefunds);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.background;
    final destinations = const [
      _AdminDestination(
        section: AdminNavSection.dashboard,
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard_rounded,
        label: 'Dashboard',
      ),
      _AdminDestination(
        section: AdminNavSection.approvals,
        icon: Icons.rule_folder_outlined,
        selectedIcon: Icons.rule_folder_rounded,
        label: 'Approvals',
      ),
      _AdminDestination(
        section: AdminNavSection.providers,
        icon: Icons.manage_accounts_outlined,
        selectedIcon: Icons.manage_accounts_rounded,
        label: 'Providers',
      ),
      _AdminDestination(
        section: AdminNavSection.patients,
        icon: Icons.people_outline_rounded,
        selectedIcon: Icons.people_rounded,
        label: 'Patients',
      ),
      _AdminDestination(
        section: AdminNavSection.overview,
        icon: Icons.analytics_outlined,
        selectedIcon: Icons.analytics_rounded,
        label: 'Overview',
      ),
      _AdminDestination(
        section: AdminNavSection.support,
        icon: Icons.support_agent_outlined,
        selectedIcon: Icons.support_agent_rounded,
        label: 'Support',
      ),
      _AdminDestination(
        section: AdminNavSection.coupons,
        icon: Icons.local_offer_outlined,
        selectedIcon: Icons.local_offer_rounded,
        label: 'Coupons',
      ),
      _AdminDestination(
        section: AdminNavSection.cms,
        icon: Icons.view_carousel_outlined,
        selectedIcon: Icons.view_carousel_rounded,
        label: 'CMS',
      ),
      _AdminDestination(
        section: AdminNavSection.refunds,
        icon: Icons.currency_exchange_rounded,
        selectedIcon: Icons.currency_exchange_rounded,
        label: 'Refunds',
      ),
    ];

    final selectedIndex = destinations
        .indexWhere((d) => d.section == section)
        .clamp(0, destinations.length - 1);

    final main = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ?header,
        Expanded(
          child: constrainBody
              ? ResponsivePage(
                  padding: ResponsiveUtils.pagePadding(context),
                  child: body,
                )
              : body,
        ),
      ],
    );

    if (ResponsiveUtils.useBottomNavigation(context)) {
      return Scaffold(
        backgroundColor: bg,
        appBar: appBar,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: bottomNavigationBar,
        body: main,
      );
    }

    final useRail = ResponsiveUtils.useNavigationRail(context);

    return Scaffold(
      backgroundColor: bg,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: Row(
        children: [
          if (useRail)
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: (i) =>
                  _go(context, destinations[i].section),
              labelType: NavigationRailLabelType.selected,
              backgroundColor: AppColors.white,
              indicatorColor: AppColors.primary.withValues(alpha: 0.12),
              selectedIconTheme:
                  const IconThemeData(color: AppColors.primary),
              unselectedIconTheme:
                  const IconThemeData(color: AppColors.textSecondary),
              destinations: [
                for (final d in destinations)
                  NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: Text(d.label),
                  ),
              ],
            )
          else
            _AdminSideNav(
              destinations: destinations,
              selectedIndex: selectedIndex,
              onSelected: (s) => _go(context, s),
            ),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: AppColors.divider.withValues(alpha: 0.8),
          ),
          Expanded(child: main),
        ],
      ),
    );
  }
}

class _AdminDestination {
  const _AdminDestination({
    required this.section,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final AdminNavSection section;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class _AdminSideNav extends StatelessWidget {
  const _AdminSideNav({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<_AdminDestination> destinations;
  final int selectedIndex;
  final ValueChanged<AdminNavSection> onSelected;

  @override
  Widget build(BuildContext context) {
    final width = ResponsiveUtils.valueFor(
      context,
      mobile: 220,
      laptop: 248,
      desktop: 268,
    );

    return Material(
      color: AppColors.white,
      child: SizedBox(
        width: width,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '1mg',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w800,
                              height: 1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Admin',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Provider verification console',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: destinations.length,
                  itemBuilder: (context, i) {
                    final d = destinations[i];
                    return _AdminSideTile(
                      destination: d,
                      selected: i == selectedIndex,
                      onTap: () => onSelected(d.section),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminSideTile extends StatefulWidget {
  const _AdminSideTile({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _AdminDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_AdminSideTile> createState() => _AdminSideTileState();
}

class _AdminSideTileState extends State<_AdminSideTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final bg = selected
        ? AppColors.primary.withValues(alpha: 0.1)
        : _hovered
            ? AppColors.grey100
            : Colors.transparent;
    final fg = selected ? AppColors.primary : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                children: [
                  Icon(
                    selected
                        ? widget.destination.selectedIcon
                        : widget.destination.icon,
                    color: fg,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.destination.label,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: fg,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
