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
import '../../../../shared/widgets/horizontal_filter_chips.dart';
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
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            title: Text(
              user?.fullName ?? 'My account',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
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
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppColors.gradientHero,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (user != null)
                        PatientHeaderAvatar(user: user, size: 80),
                      const SizedBox(height: 8),
                      if (user?.email != null)
                        Text(
                          user!.email,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      const SizedBox(height: 12),
                    ],
                  ),
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
            _ProfileTab(user: user),
          ],
        ),
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({required this.user});

  final PatientUserModel? user;

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Center(child: Text('Not signed in'));
    }

    final u = user!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
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
  PatientBookingCategory _category = PatientBookingCategory.all;

  @override
  Widget build(BuildContext context) {
    return _FilteredBookingsTab(
      dash: widget.dash,
      onRefresh: widget.onRefresh,
      category: _category,
      onCategoryChanged: (value) {
        setState(() {
          _category = PatientBookingCategory.values.firstWhere(
            (c) => c.label == value,
            orElse: () => PatientBookingCategory.all,
          );
        });
      },
      bookings: widget.dash.filterByCategory(
        widget.dash.upcomingBookings,
        _category,
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
  PatientBookingCategory _category = PatientBookingCategory.all;

  @override
  Widget build(BuildContext context) {
    return _FilteredBookingsTab(
      dash: widget.dash,
      onRefresh: widget.onRefresh,
      category: _category,
      onCategoryChanged: (value) {
        setState(() {
          _category = PatientBookingCategory.values.firstWhere(
            (c) => c.label == value,
            orElse: () => PatientBookingCategory.all,
          );
        });
      },
      bookings: widget.dash.filterByCategory(
        widget.dash.pastBookings,
        _category,
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
    required this.category,
    required this.onCategoryChanged,
    required this.bookings,
    required this.isUpcoming,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  final PatientDashboardState dash;
  final Future<void> Function() onRefresh;
  final PatientBookingCategory category;
  final ValueChanged<String> onCategoryChanged;
  final List<PatientBookingModel> bookings;
  final bool isUpcoming;
  final String emptyTitle;
  final String emptySubtitle;

  @override
  Widget build(BuildContext context) {
    if (dash.isLoadingBookings && dash.bookings.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final filterLabels =
        PatientBookingCategory.values.map((c) => c.label).toList();

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.only(top: 12, bottom: 16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          HorizontalFilterChips(
            labels: filterLabels,
            selected: category.label,
            onSelected: onCategoryChanged,
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
