import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Intercepts the Android system back button so nested [Navigator.push] routes
/// and [GoRouter] stacks pop correctly instead of closing the app.
class AppBackButtonScope extends StatelessWidget {
  const AppBackButtonScope({super.key, required this.child});

  final Widget child;

  static bool canNavigateBack(BuildContext context) {
    if (GoRouter.of(context).canPop()) return true;
    return Navigator.of(context).canPop();
  }

  static void navigateBack(BuildContext context) {
    if (GoRouter.of(context).canPop()) {
      context.pop();
      return;
    }
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackButtonListener(
      onBackButtonPressed: () async {
        if (canNavigateBack(context)) {
          navigateBack(context);
          return true;
        }
        return false;
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
