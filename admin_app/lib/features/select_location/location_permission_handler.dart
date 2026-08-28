import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/services/live_address_service.dart';
import '../../core/services/location_service.dart';

enum LocationPermissionUiState {
  granted,
  denied,
  unavailable,
}

class LocationPermissionHandler {
  LocationPermissionHandler._();

  static Future<LocationPermissionUiState> currentState() async {
    if (!await LocationService.isServiceEnabled()) {
      return LocationPermissionUiState.unavailable;
    }
    final permission = await LocationService.checkPermission();
    if (LocationService.permissionGranted(permission)) {
      return LocationPermissionUiState.granted;
    }
    return LocationPermissionUiState.denied;
  }

  static Future<CapturedLiveAddress?> capture(BuildContext context) {
    return LiveAddressService.capture(context);
  }

  static Future<bool> requestAccess(BuildContext context) {
    return LocationService.ensureReady(context);
  }

  static Future<LocationPermission> rawPermission() {
    return LocationService.checkPermission();
  }
}
