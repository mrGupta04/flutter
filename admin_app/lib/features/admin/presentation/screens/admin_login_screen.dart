import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../shared/widgets/healthcare_ui.dart';
import '../../provider/admin_auth_provider.dart';

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _asApprover = false;

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter email and password')));
      return;
    }

    final ok = await ref
        .read(adminAuthProvider.notifier)
        .login(email: email, password: password, asApprover: _asApprover);

    if (!mounted) return;

    if (ok) {
      context.go(
        _asApprover
            ? AppConstants.routeApprovalManagement
            : AppConstants.routeAdminDashboard,
      );
    } else {
      final err = ref.read(adminAuthProvider).error;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(err ?? 'Login failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(adminAuthProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          OneMgHeader(
            locationLabel: 'Admin',
            locationValue: 'Sign in to admin panel',
            searchHint: '',
            trailing: const Icon(Icons.arrow_back_rounded, size: 22),
            onTrailingTap: () => context.go(AppConstants.routeProviderLanding),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: ResponsiveUtils.pagePadding(context),
              child: ResponsiveFormWidth(
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Text(
                    _asApprover ? 'Approver login' : 'Admin login',
                    style: AppTextStyles.headlineSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _asApprover
                        ? 'Sign in with the credentials created by your administrator.'
                        : 'Use your administrator credentials.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 28),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: false,
                        icon: Icon(Icons.admin_panel_settings_outlined),
                        label: Text('Admin'),
                      ),
                      ButtonSegment(
                        value: true,
                        icon: Icon(Icons.fact_check_outlined),
                        label: Text('Approver'),
                      ),
                    ],
                    selected: {_asApprover},
                    onSelectionChanged: auth.isLoading
                        ? null
                        : (value) => setState(() => _asApprover = value.first),
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'admin@1mgdoctors.com',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _passwordController,
                    label: 'Password',
                    hint: 'Your admin password',
                    prefixIcon: Icons.lock_outline_rounded,
                    obscureText: true,
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    label: 'Sign in',
                    onPressed: _login,
                    isLoading: auth.isLoading,
                    isEnabled: !auth.isLoading,
                  ),
                ],
              ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
