import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_constants.dart';

typedef AppBackHandler = bool Function();

/// Intercepts the Android system back button so nested routes, console screens,
/// and multi-step forms go to the previous step/page instead of closing the app.
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

  /// Screens can consume system back (tabs, drill-downs, wizard steps) first.
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
    Route<dynamic>? top;
    nav.popUntil((route) {
      top = route;
      return true;
    });
    if (top is PopupRoute) {
      nav.pop();
      return true;
    }
    return false;
  }

  static bool canNavigateBack(
    BuildContext context, {
    GoRouter? router,
  }) {
    if (router != null && router.canPop()) return true;
    final goRouter = GoRouter.maybeOf(context);
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

  /// When the stack is empty (typical after [GoRouter.go]), return to the
  /// parent workspace instead of killing the process.
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
    if (path == AppConstants.routeProviderLanding) return null;

    if (path == AppConstants.routeAdminDashboard ||
        path == AppConstants.routeApprovalManagement ||
        path == AppConstants.routeAdminLogin) {
      return AppConstants.routeProviderLanding;
    }

    if (path.startsWith('/admin-')) {
      if (path.startsWith(AppConstants.routeAdminDoctorDetails)) {
        return AppConstants.routeAdminDoctorList;
      }
      if (path.startsWith(AppConstants.routeAdminNurseDetails)) {
        return AppConstants.routeAdminNurseList;
      }
      if (path.startsWith(AppConstants.routeAdminAmbulanceDetails)) {
        return AppConstants.routeAdminAmbulanceList;
      }
      if (path.startsWith(AppConstants.routeAdminBloodBankDetails)) {
        return AppConstants.routeAdminBloodBankList;
      }
      if (path.startsWith(AppConstants.routeAdminLabDetails)) {
        return AppConstants.routeAdminLabList;
      }
      if (path.startsWith(AppConstants.routeAdminScanDetails)) {
        return AppConstants.routeAdminScanList;
      }
      if (path.startsWith(AppConstants.routeAdminDoctorSessionDetails)) {
        return AppConstants.routeAdminDoctorSessions;
      }
      if (path.startsWith(AppConstants.routeAdminDiagnosticSessionDetails)) {
        return AppConstants.routeAdminDiagnosticSessions;
      }
      if (path.startsWith(AppConstants.routeAdminPatientDetails)) {
        return AppConstants.routeAdminPatients;
      }
      if (path.startsWith(AppConstants.routeAdminBookings)) {
        return AppConstants.routeAdminOverview;
      }
      return AppConstants.routeAdminDashboard;
    }

    if (path.startsWith(AppConstants.routeLabPrescriptionInbox) ||
        path.startsWith(AppConstants.routeLabPrescriptionDetail)) {
      return AppConstants.routeLabDashboard;
    }
    if (path.startsWith(AppConstants.routeNurseVisitAssessment) ||
        path.startsWith(AppConstants.routeNurseVisitOtp) ||
        path.startsWith(AppConstants.routeProviderHomeVisitTrip)) {
      return AppConstants.routeNurseDashboard;
    }
    if (path.startsWith(AppConstants.routeProviderEarnings) ||
        path.startsWith(AppConstants.routeProviderNotifications) ||
        path.startsWith(AppConstants.routeProviderBookingChat) ||
        path.startsWith(AppConstants.routeProviderProfile) ||
        path.startsWith(AppConstants.routeVideoConsult)) {
      return AppConstants.routeProviderLanding;
    }

    return AppConstants.routeProviderLanding;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_popDialogIfPresent(context, router: router)) return;
        if (_runHandlers()) return;
        if (canNavigateBack(context, router: router)) {
          navigateBack(context, router: router);
          return;
        }
        if (goToPreviousPage(context, router: router)) return;
        SystemNavigator.pop();
      },
      child: child,
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
