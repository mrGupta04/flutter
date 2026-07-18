import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validation_utils.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/repositories/patient_auth_repository.dart';

/// Patient password recovery: email → OTP → new password.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  int _step = 0; // 0 = email, 1 = otp + new password
  bool _loading = false;
  String? _maskedEmail;
  String? _devOtp;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_emailFormKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final repo = PatientAuthRepository();
    final res = await repo.forgotPassword(email: _emailController.text.trim());
    if (!mounted) return;
    setState(() => _loading = false);

    if (!res.success) {
      SnackBarHelper.showError(
        context,
        res.error ?? 'Could not send reset code',
      );
      return;
    }

    final data = res.data;
    setState(() {
      _step = 1;
      _maskedEmail = data?['maskedEmail'] as String? ??
          _emailController.text.trim();
      _devOtp = data?['devOtp'] as String?;
    });
    SnackBarHelper.showSuccess(
      context,
      res.message ?? 'If an account exists, a reset code was sent.',
    );
  }

  Future<void> _resetPassword() async {
    if (!_resetFormKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final repo = PatientAuthRepository();
    final res = await repo.resetPassword(
      email: _emailController.text.trim(),
      otp: _otpController.text.trim(),
      newPassword: _passwordController.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (!res.success) {
      SnackBarHelper.showError(
        context,
        res.error ?? 'Could not reset password',
      );
      return;
    }

    SnackBarHelper.showSuccess(
      context,
      res.message ?? 'Password updated. Please sign in.',
    );
    context.go(AppConstants.routeUserLogin);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Forgot password')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: _step == 0 ? _buildEmailStep() : _buildResetStep(),
      ),
    );
  }

  Widget _buildEmailStep() {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Reset your password',
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter the email linked to your account. We will send a one-time code if it exists.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          CustomTextField(
            controller: _emailController,
            label: 'Email',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) => ValidationUtils.validateEmail(v ?? ''),
          ),
          const SizedBox(height: 20),
          CustomButton(
            label: 'Send reset code',
            icon: Icons.mark_email_read_outlined,
            isLoading: _loading,
            onPressed: _sendOtp,
          ),
        ],
      ),
    );
  }

  Widget _buildResetStep() {
    return Form(
      key: _resetFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Enter code & new password',
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We sent a code to ${_maskedEmail ?? 'your email'}.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          if (_devOtp != null) ...[
            const SizedBox(height: 8),
            Text(
              'Dev OTP: $_devOtp',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 24),
          CustomTextField(
            controller: _otpController,
            label: 'OTP code',
            prefixIcon: Icons.pin_outlined,
            keyboardType: TextInputType.number,
            validator: (v) {
              if (v == null || !RegExp(r'^\d{4,8}$').hasMatch(v.trim())) {
                return 'Enter the 4–8 digit code';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          CustomTextField(
            controller: _passwordController,
            label: 'New password',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: true,
            validator: (v) => ValidationUtils.validatePassword(v ?? ''),
          ),
          const SizedBox(height: 12),
          CustomTextField(
            controller: _confirmController,
            label: 'Confirm password',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: true,
            validator: (v) {
              if (v != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          CustomButton(
            label: 'Update password',
            icon: Icons.check_rounded,
            isLoading: _loading,
            onPressed: _resetPassword,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _loading
                ? null
                : () {
                    setState(() => _step = 0);
                  },
            child: const Text('Use a different email'),
          ),
          TextButton(
            onPressed: _loading ? null : _sendOtp,
            child: const Text('Resend code'),
          ),
        ],
      ),
    );
  }
}
