import 'package:flutter/material.dart';

/// Tata 1mg design system — teal-green brand, coral offer tags, white surfaces.
class AppColors {
  AppColors._();

  // 1mg brand green (header, CTAs, links)
  static const Color primary = Color(0xFF208376);
  static const Color primaryLight = Color(0xFFE8F6F3);
  static const Color primaryDark = Color(0xFF165C54);
  static const Color primarySoft = Color(0xFFB8DDD6);
  static const Color headerGreen = Color(0xFF1D6B5C);

  // 1mg coral — offers & discount badges only
  static const Color offer = Color(0xFFFF6F61);
  static const Color offerLight = Color(0xFFFFF0EE);
  static const Color offerDark = Color(0xFFE85A4D);

  // Primary buttons use brand green (1mg style)
  static const Color cta = Color(0xFF208376);
  static const Color ctaLight = Color(0xFFE8F6F3);
  static const Color ctaDark = Color(0xFF165C54);

  static const Color accent = Color(0xFF208376);
  static const Color accentLight = Color(0xFFE8F6F3);

  static const Color secondary = Color(0xFF3D9970);
  static const Color secondaryLight = Color(0xFFE6F5ED);
  static const Color secondaryDark = Color(0xFF2D7A56);

  static const Color tertiary = Color(0xFFFFB800);

  static const Color success = Color(0xFF208376);
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF208376);
  static const Color pending = Color(0xFFFF9800);
  static const Color verified = Color(0xFF208376);
  static const Color rejected = Color(0xFFD32F2F);

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF181A1F);
  static const Color grey50 = Color(0xFFF7F8FA);
  static const Color grey100 = Color(0xFFF0F2F5);
  static const Color grey200 = Color(0xFFE4E7EC);
  static const Color grey300 = Color(0xFFC8CDD4);
  static const Color grey400 = Color(0xFF9AA3AF);
  static const Color grey500 = Color(0xFF6B7280);
  static const Color grey600 = Color(0xFF4B5563);
  static const Color grey700 = Color(0xFF374151);
  static const Color grey800 = Color(0xFF1F2937);
  static const Color grey900 = Color(0xFF111827);

  static const Color textPrimary = Color(0xFF181A1F);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9AA3AF);
  static const Color textDisabled = Color(0xFFC8CDD4);

  static const Color divider = Color(0xFFE4E7EC);
  static const Color border = Color(0xFFE4E7EC);
  static const Color background = Color(0xFFF7F8FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFFFFFF);

  static const Color darkBackground = Color(0xFF0D1117);
  static const Color darkSurface = Color(0xFF161B22);
  static const Color darkSurfaceElevated = Color(0xFF21262D);
  static const Color darkTextPrimary = Color(0xFFF0F3F8);
  static const Color darkTextSecondary = Color(0xFF9AA3AF);

  static const List<Color> gradientPrimary = [
    Color(0xFF165C54),
    Color(0xFF208376),
  ];

  static const List<Color> gradientHero = [
    Color(0xFF1D6B5C),
    Color(0xFF208376),
  ];

  static const List<Color> gradientCta = [
    Color(0xFF165C54),
    Color(0xFF208376),
  ];

  static const List<Color> gradientOffer = [
    Color(0xFFFFF0EE),
    Color(0xFFFFFBFA),
  ];

  static const List<Color> gradientSuccess = [
    Color(0xFF208376),
    Color(0xFF3D9970),
  ];

  static const List<Color> gradientAdmin = [
    Color(0xFF1D6B5C),
    Color(0xFF208376),
  ];

  /// Nurse / secondary care provider accent.
  static const List<Color> gradientNurse = [
    Color(0xFF2D7A56),
    Color(0xFF3D9970),
  ];
}
