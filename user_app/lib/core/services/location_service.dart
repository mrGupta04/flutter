import 'package:geolocator/geolocator.dart';

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
