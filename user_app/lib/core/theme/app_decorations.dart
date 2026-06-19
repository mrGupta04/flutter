import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppDecorations {
  AppDecorations._();

  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radiusPill = 100;

  static BorderRadius get borderRadiusSm => BorderRadius.circular(radiusSm);
  static BorderRadius get borderRadiusMd => BorderRadius.circular(radiusMd);
  static BorderRadius get borderRadiusLg => BorderRadius.circular(radiusLg);
  static BorderRadius get borderRadiusXl => BorderRadius.circular(radiusXl);
  static BorderRadius get borderRadiusPill =>
      BorderRadius.circular(radiusPill);

  static List<BoxShadow> softShadow({double opacity = 0.05}) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: opacity),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static BoxDecoration card({
    required BuildContext context,
    Color? color,
    Gradient? gradient,
    bool elevated = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: gradient == null
          ? (color ?? (isDark ? AppColors.darkSurfaceElevated : AppColors.white))
          : null,
      gradient: gradient,
      borderRadius: borderRadiusLg,
      border: Border.all(color: AppColors.grey200),
      boxShadow: elevated ? softShadow() : null,
    );
  }

  static BoxDecoration gradientHeader({
    List<Color>? colors,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: colors ?? AppColors.gradientHero,
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    );
  }

  static BoxDecoration iconTile(Color color) {
    return BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: borderRadiusMd,
    );
  }

  static BoxDecoration offerStrip() {
    return BoxDecoration(
      color: AppColors.offerLight,
      borderRadius: borderRadiusMd,
      border: Border.all(color: AppColors.offer.withValues(alpha: 0.2)),
    );
  }
}
