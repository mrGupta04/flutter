import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/socket_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/repositories/nurse_home_visit_repository.dart';
import '../../nurse_home_visit_navigation.dart';

class NurseBookingStatusScreen extends ConsumerStatefulWidget {
  const NurseBookingStatusScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  ConsumerState<NurseBookingStatusScreen> createState() =>
      _NurseBookingStatusScreenState();
}

class _NurseBookingStatusScreenState
    extends ConsumerState<NurseBookingStatusScreen> {
  final _repo = NurseHomeVisitRepository();
  Timer? _poll;
  Map<String, dynamic>? _booking;
  String? _error;
  bool _loading = true;
  bool _autoOpenedPayment = false;

  String get _status => _booking?['status']?.toString() ?? '';

  bool get _waiting =>
      _status == 'pending_nurse_approval' ||
      _status == 'awaiting_doctor_approval';

  bool get _needsPayment =>
      _status == 'payment_pending' || _status == 'approved_pending_payment';

  bool get _confirmed => _status == 'confirmed';

  bool get _rejected =>
      _status == 'nurse_rejected' || _status == 'cancelled';

  bool get _expired => _status == 'payment_expired';

  @override
  void initState() {
    super.initState();
    _load();
    _poll = Timer.periodic(const Duration(seconds: 4), (_) => _load(silent: true));
    SocketService.instance.connectIfAuthenticated();
    SocketService.instance.joinBookingRoom(widget.bookingId);
    SocketService.instance.on('booking-status-update', _onSocket);
    SocketService.instance.on('booking_status_update', _onSocket);
    SocketService.instance.on('app_notification', _onSocket);
    SocketService.instance.on('booking-notification', _onSocket);
  }

  void _onSocket(dynamic _) {
    _load(silent: true);
  }

  @override
  void dispose() {
    _poll?.cancel();
    SocketService.instance.off('booking-status-update', _onSocket);
    SocketService.instance.off('booking_status_update', _onSocket);
    SocketService.instance.off('app_notification', _onSocket);
    SocketService.instance.off('booking-notification', _onSocket);
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    final res = await _repo.getBooking(bookingId: widget.bookingId);
    if (!mounted) return;
    if (res.success && res.data != null) {
      setState(() {
        _booking = res.data;
        _error = null;
        _loading = false;
      });
      _maybeAutoOpenPayment();
    } else {
      setState(() {
        _error = res.error ?? 'Could not load booking';
        _loading = false;
      });
    }
  }

  void _maybeAutoOpenPayment() {
    if (!mounted || !_needsPayment || _autoOpenedPayment) return;
    _autoOpenedPayment = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_needsPayment) return;
      _openPayment();
    });
  }

  Future<void> _openPayment() async {
    await context.push(nursePaymentRoute(widget.bookingId));
    if (mounted) await _load(silent: true);
  }

  String _timeLabel() {
    final start = DateTime.tryParse(_booking?['slotStart']?.toString() ?? '');
    final end = DateTime.tryParse(_booking?['slotEnd']?.toString() ?? '');
    if (start == null || end == null) {
      return _booking?['label']?.toString() ?? '';
    }
    return '${DateFormat('d MMMM yyyy').format(start.toLocal())}\n'
        '${DateFormat('h:mm a').format(start.toLocal())} - ${DateFormat('h:mm a').format(end.toLocal())}';
  }

  @override
  Widget build(BuildContext context) {
    final amount = (_booking?['consultationFee'] as num?)?.toInt();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Nurse booking')),
      body: _loading && _booking == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _booking == null
              ? AppErrorWidget(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    children: [
                      _StatusHero(
                        waiting: _waiting,
                        confirmed: _confirmed,
                        rejected: _rejected,
                        expired: _expired,
                        needsPayment: _needsPayment,
                      ),
                      const SizedBox(height: 20),
                      _InfoCard(
                        nurseName: _booking?['nurseName']?.toString() ?? 'Nurse',
                        timeLabel: _timeLabel(),
                        location: [
                          _booking?['patientAddress'],
                          _booking?['patientCity'],
                        ].whereType<String>().where((s) => s.isNotEmpty).join(', '),
                        amount: (_booking?['consultationFee'] as num?)?.toInt(),
                      ),
                      const SizedBox(height: 24),
                      if (_waiting)
                        Text(
                          'We will notify you in the app as soon as the nurse verifies this request.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      if (_needsPayment) ...[
                        FilledButton.icon(
                          onPressed: _openPayment,
                          icon: const Icon(Icons.payments_rounded),
                          label: Text(
                            amount != null
                                ? 'Pay ₹$amount to confirm'
                                : 'Pay to confirm booking',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tracking starts after payment. Complete this dummy payment to confirm the visit.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      if (_confirmed) ...[
                        FilledButton.icon(
                          onPressed: () => context.push(
                            nurseLiveTrackRoute(widget.bookingId),
                          ),
                          icon: const Icon(Icons.my_location_rounded),
                          label: const Text('Track nurse live'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () =>
                              context.go(AppConstants.routeUserDashboard),
                          child: const Text('View my bookings'),
                        ),
                      ],
                      if (_rejected || _expired)
                        FilledButton(
                          onPressed: () => context.go(AppConstants.routeNurseSearch),
                          child: const Text('Book another nurse'),
                        ),
                    ],
                  ),
                ),
    );
  }
}

class _StatusHero extends StatelessWidget {
  const _StatusHero({
    required this.waiting,
    required this.confirmed,
    required this.rejected,
    required this.expired,
    required this.needsPayment,
  });

  final bool waiting;
  final bool confirmed;
  final bool rejected;
  final bool expired;
  final bool needsPayment;

  @override
  Widget build(BuildContext context) {
    IconData icon = Icons.hourglass_top_rounded;
    Color color = AppColors.pending;
    String title = 'Waiting for nurse verification';
    String subtitle =
        'Your booking request was sent. The nurse will accept or reject it shortly.';

    if (needsPayment) {
      icon = Icons.payments_rounded;
      color = AppColors.primary;
      title = 'Payment required';
      subtitle =
          'Your nurse has verified the booking. Please complete payment within 10 minutes.';
    } else if (confirmed) {
      icon = Icons.check_circle_rounded;
      color = AppColors.success;
      title = 'Booking confirmed';
      subtitle = 'Your nurse booking is confirmed.';
    } else if (expired) {
      icon = Icons.timer_off_rounded;
      color = AppColors.error;
      title = 'Payment window expired';
      subtitle =
          'Your booking expired because payment was not completed within 10 minutes.';
    } else if (rejected) {
      icon = Icons.cancel_rounded;
      color = AppColors.error;
      title = 'Nurse declined';
      subtitle = 'This nurse could not accept the request. Please choose another slot.';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: color),
          const SizedBox(height: 12),
          Text(
            title,
            style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          if (waiting) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
          ],
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.nurseName,
    required this.timeLabel,
    required this.location,
    required this.amount,
  });

  final String nurseName;
  final String timeLabel;
  final String location;
  final int? amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row('Nurse', nurseName),
          const SizedBox(height: 10),
          _row('Date & time', timeLabel),
          if (location.isNotEmpty) ...[
            const SizedBox(height: 10),
            _row('Location', location),
          ],
          if (amount != null) ...[
            const SizedBox(height: 10),
            _row('Amount', '₹$amount'),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(value, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
