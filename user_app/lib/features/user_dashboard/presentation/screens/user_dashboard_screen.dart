import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/theme_provider.dart';
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
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Profile'),
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
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  children: [
                    ResponsivePage(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ProfileHeader(user: user),
                          const SizedBox(height: 16),
                          if (dash.emergencyActive != null) ...[
                            _EmergencyBanner(booking: dash.emergencyActive!),
                            const SizedBox(height: 12),
                          ],
                          _UpcomingSummary(booking: dash.nextUpcoming),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _QuickTile(
                                  icon: Icons.event_available_rounded,
                                  label: 'Bookings',
                                  onTap: () => context.push(
                                    AppConstants.routeCurrentBookings,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _QuickTile(
                                  icon: Icons.history_rounded,
                                  label: 'History',
                                  onTap: () => context.push(
                                    AppConstants.routeBookingHistory,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _QuickTile(
                                  icon: Icons.folder_outlined,
                                  label: 'Documents',
                                  onTap: () => context.push(
                                    AppConstants.routeNursingReports,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _MenuSection(
                            title: 'My bookings',
                            items: [
                              _MenuItem(
                                icon: Icons.upcoming_outlined,
                                label: 'Current bookings',
                                onTap: () => context.push(
                                  AppConstants.routeCurrentBookings,
                                ),
                              ),
                              _MenuItem(
                                icon: Icons.history_rounded,
                                label: 'Booking history',
                                onTap: () => context.push(
                                  AppConstants.routeBookingHistory,
                                ),
                              ),
                            ],
                          ),
                          _MenuSection(
                            title: 'Health',
                            items: [
                              _MenuItem(
                                icon: Icons.health_and_safety_outlined,
                                label: 'Medical information',
                                onTap: () => context.push(
                                  AppConstants.routeHealthProfile,
                                ),
                              ),
                              _MenuItem(
                                icon: Icons.picture_as_pdf_outlined,
                                label: 'Prescriptions & reports',
                                onTap: () => context.push(
                                  AppConstants.routeNursingReports,
                                ),
                              ),
                            ],
                          ),
                          _MenuSection(
                            title: 'Account',
                            items: [
                              _MenuItem(
                                icon: Icons.edit_outlined,
                                label: 'Edit profile',
                                onTap: () => context.push(
                                  AppConstants.routeUserEditProfile,
                                ),
                              ),
                              _MenuItem(
                                icon: Icons.notifications_outlined,
                                label: 'Notifications',
                                onTap: () => context.push(
                                  AppConstants.routeNotifications,
                                ),
                              ),
                              _MenuItem(
                                icon: Icons.favorite_outline_rounded,
                                label: 'Favorites',
                                onTap: () => context.push(
                                  AppConstants.routeFavorites,
                                ),
                              ),
                              _MenuItem(
                                icon: Icons.card_giftcard_outlined,
                                label: 'Rewards',
                                onTap: () => context.push(
                                  AppConstants.routeUserRewards,
                                ),
                              ),
                              _MenuItem(
                                icon: Icons.lock_outline_rounded,
                                label: 'Security',
                                onTap: () => context.push(
                                  AppConstants.routeAccountSecurity,
                                ),
                              ),
                              _MenuItem(
                                icon: Icons.lock_reset_outlined,
                                label: 'Change password',
                                onTap: () => context.push(
                                  AppConstants.routeForgotPassword,
                                ),
                              ),
                              _MenuItem(
                                icon: Icons.brightness_6_outlined,
                                label: 'Appearance',
                                onTap: () {
                                  ref.read(themeModeProvider.notifier).toggle();
                                },
                              ),
                            ],
                          ),
                          _MenuSection(
                            title: 'Support',
                            items: [
                              _MenuItem(
                                icon: Icons.support_agent_outlined,
                                label: 'Help & support',
                                onTap: () => context.push(
                                  AppConstants.routeSupportTickets,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: _logout,
                            icon: const Icon(Icons.logout_rounded),
                            label: const Text('Log out'),
                          ),
                          const SizedBox(height: 8),
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
    final verified = user.email.isNotEmpty && user.mobileNumber.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppDecorations.borderRadiusLg,
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        children: [
          TappableProfilePhoto(
            imageUrl: imageUrl,
            child: PatientHeaderAvatar(
              user: user,
              size: 80,
              cornerRadius: 40,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            user.fullName,
            textAlign: TextAlign.center,
            style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(user.email, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          if (user.mobileNumber.isNotEmpty)
            Text(
              '${user.countryCode} ${user.mobileNumber}',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                verified ? Icons.verified_rounded : Icons.info_outline_rounded,
                size: 16,
                color: verified ? AppColors.success : AppColors.warning,
              ),
              const SizedBox(width: 4),
              Text(
                verified ? 'Verified' : 'Complete your profile',
                style: AppTextStyles.labelSmall.copyWith(
                  color: verified ? AppColors.success : AppColors.warning,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => context.push(AppConstants.routeUserEditProfile),
            icon: const Icon(Icons.edit_rounded, size: 18),
            label: const Text('Edit profile'),
          ),
        ],
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

class _QuickTile extends StatelessWidget {
  const _QuickTile({
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
      borderRadius: AppDecorations.borderRadiusLg,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppDecorations.borderRadiusLg,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: AppDecorations.borderRadiusLg,
            border: Border.all(color: AppColors.grey200),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(height: 6),
              Text(label, style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.title, required this.items});

  final String title;
  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.grey500,
              letterSpacing: 0.7,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: AppDecorations.borderRadiusLg,
              border: Border.all(color: AppColors.grey200),
            ),
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  items[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.grey400),
      onTap: onTap,
    );
  }
}
