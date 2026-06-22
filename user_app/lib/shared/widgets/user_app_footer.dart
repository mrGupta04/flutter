import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'healthcare_ui.dart';

enum UserNavTab { home, search, care }

/// Persistent bottom navigation for the user app.
class UserBottomNavBar extends StatelessWidget {
  const UserBottomNavBar({
    super.key,
    required this.currentTab,
  });

  final UserNavTab currentTab;

  void _onTap(BuildContext context, UserNavTab tab) {
    if (tab == currentTab) return;
    switch (tab) {
      case UserNavTab.home:
        context.go(AppConstants.routeUserHome);
      case UserNavTab.search:
        context.go(AppConstants.routeGlobalSearch);
      case UserNavTab.care:
        context.go('${AppConstants.routeCareListing}?role=doctor');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                selected: currentTab == UserNavTab.home,
                onTap: () => _onTap(context, UserNavTab.home),
              ),
              _NavItem(
                icon: Icons.search_rounded,
                label: 'Search',
                selected: currentTab == UserNavTab.search,
                onTap: () => _onTap(context, UserNavTab.search),
              ),
              _NavItem(
                icon: Icons.medical_services_outlined,
                label: 'Care',
                selected: currentTab == UserNavTab.care,
                onTap: () => _onTap(context, UserNavTab.care),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textSecondary;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 24, color: color),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: color,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Scrollable footer content — trust strip, links, and copyright.
class UserScrollFooter extends StatelessWidget {
  const UserScrollFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        const OneMgTrustStrip(),
        const SizedBox(height: 20),
        const MarketplaceSectionTitle(title: 'Need help?'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _FooterLink(
                  icon: Icons.support_agent_outlined,
                  label: 'Support',
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FooterLink(
                  icon: Icons.policy_outlined,
                  label: 'Privacy',
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FooterLink(
                  icon: Icons.info_outline_rounded,
                  label: 'About',
                  onTap: () {},
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '© ${DateTime.now().year} 1mg Care · Verified providers only',
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Healthcare provider? Use the 1mg Admin app to register.',
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textTertiary,
              height: 1.35,
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              Icon(icon, size: 22, color: AppColors.primary),
              const SizedBox(height: 6),
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
