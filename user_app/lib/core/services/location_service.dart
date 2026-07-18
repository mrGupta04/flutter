import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../widgets/enable_location_services_dialog.dart';

/// Thrown when the device cannot provide a current position.
class LocationFailure implements Exception {
  LocationFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Reads GPS / network location with permission handling.
class LocationService {
  LocationService._();

  static Future<bool> isServiceEnabled() =>
      Geolocator.isLocationServiceEnabled();

  static Future<LocationPermission> checkPermission() =>
      Geolocator.checkPermission();

  static Future<LocationPermission> requestPermission() =>
      Geolocator.requestPermission();

  static Future<void> openLocationSettings() =>
      Geolocator.openLocationSettings();

  static Future<void> openAppSettings() => Geolocator.openAppSettings();

  static bool permissionGranted(LocationPermission permission) =>
      permission == LocationPermission.always ||
      permission == LocationPermission.whileInUse;

  /// Ensures location services are on and permission is granted.
  /// Requests permission when currently denied and [requestIfDenied] is true.
  static Future<LocationPermission> ensurePermission({
    bool requestIfDenied = true,
  }) async {
    if (!await isServiceEnabled()) {
      throw LocationFailure(
        'Location services are turned off. Enable GPS or location in system settings.',
      );
    }

    var permission = await checkPermission();
    if (permission == LocationPermission.denied && requestIfDenied) {
      permission = await requestPermission();
    }
    return permission;
  }

  /// Shows the Enable Location Services dialog when GPS is off, opens settings
  /// on Turn On, then requests runtime permission if needed.
  ///
  /// Returns `true` when the app can read the device location.
  static Future<bool> ensureReady(BuildContext context) async {
    if (!await isServiceEnabled()) {
      if (!context.mounted) return false;
      final turnOn = await EnableLocationServicesDialog.show(context);
      if (!turnOn) return false;
      await openLocationSettings();
      if (!await isServiceEnabled()) {
        return false;
      }
    }

    var permission = await checkPermission();
    if (permissionGranted(permission)) return true;

    if (permission == LocationPermission.deniedForever) {
      if (!context.mounted) return false;
      final turnOn = await EnableLocationServicesDialog.show(
        context,
        title: 'Enable Location Services',
        message:
            "This app requires location access to function properly. Please enable location permission by clicking the 'Turn On' button below.",
      );
      if (!turnOn) return false;
      await openAppSettings();
      permission = await checkPermission();
      return permissionGranted(permission);
    }

    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
      if (permissionGranted(permission)) return true;

      if (permission == LocationPermission.deniedForever && context.mounted) {
        final turnOn = await EnableLocationServicesDialog.show(
          context,
          title: 'Enable Location Services',
          message:
              "This app requires location access to function properly. Please enable location permission by clicking the 'Turn On' button below.",
        );
        if (turnOn) {
          await openAppSettings();
          permission = await checkPermission();
          return permissionGranted(permission);
        }
      }
      return false;
    }

    return permissionGranted(permission);
  }

  /// Ensures location is ready (with dialog if needed), then reads GPS.
  /// Returns `null` if the user cancels or location stays unavailable.
  static Future<({double latitude, double longitude})?>
      getCurrentPositionWithPrompt(BuildContext context) async {
    final ready = await ensureReady(context);
    if (!ready || !context.mounted) return null;
    try {
      return await getCurrentPosition(requestPermissionIfNeeded: false);
    } on LocationFailure {
      return null;
    }
  }

  static Future<({double latitude, double longitude})> getCurrentPosition({
    bool requestPermissionIfNeeded = true,
  }) async {
    final permission = await ensurePermission(
      requestIfDenied: requestPermissionIfNeeded,
    );
    _throwIfPermissionBlocked(permission);

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      return (latitude: position.latitude, longitude: position.longitude);
    } on LocationServiceDisabledException {
      throw LocationFailure(
        'Location services are disabled. Turn them on and try again.',
      );
    } on PermissionDeniedException {
      throw LocationFailure(
        'Location permission denied. Allow access and try again.',
      );
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('timeout') || msg.contains('time limit')) {
        throw LocationFailure(
          'Could not get your location in time. Move to an open area or try again.',
        );
      }
      throw LocationFailure(
        'Unable to read current location. Check permissions and try again.',
      );
    }
  }

  static void _throwIfPermissionBlocked(LocationPermission permission) {
    if (permission == LocationPermission.denied) {
      throw LocationFailure(
        'Location permission denied. Allow location access when prompted, then try again.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw LocationFailure(
        'Location permission blocked. Enable it in browser or app settings.',
      );
    }
  }
}
