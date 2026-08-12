import 'package:flutter/material.dart';

/// Breakpoint tokens for the marketplace UI.
enum Breakpoint {
  mobile,
  tablet,
  laptop,
  desktop,
  largeDesktop,
}

/// Central responsive helpers — prefer these over ad-hoc MediaQuery checks.
class ResponsiveUtils {
  ResponsiveUtils._();

  static const double mobileMax = 600;
  static const double tabletMax = 1024;
  static const double laptopMax = 1440;
  static const double desktopMax = 1920;

  static const double contentMaxMobile = double.infinity;
  static const double contentMaxTablet = 840;
  static const double contentMaxLaptop = 1100;
  static const double contentMaxDesktop = 1280;
  static const double contentMaxLargeDesktop = 1400;

  static const double formMaxWidth = 560;
  static const double dialogMaxWidth = 560;
  static const double wideDialogMaxWidth = 720;

  static double widthOf(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static double heightOf(BuildContext context) =>
      MediaQuery.sizeOf(context).height;

  static Breakpoint breakpointOf(BuildContext context) {
    final width = widthOf(context);
    if (width < mobileMax) return Breakpoint.mobile;
    if (width < tabletMax) return Breakpoint.tablet;
    if (width < laptopMax) return Breakpoint.laptop;
    if (width < desktopMax) return Breakpoint.desktop;
    return Breakpoint.largeDesktop;
  }

  static bool isMobile(BuildContext context) =>
      breakpointOf(context) == Breakpoint.mobile;

  static bool isTablet(BuildContext context) {
    final bp = breakpointOf(context);
    return bp == Breakpoint.tablet;
  }

  static bool isLaptop(BuildContext context) =>
      breakpointOf(context) == Breakpoint.laptop;

  static bool isDesktop(BuildContext context) {
    final bp = breakpointOf(context);
    return bp == Breakpoint.desktop || bp == Breakpoint.largeDesktop;
  }

  static bool isLargeDesktop(BuildContext context) =>
      breakpointOf(context) == Breakpoint.largeDesktop;

  /// Tablet and up (includes landscape phones that are wide enough).
  static bool isTabletOrUp(BuildContext context) =>
      widthOf(context) >= mobileMax;

  /// Laptop and up — prefer sidebar / denser layouts.
  static bool isLaptopOrUp(BuildContext context) =>
      widthOf(context) >= tabletMax;

  /// Compact navigation (bottom bar) vs rail/sidebar.
  static bool useBottomNavigation(BuildContext context) =>
      widthOf(context) < mobileMax;

  static bool useNavigationRail(BuildContext context) {
    final width = widthOf(context);
    return width >= mobileMax && width < tabletMax;
  }

  static bool useSideNavigation(BuildContext context) =>
      widthOf(context) >= tabletMax;

  static double contentMaxWidth(BuildContext context) {
    switch (breakpointOf(context)) {
      case Breakpoint.mobile:
        return contentMaxMobile;
      case Breakpoint.tablet:
        return contentMaxTablet;
      case Breakpoint.laptop:
        return contentMaxLaptop;
      case Breakpoint.desktop:
        return contentMaxDesktop;
      case Breakpoint.largeDesktop:
        return contentMaxLargeDesktop;
    }
  }

  static EdgeInsets pagePadding(BuildContext context) {
    switch (breakpointOf(context)) {
      case Breakpoint.mobile:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
      case Breakpoint.tablet:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 20);
      case Breakpoint.laptop:
        return const EdgeInsets.symmetric(horizontal: 32, vertical: 24);
      case Breakpoint.desktop:
      case Breakpoint.largeDesktop:
        return const EdgeInsets.symmetric(horizontal: 40, vertical: 28);
    }
  }

  static double space(BuildContext context, {double mobile = 16}) {
    switch (breakpointOf(context)) {
      case Breakpoint.mobile:
        return mobile;
      case Breakpoint.tablet:
        return mobile * 1.15;
      case Breakpoint.laptop:
        return mobile * 1.25;
      case Breakpoint.desktop:
      case Breakpoint.largeDesktop:
        return mobile * 1.35;
    }
  }

  /// Grid column count for card lists.
  static int gridColumns(
    BuildContext context, {
    int mobile = 1,
    int tablet = 2,
    int laptop = 3,
    int desktop = 3,
    int largeDesktop = 4,
  }) {
    switch (breakpointOf(context)) {
      case Breakpoint.mobile:
        return mobile;
      case Breakpoint.tablet:
        return tablet;
      case Breakpoint.laptop:
        return laptop;
      case Breakpoint.desktop:
        return desktop;
      case Breakpoint.largeDesktop:
        return largeDesktop;
    }
  }

  static double valueFor(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? laptop,
    double? desktop,
    double? largeDesktop,
  }) {
    switch (breakpointOf(context)) {
      case Breakpoint.mobile:
        return mobile;
      case Breakpoint.tablet:
        return tablet ?? mobile;
      case Breakpoint.laptop:
        return laptop ?? tablet ?? mobile;
      case Breakpoint.desktop:
        return desktop ?? laptop ?? tablet ?? mobile;
      case Breakpoint.largeDesktop:
        return largeDesktop ?? desktop ?? laptop ?? tablet ?? mobile;
    }
  }

  static T pick<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? laptop,
    T? desktop,
    T? largeDesktop,
  }) {
    switch (breakpointOf(context)) {
      case Breakpoint.mobile:
        return mobile;
      case Breakpoint.tablet:
        return tablet ?? mobile;
      case Breakpoint.laptop:
        return laptop ?? tablet ?? mobile;
      case Breakpoint.desktop:
        return desktop ?? laptop ?? tablet ?? mobile;
      case Breakpoint.largeDesktop:
        return largeDesktop ?? desktop ?? laptop ?? tablet ?? mobile;
    }
  }
}

/// Centers content and constrains width on larger screens.
class ResponsivePage extends StatelessWidget {
  const ResponsivePage({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final content = padding == null
        ? child
        : Padding(padding: padding!, child: child);

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? ResponsiveUtils.contentMaxWidth(context),
        ),
        child: SizedBox(width: double.infinity, child: content),
      ),
    );
  }
}

/// Constrains forms so fields do not stretch across ultra-wide monitors.
class ResponsiveFormWidth extends StatelessWidget {
  const ResponsiveFormWidth({
    super.key,
    required this.child,
    this.maxWidth = ResponsiveUtils.formMaxWidth,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final double maxWidth;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}

/// Builds different compositions when structure truly differs by breakpoint.
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  @override
  Widget build(BuildContext context) {
    if (ResponsiveUtils.isLaptopOrUp(context)) {
      return desktop ?? tablet ?? mobile;
    }
    if (ResponsiveUtils.isTabletOrUp(context)) {
      return tablet ?? mobile;
    }
    return mobile;
  }
}

/// Responsive grid for repeated cards / tiles.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.mobileColumns = 1,
    this.tabletColumns = 2,
    this.laptopColumns = 3,
    this.desktopColumns = 3,
    this.largeDesktopColumns = 4,
    this.spacing = 12,
    this.runSpacing = 12,
    this.childAspectRatio,
    this.shrinkWrap = true,
    this.physics = const NeverScrollableScrollPhysics(),
    this.padding = EdgeInsets.zero,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final int mobileColumns;
  final int tabletColumns;
  final int laptopColumns;
  final int desktopColumns;
  final int largeDesktopColumns;
  final double spacing;
  final double runSpacing;
  final double? childAspectRatio;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final columns = ResponsiveUtils.gridColumns(
      context,
      mobile: mobileColumns,
      tablet: tabletColumns,
      laptop: laptopColumns,
      desktop: desktopColumns,
      largeDesktop: largeDesktopColumns,
    );

    return GridView.builder(
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: itemCount,
      gridDelegate: childAspectRatio != null
          ? SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: runSpacing,
              crossAxisSpacing: spacing,
              childAspectRatio: childAspectRatio!,
            )
          : SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: _extentForColumns(context, columns),
              mainAxisSpacing: runSpacing,
              crossAxisSpacing: spacing,
              childAspectRatio: 1.55,
            ),
      itemBuilder: itemBuilder,
    );
  }

  double _extentForColumns(BuildContext context, int columns) {
    final width = ResponsiveUtils.widthOf(context);
    final usable = width.clamp(320.0, ResponsiveUtils.contentMaxWidth(context));
    return (usable / columns).clamp(160.0, 480.0);
  }
}

/// Shows a centered dialog with a sensible max width on large screens.
Future<T?> showResponsiveDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  double maxWidth = ResponsiveUtils.dialogMaxWidth,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (dialogContext) {
      return Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.valueFor(
            dialogContext,
            mobile: 16,
            tablet: 40,
            laptop: 80,
          ),
          vertical: 24,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: builder(dialogContext),
        ),
      );
    },
  );
}

/// Two-column form row on tablet+; stacks on mobile.
class ResponsiveFormRow extends StatelessWidget {
  const ResponsiveFormRow({
    super.key,
    required this.children,
    this.spacing = 16,
    this.breakpoint = Breakpoint.tablet,
  });

  final List<Widget> children;
  final double spacing;
  final Breakpoint breakpoint;

  @override
  Widget build(BuildContext context) {
    final width = ResponsiveUtils.widthOf(context);
    final useRow = switch (breakpoint) {
      Breakpoint.mobile => true,
      Breakpoint.tablet => width >= ResponsiveUtils.mobileMax,
      Breakpoint.laptop => width >= ResponsiveUtils.tabletMax,
      Breakpoint.desktop => width >= ResponsiveUtils.laptopMax,
      Breakpoint.largeDesktop => width >= ResponsiveUtils.desktopMax,
    };

    if (!useRow || children.length < 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(height: spacing),
            children[i],
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(width: spacing),
          Expanded(child: children[i]),
        ],
      ],
    );
  }
}
