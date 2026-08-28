import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_text_styles.dart';
import 'location_permission_handler.dart';

class LocationPermissionBanner extends StatelessWidget {
  const LocationPermissionBanner({
    super.key,
    required this.state,
    required this.onEnable,
  });

  final LocationPermissionUiState state;
  final VoidCallback onEnable;

  @override
  Widget build(BuildContext context) {
    if (state == LocationPermissionUiState.granted) {
      return const SizedBox.shrink();
    }
    final unavailable = state == LocationPermissionUiState.unavailable;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: AppDecorations.borderRadiusMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            unavailable
                ? 'Location is turned off'
                : 'Allow location access',
            style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            unavailable
                ? 'Turn on GPS to use your current location, or search and select an address manually.'
                : 'Enable location so we can detect your current address. You can still search or pick a saved address.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onEnable,
            child: Text(unavailable ? 'Turn on location' : 'Enable location'),
          ),
        ],
      ),
    );
  }
}
