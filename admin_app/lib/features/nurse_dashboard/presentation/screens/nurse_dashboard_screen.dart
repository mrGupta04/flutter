import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/doctor_availability_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validation_utils.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/models/doctor_model.dart';
import '../../../../data/models/doctor_booking_model.dart';
import '../../../../data/models/nurse_model.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../../../shared/widgets/healthcare_ui.dart';
import '../../../../shared/widgets/patient_location_map_card.dart';
import '../../../../shared/widgets/provider_online_toggle_card.dart';
import '../../../../shared/widgets/provider_profile_visibility_card.dart';
import '../../../../data/services/dio_service.dart';
import '../../../../core/services/socket_service.dart';
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
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(nurseDashboardProvider.notifier).refreshAll();
      _loadUnreadNotifications();
      _listenRealtime();
    });
  }

  void _listenRealtime() {
    SocketService.instance.connect().catchError((_) {});
    SocketService.instance.on('booking-notification', _onRealtime);
    SocketService.instance.on('app_notification', _onRealtime);
    SocketService.instance.on('booking-status-update', _onRealtime);
  }

  void _onRealtime(dynamic _) {
    ref.read(nurseDashboardProvider.notifier).loadBookings();
    _loadUnreadNotifications();
  }

  @override
  void dispose() {
    SocketService.instance.off('booking-notification', _onRealtime);
    SocketService.instance.off('app_notification', _onRealtime);
    SocketService.instance.off('booking-status-update', _onRealtime);
    super.dispose();
  }

  Future<void> _loadUnreadNotifications() async {
    try {
      final response =
          await DioService().get(AppConstants.endpointNurseNotifications);
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      if (!mounted) return;
      setState(() {
        _unreadNotifications = (data['unreadCount'] as num?)?.toInt() ?? 0;
      });
    } catch (_) {}
  }

  Future<void> _openNotifications() async {
    await context.push('${AppConstants.routeProviderNotifications}?role=nurse');
    if (mounted) _loadUnreadNotifications();
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
            icon: Badge(
              isLabelVisible: _unreadNotifications > 0,
              label: Text('$_unreadNotifications'),
              child: const Icon(Icons.notifications_outlined),
            ),
            tooltip: 'Notifications',
            onPressed: _openNotifications,
          ),
          IconButton(
            icon: const Icon(Icons.schedule_rounded),
            tooltip: 'Weekly availability',
            onPressed: () => _showAvailabilitySheet(dashboard),
          ),
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            tooltip: 'Earnings',
            onPressed: () => context.push(
              '${AppConstants.routeProviderEarnings}?role=nurse',
            ),
          ),
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
                        const SizedBox(height: 12),
                        const ProviderOnlineToggleCard(roleLabel: 'nurse'),
                        const SizedBox(height: 12),
                        const ProviderProfileVisibilityCard(
                          role: ProviderVisibilityRole.nurse,
                        ),
                      ],
                      const SizedBox(height: 16),
                      _BookingStatsRow(
                        pending: dashboard.pendingHomeVisitRequests.length,
                        upcoming: dashboard.upcomingHomeBookings.length,
                        awaitingPay: dashboard.awaitingPaymentBookings.length,
                        history: dashboard.pastBookings.length,
                      ),
                      const SizedBox(height: 16),
                      ServiceBenefitCard(
                        icon: Icons.schedule_rounded,
                        title: 'Weekly availability',
                        subtitle: () {
                          final count = dashboard.homeAvailability
                                  ?.selectedSlotKeys.length ??
                              0;
                          if (count == 0) {
                            return 'Tap to set home visit hours (12 AM–12 AM). Patients can book only after you save slots.';
                          }
                          return '$count hour(s) selected this week. Tap to add, remove, or update slots.';
                        }(),
                        color: AppColors.primary,
                        onTap: () => _showAvailabilitySheet(dashboard),
                      ),
                      if (dashboard.needsAvailabilityUpdate) ...[
                        const SizedBox(height: 12),
                        _AvailabilityReminder(
                          onUpdate: () => _showAvailabilitySheet(dashboard),
                        ),
                      ],
                      if (dashboard.bookingsError != null) ...[
                        Text(
                          dashboard.bookingsError!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
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
                      if (dashboard.awaitingPaymentBookings.isNotEmpty) ...[
                        const MarketplaceSectionTitle(
                          title: 'Waiting for patient payment',
                        ),
                        ...dashboard.awaitingPaymentBookings.map(
                          (b) => _BookingTile(booking: b, readOnly: true),
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
                          'No confirmed visits yet. After you approve a request and the patient pays, it appears here with Start trip.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        )
                      else
                        ...dashboard.upcomingHomeBookings.map(
                          (b) => _BookingTile(booking: b),
                        ),
                      const SizedBox(height: 20),
                      MarketplaceSectionTitle(
                        title:
                            'Booking history (${dashboard.pastBookings.length})',
                      ),
                      if (dashboard.isLoadingBookings)
                        const SizedBox.shrink()
                      else if (dashboard.pastBookings.isEmpty)
                        Text(
                          'Completed and cancelled visits will show here.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        )
                      else
                        ...dashboard.pastBookings.map(
                          (b) => _BookingTile(booking: b, readOnly: true),
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
      ok ? 'Request accepted. The patient has 10 minutes to pay.' : 'Approval failed',
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
    var selfBusy = Set<String>.from(
      dashboard.homeAvailability?.selfBusySlotKeys ?? {},
    );
    var isUpdatingSlot = false;

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
                      selfBusySlots: selfBusy,
                      enableSlotActions: true,
                      isUpdating: isUpdatingSlot,
                      onToggle: (day, hour, isSelected, {startMinute = 0}) {
                        setModalState(() {
                          final key = '${day}_$hour';
                          if (isSelected) {
                            selected.add(key);
                            selfBusy.remove(key);
                          } else {
                            selected.remove(key);
                            selfBusy.remove(key);
                          }
                        });
                      },
                      onSlotAction: (day, hour, action, {startMinute = 0}) async {
                        final key = '${day}_$hour';
                        final wasSelected = selected.contains(key);
                        final wasSelfBusy = selfBusy.contains(key);
                        final status = switch (action) {
                          SlotScheduleAction.selfBusy =>
                            DoctorAvailabilityConstants.statusSelfBusy,
                          SlotScheduleAction.available =>
                            DoctorAvailabilityConstants.statusAvailable,
                          SlotScheduleAction.discard =>
                            DoctorAvailabilityConstants.statusDiscarded,
                        };

                        setModalState(() {
                          isUpdatingSlot = true;
                          if (action == SlotScheduleAction.discard) {
                            selected.remove(key);
                            selfBusy.remove(key);
                          } else {
                            selected.add(key);
                            if (action == SlotScheduleAction.selfBusy) {
                              selfBusy.add(key);
                            } else {
                              selfBusy.remove(key);
                            }
                          }
                        });

                        final ok = await ref
                            .read(nurseDashboardProvider.notifier)
                            .updateSlotStatus(
                              dayOfWeek: day,
                              startHour: hour,
                              status: status,
                            );

                        if (!context.mounted) return;
                        setModalState(() {
                          isUpdatingSlot = false;
                          if (!ok) {
                            if (wasSelected) {
                              selected.add(key);
                            } else {
                              selected.remove(key);
                            }
                            if (wasSelfBusy) {
                              selfBusy.add(key);
                            } else {
                              selfBusy.remove(key);
                            }
                          }
                        });
                        if (!ok) {
                          SnackBarHelper.showError(
                            context,
                            'Could not update slot',
                          );
                        }
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
                            .saveAvailability(
                              selected,
                              selfBusySlotKeys: selfBusy,
                            );
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
    final details = <String>[
      if (nurse.qualification != null && nurse.qualification!.trim().isNotEmpty)
        nurse.qualification!.trim(),
      if (nurse.yearsOfExperience != null)
        '${nurse.yearsOfExperience} yrs experience',
      if (nurse.city != null && nurse.city!.trim().isNotEmpty)
        nurse.city!.trim(),
    ];
    final spec = (nurse.specialization ?? '').trim();

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
          if (spec.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              spec,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
          if (details.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              details.join(' · '),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.white.withValues(alpha: 0.85),
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
          if (nurse.mobileNumber != null &&
              nurse.mobileNumber!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              FormattingUtils.formatPhoneNumber(nurse.mobileNumber!),
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

class _BookingStatsRow extends StatelessWidget {
  const _BookingStatsRow({
    required this.pending,
    required this.upcoming,
    required this.awaitingPay,
    required this.history,
  });

  final int pending;
  final int upcoming;
  final int awaitingPay;
  final int history;

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, int value, Color color) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Text(
                '$value',
                style: AppTextStyles.titleSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
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

    return Row(
      children: [
        chip('Pending', pending, AppColors.warning),
        const SizedBox(width: 8),
        chip('Upcoming', upcoming, AppColors.primary),
        const SizedBox(width: 8),
        chip('To pay', awaitingPay, AppColors.offer),
        const SizedBox(width: 8),
        chip('History', history, AppColors.grey600),
      ],
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
    final addressLine = booking.patientLocationLine;
    final hasCoords =
        booking.patientLatitude != null && booking.patientLongitude != null;

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
            if (addressLine != null) ...[
              const SizedBox(height: 6),
              Text(
                addressLine,
                style: AppTextStyles.bodySmall,
              ),
            ],
            if (booking.distanceKm != null) ...[
              const SizedBox(height: 6),
              Text(
                'Distance: ${booking.distanceKm} km',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            if (hasCoords) ...[
              const SizedBox(height: 10),
              PatientLocationMapCard(
                latitude: booking.patientLatitude!,
                longitude: booking.patientLongitude!,
                addressLine: addressLine,
                title: 'Patient location',
                mapHeight: 220,
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
                    child: const Text('REJECT'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: onApprove,
                    child: const Text('ACCEPT'),
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

class _BookingTile extends ConsumerWidget {
  const _BookingTile({required this.booking, this.readOnly = false});

  final DoctorBookingModel booking;
  final bool readOnly;

  Future<void> _setProgress(
    BuildContext context,
    WidgetRef ref,
    String progress,
  ) async {
    try {
      await DioService().post(
        AppConstants.endpointNurseVisitProgress(booking.id),
        data: {'progress': progress},
      );
      await ref.read(nurseDashboardProvider.notifier).refreshAll();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Marked as ${progress.replaceAll('_', ' ')}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  Future<void> _startVisit(BuildContext context, WidgetRef ref) async {
    try {
      await DioService().post(
        AppConstants.endpointNurseVisitStart(booking.id),
        data: {},
      );
      await ref.read(nurseDashboardProvider.notifier).refreshAll();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Visit started')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _openAssessment(BuildContext context, WidgetRef ref) async {
    final done = await context.push<bool>(
      AppConstants.routeNurseVisitAssessment,
      extra: booking,
    );
    if (done == true) {
      await ref.read(nurseDashboardProvider.notifier).refreshAll();
    }
  }

  Future<void> _openOtp(BuildContext context, WidgetRef ref) async {
    final done = await context.push<bool>(
      AppConstants.routeNurseVisitOtp,
      extra: booking,
    );
    if (done == true) {
      await ref.read(nurseDashboardProvider.notifier).refreshAll();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressLine = booking.patientLocationLine;
    final hasCoords =
        booking.patientLatitude != null && booking.patientLongitude != null;
    final isConfirmed = booking.status == 'confirmed';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.home_outlined, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.patientName ?? 'Patient',
                        style: AppTextStyles.labelLarge.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        booking.subtitle ?? '',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    booking.displayStatusLabel,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (booking.consultationFee != null) ...[
              const SizedBox(height: 6),
              Text(
                'Fee: ₹${booking.consultationFee}'
                '${booking.paymentStatus != null ? ' · ${booking.paymentStatus}' : ''}',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            if (booking.patientMobile != null &&
                booking.patientMobile!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                FormattingUtils.formatPhoneNumber(booking.patientMobile!),
                style: AppTextStyles.bodySmall,
              ),
            ],
            if (addressLine != null) ...[
              const SizedBox(height: 8),
              Text(
                addressLine,
                style: AppTextStyles.bodySmall,
              ),
            ],
            if (booking.distanceKm != null) ...[
              const SizedBox(height: 4),
              Text(
                '${booking.distanceKm} km from you',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            if (hasCoords) ...[
              const SizedBox(height: 10),
              PatientLocationMapCard(
                latitude: booking.patientLatitude!,
                longitude: booking.patientLongitude!,
                addressLine: addressLine,
                title: 'Patient location',
                mapHeight: 220,
              ),
            ],
            if (!readOnly &&
                isConfirmed &&
                booking.visitProgress != 'completed') ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    context.push(
                      '${AppConstants.routeProviderHomeVisitTrip}'
                      '?role=nurse&bookingId=${Uri.encodeComponent(booking.id)}'
                      '${booking.patientName != null && booking.patientName!.isNotEmpty ? '&patientName=${Uri.encodeComponent(booking.patientName!)}' : ''}'
                      '${addressLine != null ? '&address=${Uri.encodeComponent(addressLine)}' : ''}'
                      '${booking.patientLatitude != null ? '&lat=${booking.patientLatitude}' : ''}'
                      '${booking.patientLongitude != null ? '&lng=${booking.patientLongitude}' : ''}',
                    );
                  },
                  icon: const Icon(Icons.navigation_rounded, size: 18),
                  label: Text(
                    booking.visitProgress == 'en_route' ||
                            booking.visitProgress == 'arrived'
                        ? 'Open live trip'
                        : 'Start trip',
                  ),
                ),
              ),
            ],
            if (!readOnly && isConfirmed) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => _setProgress(context, ref, 'arrived'),
                    child: const Text('Arrived'),
                  ),
                  FilledButton(
                    onPressed: () => _startVisit(context, ref),
                    child: const Text('Start visit'),
                  ),
                  OutlinedButton(
                    onPressed: () => _openAssessment(context, ref),
                    child: const Text('Nursing report'),
                  ),
                  FilledButton.tonal(
                    onPressed: () => _openOtp(context, ref),
                    child: const Text('Complete service'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.push(
                      '${AppConstants.routeProviderBookingChat}'
                      '?role=nurse&bookingId=${booking.id}'
                      '&title=${Uri.encodeComponent(booking.patientName ?? "Patient")}',
                    ),
                    icon: const Icon(Icons.chat_bubble_outline, size: 16),
                    label: const Text('Chat'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
