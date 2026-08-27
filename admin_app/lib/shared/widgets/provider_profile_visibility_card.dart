import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/doctor_model.dart';
import '../../features/doctor_dashboard/provider/dashboard_provider.dart';
import '../../features/nurse_dashboard/provider/nurse_dashboard_provider.dart';

enum ProviderVisibilityRole { doctor, nurse }

/// Lets a doctor or nurse hide their profile from the patient marketplace.
class ProviderProfileVisibilityCard extends ConsumerStatefulWidget {
  const ProviderProfileVisibilityCard({
    super.key,
    required this.role,
  });

  final ProviderVisibilityRole role;

  @override
  ConsumerState<ProviderProfileVisibilityCard> createState() =>
      _ProviderProfileVisibilityCardState();
}

class _ProviderProfileVisibilityCardState
    extends ConsumerState<ProviderProfileVisibilityCard> {
  bool _saving = false;

  ProfileStatus get _profileStatus {
    return switch (widget.role) {
      ProviderVisibilityRole.doctor =>
        ref.watch(doctorDashboardProvider).doctor?.profileStatus ??
            ProfileStatus.active,
      ProviderVisibilityRole.nurse =>
        ref.watch(nurseDashboardProvider).nurse?.profileStatus ??
            ProfileStatus.active,
    };
  }

  @override
  Widget build(BuildContext context) {
    final profileStatus = _profileStatus;
    final disabled = profileStatus == ProfileStatus.disabled;
    final accent = disabled ? AppColors.warning : AppColors.primary;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppDecorations.borderRadiusLg,
        border: Border.all(
          color: disabled
              ? AppColors.warning.withValues(alpha: 0.45)
              : AppColors.primary.withValues(alpha: 0.35),
        ),
        boxShadow: AppDecorations.softShadow(opacity: 0.04),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: disabled ? AppColors.offerLight : AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              disabled
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              color: accent,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profile Visibility',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  disabled ? 'Disable Profile' : 'Profile Active',
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  disabled
                      ? 'Your profile is currently hidden from users. Enable your profile when you are ready to accept new bookings.'
                      : 'Your profile is visible to users.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          if (_saving)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Switch.adaptive(
              value: !disabled,
              onChanged: (value) => _onToggle(value: value),
            ),
        ],
      ),
    );
  }

  Future<void> _onToggle({required bool value}) async {
    final next = value ? ProfileStatus.active : ProfileStatus.disabled;
    if (next == ProfileStatus.disabled) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Disable Profile'),
          content: const Text(
            'Are you sure you want to disable your profile? Your profile will not be visible to users while it is disabled.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Disable Profile'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    setState(() => _saving = true);
    final ok = switch (widget.role) {
      ProviderVisibilityRole.doctor => await ref
          .read(doctorDashboardProvider.notifier)
          .setProfileStatus(next),
      ProviderVisibilityRole.nurse => await ref
          .read(nurseDashboardProvider.notifier)
          .setProfileStatus(next),
    };
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (next == ProfileStatus.disabled
                  ? 'Your profile is now hidden from users'
                  : 'Your profile is now visible to users')
              : (widget.role == ProviderVisibilityRole.doctor
                      ? ref.read(doctorDashboardProvider).error
                      : ref.read(nurseDashboardProvider).error) ??
                  'Could not update profile visibility',
        ),
      ),
    );
  }
}
