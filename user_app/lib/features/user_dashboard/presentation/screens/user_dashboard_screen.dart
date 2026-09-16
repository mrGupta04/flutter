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
                          if (dash.nextUpcoming != null) ...[
                            const SizedBox(height: 12),
                            _UpcomingSummary(booking: dash.nextUpcoming),
                          ],
                          const SizedBox(height: 8),
                          _ProfileMenuList(
                            items: [
                              _ProfileMenuItem(
                                icon: Icons.account_balance_wallet_outlined,
                                label: 'My wallet',
                                onTap: () => context.push(
                                  AppConstants.routeUserRewards,
                                ),
                              ),
                              _ProfileMenuItem(
                                icon: Icons.inventory_2_outlined,
                                label: 'My orders',
                                onTap: () => context.push(
                                  AppConstants.routeCurrentBookings,
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

class _UpcomingSummary extends StatelessWidget {
  const _UpcomingSummary({this.booking});

  final PatientBookingModel? booking;

  @override
  Widget build(BuildContext context) {
    if (booking == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: AppDecorations.borderRadiusLg,
          border: Border.all(color: AppColors.grey200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Upcoming', style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              'No upcoming appointments',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => context.go(AppConstants.routeUserHome),
              child: const Text('Book a service'),
            ),
          ],
        ),
      );
    }

    final item = booking!;
    final when =
        '${DateFormat('d MMM').format(item.slotStart.toLocal())} • ${DateFormat('h:mm a').format(item.slotStart.toLocal())}';
    return Material(
      color: AppColors.primaryLight,
      borderRadius: AppDecorations.borderRadiusLg,
      child: InkWell(
        borderRadius: AppDecorations.borderRadiusLg,
        onTap: () => context.push(
          '${AppConstants.routeBookingDetails}?bookingId=${Uri.encodeComponent(item.id)}',
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Upcoming', style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(
                      item.doctorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(when, style: AppTextStyles.bodySmall),
                    const SizedBox(height: 6),
                    BookingStatusBadge(status: BookingStatusView.of(item)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
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
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

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
          ],
        ),
      ),
    );
  }
}
