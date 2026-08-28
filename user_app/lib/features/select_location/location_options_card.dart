import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_text_styles.dart';

class CurrentLocationOption extends StatelessWidget {
  const CurrentLocationOption({
    super.key,
    required this.onTap,
    this.detectedAddress,
    this.isLoading = false,
  });

  final VoidCallback onTap;
  final String? detectedAddress;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            const Icon(Icons.my_location_rounded, color: AppColors.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Use current location',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isLoading
                        ? 'Detecting your location…'
                        : (detectedAddress == null || detectedAddress!.isEmpty)
                            ? 'We will request permission and fill your address'
                            : detectedAddress!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isLoading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              const Icon(Icons.chevron_right_rounded, color: AppColors.grey400),
          ],
        ),
      ),
    );
  }
}

class AddAddressOption extends StatelessWidget {
  const AddAddressOption({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            const Icon(Icons.add_rounded, color: AppColors.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Add Address',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.grey400),
          ],
        ),
      ),
    );
  }
}

class LocationOptionsCard extends StatelessWidget {
  const LocationOptionsCard({
    super.key,
    required this.onUseCurrentLocation,
    required this.onAddAddress,
    this.detectedAddress,
    this.isLocating = false,
  });

  final VoidCallback onUseCurrentLocation;
  final VoidCallback onAddAddress;
  final String? detectedAddress;
  final bool isLocating;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppDecorations.borderRadiusLg,
        boxShadow: AppDecorations.softShadow(opacity: 0.04),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          CurrentLocationOption(
            onTap: onUseCurrentLocation,
            detectedAddress: detectedAddress,
            isLoading: isLocating,
          ),
          const Divider(height: 1, color: AppColors.grey200),
          AddAddressOption(onTap: onAddAddress),
        ],
      ),
    );
  }
}
