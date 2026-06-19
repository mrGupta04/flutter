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

  static Future<({double latitude, double longitude})> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationFailure(
        'Location services are turned off. Enable GPS or location in system settings.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

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
}
