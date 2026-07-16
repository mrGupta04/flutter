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
import '../../../../shared/widgets/patient_location_map_card.dart';
import '../../../../data/services/dio_service.dart';
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
    });
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
                mapHeight: 170,
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

  Future<void> _setProgress(BuildContext context, String progress) async {
    try {
      await DioService().post(
        AppConstants.endpointNurseVisitProgress(booking.id),
        data: {'progress': progress},
      );
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

  Future<void> _writeVisitNote(BuildContext context) async {
    final summaryCtrl = TextEditingController();
    final vitalsCtrl = TextEditingController();
    final proceduresCtrl = TextEditingController();
    final adviceCtrl = TextEditingController();
    var followUpNeeded = false;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Care summary',
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: summaryCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Care summary *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: vitalsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Vitals (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: proceduresCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Procedures done (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: adviceCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Advice (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 4),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: followUpNeeded,
                  onChanged: (v) =>
                      setModalState(() => followUpNeeded = v ?? false),
                  title: const Text('Follow-up visit needed'),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Save & share with patient'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (ok != true || summaryCtrl.text.trim().isEmpty) return;
    try {
      await DioService().post(
        AppConstants.endpointNurseVisitNote(booking.id),
        data: {
          'careSummary': summaryCtrl.text.trim(),
          if (vitalsCtrl.text.trim().isNotEmpty) 'vitals': vitalsCtrl.text.trim(),
          if (proceduresCtrl.text.trim().isNotEmpty)
            'proceduresDone': proceduresCtrl.text.trim(),
          if (adviceCtrl.text.trim().isNotEmpty) 'advice': adviceCtrl.text.trim(),
          'followUpNeeded': followUpNeeded,
        },
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Care summary shared with patient')),
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

  @override
  Widget build(BuildContext context) {
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
              ],
            ),
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
                mapHeight: 150,
              ),
            ],
            if (isConfirmed) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => _setProgress(context, 'en_route'),
                    child: const Text('On the way'),
                  ),
                  OutlinedButton(
                    onPressed: () => _setProgress(context, 'arrived'),
                    child: const Text('Arrived'),
                  ),
                  OutlinedButton(
                    onPressed: () => _setProgress(context, 'completed'),
                    child: const Text('Completed'),
                  ),
                  OutlinedButton(
                    onPressed: () => _writeVisitNote(context),
                    child: const Text('Care summary'),
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
