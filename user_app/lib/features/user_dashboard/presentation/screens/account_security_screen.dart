import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../user_auth/provider/patient_auth_provider.dart';

class AccountSecurityScreen extends ConsumerStatefulWidget {
  const AccountSecurityScreen({super.key});

  @override
  ConsumerState<AccountSecurityScreen> createState() =>
      _AccountSecurityScreenState();
}

class _AccountSecurityScreenState extends ConsumerState<AccountSecurityScreen> {
  bool _busy = false;

  Future<void> _logoutAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out everywhere?'),
        content: const Text(
          'This ends all active sessions on other phones and browsers. You will need to sign in again here.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign out all')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    await ref.read(patientAuthProvider.notifier).logoutAllDevices();
    if (!mounted) return;
    context.go(AppConstants.routeUserHome);
  }

  Future<void> _deleteAccount() async {
    final passwordCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete account'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'This removes profile access. Completed bookings, payments, and medical documents are retained where required for medical, financial, and audit records.',
                ),
                const SizedBox(height: 12),
                const Text('Type DELETE to confirm, then enter your password.'),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmCtrl,
                  decoration: const InputDecoration(labelText: 'Type DELETE'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: passwordCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep account')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete account'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    final error = await ref.read(patientAuthProvider.notifier).deleteAccount(
          password: passwordCtrl.text,
          confirmText: confirmCtrl.text,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      SnackBarHelper.showError(context, error);
      return;
    }
    context.go(AppConstants.routeUserHome);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Security')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Protect your healthcare account',
            style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.lock_reset_outlined),
            title: const Text('Change password'),
            subtitle: const Text('Reset using email verification'),
            onTap: () => context.push(AppConstants.routeForgotPassword),
          ),
          ListTile(
            leading: const Icon(Icons.verified_user_outlined),
            title: const Text('Email & phone'),
            subtitle: const Text('Verified from your signed-in profile'),
          ),
          ListTile(
            leading: const Icon(Icons.devices_outlined),
            title: const Text('Sign out of all devices'),
            subtitle: const Text('Invalidates other active sessions'),
            onTap: _busy ? null : _logoutAll,
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.delete_forever_outlined, color: AppColors.error),
            title: Text('Delete account', style: TextStyle(color: AppColors.error)),
            subtitle: const Text('Multi-step confirmation required'),
            onTap: _busy ? null : _deleteAccount,
          ),
          if (_busy) const LinearProgressIndicator(),
        ],
      ),
    );
  }
}
