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
import '../../../user_dashboard/provider/patient_dashboard_provider.dart';

class NursePaymentScreen extends ConsumerStatefulWidget {
  const NursePaymentScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  ConsumerState<NursePaymentScreen> createState() => _NursePaymentScreenState();
}

class _NursePaymentScreenState extends ConsumerState<NursePaymentScreen> {
  final _repo = NurseHomeVisitRepository();
  Timer? _ticker;
  Map<String, dynamic>? _booking;
  String? _error;
  bool _loading = true;
  Duration _remaining = Duration.zero;
  DateTime? _expiresAt;

  @override
  void initState() {
    super.initState();
    _load();
    SocketService.instance.connectIfAuthenticated();
    SocketService.instance.joinBookingRoom(widget.bookingId);
    SocketService.instance.on('booking-status-update', _onSocket);
    SocketService.instance.on('booking_status_update', _onSocket);
  }

  void _onSocket(dynamic _) => _load(silent: true);

  @override
  void dispose() {
    _ticker?.cancel();
    SocketService.instance.off('booking-status-update', _onSocket);
    SocketService.instance.off('booking_status_update', _onSocket);
    super.dispose();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_expiresAt == null) return;
      final left = _expiresAt!.difference(DateTime.now());
      if (!mounted) return;
      setState(() => _remaining = left.isNegative ? Duration.zero : left);
      if (left.isNegative || left == Duration.zero) {
        _load(silent: true);
      }
    });
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    final res = await _repo.getBooking(bookingId: widget.bookingId);
    if (!mounted) return;
    if (!res.success || res.data == null) {
      setState(() {
        _error = res.error ?? 'Could not load booking';
        _loading = false;
      });
      return;
    }

    final data = res.data!;
    final status = data['status']?.toString() ?? '';
    final remainingSec = (data['remainingPaymentSeconds'] as num?)?.toInt();
    final serverTime = DateTime.tryParse(data['serverTime']?.toString() ?? '');
    final expires = DateTime.tryParse(data['paymentExpiresAt']?.toString() ?? '');

    Duration remaining = Duration.zero;
    if (remainingSec != null) {
      remaining = Duration(seconds: remainingSec);
      _expiresAt = DateTime.now().add(remaining);
    } else if (expires != null) {
      final now = serverTime?.toLocal() ?? DateTime.now();
      remaining = expires.toLocal().difference(now);
      _expiresAt = DateTime.now().add(remaining.isNegative ? Duration.zero : remaining);
    }

    setState(() {
      _booking = data;
      _remaining = remaining.isNegative ? Duration.zero : remaining;
      _error = null;
      _loading = false;
    });
    _startTicker();

    if (status == 'confirmed') {
      context.go(
        '${AppConstants.routeNurseBookingStatus}?bookingId=${Uri.encodeComponent(widget.bookingId)}',
      );
      return;
    }
    if (status == 'payment_expired') {
      return;
    }
  }

  String _clock(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _payNow() async {
    final result = await context.push<bool>(
      '${AppConstants.routeNurseMockPayment}?bookingId=${Uri.encodeComponent(widget.bookingId)}'
      '&amount=${(_booking?['consultationFee'] as num?)?.toInt() ?? 0}',
    );
    if (result == true && mounted) {
      await ref.read(patientDashboardProvider.notifier).loadBookings();
      if (mounted) {
        context.go(
          '${AppConstants.routeNurseBookingStatus}?bookingId=${Uri.encodeComponent(widget.bookingId)}',
        );
      }
    } else {
      await _load(silent: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final expired = _remaining == Duration.zero &&
        (_booking?['status'] == 'payment_expired' ||
            (_booking?['paymentExpiresAt'] != null &&
                _expiresAt != null &&
                DateTime.now().isAfter(_expiresAt!)));
    final start = DateTime.tryParse(_booking?['slotStart']?.toString() ?? '');
    final end = DateTime.tryParse(_booking?['slotEnd']?.toString() ?? '');
    final dateLabel = start == null
        ? ''
        : DateFormat('d MMMM yyyy').format(start.toLocal());
    final timeLabel = (start != null && end != null)
        ? '${DateFormat('h:mm a').format(start.toLocal())} - ${DateFormat('h:mm a').format(end.toLocal())}'
        : _booking?['label']?.toString() ?? '';
    final amount = (_booking?['consultationFee'] as num?)?.toInt() ??
        (_booking?['amount'] as num?)?.toInt();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Payment required')),
      body: _loading && _booking == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _booking == null
              ? AppErrorWidget(message: _error!, onRetry: _load)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    Text(
                      'Confirm Payment',
                      style: AppTextStyles.titleLarge.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _row('Nurse', _booking?['nurseName']?.toString() ?? 'Nurse'),
                          const SizedBox(height: 12),
                          _row('Date', dateLabel),
                          const SizedBox(height: 12),
                          _row('Time', timeLabel),
                          const SizedBox(height: 12),
                          _row('Amount', amount == null ? '—' : '₹$amount'),
                          const SizedBox(height: 18),
                          Text(
                            expired
                                ? 'Payment window expired.'
                                : 'Payment expires in',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            expired ? '00:00' : _clock(_remaining),
                            style: AppTextStyles.headlineMedium.copyWith(
                              fontWeight: FontWeight.w800,
                              color: expired ? AppColors.error : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (expired)
                      Text(
                        'Your booking expired because payment was not completed within 10 minutes.',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
                      )
                    else
                      FilledButton(
                        onPressed: _payNow,
                        child: const Text('PAY NOW'),
                      ),
                  ],
                ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 88,
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
