import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_text_styles.dart';
import 'incoming_booking_alert_controller.dart';
import 'incoming_booking_request.dart';

class IncomingBookingAlertOverlay extends ConsumerWidget {
  const IncomingBookingAlertOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alert = ref.watch(incomingBookingAlertProvider);
    final request = alert.current;
    if (request == null) return const SizedBox.shrink();

    return Positioned.fill(
      child: PopScope(
        canPop: false,
        child: Material(
          color: const Color(0xE60D1F14),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: _IncomingCallCard(
                  request: request,
                  remainingSeconds: alert.remainingSeconds,
                  isActing: alert.isActing,
                  error: alert.actionError,
                  onAccept: () =>
                      ref.read(incomingBookingAlertProvider.notifier).accept(),
                  onReject: () =>
                      ref.read(incomingBookingAlertProvider.notifier).reject(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IncomingCallCard extends StatefulWidget {
  const _IncomingCallCard({
    required this.request,
    required this.remainingSeconds,
    required this.isActing,
    required this.onAccept,
    required this.onReject,
    this.error,
  });

  final IncomingBookingRequest request;
  final int remainingSeconds;
  final bool isActing;
  final String? error;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  State<_IncomingCallCard> createState() => _IncomingCallCardState();
}

class _IncomingCallCardState extends State<_IncomingCallCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  String _clock(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(1, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    final expired = request.status.toLowerCase() == 'expired';
    final waiting = request.isPending && !expired;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.28),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
              decoration: const BoxDecoration(
                color: AppColors.headerGreen,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, child) {
                      final t = Curves.easeOut.transform(_pulse.value);
                      return Container(
                        width: 92 + (18 * t),
                        height: 92 + (18 * t),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.white.withValues(alpha: 0.12 + (0.18 * (1 - t))),
                          border: Border.all(
                            color: AppColors.white.withValues(alpha: 0.55 * (1 - t)),
                            width: 3,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: child,
                      );
                    },
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        color: AppColors.headerGreen,
                        size: 34,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    expired ? 'Request expired' : 'New Booking Request',
                    style: AppTextStyles.titleLarge.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    waiting
                        ? 'Incoming request · ${_clock(widget.remainingSeconds)}'
                        : request.statusLabel,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _InfoRow(label: 'Patient', value: request.patientName),
                  _InfoRow(label: 'Service', value: request.serviceType),
                  _InfoRow(label: 'Date', value: request.dateLabel),
                  _InfoRow(label: 'Time', value: request.displayTime),
                  if (request.locationLine != null &&
                      request.locationLine!.trim().isNotEmpty)
                    _InfoRow(label: 'Location', value: request.locationLine!),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: expired
                            ? AppColors.error.withValues(alpha: 0.1)
                            : AppColors.warning.withValues(alpha: 0.12),
                        borderRadius: AppDecorations.borderRadiusPill,
                      ),
                      child: Text(
                        request.statusLabel,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: expired ? AppColors.error : AppColors.warning,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  if (widget.error != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      widget.error!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: widget.isActing || expired
                              ? null
                              : widget.onReject,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppDecorations.borderRadiusMd,
                            ),
                          ),
                              child: const Text('Reject Booking'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: widget.isActing || expired
                              ? null
                              : widget.onAccept,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppDecorations.borderRadiusMd,
                            ),
                          ),
                          child: widget.isActing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.white,
                                  ),
                                )
                              : const Text('Accept Booking'),
                        ),
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
            width: 78,
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
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
