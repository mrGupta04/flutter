import 'dart:math' as math;

class TrackingRouteEstimate {
  const TrackingRouteEstimate({
    required this.distanceText,
    required this.etaMinutes,
    required this.durationText,
    required this.polyline,
  });

  final String distanceText;
  final int etaMinutes;
  final String durationText;
  final List<({double latitude, double longitude})> polyline;
}

/// Straight-line ETA used when Google Directions is unavailable.
class TrackingGeo {
  TrackingGeo._();

  static const urbanKmh = 25.0;

  static DateTime? parseTimestamp(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    if (raw is num) {
      final n = raw.toInt();
      if (n <= 0) return null;
      return DateTime.fromMillisecondsSinceEpoch(
        n < 100000000000 ? n * 1000 : n,
      );
    }
    final text = raw.toString().trim();
    if (text.isEmpty) return null;
    final asInt = int.tryParse(text);
    if (asInt != null) return parseTimestamp(asInt);
    return DateTime.tryParse(text);
  }

  static double haversineMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const r = 6371000.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.pow(math.sin(dLon / 2), 2);
    return 2 * r * math.asin(math.sqrt(a.clamp(0, 1)));
  }

  static TrackingRouteEstimate estimate({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) {
    final meters = haversineMeters(fromLat, fromLng, toLat, toLng);
    final km = (meters / 1000 * 10).round() / 10;
    final minutes = (km / urbanKmh * 60).round().clamp(1, 24 * 60);
    return TrackingRouteEstimate(
      distanceText: km < 1 ? '${meters.round()} m' : '$km km',
      etaMinutes: minutes,
      durationText: minutes == 1 ? '1 min' : '$minutes min',
      polyline: [
        (latitude: fromLat, longitude: fromLng),
        (latitude: toLat, longitude: toLng),
      ],
    );
  }

  static double _toRad(double deg) => deg * math.pi / 180;
}
