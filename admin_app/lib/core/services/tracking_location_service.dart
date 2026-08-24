import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../widgets/enable_location_services_dialog.dart';
import 'location_service.dart';

class TrackingPoint {
  const TrackingPoint({
    required this.latitude,
    required this.longitude,
    this.heading,
    this.speed,
    required this.timestamp,
  });

  final double latitude;
  final double longitude;
  final double? heading;
  final double? speed;
  final int timestamp;
}

/// Single GPS stream for home-visit trips. Prevents duplicate listeners.
class TrackingLocationService {
  TrackingLocationService._();

  static final TrackingLocationService instance = TrackingLocationService._();

  StreamSubscription<Position>? _subscription;
  String? _activeBookingId;
  bool _starting = false;

  bool get isTracking => _subscription != null && _activeBookingId != null;
  String? get activeBookingId => _activeBookingId;

  LocationSettings _settings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        intervalDuration: const Duration(seconds: 4),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Home visit trip in progress',
          notificationText:
              'Sharing your live location with this patient only. Tracking stops when you arrive or complete the visit.',
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.automotiveNavigation,
        distanceFilter: 0,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
    );
  }

  Future<bool> ensurePermissions(
    BuildContext context, {
    bool requestBackground = true,
  }) async {
    final ready = await LocationService.ensureReady(context);
    if (!ready) return false;

    if (!requestBackground) return true;
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return true;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.always) return true;

    if (!context.mounted) return true;
    final allowBackground = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keep sharing while you travel'),
        content: const Text(
          'To show the patient your live location if you lock the phone or switch apps, allow location access all the time. '
          'We only share it for this home visit and stop automatically when you arrive or complete the visit.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Foreground only'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Allow background'),
          ),
        ],
      ),
    );

    if (allowBackground == true) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever && context.mounted) {
        await EnableLocationServicesDialog.show(
          context,
          title: 'Background location',
          message:
              'Open settings and set location to “Allow all the time” so the patient can follow your trip if the app is in the background.',
        );
      }
    }
    return true;
  }

  void Function(TrackingPoint point)? _onLocation;
  void Function(String message)? _onError;

  Future<void> start({
    required String bookingId,
    required void Function(TrackingPoint point) onLocation,
    void Function(String message)? onError,
  }) async {
    _onLocation = onLocation;
    _onError = onError;
    if (_starting) return;
    if (_activeBookingId == bookingId && _subscription != null) return;

    _starting = true;
    try {
      await _subscription?.cancel();
      _subscription = null;
      _activeBookingId = null;
      if (!await Geolocator.isLocationServiceEnabled()) {
        _onError?.call('GPS is turned off. Enable location services to start the trip.');
        return;
      }
      final permission = await Geolocator.checkPermission();
      if (!LocationService.permissionGranted(permission)) {
        _onError?.call('Location permission denied. Allow location access to share your trip.');
        return;
      }

      _activeBookingId = bookingId;
      _subscription = Geolocator.getPositionStream(locationSettings: _settings()).listen(
        (position) {
          _onLocation?.call(_pointFrom(position));
        },
        onError: (Object error) {
          _onError?.call('Location stream interrupted. Trying to continue…');
        },
        cancelOnError: false,
      );
      try {
        final current = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        );
        _onLocation?.call(_pointFrom(current));
      } catch (_) {
        // Stream updates will follow.
      }
    } finally {
      _starting = false;
    }
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    _activeBookingId = null;
    _onLocation = null;
    _onError = null;
  }

  TrackingPoint _pointFrom(Position position) {
    return TrackingPoint(
      latitude: position.latitude,
      longitude: position.longitude,
      heading: position.heading.isNaN ? null : position.heading,
      speed: position.speed.isNaN || position.speed < 0 ? null : position.speed,
      timestamp: position.timestamp.millisecondsSinceEpoch,
    );
  }
}
