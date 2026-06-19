import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_constants.dart';
import '../services/token_storage.dart';

/// Returns true if the patient is logged in; otherwise prompts login/register.
Future<bool> ensureUserLoggedIn(
  BuildContext context, {
  String? message,
}) async {
  final loggedIn = await TokenStorage.instance.isPatientLoggedIn();
  if (loggedIn) return true;

  if (!context.mounted) return false;

  final action = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Login required'),
      content: Text(
        message ??
            'Please log in or create an account before booking an appointment.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, 'cancel'),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, 'register'),
          child: const Text('Register'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, 'login'),
          child: const Text('Login'),
        ),
      ],
    ),
  );

  if (!context.mounted || action == null || action == 'cancel') {
    return false;
  }

  final redirect = GoRouterState.of(context).uri.toString();

  if (action == 'register') {
    await context.push(
      '${AppConstants.routeUserRegister}?redirect=${Uri.encodeComponent(redirect)}',
    );
  } else if (action == 'login') {
    await context.push(
      '${AppConstants.routeUserLogin}?redirect=${Uri.encodeComponent(redirect)}',
    );
  }

  return TokenStorage.instance.isPatientLoggedIn();
}
