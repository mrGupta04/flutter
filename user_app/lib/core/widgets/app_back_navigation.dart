import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_constants.dart';

/// Bottom-nav tab roots that should return to Home instead of exiting the app.
bool _isNonHomeTabRoot(String path) {
  return path == AppConstants.routeLabs ||
      path == AppConstants.routeCareListing ||
      path == AppConstants.routeUserDashboard ||
      path == AppConstants.routeUserDashboardLegacy ||
      path == AppConstants.routeUserLogin ||
      path == AppConstants.routeScans;
}

/// Intercepts the Android system back button so nested [Navigator.push] routes
/// and [GoRouter] stacks pop correctly instead of closing the app.
class AppBackButtonScope extends StatelessWidget {
  const AppBackButtonScope({
    super.key,
    required this.child,
    this.router,
  });

  final Widget child;

  /// Optional when this scope sits above [GoRouter] (e.g. [MaterialApp.builder]).
  final GoRouter? router;

  static bool canNavigateBack(
    BuildContext context, {
    GoRouter? router,
  }) {
    if (router != null && router.canPop()) return true;
    final goRouter = GoRouter.maybeOf(context);
    if (goRouter != null && goRouter.canPop()) return true;
    return Navigator.of(context).canPop();
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
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  static bool goHomeIfOnTabRoot(
    BuildContext context, {
    GoRouter? router,
  }) {
    final goRouter = router ?? GoRouter.maybeOf(context);
    if (goRouter == null) return false;
    final path = goRouter.state.uri.path;
    if (path == AppConstants.routeUserHome) return false;
    if (!_isNonHomeTabRoot(path)) return false;
    goRouter.go(AppConstants.routeUserHome);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (canNavigateBack(context, router: router)) {
          navigateBack(context, router: router);
          return;
        }
        // Care / Profile / Labs tab roots use go() so the stack is empty —
        // send users Home instead of killing the app.
        if (goHomeIfOnTabRoot(context, router: router)) return;
        SystemNavigator.pop();
      },
      child: child,
    );
  }
}

/// For bottom-nav tab roots: back goes to home instead of exiting the app.
class UserTabBackScope extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (AppBackButtonScope.canNavigateBack(context)) {
          AppBackButtonScope.navigateBack(context);
          return;
        }
        if (!isHomeTab) {
          context.go(homeRoute ?? AppConstants.routeUserHome);
          return;
        }
        SystemNavigator.pop();
      },
      child: child,
    );
  }
}

/// Multi-step forms: system back moves to the previous step before leaving.
class StepBackScope extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (step > 0) {
          onPreviousStep();
          return;
        }
        if (AppBackButtonScope.canNavigateBack(context)) {
          AppBackButtonScope.navigateBack(context);
          return;
        }
        Navigator.of(context).maybePop();
      },
      child: child,
    );
  }
}
