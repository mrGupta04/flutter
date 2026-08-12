import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Prevents double-taps from stacking the same destination multiple times.
class SafeNavigation {
  SafeNavigation._();

  static bool _locked = false;

  static bool get isLocked => _locked;

  static Future<T?> push<T extends Object?>(
    BuildContext context,
    String location, {
    Object? extra,
  }) async {
    if (_locked) return null;
    _locked = true;
    try {
      return await context.push<T>(location, extra: extra);
    } finally {
      _locked = false;
    }
  }
}
