import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_text_styles.dart';
import 'select_location_navigation.dart';
import 'selected_location.dart';

class LocationSelectorField extends StatelessWidget {
  const LocationSelectorField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'Service location',
    this.hint = 'Select a location',
  });

  final SelectedLocationResult? value;
  final ValueChanged<SelectedLocationResult> onChanged;
  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final selected = value != null && value!.addressLine.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Material(
          color: AppColors.white,
          borderRadius: AppDecorations.borderRadiusLg,
          child: InkWell(
            borderRadius: AppDecorations.borderRadiusLg,
            onTap: () async {
              final result = await openSelectLocation(
                context,
                args: SelectLocationArgs(initial: value),
              );
              if (result != null) onChanged(result);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: AppDecorations.borderRadiusLg,
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.grey200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    selected ? Icons.place_rounded : Icons.place_outlined,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      selected ? value!.displayLine : hint,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: selected
                            ? AppColors.textPrimary
                            : AppColors.grey400,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.grey400),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
