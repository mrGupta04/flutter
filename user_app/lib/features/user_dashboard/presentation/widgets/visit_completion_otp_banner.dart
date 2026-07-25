import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/repositories/notifications_repository.dart';

/// Shows the 6-digit OTP the patient must share with the nurse to complete a visit.
class VisitCompletionOtpBanner extends StatefulWidget {
  const VisitCompletionOtpBanner({
    super.key,
    required this.bookingId,
  });

  final String bookingId;

  @override
  State<VisitCompletionOtpBanner> createState() =>
      _VisitCompletionOtpBannerState();
}

class _VisitCompletionOtpBannerState extends State<VisitCompletionOtpBanner> {
  String? _otp;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOtp();
  }

  Future<void> _loadOtp() async {
    try {
      final result = await NotificationsRepository().list();
      final match = result.notifications.where((n) {
        if (n.type != 'visit_completion_otp') return false;
        return n.data['bookingId']?.toString() == widget.bookingId;
      }).toList();
      if (match.isEmpty) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      match.sort((a, b) {
        final at = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bt.compareTo(at);
      });
      final latest = match.first;
      final otp = latest.data['otp']?.toString() ??
          RegExp(r'\b(\d{6})\b').firstMatch(latest.body)?.group(1);
      if (mounted) {
        setState(() {
          _otp = otp;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _otp == null || _otp!.length != 6) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Share this OTP with your nurse',
            style: AppTextStyles.labelLarge.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your nurse has finished the visit. Share this code so they can mark the service complete.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  _otp!,
                  style: AppTextStyles.headlineSmall.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 6,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Copy OTP',
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: _otp!));
                  if (context.mounted) {
                    SnackBarHelper.showSuccess(context, 'OTP copied');
                  }
                },
                icon: const Icon(Icons.copy_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
