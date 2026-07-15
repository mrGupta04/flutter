import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/models/doctor_model.dart';
import '../../../../data/models/doctor_booking_model.dart';
import '../../../../data/models/nurse_model.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../../../shared/widgets/healthcare_ui.dart';
import '../../../auth/provider/provider_auth_provider.dart';
import '../../../doctor_registration/presentation/widgets/weekly_availability_picker.dart';
import '../../provider/nurse_dashboard_provider.dart';

class NurseDashboardScreen extends ConsumerStatefulWidget {
  const NurseDashboardScreen({super.key});

  @override
  ConsumerState<NurseDashboardScreen> createState() =>
      _NurseDashboardScreenState();
}

class _NurseDashboardScreenState extends ConsumerState<NurseDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(nurseDashboardProvider.notifier).refreshAll();
    });
  }

  Future<void> _logout() async {
    await ref.read(providerAuthProvider.notifier).logout();
    if (mounted) context.go(AppConstants.routeProviderLanding);
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = ref.watch(nurseDashboardProvider);
    final nurse = dashboard.nurse;
    final isVerified =
        nurse?.verificationStatus == VerificationStatus.verified;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My home visits'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: dashboard.isLoading
                ? null
                : () => ref.read(nurseDashboardProvider.notifier).refreshAll(),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign out',
            onPressed: _logout,
          ),
        ],
      ),
      body: dashboard.isLoading && nurse == null
          ? const Center(child: CircularProgressIndicator())
          : dashboard.error != null && nurse == null
              ? AppErrorWidget(
                  message: dashboard.error!,
                  onRetry: () =>
                      ref.read(nurseDashboardProvider.notifier).loadProfile(),
                )
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(nurseDashboardProvider.notifier).refreshAll(),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    children: [
                      if (nurse != null && !isVerified)
                        OfferPromoCard(
                          title: 'Verification pending',
                          subtitle:
                              'You can update availability while admin reviews your application.',
                          icon: Icons.hourglass_top_rounded,
                        ),
                      if (nurse != null) ...[
                        const SizedBox(height: 8),
                        _ProfileCard(nurse: nurse),
                      ],
                      const SizedBox(height: 20),
                      if (dashboard.needsAvailabilityUpdate)
                        _AvailabilityReminder(
                          onUpdate: () => _showAvailabilitySheet(dashboard),
                        ),
                      if (dashboard.pendingHomeVisitRequests.isNotEmpty) ...[
                        const MarketplaceSectionTitle(
                          title: 'Pending home visit requests',
                        ),
                        ...dashboard.pendingHomeVisitRequests.map(
                          (b) => _PendingRequestCard(
                            booking: b,
                            onApprove: () => _approve(b.id),
                            onReject: () => _reject(b.id),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      const MarketplaceSectionTitle(title: 'Upcoming visits'),
                      if (dashboard.isLoadingBookings)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (dashboard.upcomingHomeBookings.isEmpty)
                        Text(
                          'No confirmed home visits yet.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        )
                      else
                        ...dashboard.upcomingHomeBookings.map(
                          (b) => _BookingTile(booking: b),
                        ),
                    ],
                  ),
                ),
    );
  }

  Future<void> _approve(String bookingId) async {
    final ok = await ref
        .read(nurseDashboardProvider.notifier)
        .approveHomeVisitRequest(bookingId);
    if (!mounted) return;
    SnackBarHelper.showSuccess(
      context,
      ok ? 'Request approved. Patient can pay to confirm.' : 'Approval failed',
    );
  }

  Future<void> _reject(String bookingId) async {
    final ok = await ref
        .read(nurseDashboardProvider.notifier)
        .rejectHomeVisitRequest(bookingId);
    if (!mounted) return;
    SnackBarHelper.showSuccess(
      context,
      ok ? 'Request declined' : 'Could not decline request',
    );
  }

  Future<void> _showAvailabilitySheet(NurseDashboardState dashboard) async {
    var selected = Set<String>.from(
      dashboard.homeAvailability?.selectedSlotKeys ?? {},
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Home visit availability',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    WeeklyAvailabilityPicker(
                      selectedSlots: selected,
                      onToggle: (day, hour, isSelected) {
                        setModalState(() {
                          final key = '${day}_$hour';
                          if (isSelected) {
                            selected.add(key);
                          } else {
                            selected.remove(key);
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      label: 'Save availability',
                      isLoading: ref
                          .watch(nurseDashboardProvider)
                          .isSavingAvailability,
                      onPressed: () async {
                        final ok = await ref
                            .read(nurseDashboardProvider.notifier)
                            .saveAvailability(selected);
                        if (!context.mounted) return;
                        if (ok) {
                          Navigator.pop(ctx);
                          SnackBarHelper.showSuccess(
                            context,
                            'Availability updated',
                          );
                        } else {
                          SnackBarHelper.showError(
                            context,
                            'Could not save availability',
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.nurse});

  final NurseModel nurse;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: AppColors.gradientHero),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            nurse.displayName,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (nurse.specialization != null) ...[
            const SizedBox(height: 4),
            Text(
              nurse.specialization!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
          if (nurse.gender != null && nurse.gender!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              nurse.gender!.trim(),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
          if (nurse.homeVisitFee != null) ...[
            const SizedBox(height: 8),
            Text(
              'Home visit fee: ₹${nurse.homeVisitFee}',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AvailabilityReminder extends StatelessWidget {
  const _AvailabilityReminder({required this.onUpdate});

  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: const Icon(Icons.schedule_rounded, color: AppColors.warning),
        title: const Text('Update your weekly slots'),
        subtitle: const Text('Patients can only book when availability is set.'),
        trailing: TextButton(onPressed: onUpdate, child: const Text('Update')),
      ),
    );
  }
}

class _PendingRequestCard extends StatelessWidget {
  const _PendingRequestCard({
    required this.booking,
    required this.onApprove,
    required this.onReject,
  });

  final DoctorBookingModel booking;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              booking.patientName ?? 'Patient',
              style: AppTextStyles.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              booking.subtitle ?? '',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (booking.patientAddress != null) ...[
              const SizedBox(height: 6),
              Text(
                [
                  booking.patientAddress,
                  booking.patientCity,
                  booking.patientPincode,
                ].where((e) => (e ?? '').isNotEmpty).join(', '),
                style: AppTextStyles.bodySmall,
              ),
            ],
            if (booking.visitReason != null &&
                booking.visitReason!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Reason: ${booking.visitReason}'),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: onApprove,
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingTile extends StatelessWidget {
  const _BookingTile({required this.booking});

  final DoctorBookingModel booking;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.home_outlined, color: AppColors.primary),
        title: Text(booking.patientName ?? 'Patient'),
        subtitle: Text(booking.subtitle ?? ''),
      ),
    );
  }
}
