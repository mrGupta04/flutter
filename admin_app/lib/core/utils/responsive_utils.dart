import 'package:flutter/material.dart';

/// Responsive layout helpers for mobile and tablet widths.
class ResponsiveUtils {
  ResponsiveUtils._();

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 600;

  static double contentMaxWidth(BuildContext context) =>
      isTablet(context) ? 720 : double.infinity;

  static EdgeInsets pagePadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 900) {
      return const EdgeInsets.symmetric(horizontal: 48, vertical: 24);
    }
    if (width >= 600) {
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 24);
    }
    return const EdgeInsets.symmetric(horizontal: 24, vertical: 24);
  }
}

/// Centers content and constrains width on larger screens.
class ResponsivePage extends StatelessWidget {
  const ResponsivePage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: ResponsiveUtils.contentMaxWidth(context),
        ),
        child: child,
      ),
    );
  }
}
