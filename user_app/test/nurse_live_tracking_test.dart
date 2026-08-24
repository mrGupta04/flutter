import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/features/home_visit_tracking/data/tracking_geo.dart';
import 'package:user_app/features/home_visit_tracking/data/tracking_models.dart';

void main() {
  test('client fallback fills ETA when server omits the route', () {
    final snapshot = TrackingSnapshot(
      bookingId: 'b1',
      trackingStatus: 'on_the_way',
      patientLatitude: 28.6139,
      patientLongitude: 77.2090,
      currentLatitude: 28.7041,
      currentLongitude: 77.1025,
    ).withClientRouteFallback();

    expect(snapshot.etaMinutes, isNotNull);
    expect(snapshot.etaMinutes! >= 1, isTrue);
    expect(snapshot.distanceText, isNotEmpty);
    expect(snapshot.polyline.length, 2);
  });

  test('poll snapshot keeps previously computed route', () {
    final withRoute = TrackingSnapshot(
      bookingId: 'b1',
      trackingStatus: 'on_the_way',
      patientLatitude: 28.61,
      patientLongitude: 77.20,
      currentLatitude: 28.70,
      currentLongitude: 77.10,
      distanceText: '12 km',
      etaMinutes: 28,
      polyline: const [
        (latitude: 28.70, longitude: 77.10),
        (latitude: 28.61, longitude: 77.20),
      ],
    );
    final poll = TrackingSnapshot(
      bookingId: 'b1',
      trackingStatus: 'on_the_way',
      patientLatitude: 28.61,
      patientLongitude: 77.20,
      currentLatitude: 28.71,
      currentLongitude: 77.11,
    );

    final merged = poll.mergePreservingRoute(withRoute);
    expect(merged.distanceText, '12 km');
    expect(merged.etaMinutes, 28);
    expect(merged.currentLatitude, 28.71);
    expect(merged.polyline.length, 2);
  });

  test('parseTimestamp accepts unix milliseconds', () {
    final at = TrackingGeo.parseTimestamp(1710000000000);
    expect(at, isNotNull);
    expect(at!.year, greaterThan(2015));
  });
}
