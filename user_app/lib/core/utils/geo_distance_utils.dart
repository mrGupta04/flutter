import 'dart:math' as math;

import '../../data/models/doctor_model.dart';
import '../../data/models/nurse_model.dart';

/// Haversine distance in kilometres between two WGS84 points.
double distanceKm(double lat1, double lon1, double lat2, double lon2) {
  const earthRadiusKm = 6371.0;
  final dLat = _toRadians(lat2 - lat1);
  final dLon = _toRadians(lon2 - lon1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRadians(lat1)) *
          math.cos(_toRadians(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadiusKm * c;
}

double _toRadians(double degrees) => degrees * math.pi / 180;

/// Closer first; missing distance last. Equal distance uses higher rating.
int compareNearbyThenRating({
  required double? distanceA,
  required double? distanceB,
  required double ratingA,
  required double ratingB,
}) {
  if (distanceA == null && distanceB == null) {
    return ratingB.compareTo(ratingA);
  }
  if (distanceA == null) return 1;
  if (distanceB == null) return -1;
  final distCmp = distanceA.compareTo(distanceB);
  if (distCmp != 0) return distCmp;
  return ratingB.compareTo(ratingA);
}

/// Distance from the user to a doctor's clinic/base, if coordinates exist.
double? doctorDistanceKm(
  DoctorModel doctor,
  double userLatitude,
  double userLongitude,
) {
  final lat = doctor.latitude;
  final lng = doctor.longitude;
  if (lat == null || lng == null) return null;
  return distanceKm(userLatitude, userLongitude, lat, lng);
}

/// Nearest doctors first, then higher rated. Falls back to rating only.
List<DoctorModel> sortDoctorsByProximityAndRating(
  List<DoctorModel> doctors, {
  double? userLatitude,
  double? userLongitude,
}) {
  final hasUser = userLatitude != null && userLongitude != null;
  final ranked = doctors
      .map(
        (doctor) => (
          doctor: doctor,
          distance: hasUser
              ? doctorDistanceKm(doctor, userLatitude, userLongitude)
              : null,
          rating: doctor.averageRating ?? 0,
        ),
      )
      .toList(growable: false);

  ranked.sort((a, b) {
    if (!hasUser) return b.rating.compareTo(a.rating);
    return compareNearbyThenRating(
      distanceA: a.distance,
      distanceB: b.distance,
      ratingA: a.rating,
      ratingB: b.rating,
    );
  });

  return ranked.map((entry) => entry.doctor).toList(growable: false);
}

/// Doctors with map coordinates first, sorted nearest to farthest.
List<DoctorModel> sortDoctorsByDistance(
  List<DoctorModel> doctors,
  double userLatitude,
  double userLongitude,
) {
  return sortDoctorsByProximityAndRating(
    doctors,
    userLatitude: userLatitude,
    userLongitude: userLongitude,
  );
}

/// Distance from the user to a nurse's base location, if coordinates exist.
double? nurseDistanceKm(
  NurseModel nurse,
  double userLatitude,
  double userLongitude,
) {
  final lat = nurse.latitude;
  final lng = nurse.longitude;
  if (lat == null || lng == null) return null;
  return distanceKm(userLatitude, userLongitude, lat, lng);
}

/// Nearest nurses first, then higher rated. Falls back to rating only.
List<NurseModel> sortNursesByProximityAndRating(
  List<NurseModel> nurses, {
  double? userLatitude,
  double? userLongitude,
}) {
  final hasUser = userLatitude != null && userLongitude != null;
  final ranked = nurses
      .map(
        (nurse) => (
          nurse: nurse,
          distance: hasUser
              ? nurseDistanceKm(nurse, userLatitude, userLongitude)
              : null,
          rating: nurse.averageRating ?? 0,
        ),
      )
      .toList(growable: false);

  ranked.sort((a, b) {
    if (!hasUser) return b.rating.compareTo(a.rating);
    return compareNearbyThenRating(
      distanceA: a.distance,
      distanceB: b.distance,
      ratingA: a.rating,
      ratingB: b.rating,
    );
  });

  return ranked.map((entry) => entry.nurse).toList(growable: false);
}

/// Nurses with map coordinates first, sorted nearest to farthest.
List<NurseModel> sortNursesByDistance(
  List<NurseModel> nurses,
  double userLatitude,
  double userLongitude,
) {
  return sortNursesByProximityAndRating(
    nurses,
    userLatitude: userLatitude,
    userLongitude: userLongitude,
  );
}

String? formatNearbyDistanceLabel(double? distanceKm) {
  if (distanceKm == null) return null;
  if (distanceKm < 1) return 'Less than 1 km away';
  return '${distanceKm.toStringAsFixed(distanceKm < 10 ? 1 : 0)} km away';
}
