import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/interactive_styles.dart';

/// Selectable filter chip with readable text in light and dark mode.
class CareFilterChip extends StatelessWidget {
  const CareFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary
                : InteractiveStyles.surface(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : InteractiveStyles.border(context),
            ),
          ),
          child: Text(
            label,
            style: InteractiveStyles.chipLabel(
              context,
              selected: selected,
            ).copyWith(
              color: selected
                  ? AppColors.white
                  : InteractiveStyles.onSurface(context),
            ),
          ),
        ),
      ),
    );
  }
}
