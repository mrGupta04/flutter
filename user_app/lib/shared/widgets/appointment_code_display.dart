import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Clinic arrival OTP — patient shows this to the receptionist. Never used for self-verify.
class AppointmentCodeDisplay extends StatefulWidget {
  const AppointmentCodeDisplay({
    super.key,
    required this.code,
    this.verified = false,
    this.compact = false,
    this.bookingId,
    this.onRegenerate,
  });

  final String code;
  final bool verified;
  final bool compact;
  final String? bookingId;
  final Future<String?> Function()? onRegenerate;

  @override
  State<AppointmentCodeDisplay> createState() => _AppointmentCodeDisplayState();
}

class _AppointmentCodeDisplayState extends State<AppointmentCodeDisplay> {
  bool _visible = false;
  bool _regenerating = false;
  String? _code;

  String get _displayCode => _code ?? widget.code;

  @override
  void didUpdateWidget(covariant AppointmentCodeDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.verified ||
        (widget.code != oldWidget.code && widget.code.isNotEmpty)) {
      _code = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.verified) {
      return Container(
        width: widget.compact ? null : double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified_rounded, color: AppColors.success),
                const SizedBox(width: 8),
                Text(
                  'Arrival Verified',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'You have been verified by the clinic receptionist.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    final raw = _displayCode.trim();
    if (raw.isEmpty) {
      return Container(
        width: widget.compact ? null : double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Arrival Verification',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Waiting for Clinic Verification',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Please show the OTP to the receptionist when you arrive at the clinic.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            if (widget.onRegenerate != null)
              TextButton(
                onPressed: _regenerating
                    ? null
                    : () async {
                        setState(() => _regenerating = true);
                        final next = await widget.onRegenerate!();
                        if (!mounted) return;
                        setState(() {
                          _regenerating = false;
                          if (next != null && next.isNotEmpty) _code = next;
                        });
                      },
                child: Text(
                  _regenerating ? 'Generating…' : 'Generate verification code',
                ),
              ),
          ],
        ),
      );
    }

    final digits = raw.padLeft(4, '0').split('');

    return Container(
      width: widget.compact ? null : double.infinity,
      padding: EdgeInsets.all(widget.compact ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Arrival Verification',
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'When you arrive at the clinic, show this OTP to the receptionist.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Waiting for Clinic Verification',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.warning,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: widget.compact ? 10 : 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: digits.map((digit) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: widget.compact ? 36 : 44,
                height: widget.compact ? 44 : 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _visible ? digit : '•',
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => setState(() => _visible = !_visible),
            icon: Icon(
              _visible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              size: 18,
            ),
            label: Text(_visible ? 'Hide OTP' : 'Show OTP'),
          ),
          if (widget.onRegenerate != null)
            TextButton(
              onPressed: _regenerating
                  ? null
                  : () async {
                      setState(() => _regenerating = true);
                      final next = await widget.onRegenerate!();
                      if (!mounted) return;
                      setState(() {
                        _regenerating = false;
                        if (next != null && next.isNotEmpty) _code = next;
                      });
                    },
              child: Text(_regenerating ? 'Generating…' : 'Generate new code'),
            ),
        ],
      ),
    );
  }
}
