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
/// Mobile: bottom navigation that auto-hides on scroll down and returns on scroll up.
/// Tablet: navigation rail.
/// Laptop+: persistent sidebar + max-width content.
class UserAdaptiveScaffold extends StatefulWidget {
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

  @override
  State<UserAdaptiveScaffold> createState() => _UserAdaptiveScaffoldState();
}

class _UserAdaptiveScaffoldState extends State<UserAdaptiveScaffold>
    with SingleTickerProviderStateMixin {
  static const _hideThreshold = 14.0;
  static const _showThreshold = 8.0;

  late final AnimationController _footerController;
  late final Animation<double> _footerSize;
  late final Animation<double> _footerFade;
  double _scrollAcc = 0;

  @override
  void initState() {
    super.initState();
    _footerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      reverseDuration: const Duration(milliseconds: 240),
      value: 1,
    );
    _footerSize = CurvedAnimation(
      parent: _footerController,
      curve: const Cubic(0.16, 1, 0.3, 1),
      reverseCurve: const Cubic(0.4, 0, 1, 1),
    );
    _footerFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _footerController,
        curve: const Interval(0.2, 1, curve: Curves.easeOut),
        reverseCurve: const Interval(0, 0.6, curve: Curves.easeIn),
      ),
    );
  }

  @override
  void didUpdateWidget(UserAdaptiveScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentTab != widget.currentTab) {
      _scrollAcc = 0;
      _footerController.forward();
    }
  }

  @override
  void dispose() {
    _footerController.dispose();
    super.dispose();
  }

  Future<void> _onTap(BuildContext context, UserNavTab tab) async {
    if (tab == widget.currentTab) return;
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

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;

    final atTop = notification.metrics.pixels <= 8;
    final atBottom = notification.metrics.pixels >=
        notification.metrics.maxScrollExtent - 24;
    final outOfRange = notification.metrics.outOfRange;

    if (outOfRange || atTop || atBottom) {
      _scrollAcc = 0;
      _showFooter();
      return false;
    }

    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta ?? 0;
      if (delta == 0) return false;

      if (delta > 0) {
        if (_scrollAcc < 0) _scrollAcc = 0;
        _scrollAcc += delta;
        if (_scrollAcc > _hideThreshold) _hideFooter();
      } else {
        if (_scrollAcc > 0) _scrollAcc = 0;
        _scrollAcc += delta;
        if (_scrollAcc < -_showThreshold) _showFooter();
      }
    } else if (notification is ScrollEndNotification) {
      _scrollAcc = 0;
    }

    return false;
  }

  void _showFooter() {
    if (_footerController.status == AnimationStatus.forward ||
        _footerController.status == AnimationStatus.completed) {
      return;
    }
    _footerController.forward();
  }

  void _hideFooter() {
    if (_footerController.status == AnimationStatus.reverse ||
        _footerController.status == AnimationStatus.dismissed) {
      return;
    }
    _footerController.reverse();
  }

  Widget _animatedFooter(Widget bar) {
    return SizeTransition(
      sizeFactor: _footerSize,
      axisAlignment: -1,
      child: FadeTransition(
        opacity: _footerFade,
        child: bar,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.backgroundColor ?? AppColors.background;
    final useBottom = ResponsiveUtils.useBottomNavigation(context);
    final useRail = ResponsiveUtils.useNavigationRail(context);

    final constrainedBody = widget.constrainBody
        ? ResponsivePage(child: widget.body)
        : widget.body;

    final scrollBody = NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: constrainedBody,
    );

    if (useBottom) {
      final Widget bottomBar = widget.secondaryBottomBar == null
          ? UserBottomNavBar(currentTab: widget.currentTab)
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                widget.secondaryBottomBar!,
                UserBottomNavBar(currentTab: widget.currentTab),
              ],
            );

      return Scaffold(
        backgroundColor: bg,
        appBar: widget.appBar,
        extendBodyBehindAppBar: widget.extendBodyBehindAppBar,
        endDrawer: widget.endDrawer,
        floatingActionButton: widget.floatingActionButton,
        floatingActionButtonLocation: widget.floatingActionButtonLocation,
        bottomNavigationBar: _animatedFooter(bottomBar),
        body: scrollBody,
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
        destinations.indexWhere((d) => d.tab == widget.currentTab).clamp(0, 3);

    return Scaffold(
      backgroundColor: bg,
      appBar: widget.appBar,
      extendBodyBehindAppBar: widget.extendBodyBehindAppBar,
      endDrawer: widget.endDrawer,
      floatingActionButton: widget.floatingActionButton,
      floatingActionButtonLocation: widget.floatingActionButtonLocation,
      bottomNavigationBar: widget.secondaryBottomBar,
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
