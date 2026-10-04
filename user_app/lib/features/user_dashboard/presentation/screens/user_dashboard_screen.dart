import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/socket_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/media_url_utils.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/widgets/app_back_navigation.dart';
import '../../../../data/models/patient_booking_model.dart';
import '../../../../data/models/patient_user_model.dart';
import '../../../../shared/widgets/diagnostic_cart_icon_button.dart';
import '../../../../shared/widgets/full_screen_image_viewer.dart';
import '../../../../shared/widgets/user_adaptive_scaffold.dart';
import '../../../../shared/widgets/user_app_footer.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';
import '../../../user_auth/presentation/widgets/patient_header_avatar.dart';
import '../../../user_auth/provider/patient_auth_provider.dart';
import '../../data/booking_status_config.dart';
import '../../provider/patient_dashboard_provider.dart';
import '../widgets/booking_status_badge.dart';
import '../widgets/unified_booking_card.dart';

class UserDashboardScreen extends ConsumerStatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  ConsumerState<UserDashboardScreen> createState() =>
      _UserDashboardScreenState();
}

class _UserDashboardScreenState extends ConsumerState<UserDashboardScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SocketService.instance.on('booking-status-update', _onRealtime);
    SocketService.instance.on('booking_status_update', _onRealtime);
    SocketService.instance.on('app_notification', _onRealtime);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _onRealtime(dynamic _) {
    if (!mounted) return;
    ref.read(patientDashboardProvider.notifier).loadBookings();
    ref.invalidate(notificationsProvider);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _onRealtime(null);
    }
  }

  Future<void> _load() async {
    final auth = ref.read(patientAuthProvider);
    if (!auth.isInitialized) {
      await ref.read(patientAuthProvider.notifier).initialize();
    }
    if (!mounted) return;
    await ref.read(patientDashboardProvider.notifier).loadBookings();
    if (mounted) {
      ref.read(patientDashboardProvider.notifier).loadHistory(refresh: true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SocketService.instance.off('booking-status-update', _onRealtime);
    SocketService.instance.off('booking_status_update', _onRealtime);
    SocketService.instance.off('app_notification', _onRealtime);
    super.dispose();
  }

  Future<void> _showInfoSheet(
    BuildContext context, {
    required String title,
    required String body,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              body,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to view bookings and health records.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Stay')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Log out')),
        ],
      ),
    );
    if (ok == true && mounted) {
      await ref.read(patientAuthProvider.notifier).logout();
      if (mounted) context.go(AppConstants.routeUserHome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(patientAuthProvider).user;
    final dash = ref.watch(patientDashboardProvider);

    ref.listen<PatientAuthState>(patientAuthProvider, (prev, next) {
      if (next.isLoggedIn && prev?.isLoggedIn != true) {
        ref.read(patientDashboardProvider.notifier).loadBookings();
      }
    });

    return UserTabBackScope(
      isHomeTab: false,
      homeRoute: AppConstants.routeUserHome,
      child: UserAdaptiveScaffold(
        currentTab: UserNavTab.profile,
        backgroundColor: AppColors.white,
        appBar: AppBar(
          title: const Text('Profile'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () {
              if (!AppBackButtonScope.handleSystemBack(context)) {
                context.go(AppConstants.routeUserHome);
              }
            },
          ),
          actions: const [
            DiagnosticCartIconButton(),
            NotificationBellButton(),
          ],
        ),
        body: user == null
            ? const Center(child: Text('Not signed in'))
            : RefreshIndicator(
                onRefresh: () =>
                    ref.read(patientDashboardProvider.notifier).refreshAll(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    ResponsivePage(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ProfileHeader(user: user),
                          const SizedBox(height: 12),
                          _MembershipBanner(
                            onTap: () =>
                                context.push(AppConstants.routeUserRewards),
                          ),
                          if (dash.emergencyActive != null) ...[
                            const SizedBox(height: 12),
                            _EmergencyBanner(booking: dash.emergencyActive!),
                          ],
                          const SizedBox(height: 14),
                          _UserProfileBookingsSection(dash: dash),
                          const SizedBox(height: 14),
                          _ProfileMenuList(
                            items: [
                              _ProfileMenuItem(
                                icon: Icons.calendar_month_rounded,
                                label: 'My bookings',
                                trailing: dash.upcomingBookings.isNotEmpty
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '${dash.upcomingBookings.length}',
                                          style: const TextStyle(
                                            color: AppColors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      )
                                    : null,
                                onTap: () => context.push(
                                  AppConstants.routeCurrentBookings,
                                ),
                              ),
                              _ProfileMenuItem(
                                icon: Icons.history_rounded,
                                label: 'Booking history',
                                onTap: () => context.push(
                                  AppConstants.routeBookingHistory,
                                ),
                              ),
                              _ProfileMenuItem(
                                icon: Icons.account_balance_wallet_outlined,
                                label: 'My wallet',
                                onTap: () => context.push(
                                  AppConstants.routeUserRewards,
                                ),
                              ),
                              _ProfileMenuItem(
                                icon: Icons.location_on_outlined,
                                label: 'My addresses',
                                onTap: () => context.push(
                                  '${AppConstants.routeHealthProfile}?tab=1',
                                ),
                              ),
                              _ProfileMenuItem(
                                icon: Icons.medical_information_outlined,
                                label: 'Health records',
                                onTap: () => context.push(
                                  AppConstants.routeNursingReports,
                                ),
                              ),
                              _ProfileMenuItem(
                                icon: Icons.notifications_outlined,
                                label: 'Notification',
                                onTap: () => context.push(
                                  AppConstants.routeNotifications,
                                ),
                              ),
                              _ProfileMenuItem(
                                icon: Icons.card_membership_outlined,
                                label: 'My subscriptions',
                                onTap: () => context.push(
                                  AppConstants.routeUserRewards,
                                ),
                              ),
                              _ProfileMenuItem(
                                icon: Icons.groups_outlined,
                                label: 'Family members',
                                onTap: () => context.push(
                                  '${AppConstants.routeHealthProfile}?tab=0',
                                ),
                              ),
                              _ProfileMenuItem(
                                icon: Icons.bookmark_border_rounded,
                                label: 'Saved for later',
                                onTap: () => context.push(
                                  AppConstants.routeFavorites,
                                ),
                              ),
                              _ProfileMenuItem(
                                icon: Icons.help_outline_rounded,
                                label: 'Help & support',
                                onTap: () => context.push(
                                  AppConstants.routeSupportTickets,
                                ),
                              ),
                              _ProfileMenuItem(
                                icon: Icons.gavel_outlined,
                                label: 'Legal information',
                                onTap: () => _showInfoSheet(
                                  context,
                                  title: 'Legal information',
                                  body:
                                      '1mg Care is a healthcare marketplace. Bookings are fulfilled by independently verified providers. Use of the app is subject to our terms of service and privacy practices. For account deletion or data requests, open Security.',
                                ),
                              ),
                              _ProfileMenuItem(
                                icon: Icons.info_outline_rounded,
                                label: 'About us',
                                onTap: () => _showInfoSheet(
                                  context,
                                  title: 'About us',
                                  body:
                                      '1mg Care helps you find verified doctors, nurses, labs, scan centres, ambulances, and blood banks. We do not replace emergency services — call 108 / 112 in a life-threatening emergency.',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: _logout,
                            icon: const Icon(Icons.logout_rounded),
                            label: const Text(
                              'Log out',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                context.push(AppConstants.routeAccountSecurity),
                            child: const Text('Delete account'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final PatientUserModel user;

  @override
  Widget build(BuildContext context) {
    final imageUrl = MediaUrlUtils.resolve(user.profilePicture);
    final completion = user.profileCompletionPercent;
    final phone = user.mobileNumber.isNotEmpty
        ? '${user.countryCode} ${user.mobileNumber}'
        : user.email;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TappableProfilePhoto(
          imageUrl: imageUrl,
          child: PatientHeaderAvatar(
            user: user,
            size: 56,
            cornerRadius: 28,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              if (phone.isNotEmpty)
                Text(
                  phone,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                'Profile Completion: $completion%',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: completion / 100,
                  minHeight: 6,
                  backgroundColor: AppColors.grey200,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () => context.push(AppConstants.routeUserEditProfile),
          child: Text(
            'Edit',
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _MembershipBanner extends StatelessWidget {
  const _MembershipBanner({required this.onTap});

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
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.grey200),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Get 1mg Care Rewards',
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Cashback, extra discount & more',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.grey400),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmergencyBanner extends StatelessWidget {
  const _EmergencyBanner({required this.booking});

  final PatientBookingModel booking;

  @override
  Widget build(BuildContext context) {
    final ambulance = booking.serviceType == 'ambulance';
    return Material(
      color: AppColors.error.withValues(alpha: 0.08),
      borderRadius: AppDecorations.borderRadiusLg,
      child: InkWell(
        borderRadius: AppDecorations.borderRadiusLg,
        onTap: () => context.push(
          '${AppConstants.routeBookingDetails}?bookingId=${Uri.encodeComponent(booking.id)}',
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(
                ambulance ? Icons.emergency_rounded : Icons.directions_run_rounded,
                color: AppColors.error,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ambulance ? 'ACTIVE AMBULANCE' : 'ACTIVE CARE',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      BookingStatusView.of(booking).label,
                      style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              Text(
                ambulance ? 'Track now' : 'View',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserProfileBookingsSection extends StatelessWidget {
  const _UserProfileBookingsSection({
    required this.dash,
  });

  final PatientDashboardState dash;

  @override
  Widget build(BuildContext context) {
    final upcomingList = dash.upcomingBookings;
    final activeCount = dash.activeBookings.length;
    final upcomingConfirmedCount = dash.upcomingConfirmedBookings.length;
    final pastCount = dash.stats.past > 0
        ? dash.stats.past
        : dash.historyBookings.length;

    final grouped = groupBookingsByCategory(upcomingList);
    final presentCategories = PatientBookingCategory.bookingSections
        .where((c) => (grouped[c] ?? []).isNotEmpty)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppDecorations.borderRadiusLg,
        border: Border.all(color: AppColors.grey200),
        boxShadow: AppDecorations.softShadow(opacity: 0.04),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Bookings',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      upcomingList.isNotEmpty
                          ? '${upcomingList.length} scheduled / in-progress'
                          : 'Appointments & healthcare visits',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () =>
                    context.push(AppConstants.routeCurrentBookings),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View all',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Booking Summary Counters
          Row(
            children: [
              Expanded(
                child: _BookingStatusCounterCard(
                  title: 'Active',
                  count: activeCount,
                  color: activeCount > 0
                      ? AppColors.error
                      : AppColors.grey500,
                  icon: Icons.flash_on_rounded,
                  onTap: () =>
                      context.push(AppConstants.routeCurrentBookings),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _BookingStatusCounterCard(
                  title: 'Upcoming',
                  count: upcomingConfirmedCount,
                  color: upcomingConfirmedCount > 0
                      ? AppColors.primary
                      : AppColors.grey500,
                  icon: Icons.event_rounded,
                  onTap: () =>
                      context.push(AppConstants.routeCurrentBookings),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _BookingStatusCounterCard(
                  title: 'Completed',
                  count: pastCount,
                  color: pastCount > 0
                      ? AppColors.success
                      : AppColors.grey500,
                  icon: Icons.check_circle_outline_rounded,
                  onTap: () =>
                      context.push(AppConstants.routeBookingHistory),
                ),
              ),
            ],
          ),

          if (dash.isLoadingBookings && upcomingList.isEmpty) ...[
            const SizedBox(height: 16),
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ] else if (upcomingList.isEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.grey50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.grey200),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.event_available_outlined,
                    size: 34,
                    color: AppColors.grey400,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No active bookings',
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your active doctor visits, nurse appointments, lab tests, and care bookings will appear here.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                        ),
                        onPressed: () =>
                            context.push(AppConstants.routeFindSpecialists),
                        icon: const Icon(Icons.person_search_rounded,
                            size: 15),
                        label: const Text('Find doctor',
                            style: TextStyle(fontSize: 12)),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                        ),
                        onPressed: () => context.go(AppConstants.routeLabs),
                        icon: const Icon(Icons.biotech_rounded, size: 15),
                        label: const Text('Book lab test',
                            style: TextStyle(fontSize: 12)),
                      ),
                      if (pastCount > 0)
                        TextButton(
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () => context
                              .push(AppConstants.routeBookingHistory),
                          child: const Text('View history',
                              style: TextStyle(fontSize: 12)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 14),
            // Render bookings grouped under their relevant sections
            for (final cat in presentCategories) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 6),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: cat.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(cat.icon, size: 14, color: cat.color),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      cat.sectionTitle,
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${grouped[cat]?.length ?? 0}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              for (final booking in (grouped[cat] ??
                  <PatientBookingModel>[])) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: UnifiedBookingCard(
                    booking: booking,
                    showCategoryTag: false,
                  ),
                ),
              ],
            ],
          ],
        ],
      ),
    );
  }
}

class _BookingStatusCounterCard extends StatelessWidget {
  const _BookingStatusCounterCard({
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final int count;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 14, color: color),
                  const SizedBox(width: 4),
                  Text(
                    '$count',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileMenuList extends StatelessWidget {
  const _ProfileMenuList({required this.items});

  final List<_ProfileMenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const Divider(height: 1, color: AppColors.divider),
          items[i],
        ],
      ],
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (trailing != null) ...[
              trailing!,
              const SizedBox(width: 8),
            ],
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.grey400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
