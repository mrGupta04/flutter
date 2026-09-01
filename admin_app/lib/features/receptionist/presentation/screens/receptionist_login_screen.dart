import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../shared/widgets/healthcare_ui.dart';
import '../../provider/receptionist_providers.dart';

class ReceptionistLoginScreen extends ConsumerStatefulWidget {
  const ReceptionistLoginScreen({super.key});

  @override
  ConsumerState<ReceptionistLoginScreen> createState() =>
      _ReceptionistLoginScreenState();
}

class _ReceptionistLoginScreenState
    extends ConsumerState<ReceptionistLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      SnackBarHelper.showError(context, 'Enter email and password');
      return;
    }
    final ok = await ref.read(receptionistAuthProvider.notifier).login(
          email: email,
          password: password,
        );
    if (!mounted) return;
    if (ok) {
      context.go(AppConstants.routeReceptionistDashboard);
    } else {
      SnackBarHelper.showError(
        context,
        ref.read(receptionistAuthProvider).error ?? 'Login failed',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(receptionistAuthProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          OneMgHeader(
            locationLabel: 'Staff login',
            locationValue: 'Receptionist',
            searchHint: '',
            trailing: const Icon(Icons.arrow_back_rounded, size: 22),
            onTrailingTap: () => context.go(AppConstants.routeProviderLanding),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: ResponsiveUtils.pagePadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Text(
                    'Receptionist login',
                    style: AppTextStyles.headlineSmall.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Use the email and password created by your doctor.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  CustomTextField(
                    controller: _emailController,
                    label: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _passwordController,
                    label: 'Password',
                    obscureText: true,
                    prefixIcon: Icons.lock_outline_rounded,
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    label: 'Sign in',
                    isLoading: auth.isLoading,
                    onPressed: _login,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
