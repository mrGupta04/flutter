import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../data/services/dio_service.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/models/doctor_booking_model.dart';
import '../../provider/nurse_dashboard_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NurseVisitOtpScreen extends ConsumerStatefulWidget {
  const NurseVisitOtpScreen({super.key, required this.booking});

  final DoctorBookingModel booking;

  @override
  ConsumerState<NurseVisitOtpScreen> createState() =>
      _NurseVisitOtpScreenState();
}

class _NurseVisitOtpScreenState extends ConsumerState<NurseVisitOtpScreen> {
  final _otpController = TextEditingController();
  bool _requesting = false;
  bool _verifying = false;
  bool _otpSent = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    setState(() => _requesting = true);
    try {
      await DioService().post(
        AppConstants.endpointNurseVisitCompleteRequestOtp(widget.booking.id),
        data: {},
      );
      if (mounted) {
        setState(() => _otpSent = true);
        SnackBarHelper.showSuccess(
          context,
          'OTP sent to patient via app & email',
        );
      }
    } catch (e) {
      if (mounted) SnackBarHelper.showError(context, '$e');
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  Future<void> _verify() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      SnackBarHelper.showError(context, 'Enter the 6-digit OTP');
      return;
    }
    setState(() => _verifying = true);
    try {
      await DioService().post(
        AppConstants.endpointNurseVisitCompleteVerifyOtp(widget.booking.id),
        data: {'otp': otp},
      );
      await ref.read(nurseDashboardProvider.notifier).refreshAll();
      if (!mounted) return;
      SnackBarHelper.showSuccess(context, 'Visit completed successfully');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) SnackBarHelper.showError(context, '$e');
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify completion')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Complete service',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ask the patient for the 6-digit OTP sent to their app and email. '
              'This confirms the visit was completed successfully.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 24),
            if (!_otpSent)
              FilledButton(
                onPressed: _requesting ? null : _requestOtp,
                child: _requesting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Send OTP to patient'),
              ),
            if (_otpSent) ...[
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 8,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Enter 6-digit OTP',
                  counterText: '',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _verifying ? null : _verify,
                child: _verifying
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Verify & complete visit'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _requesting ? null : _requestOtp,
                child: const Text('Resend OTP'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
