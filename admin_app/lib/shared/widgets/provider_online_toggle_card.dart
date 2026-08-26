import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/provider/provider/provider_online_status_provider.dart';

/// Lets a doctor or nurse appear as online in the patient app.
class ProviderOnlineToggleCard extends ConsumerWidget {
  const ProviderOnlineToggleCard({
    super.key,
    this.roleLabel = 'provider',
  });

  final String roleLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(providerOnlineStatusProvider);
    final online = status.isOnline;
    final accent = online ? AppColors.primary : AppColors.grey500;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppDecorations.borderRadiusLg,
        border: Border.all(
          color: online
              ? AppColors.primary.withValues(alpha: 0.35)
              : AppColors.border,
        ),
        boxShadow: AppDecorations.softShadow(opacity: 0.04),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: online ? AppColors.primaryLight : AppColors.grey100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              online ? Icons.wifi_rounded : Icons.wifi_off_rounded,
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
                  online ? 'You are online' : 'You are offline',
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  online
                      ? 'Patients can see this $roleLabel as available now.'
                      : 'Turn on to show this $roleLabel as online in the patient app.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: online,
            onChanged: !status.isReady || status.isSaving
                ? null
                : (value) async {
                    await ref
                        .read(providerOnlineStatusProvider.notifier)
                        .setOnline(value);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          value
                              ? 'You are now visible as online'
                              : 'You are now offline',
                        ),
                      ),
                    );
                  },
          ),
        ],
      ),
    );
  }
}
