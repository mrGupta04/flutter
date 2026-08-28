import 'package:flutter/material.dart';

import 'geocoding_service.dart';
import 'location_service.dart';

class CapturedLiveAddress {
  const CapturedLiveAddress({
    required this.latitude,
    required this.longitude,
    this.resolved,
  });

  final double latitude;
  final double longitude;
  final ResolvedAddress? resolved;

  bool get hasAddress =>
      resolved != null && resolved!.address.trim().isNotEmpty;
}

class LiveAddressService {
  LiveAddressService._();

  static Future<CapturedLiveAddress?> capture(
    BuildContext context, {
    bool promptIfNeeded = true,
  }) async {
    late final ({double latitude, double longitude}) position;
    if (promptIfNeeded) {
      final prompted =
          await LocationService.getCurrentPositionWithPrompt(context);
      if (prompted == null) return null;
      position = prompted;
    } else {
      if (!await LocationService.isServiceEnabled()) return null;
      final permission = await LocationService.checkPermission();
      if (!LocationService.permissionGranted(permission)) return null;
      position = await LocationService.getCurrentPosition(
        requestPermissionIfNeeded: false,
      );
    }

    ResolvedAddress? resolved;
    try {
      resolved = await GeocodingService.reverseGeocode(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } on GeocodingFailure {
      resolved = null;
    }

    return CapturedLiveAddress(
      latitude: position.latitude,
      longitude: position.longitude,
      resolved: resolved,
    );
  }
}
