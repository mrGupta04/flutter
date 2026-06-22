import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/media_url_utils.dart';
import '../../../../data/models/patient_booking_model.dart';
import '../../../../shared/widgets/appointment_code_display.dart';
import '../../../../shared/widgets/booking_category_filter_dropdown.dart';
import '../../../../data/models/patient_user_model.dart';
import '../../../user_auth/presentation/widgets/patient_header_avatar.dart';
import '../../../user_auth/provider/patient_auth_provider.dart';
import '../../../video_consult/presentation/widgets/join_video_consult_button.dart';
import '../../provider/patient_dashboard_provider.dart';
import '../../../feedback/presentation/utils/feedback_prompt_helper.dart';
import '../../../feedback/presentation/widgets/post_session_feedback_sheet.dart';

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
    Future.microtask(() {
      ref.read(patientDashboardProvider.notifier).loadBookings();
    });
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
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 252,
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
                  if (value == 'logout') {
                    await ref.read(patientAuthProvider.notifier).logout();
                    if (context.mounted) context.go(AppConstants.routeUserHome);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'logout',
                    child: Text('Log out'),
                  ),
                ],
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
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.18),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.12),
                          ],
                        ),
                      ),
                    ),
                    SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 60),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (user != null) ...[
                              PatientHeaderAvatar(user: user, size: 72),
                              const SizedBox(height: 10),
                              Text(
                                user.fullName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w800,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(alpha: 0.28),
                                      blurRadius: 6,
                                    ),
                                  ],
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
                                    color: AppColors.white.withValues(alpha: 0.95),
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withValues(alpha: 0.22),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.white,
              labelColor: AppColors.white,
              unselectedLabelColor: AppColors.white.withValues(alpha: 0.7),
              tabs: const [
                Tab(text: 'Current booking'),
                Tab(text: 'My bookings'),
                Tab(text: 'Profile'),
              ],
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
                  .where((b) => b.hasPrescription && b.isOnlineConsult)
                  .toList(),
              pendingPrescriptions: dash.bookings
                  .where(
                    (b) =>
                        b.isOnlineConsult &&
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

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({
    required this.user,
    required this.prescriptions,
    required this.pendingPrescriptions,
  });

  final PatientUserModel? user;
  final List<PatientBookingModel> prescriptions;
  final List<PatientBookingModel> pendingPrescriptions;

  Future<void> _openPrescriptionPdf(BuildContext context, String? url) async {
    final resolved = MediaUrlUtils.resolve(url);
    if (resolved.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prescription file is not available yet.')),
      );
      return;
    }
    final uri = Uri.parse(resolved);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the prescription PDF.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                'Prescriptions from your online consultations appear here and are also emailed to you.',
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
                            onPressed: () => _openPrescriptionPdf(
                              context,
                              booking.prescriptionPdfUrl,
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
      ],
    );
  }
}

class _CurrentBookingsTab extends StatefulWidget {
  const _CurrentBookingsTab({required this.dash, required this.onRefresh});

  final PatientDashboardState dash;
  final Future<void> Function() onRefresh;

  @override
  State<_CurrentBookingsTab> createState() => _CurrentBookingsTabState();
}

class _CurrentBookingsTabState extends State<_CurrentBookingsTab> {
  Set<PatientBookingCategory> _categories = {PatientBookingCategory.all};

  @override
  Widget build(BuildContext context) {
    return _FilteredBookingsTab(
      dash: widget.dash,
      onRefresh: widget.onRefresh,
      categories: _categories,
      onCategoriesChanged: (value) => setState(() => _categories = value),
      bookings: filterBookingsByCategories(
        widget.dash.upcomingBookings,
        _categories,
      ),
      isUpcoming: true,
      emptyTitle: 'No upcoming bookings',
      emptySubtitle:
          'Book an online consult, clinic visit, or other care service from home.',
    );
  }
}

class _PastBookingsTab extends StatefulWidget {
  const _PastBookingsTab({required this.dash, required this.onRefresh});

  final PatientDashboardState dash;
  final Future<void> Function() onRefresh;

  @override
  State<_PastBookingsTab> createState() => _PastBookingsTabState();
}

class _PastBookingsTabState extends State<_PastBookingsTab> {
  Set<PatientBookingCategory> _categories = {PatientBookingCategory.all};

  @override
  Widget build(BuildContext context) {
    return _FilteredBookingsTab(
      dash: widget.dash,
      onRefresh: widget.onRefresh,
      categories: _categories,
      onCategoriesChanged: (value) => setState(() => _categories = value),
      bookings: filterBookingsByCategories(
        widget.dash.pastBookings,
        _categories,
      ),
      isUpcoming: false,
      emptyTitle: 'No past bookings',
      emptySubtitle: 'Your completed appointments will appear here.',
    );
  }
}

class _FilteredBookingsTab extends StatelessWidget {
  const _FilteredBookingsTab({
    required this.dash,
    required this.onRefresh,
    required this.categories,
    required this.onCategoriesChanged,
    required this.bookings,
    required this.isUpcoming,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  final PatientDashboardState dash;
  final Future<void> Function() onRefresh;
  final Set<PatientBookingCategory> categories;
  final ValueChanged<Set<PatientBookingCategory>> onCategoriesChanged;
  final List<PatientBookingModel> bookings;
  final bool isUpcoming;
  final String emptyTitle;
  final String emptySubtitle;

  @override
  Widget build(BuildContext context) {
    if (dash.isLoadingBookings && dash.bookings.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.only(top: 20, bottom: 16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          BookingCategoryFilterDropdown(
            selected: categories,
            onChanged: onCategoriesChanged,
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _StatChip(
                  label: isUpcoming ? 'Upcoming' : 'Past',
                  value: '${bookings.length}',
                  color: isUpcoming ? AppColors.success : AppColors.textSecondary,
                ),
              ],
            ),
          ),
          if (dash.error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(
                dash.error!,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
              ),
            ),
          const SizedBox(height: 12),
          if (bookings.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
              child: Column(
                children: [
                  Icon(
                    Icons.event_busy_outlined,
                    size: 56,
                    color: AppColors.grey400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    emptyTitle,
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    emptySubtitle,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: bookings
                    .map(
                      (b) => _BookingCard(
                        booking: b,
                        isUpcoming: isUpcoming,
                        onVideoEnded: isUpcoming ? onRefresh : null,
                        onRefresh: onRefresh,
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
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

  Future<void> _openPrescriptionPdf(BuildContext context, String? url) async {
    final resolved = MediaUrlUtils.resolve(url);
    if (resolved.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prescription file is not available yet.')),
      );
      return;
    }
    final uri = Uri.parse(resolved);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the prescription PDF.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('EEE, dd MMM yyyy');
    final imageUrl = MediaUrlUtils.resolve(booking.doctorProfilePicture);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
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
                  ? Icon(Icons.medical_services, color: AppColors.primary)
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
                        onPressed: () => _openPrescriptionPdf(
                          context,
                          booking.prescriptionPdfUrl,
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
                  if (booking.isOnlineConsult &&
                      !booking.hasPrescription &&
                      (booking.prescriptionPending ||
                          (isUpcoming && booking.canJoinVideo))) ...[
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
