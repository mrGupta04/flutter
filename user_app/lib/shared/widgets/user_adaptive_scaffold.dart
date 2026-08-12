import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/token_storage.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/responsive_utils.dart';
import 'user_app_footer.dart';

/// Adaptive shell for tabbed marketplace screens.
///
/// Mobile: bottom navigation (existing look).
/// Tablet: navigation rail.
/// Laptop+: persistent sidebar + max-width content.
class UserAdaptiveScaffold extends StatelessWidget {
  const UserAdaptiveScaffold({
    super.key,
    required this.currentTab,
    required this.body,
    this.backgroundColor,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.endDrawer,
    this.secondaryBottomBar,
    this.extendBodyBehindAppBar = false,
    this.constrainBody = false,
  });

  final UserNavTab currentTab;
  final Widget body;
  final Color? backgroundColor;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? endDrawer;
  /// Extra bar above bottom nav (e.g. sticky cart). Ignored as bottom nav on rail/sidebar.
  final Widget? secondaryBottomBar;
  final bool extendBodyBehindAppBar;
  /// When true, wraps [body] in [ResponsivePage]. Keep false when the body
  /// includes a full-bleed header; constrain inner content instead.
  final bool constrainBody;

  Future<void> _onTap(BuildContext context, UserNavTab tab) async {
    if (tab == currentTab) return;
    switch (tab) {
      case UserNavTab.home:
        context.go(AppConstants.routeUserHome);
      case UserNavTab.labs:
        context.go(AppConstants.routeLabs);
      case UserNavTab.care:
        context.go('${AppConstants.routeCareListing}?role=doctor');
      case UserNavTab.profile:
        final loggedIn = await TokenStorage.instance.isPatientLoggedIn();
        if (!context.mounted) return;
        if (loggedIn) {
          context.go(AppConstants.routeUserDashboard);
        } else {
          context.go(AppConstants.routeUserLogin);
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.background;
    final useBottom = ResponsiveUtils.useBottomNavigation(context);
    final useRail = ResponsiveUtils.useNavigationRail(context);

    final constrainedBody = constrainBody
        ? ResponsivePage(child: body)
        : body;

    if (useBottom) {
      final Widget bottomBar = secondaryBottomBar == null
          ? UserBottomNavBar(currentTab: currentTab)
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                secondaryBottomBar!,
                UserBottomNavBar(currentTab: currentTab),
              ],
            );

      return Scaffold(
        backgroundColor: bg,
        appBar: appBar,
        extendBodyBehindAppBar: extendBodyBehindAppBar,
        endDrawer: endDrawer,
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
        bottomNavigationBar: bottomBar,
        body: constrainedBody,
      );
    }

    final destinations = const [
      _NavDestination(
        tab: UserNavTab.home,
        icon: Icons.home_outlined,
        selectedIcon: Icons.home_rounded,
        label: 'Home',
      ),
      _NavDestination(
        tab: UserNavTab.labs,
        icon: Icons.biotech_outlined,
        selectedIcon: Icons.biotech_rounded,
        label: 'Lab Tests',
      ),
      _NavDestination(
        tab: UserNavTab.care,
        icon: Icons.medical_services_outlined,
        selectedIcon: Icons.medical_services_rounded,
        label: 'Care',
      ),
      _NavDestination(
        tab: UserNavTab.profile,
        icon: Icons.person_outline_rounded,
        selectedIcon: Icons.person_rounded,
        label: 'Profile',
      ),
    ];

    final selectedIndex =
        destinations.indexWhere((d) => d.tab == currentTab).clamp(0, 3);

    return Scaffold(
      backgroundColor: bg,
      appBar: appBar,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      endDrawer: endDrawer,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: secondaryBottomBar,
      body: Row(
        children: [
          if (useRail)
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) =>
                  _onTap(context, destinations[index].tab),
              labelType: NavigationRailLabelType.all,
              backgroundColor: AppColors.white,
              indicatorColor: AppColors.primary.withValues(alpha: 0.12),
              selectedIconTheme:
                  const IconThemeData(color: AppColors.primary),
              selectedLabelTextStyle: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
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
            _UserSideNav(
              destinations: destinations,
              selectedIndex: selectedIndex,
              onSelected: (tab) => _onTap(context, tab),
            ),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: AppColors.divider.withValues(alpha: 0.8),
          ),
          Expanded(child: constrainedBody),
        ],
      ),
    );
  }
}

class _NavDestination {
  const _NavDestination({
    required this.tab,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final UserNavTab tab;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class _UserSideNav extends StatelessWidget {
  const _UserSideNav({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<_NavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<UserNavTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final width = ResponsiveUtils.valueFor(
      context,
      mobile: 220,
      laptop: 240,
      desktop: 260,
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
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
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
                      'Care',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < destinations.length; i++)
                _SideNavTile(
                  destination: destinations[i],
                  selected: i == selectedIndex,
                  onTap: () => onSelected(destinations[i].tab),
                ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Verified healthcare marketplace',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SideNavTile extends StatefulWidget {
  const _SideNavTile({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _NavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_SideNavTile> createState() => _SideNavTileState();
}

class _SideNavTileState extends State<_SideNavTile> {
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
