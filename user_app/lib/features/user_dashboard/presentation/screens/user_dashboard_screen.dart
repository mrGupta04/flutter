import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/media_url_utils.dart';
import '../../../../data/models/patient_booking_model.dart';
import '../../../../shared/widgets/appointment_code_display.dart';
import '../../../../data/models/patient_user_model.dart';
import '../../../user_auth/presentation/widgets/patient_header_avatar.dart';
import '../../../user_auth/provider/patient_auth_provider.dart';
import '../../../video_consult/presentation/widgets/join_video_consult_button.dart';
import '../../provider/patient_dashboard_provider.dart';
import '../utils/prescription_view_utils.dart';
import '../../../feedback/presentation/utils/feedback_prompt_helper.dart';
import '../../../feedback/presentation/widgets/post_session_feedback_sheet.dart';
import '../../../online_consult/provider/online_consult_provider.dart';
import '../../../../data/services/lab_scan_payment_flow.dart';
import '../../../../shared/widgets/user_app_footer.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/repositories/booking_lifecycle_repository.dart';
import '../../../../data/services/dio_service.dart';
import '../widgets/reschedule_booking_sheet.dart';

final labScanPaymentFlowProvider = Provider.autoDispose((ref) {
  final flow = LabScanPaymentFlow();
  ref.onDispose(flow.dispose);
  return flow;
});

class UserDashboardScreen extends ConsumerStatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  ConsumerState<UserDashboardScreen> createState() =>
      _UserDashboardScreenState();
}

class _UserDashboardScreenState extends ConsumerState<UserDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBookingsWhenReady());
  }

  Future<void> _loadBookingsWhenReady() async {
    final auth = ref.read(patientAuthProvider);
    if (!auth.isInitialized) {
      await ref.read(patientAuthProvider.notifier).initialize();
    }
    if (!mounted) return;
    await ref.read(patientDashboardProvider.notifier).loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(patientAuthProvider).user;
    final dash = ref.watch(patientDashboardProvider);

    ref.listen<PatientAuthState>(patientAuthProvider, (prev, next) {
      final becameLoggedIn =
          next.isLoggedIn && prev?.isLoggedIn != true;
      final authReadyWithUser =
          next.isInitialized &&
              next.isLoggedIn &&
              prev?.isInitialized != true;
      if (becameLoggedIn || authReadyWithUser) {
        ref.read(patientDashboardProvider.notifier).loadBookings();
      }
    });

    ref.listen<PatientDashboardState>(patientDashboardProvider, (prev, next) {
      if (prev?.isLoadingBookings == true &&
          !next.isLoadingBookings &&
          next.error == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            maybeShowPendingFeedbackPrompt(context, next.bookings);
          }
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar:
          const UserBottomNavBar(currentTab: UserNavTab.profile),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 268,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            title: innerBoxIsScrolled
                ? Text(
                    user?.fullName ?? 'My account',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : null,
            actions: [
              IconButton(
                tooltip: 'Notifications',
                onPressed: () => context.push(AppConstants.routeNotifications),
                icon: const Icon(Icons.notifications_outlined),
              ),
              IconButton(
                tooltip: 'Edit profile',
                onPressed: user == null
                    ? null
                    : () async {
                        final updated = await context.push<bool>(
                          AppConstants.routeUserEditProfile,
                        );
                        if (updated == true && mounted) {
                          await ref
                              .read(patientDashboardProvider.notifier)
                              .refreshAll();
                        }
                      },
                icon: const Icon(Icons.edit_outlined),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) async {
                  if (value == 'favorites') {
                    if (context.mounted) {
                      context.push(AppConstants.routeFavorites);
                    }
                  } else if (value == 'support') {
                    if (context.mounted) {
                      context.push(AppConstants.routeSupportTickets);
                    }
                  } else if (value == 'rewards') {
                    if (context.mounted) {
                      context.push(AppConstants.routeUserRewards);
                    }
                  } else if (value == 'theme') {
                    ref.read(themeModeProvider.notifier).toggle();
                  } else if (value == 'logout') {
                    await ref.read(patientAuthProvider.notifier).logout();
                    if (context.mounted) context.go(AppConstants.routeUserHome);
                  }
                },
                itemBuilder: (_) {
                  final isDark =
                      ref.read(themeModeProvider) == ThemeMode.dark;
                  return [
                    const PopupMenuItem(
                      value: 'favorites',
                      child: Text('Favorites'),
                    ),
                    const PopupMenuItem(
                      value: 'support',
                      child: Text('Support'),
                    ),
                    const PopupMenuItem(
                      value: 'rewards',
                      child: Text('Rewards'),
                    ),
                    PopupMenuItem(
                      value: 'theme',
                      child: Text(isDark ? 'Light mode' : 'Dark mode'),
                    ),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Text('Log out'),
                    ),
                  ];
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppColors.gradientHero,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 68),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '1mg',
                                style: AppTextStyles.titleLarge.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                  height: 1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Care',
                              style: AppTextStyles.titleMedium.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (user != null) ...[
                          PatientHeaderAvatar(user: user, size: 72, cornerRadius: 16),
                          const SizedBox(height: 10),
                          Text(
                            user.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.titleMedium.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (user.email.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              user.email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.white.withValues(alpha: 0.92),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: AppColors.white,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.primary,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  tabs: const [
                    Tab(text: 'Upcoming'),
                    Tab(text: 'History'),
                    Tab(text: 'Profile'),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _CurrentBookingsTab(
              dash: dash,
              onRefresh: () =>
                  ref.read(patientDashboardProvider.notifier).loadBookings(),
            ),
            _PastBookingsTab(
              dash: dash,
              onRefresh: () =>
                  ref.read(patientDashboardProvider.notifier).loadBookings(),
            ),
            _ProfileTab(
              user: user,
              prescriptions: dash.bookings
                  .where((b) => b.hasPrescription && b.isPrescriptionEligible)
                  .toList(),
              pendingPrescriptions: dash.bookings
                  .where(
                    (b) =>
                        b.isPrescriptionEligible &&
                        b.prescriptionPending &&
                        !b.hasPrescription,
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTab extends ConsumerWidget {
  const _ProfileTab({
    required this.user,
    required this.prescriptions,
    required this.pendingPrescriptions,
  });

  final PatientUserModel? user;
  final List<PatientBookingModel> prescriptions;
  final List<PatientBookingModel> pendingPrescriptions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (user == null) {
      return const Center(child: Text('Not signed in'));
    }

    final u = user!;
    final dateFmt = DateFormat('EEE, dd MMM yyyy');

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      children: [
        if (pendingPrescriptions.isNotEmpty) ...[
          _InfoCard(
            title: 'Pending prescriptions',
            children: [
              ...pendingPrescriptions.map(
                (booking) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _PrescriptionPendingBanner(
                    doctorName: booking.doctorName,
                    processing: booking.prescriptionProcessing,
                    slotLabel: booking.label,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (prescriptions.isNotEmpty) ...[
          _InfoCard(
            title: 'My prescriptions',
            children: [
              Text(
                'Prescriptions from your online and home visit consultations appear here and are also emailed to you.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              ...prescriptions.map((booking) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.grey50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.grey200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.doctorName,
                          style: AppTextStyles.labelLarge.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          booking.label,
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          dateFmt.format(booking.slotStart),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () => openPatientPrescriptionPdf(
                              context,
                              bookingId: booking.id,
                              prescriptionPdfUrl: booking.prescriptionPdfUrl,
                              repository:
                                  ref.read(patientDashboardRepositoryProvider),
                            ),
                            icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                            label: Text(
                              booking.prescriptionFileName != null &&
                                      booking.prescriptionFileName!.isNotEmpty
                                  ? 'View prescription'
                                  : 'View prescription PDF',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 12),
        ],
        _InfoCard(
          title: 'Personal details',
          children: [
            _InfoRow(label: 'Full name', value: u.fullName),
            _InfoRow(label: 'Email', value: u.email),
            _InfoRow(label: 'Mobile', value: u.mobileNumber),
            _InfoRow(
              label: 'Age',
              value: u.age != null ? '${u.age} years' : '—',
            ),
            _InfoRow(label: 'Gender', value: u.gender ?? '—'),
            _InfoRow(
              label: 'Aadhaar',
              value: u.aadhaarMaskedDisplay,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (u.profilePicture != null && u.profilePicture!.isNotEmpty)
          _InfoCard(
            title: 'Profile photo',
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: MediaUrlUtils.resolve(u.profilePicture),
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
        const SizedBox(height: 12),
        if (u.aadhaarCardUrl != null && u.aadhaarCardUrl!.isNotEmpty)
          _InfoCard(
            title: 'Aadhaar card',
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: MediaUrlUtils.resolve(u.aadhaarCardUrl),
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => context.push(AppConstants.routeUserEditProfile),
          icon: const Icon(Icons.edit_rounded),
          label: const Text('Edit profile'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => context.push(AppConstants.routeHealthProfile),
          icon: const Icon(Icons.health_and_safety_outlined),
          label: const Text('Family, addresses & medical'),
        ),
      ],
    );
  }
}

class _CurrentBookingsTab extends StatelessWidget {
  const _CurrentBookingsTab({required this.dash, required this.onRefresh});

  final PatientDashboardState dash;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return _CategorizedBookingsTab(
      dash: dash,
      onRefresh: onRefresh,
      bookings: dash.upcomingBookings,
      isUpcoming: true,
    );
  }
}

class _PastBookingsTab extends StatelessWidget {
  const _PastBookingsTab({required this.dash, required this.onRefresh});

  final PatientDashboardState dash;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return _CategorizedBookingsTab(
      dash: dash,
      onRefresh: onRefresh,
      bookings: dash.pastBookings,
      isUpcoming: false,
    );
  }
}

class _CategorizedBookingsTab extends StatelessWidget {
  const _CategorizedBookingsTab({
    required this.dash,
    required this.onRefresh,
    required this.bookings,
    required this.isUpcoming,
  });

  final PatientDashboardState dash;
  final Future<void> Function() onRefresh;
  final List<PatientBookingModel> bookings;
  final bool isUpcoming;

  IconData _sectionIcon(PatientBookingCategory category) {
    switch (category) {
      case PatientBookingCategory.onlineConsult:
        return Icons.videocam_rounded;
      case PatientBookingCategory.hospitalVisit:
        return Icons.local_hospital_rounded;
      case PatientBookingCategory.homeVisit:
        return Icons.home_rounded;
      case PatientBookingCategory.nurse:
        return Icons.health_and_safety_rounded;
      case PatientBookingCategory.scan:
        return Icons.radar_rounded;
      case PatientBookingCategory.lab:
        return Icons.biotech_rounded;
      case PatientBookingCategory.bloodBank:
        return Icons.bloodtype_rounded;
      case PatientBookingCategory.ambulance:
        return Icons.local_shipping_rounded;
      case PatientBookingCategory.all:
        return Icons.event_note_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (dash.isLoadingBookings && dash.bookings.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final grouped = groupBookingsByCategory(bookings);
    final totalCount = bookings.length;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Row(
            children: [
              _StatChip(
                label: isUpcoming ? 'Upcoming' : 'Past',
                value: '$totalCount',
                color: isUpcoming ? AppColors.success : AppColors.textSecondary,
              ),
            ],
          ),
          if (dash.error != null) ...[
            const SizedBox(height: 12),
            Text(
              dash.error!,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
          ],
          const SizedBox(height: 16),
          ...PatientBookingCategory.bookingSections.map((category) {
            final sectionBookings = grouped[category] ?? const [];
            return _BookingCategorySection(
              title: category.label,
              icon: _sectionIcon(category),
              bookings: sectionBookings,
              isUpcoming: isUpcoming,
              onRefresh: onRefresh,
            );
          }),
        ],
      ),
    );
  }
}

class _BookingCategorySection extends StatelessWidget {
  const _BookingCategorySection({
    required this.title,
    required this.icon,
    required this.bookings,
    required this.isUpcoming,
    required this.onRefresh,
  });

  final String title;
  final IconData icon;
  final List<PatientBookingModel> bookings;
  final bool isUpcoming;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${bookings.length}',
                    style: AppTextStyles.labelSmall.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (bookings.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  isUpcoming
                      ? 'No upcoming bookings in this category.'
                      : 'No past bookings in this category.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              )
            else
              ...bookings.map(
                (booking) => _BookingCard(
                  booking: booking,
                  isUpcoming: isUpcoming,
                  onVideoEnded: isUpcoming ? onRefresh : null,
                  onRefresh: onRefresh,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BookingCard extends ConsumerWidget {
  const _BookingCard({
    required this.booking,
    required this.isUpcoming,
    this.onVideoEnded,
    this.onRefresh,
  });

  final PatientBookingModel booking;
  final bool isUpcoming;
  final Future<void> Function()? onVideoEnded;
  final Future<void> Function()? onRefresh;

  Future<void> _payForBooking(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(bookingPaymentFlowProvider).payForExistingBooking(
            bookingId: booking.id,
          );
      if (context.mounted) {
        SnackBarHelper.showSuccess(
          context,
          'Payment successful. Your home visit is confirmed.',
        );
      }
      if (onRefresh != null) await onRefresh!();
    } catch (e) {
      if (context.mounted) {
        SnackBarHelper.showError(
          context,
          e.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
  }

  Future<void> _payLabOrScan(BuildContext context, WidgetRef ref) async {
    try {
      final flow = ref.read(labScanPaymentFlowProvider);
      if (booking.serviceType == 'scan') {
        await flow.payScanBooking(
          bookingId: booking.id,
          businessName: booking.doctorName,
        );
      } else {
        await flow.payLabBooking(
          bookingId: booking.id,
          businessName: booking.doctorName,
        );
      }
      if (context.mounted) {
        SnackBarHelper.showSuccess(
          context,
          'Payment successful. Your booking is paid.',
        );
      }
      if (onRefresh != null) await onRefresh!();
    } catch (e) {
      if (context.mounted) {
        SnackBarHelper.showError(
          context,
          e.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFmt = DateFormat('EEE, dd MMM yyyy');
    final imageUrl = MediaUrlUtils.resolve(booking.doctorProfilePicture);
    final category = PatientBookingCategory.resolve(booking);
    final providerIcon = switch (category) {
      PatientBookingCategory.nurse => Icons.health_and_safety_rounded,
      PatientBookingCategory.lab => Icons.biotech_rounded,
      PatientBookingCategory.scan => Icons.radar_rounded,
      PatientBookingCategory.bloodBank => Icons.bloodtype_rounded,
      PatientBookingCategory.ambulance => Icons.local_shipping_rounded,
      PatientBookingCategory.hospitalVisit => Icons.local_hospital_rounded,
      PatientBookingCategory.homeVisit => Icons.home_rounded,
      _ => Icons.medical_services_rounded,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: AppColors.grey50,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.grey100,
              backgroundImage:
                  imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
              child: imageUrl.isEmpty
                  ? Icon(providerIcon, color: AppColors.primary)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          booking.doctorName,
                          style: AppTextStyles.titleSmall.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isUpcoming
                              ? AppColors.success.withValues(alpha: 0.12)
                              : AppColors.grey100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          booking.typeLabel,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: isUpcoming
                                ? AppColors.success
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    booking.label,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    dateFmt.format(booking.slotStart),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (booking.consultationFee != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Fee: ₹${booking.consultationFee}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  if (booking.status != 'confirmed') ...[
                    const SizedBox(height: 6),
                    Text(
                      booking.statusLabel,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: booking.needsHomeVisitPayment
                            ? AppColors.warning
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  if (booking.clinicName != null &&
                      booking.clinicName!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      booking.clinicName!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  if (booking.clinicAddress != null &&
                      booking.clinicAddress!.isNotEmpty)
                    Text(
                      booking.clinicAddress!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  if (booking.visitReason != null &&
                      booking.visitReason!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Reason: ${booking.visitReason}',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                  if (booking.needsHomeVisitPayment && isUpcoming) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _payForBooking(context, ref),
                        icon: const Icon(Icons.payments_rounded, size: 18),
                        label: Text(
                          booking.consultationFee != null
                              ? 'Pay ₹${booking.consultationFee} to confirm'
                              : 'Pay to confirm booking',
                        ),
                      ),
                    ),
                  ],
                  if (booking.needsLabOrScanPayment && isUpcoming) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _payLabOrScan(context, ref),
                        icon: const Icon(Icons.payments_rounded, size: 18),
                        label: Text(
                          booking.consultationFee != null
                              ? 'Pay ₹${booking.consultationFee} now'
                              : 'Pay now',
                        ),
                      ),
                    ),
                  ],
                  if (booking.isClinicVisit &&
                      booking.appointmentCode != null &&
                      isUpcoming) ...[
                    const SizedBox(height: 12),
                    AppointmentCodeDisplay(
                      code: booking.appointmentCode!,
                      verified: booking.isAppointmentVerified,
                      compact: true,
                    ),
                  ],
                  if (booking.isOnlineConsult && isUpcoming) ...[
                    const SizedBox(height: 12),
                    JoinVideoConsultButton(
                      bookingId: booking.id,
                      canJoinVideo: booking.canJoinVideo,
                      peerName: booking.doctorName,
                      doctorId: booking.doctorId,
                      doctorProfilePicture: booking.doctorProfilePicture,
                      consultationType: booking.consultationType,
                      sessionLabel: booking.label,
                      videoStartsInMinutes: booking.videoStartsInMinutes,
                      onReturned: onVideoEnded,
                    ),
                  ],
                  if (!isUpcoming && booking.hasPrescription) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => openPatientPrescriptionPdf(
                          context,
                          bookingId: booking.id,
                          prescriptionPdfUrl: booking.prescriptionPdfUrl,
                          repository:
                              ref.read(patientDashboardRepositoryProvider),
                        ),
                        icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                        label: Text(
                          booking.prescriptionFileName != null &&
                                  booking.prescriptionFileName!.isNotEmpty
                              ? 'View prescription'
                              : 'View prescription PDF',
                        ),
                      ),
                    ),
                  ],
                  if (booking.isPrescriptionEligible &&
                      !booking.hasPrescription &&
                      (booking.prescriptionPending ||
                          (booking.isOnlineConsult &&
                              isUpcoming &&
                              booking.canJoinVideo))) ...[
                    const SizedBox(height: 12),
                    _PrescriptionPendingBanner(
                      doctorName: booking.doctorName,
                      processing: booking.prescriptionProcessing,
                      slotLabel: booking.label,
                    ),
                  ],
                  if (!isUpcoming && booking.canRequestFeedback) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await showFeedbackAfterSession(
                            context,
                            PostSessionFeedbackInfo(
                              bookingId: booking.id,
                              doctorId: booking.doctorId,
                              doctorName: booking.doctorName,
                              doctorProfilePicture: booking.doctorProfilePicture,
                              consultationType: booking.consultationType,
                              sessionLabel: booking.label,
                            ),
                          );
                          if (onRefresh != null) await onRefresh!();
                        },
                        icon: const Icon(Icons.star_outline_rounded, size: 18),
                        label: const Text('Rate your experience'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          context.push(
                            '${AppConstants.routeBookingTimeline}?bookingId=${booking.id}',
                          );
                        },
                        icon: const Icon(Icons.timeline, size: 16),
                        label: const Text('Track'),
                      ),
                      if (booking.canTrackAmbulanceLive)
                        OutlinedButton.icon(
                          onPressed: () {
                            context.push(
                              '${AppConstants.routeAmbulanceTrack}?bookingId=${booking.id}',
                            );
                          },
                          icon: const Icon(Icons.my_location_rounded, size: 16),
                          label: const Text('Track live'),
                        ),
                      if (booking.canChat)
                        OutlinedButton.icon(
                          onPressed: () {
                            context.push(
                              '${AppConstants.routeBookingChat}?bookingId=${booking.id}&title=${Uri.encodeComponent(booking.doctorName)}',
                            );
                          },
                          icon: const Icon(Icons.chat_bubble_outline, size: 16),
                          label: const Text('Chat'),
                        ),
                      if (booking.hasVisitNote)
                        OutlinedButton.icon(
                          onPressed: () => _showVisitNote(context, booking.id),
                          icon: const Icon(Icons.note_alt_outlined, size: 16),
                          label: const Text('Care summary'),
                        ),
                      if (booking.canCancel && isUpcoming)
                        OutlinedButton.icon(
                          onPressed: () => _cancelBooking(context, ref),
                          icon: const Icon(Icons.cancel_outlined, size: 16),
                          label: const Text('Cancel'),
                        ),
                      if (booking.canCancel &&
                          isUpcoming &&
                          (booking.isConfirmed ||
                              booking.isApprovedPendingPayment ||
                              booking.status == 'pending'))
                        OutlinedButton.icon(
                          onPressed: () async {
                            final ok = await showRescheduleBookingSheet(
                              context,
                              booking: booking,
                            );
                            if (ok && onRefresh != null) await onRefresh!();
                            if (ok && context.mounted) {
                              SnackBarHelper.showSuccess(
                                context,
                                'Visit rescheduled',
                              );
                            }
                          },
                          icon: const Icon(Icons.event_repeat, size: 16),
                          label: const Text('Reschedule'),
                        ),
                      if (!isUpcoming &&
                          (booking.serviceType == 'doctor' ||
                              booking.serviceType == 'nurse'))
                        OutlinedButton.icon(
                          onPressed: () {
                            if (booking.isNurseVisit) {
                              context.push(
                                '${AppConstants.routeNurseProfile}?id=${booking.providerId}',
                              );
                            } else {
                              context.push(
                                '${AppConstants.routeDoctorProfile}?id=${booking.providerId}',
                              );
                            }
                          },
                          icon: const Icon(Icons.replay, size: 16),
                          label: const Text('Book again'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cancelBooking(BuildContext context, WidgetRef ref) async {
    final repo = BookingLifecycleRepository();
    try {
      final policy = await repo.fetchPolicy(booking.id);
      if (!context.mounted) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Cancel booking?'),
          content: Text(policy.message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Cancel booking'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
      await repo.cancel(booking.id);
      if (context.mounted) {
        SnackBarHelper.showSuccess(context, 'Booking cancelled');
      }
      if (onRefresh != null) await onRefresh!();
    } catch (e) {
      if (context.mounted) {
        SnackBarHelper.showError(
          context,
          e.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
  }

  Future<void> _showVisitNote(BuildContext context, String bookingId) async {
    try {
      final dio = DioService();
      final response =
          await dio.get(AppConstants.endpointPatientVisitNote(bookingId));
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      if (!context.mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Care summary',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(data['careSummary']?.toString() ?? ''),
              if ((data['vitals']?.toString() ?? '').isNotEmpty) ...[
                const SizedBox(height: 10),
                Text('Vitals: ${data['vitals']}'),
              ],
              if ((data['proceduresDone']?.toString() ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Procedures: ${data['proceduresDone']}'),
              ],
              if ((data['advice']?.toString() ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Advice: ${data['advice']}'),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        SnackBarHelper.showError(
          context,
          e.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.titleSmall.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: AppTextStyles.titleLarge.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrescriptionPendingBanner extends StatelessWidget {
  const _PrescriptionPendingBanner({
    required this.doctorName,
    required this.processing,
    this.slotLabel,
  });

  final String doctorName;
  final bool processing;
  final String? slotLabel;

  @override
  Widget build(BuildContext context) {
    final color = processing ? AppColors.warning : AppColors.primary;
    final title = processing
        ? 'Prescription being prepared'
        : 'Prescription pending';
    final message = processing
        ? 'Your prescription from this consultation will appear here shortly. A copy will also be emailed to you.'
        : 'Dr. $doctorName will share your prescription after the consultation. It will appear here and be emailed to you.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (processing)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: color,
                ),
              ),
            )
          else
            Icon(Icons.hourglass_top_rounded, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (slotLabel != null && slotLabel!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    slotLabel!,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  message,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.35,
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
