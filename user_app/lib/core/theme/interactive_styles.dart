import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// Shared colors for chips, filter cards, and pill buttons on light surfaces.
class InteractiveStyles {
  InteractiveStyles._();

  static bool isDark(BuildContext context) => false;

  /// Card / chip background when not selected.
  static Color surface(BuildContext context) => AppColors.white;

  /// Primary text on [surface].
  static Color onSurface(BuildContext context) => AppColors.textPrimary;

  static Color secondaryOnSurface(BuildContext context) =>
      AppColors.textSecondary;

  static Color border(BuildContext context, {bool selected = false}) =>
      selected ? AppColors.primary : AppColors.divider;

  static TextStyle chipLabel(
    BuildContext context, {
    bool selected = false,
    double fontSize = 12,
  }) {
    return AppTextStyles.labelSmall.copyWith(
      fontWeight: FontWeight.w700,
      fontSize: fontSize,
      color: selected ? AppColors.primaryDark : onSurface(context),
    );
  }

  static BoxDecoration filterCard(
    BuildContext context, {
    required bool selected,
    BorderRadius? radius,
  }) {
    return BoxDecoration(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.10)
          : surface(context),
      borderRadius: radius ?? BorderRadius.circular(8),
      border: Border.all(
        color: border(context, selected: selected),
        width: selected ? 2 : 1,
      ),
    );
  }
}
