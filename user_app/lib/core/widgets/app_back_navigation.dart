import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_constants.dart';

typedef AppBackHandler = bool Function();

/// Intercepts the Android system back button so nested routes, tab roots, and
/// multi-step screens go to the previous step/page instead of closing the app.
class AppBackButtonScope extends StatelessWidget {
  const AppBackButtonScope({
    super.key,
    required this.child,
    this.router,
  });

  final Widget child;

  /// Optional when this scope sits above [GoRouter] (e.g. [MaterialApp.builder]).
  final GoRouter? router;

  static final List<AppBackHandler> _handlers = [];

  static void addHandler(AppBackHandler handler) => _handlers.add(handler);

  static void removeHandler(AppBackHandler handler) =>
      _handlers.remove(handler);

  static bool _runHandlers() {
    for (final handler in _handlers.reversed) {
      if (handler()) return true;
    }
    return false;
  }

  static NavigatorState? _rootNavigator(
    BuildContext context, {
    GoRouter? router,
  }) {
    return router?.routerDelegate.navigatorKey.currentState ??
        GoRouter.maybeOf(context)?.routerDelegate.navigatorKey.currentState ??
        Navigator.maybeOf(context, rootNavigator: true);
  }

  static bool _popDialogIfPresent(
    BuildContext context, {
    GoRouter? router,
  }) {
    final nav = _rootNavigator(context, router: router);
    if (nav == null || !nav.canPop()) return false;
    var poppedDialog = false;
    nav.popUntil((route) {
      if (route is PopupRoute) {
        poppedDialog = true;
        return false;
      }
      return true;
    });
    return poppedDialog;
  }

  static bool _isHomePath(String path) => path == AppConstants.routeUserHome;

  static bool _isTabRootPath(String path) {
    return path == AppConstants.routeLabs ||
        path == AppConstants.routeScans ||
        path == AppConstants.routeUserDashboard ||
        path == AppConstants.routeUserDashboardLegacy ||
        path == AppConstants.routeCareListing;
  }

  static bool _hasStackedPages(GoRouter? router) {
    if (router == null) return false;
    return router.routerDelegate.currentConfiguration.matches.length > 1;
  }

  /// Handles Android/iOS back: dialogs, multi-step forms, previous route, then
  /// the parent module. Returns false only on Home so the app can exit.
  static bool handleSystemBack(
    BuildContext context, {
    GoRouter? router,
  }) {
    if (_popDialogIfPresent(context, router: router)) return true;
    if (_runHandlers()) return true;
    final goRouter = router ?? GoRouter.maybeOf(context);
    if (_hasStackedPages(goRouter) && canNavigateBack(context, router: router)) {
      navigateBack(context, router: router);
      return true;
    }
    final path = goRouter?.state.uri.path;
    if (path != null && _isTabRootPath(path)) {
      goRouter?.go(AppConstants.routeUserHome);
      return true;
    }
    if (goToPreviousPage(context, router: router)) return true;
    if (path != null && !_isHomePath(path)) {
      goRouter?.go(AppConstants.routeUserHome);
      return true;
    }
    return false;
  }

  static bool canNavigateBack(
    BuildContext context, {
    GoRouter? router,
  }) {
    final goRouter = router ?? GoRouter.maybeOf(context);
    if (!_hasStackedPages(goRouter)) return false;
    if (goRouter != null && goRouter.canPop()) return true;
    return _rootNavigator(context, router: router)?.canPop() ?? false;
  }

  static void navigateBack(
    BuildContext context, {
    GoRouter? router,
  }) {
    if (router != null && router.canPop()) {
      router.pop();
      return;
    }
    final goRouter = GoRouter.maybeOf(context);
    if (goRouter != null && goRouter.canPop()) {
      goRouter.pop();
      return;
    }
    final navigator = _rootNavigator(context, router: router);
    if (navigator != null && navigator.canPop()) {
      navigator.pop();
    }
  }

  /// Pop if possible; otherwise [go] to [fallback].
  static void popOrGo(
    BuildContext context,
    String fallback, {
    GoRouter? router,
  }) {
    if (canNavigateBack(context, router: router)) {
      navigateBack(context, router: router);
      return;
    }
    final goRouter = router ?? GoRouter.maybeOf(context);
    goRouter?.go(fallback);
  }

  /// When the stack is empty (typical after [GoRouter.go]), send the user to
  /// the parent module or Home instead of killing the process.
  static bool goToPreviousPage(
    BuildContext context, {
    GoRouter? router,
  }) {
    final goRouter = router ?? GoRouter.maybeOf(context);
    if (goRouter == null) return false;
    final path = goRouter.state.uri.path;
    final parent = _parentRoute(path);
    if (parent == null) return false;
    goRouter.go(parent);
    return true;
  }

  static String? _parentRoute(String path) {
    if (path == AppConstants.routeUserHome) return null;

    if (path == AppConstants.routeLabs ||
        path == AppConstants.routeCareListing ||
        path == AppConstants.routeUserDashboard ||
        path == AppConstants.routeUserDashboardLegacy ||
        path == AppConstants.routeUserLogin ||
        path == AppConstants.routeScans) {
      return AppConstants.routeUserHome;
    }

    if (path.startsWith('${AppConstants.routeLabDetail}/') ||
        path.startsWith(AppConstants.routeLabCart) ||
        path.startsWith(AppConstants.routeLabSearch) ||
        path.startsWith(AppConstants.routeLabBookingConfirmation) ||
        path.startsWith(AppConstants.routeUploadPrescription) ||
        path.startsWith(AppConstants.routePrescriptionRequests) ||
        path.startsWith(AppConstants.routePrescriptionRequestDetail)) {
      return AppConstants.routeLabs;
    }

    if (path.startsWith(AppConstants.routeScansCatalog) ||
        path.startsWith(AppConstants.routeScanSearch) ||
        path.startsWith(AppConstants.routeScanCenterDetail)) {
      return AppConstants.routeScans;
    }

    if (path.startsWith(AppConstants.routeUserEditProfile) ||
        path.startsWith(AppConstants.routeHealthProfile) ||
        path.startsWith(AppConstants.routeNursingReports) ||
        path.startsWith(AppConstants.routeSupportTickets) ||
        path.startsWith(AppConstants.routeUserRewards) ||
        path.startsWith(AppConstants.routeFavorites) ||
        path.startsWith(AppConstants.routeNotifications) ||
        path.startsWith(AppConstants.routeCurrentBookings) ||
        path.startsWith(AppConstants.routeBookingHistory) ||
        path.startsWith(AppConstants.routeBookingDetails)) {
      return AppConstants.routeUserDashboard;
    }

    return AppConstants.routeUserHome;
  }

  @override
  Widget build(BuildContext context) => child;
}

/// Put this *inside* a [GoRouter] page so Android back is intercepted by the
/// route itself. Wrapping [MaterialApp] does not stop the navigator from
/// finishing the activity when the stack has only one page.
class RouteBackScope extends StatelessWidget {
  const RouteBackScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (AppBackButtonScope.handleSystemBack(context)) return;
        SystemNavigator.pop();
      },
      child: child,
    );
  }
}

/// For bottom-nav tab roots: back goes to home instead of exiting the app.
class UserTabBackScope extends StatefulWidget {
  const UserTabBackScope({
    super.key,
    required this.child,
    required this.isHomeTab,
    this.homeRoute,
  });

  final Widget child;
  final bool isHomeTab;
  final String? homeRoute;

  @override
  State<UserTabBackScope> createState() => _UserTabBackScopeState();
}

class _UserTabBackScopeState extends State<UserTabBackScope> {
  late final AppBackHandler _handler = _onBack;

  bool _onBack() {
    if (widget.isHomeTab) return false;
    if (_hasStackedPagesAboveTab()) return false;
    context.go(widget.homeRoute ?? AppConstants.routeUserHome);
    return true;
  }

  bool _hasStackedPagesAboveTab() {
    return AppBackButtonScope.canNavigateBack(context);
  }

  @override
  void initState() {
    super.initState();
    AppBackButtonScope.addHandler(_handler);
  }

  @override
  void dispose() {
    AppBackButtonScope.removeHandler(_handler);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isHomeTab) return widget.child;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_onBack()) return;
        context.go(widget.homeRoute ?? AppConstants.routeUserHome);
      },
      child: widget.child,
    );
  }
}

/// Multi-step forms: system back moves to the previous step before leaving.
class StepBackScope extends StatefulWidget {
  const StepBackScope({
    super.key,
    required this.child,
    required this.step,
    required this.onPreviousStep,
  });

  final Widget child;
  final int step;
  final VoidCallback onPreviousStep;

  @override
  State<StepBackScope> createState() => _StepBackScopeState();
}

class _StepBackScopeState extends State<StepBackScope> {
  late final AppBackHandler _handler = _onBack;

  bool _onBack() {
    if (widget.step <= 0) return false;
    widget.onPreviousStep();
    return true;
  }

  @override
  void initState() {
    super.initState();
    AppBackButtonScope.addHandler(_handler);
  }

  @override
  void dispose() {
    AppBackButtonScope.removeHandler(_handler);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
