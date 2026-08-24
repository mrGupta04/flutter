import 'tracking_geo.dart';

class TrackingSnapshot {
  const TrackingSnapshot({
    required this.bookingId,
    required this.trackingStatus,
    this.visitProgress,
    this.bookingStatus,
    this.providerType,
    this.providerId,
    this.providerName,
    this.providerMobile,
    this.patientName,
    this.patientAddress,
    this.patientCity,
    this.patientLatitude,
    this.patientLongitude,
    this.currentLatitude,
    this.currentLongitude,
    this.heading,
    this.speed,
    this.lastUpdatedAt,
    this.distanceText,
    this.etaMinutes,
    this.durationText,
    this.polyline = const [],
    this.isTracking = false,
    this.routeWarning,
  });

  final String bookingId;
  final String trackingStatus;
  final String? visitProgress;
  final String? bookingStatus;
  final String? providerType;
  final String? providerId;
  final String? providerName;
  final String? providerMobile;
  final String? patientName;
  final String? patientAddress;
  final String? patientCity;
  final double? patientLatitude;
  final double? patientLongitude;
  final double? currentLatitude;
  final double? currentLongitude;
  final double? heading;
  final double? speed;
  final DateTime? lastUpdatedAt;
  final String? distanceText;
  final int? etaMinutes;
  final String? durationText;
  final List<({double latitude, double longitude})> polyline;
  final bool isTracking;
  final String? routeWarning;

  bool get isOnTheWay => trackingStatus == 'on_the_way';
  bool get isTerminal =>
      trackingStatus == 'arrived' ||
      trackingStatus == 'in_service' ||
      trackingStatus == 'completed' ||
      trackingStatus == 'cancelled';

  factory TrackingSnapshot.fromJson(Map<String, dynamic> json) {
    final rawLine = json['polyline'] as List<dynamic>? ?? const [];
    return TrackingSnapshot(
      bookingId: json['bookingId']?.toString() ?? '',
      trackingStatus: json['trackingStatus']?.toString() ?? 'idle',
      visitProgress: json['visitProgress']?.toString(),
      bookingStatus: json['bookingStatus']?.toString(),
      providerType: json['providerType']?.toString(),
      providerId: json['providerId']?.toString(),
      providerName: json['providerName']?.toString(),
      providerMobile: json['providerMobile']?.toString(),
      patientName: json['patientName']?.toString(),
      patientAddress: json['patientAddress']?.toString(),
      patientCity: json['patientCity']?.toString(),
      patientLatitude: (json['patientLatitude'] as num?)?.toDouble(),
      patientLongitude: (json['patientLongitude'] as num?)?.toDouble(),
      currentLatitude: (json['currentLatitude'] as num?)?.toDouble(),
      currentLongitude: (json['currentLongitude'] as num?)?.toDouble(),
      heading: (json['heading'] as num?)?.toDouble(),
      speed: (json['speed'] as num?)?.toDouble(),
      lastUpdatedAt: TrackingGeo.parseTimestamp(json['lastUpdatedAt']),
      distanceText: json['distanceText']?.toString(),
      etaMinutes: (json['etaMinutes'] as num?)?.toInt(),
      durationText: json['durationText']?.toString(),
      polyline: rawLine
          .whereType<Map>()
          .map((e) {
            final lat = (e['latitude'] as num?)?.toDouble();
            final lng = (e['longitude'] as num?)?.toDouble();
            if (lat == null || lng == null) return null;
            return (latitude: lat, longitude: lng);
          })
          .whereType<({double latitude, double longitude})>()
          .toList(),
      isTracking: json['isTracking'] as bool? ?? false,
      routeWarning: json['routeWarning']?.toString() ?? json['warning']?.toString(),
    );
  }

  TrackingSnapshot copyWith({
    double? currentLatitude,
    double? currentLongitude,
    double? heading,
    double? speed,
    DateTime? lastUpdatedAt,
    String? distanceText,
    int? etaMinutes,
    String? durationText,
    List<({double latitude, double longitude})>? polyline,
    String? trackingStatus,
    bool? isTracking,
  }) {
    return TrackingSnapshot(
      bookingId: bookingId,
      trackingStatus: trackingStatus ?? this.trackingStatus,
      visitProgress: visitProgress,
      bookingStatus: bookingStatus,
      providerType: providerType,
      providerId: providerId,
      providerName: providerName,
      providerMobile: providerMobile,
      patientName: patientName,
      patientAddress: patientAddress,
      patientCity: patientCity,
      patientLatitude: patientLatitude,
      patientLongitude: patientLongitude,
      currentLatitude: currentLatitude ?? this.currentLatitude,
      currentLongitude: currentLongitude ?? this.currentLongitude,
      heading: heading ?? this.heading,
      speed: speed ?? this.speed,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      distanceText: distanceText ?? this.distanceText,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      durationText: durationText ?? this.durationText,
      polyline: polyline ?? this.polyline,
      isTracking: isTracking ?? this.isTracking,
      routeWarning: routeWarning,
    );
  }

  TrackingSnapshot withClientRouteFallback() {
    if (etaMinutes != null &&
        distanceText != null &&
        distanceText!.isNotEmpty &&
        polyline.length >= 2) {
      return this;
    }
    final fromLat = currentLatitude;
    final fromLng = currentLongitude;
    final toLat = patientLatitude;
    final toLng = patientLongitude;
    if (fromLat == null || fromLng == null || toLat == null || toLng == null) {
      return this;
    }
    final estimate = TrackingGeo.estimate(
      fromLat: fromLat,
      fromLng: fromLng,
      toLat: toLat,
      toLng: toLng,
    );
    return copyWith(
      distanceText: (distanceText != null && distanceText!.isNotEmpty)
          ? distanceText
          : estimate.distanceText,
      etaMinutes: etaMinutes ?? estimate.etaMinutes,
      durationText: (durationText != null && durationText!.isNotEmpty)
          ? durationText
          : estimate.durationText,
      polyline: polyline.length >= 2 ? polyline : estimate.polyline,
    );
  }
}

class ProviderLocationUpdate {
  const ProviderLocationUpdate({
    required this.bookingId,
    required this.latitude,
    required this.longitude,
    this.heading,
    this.speed,
    required this.timestamp,
  });

  final String bookingId;
  final double latitude;
  final double longitude;
  final double? heading;
  final double? speed;
  final int timestamp;

  factory ProviderLocationUpdate.fromJson(Map<String, dynamic> json) {
    return ProviderLocationUpdate(
      bookingId: json['bookingId']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      heading: (json['heading'] as num?)?.toDouble(),
      speed: (json['speed'] as num?)?.toDouble(),
      timestamp: (json['timestamp'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch,
    );
  }
}
