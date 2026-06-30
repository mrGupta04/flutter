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

/// Doctors with map coordinates first, sorted nearest to farthest.
List<DoctorModel> sortDoctorsByDistance(
  List<DoctorModel> doctors,
  double userLatitude,
  double userLongitude,
) {
  final ranked = doctors
      .map(
        (doctor) => (
          doctor: doctor,
          distance: doctorDistanceKm(doctor, userLatitude, userLongitude),
        ),
      )
      .toList(growable: false);

  ranked.sort((a, b) {
    final distA = a.distance;
    final distB = b.distance;
    if (distA == null && distB == null) return 0;
    if (distA == null) return 1;
    if (distB == null) return -1;
    return distA.compareTo(distB);
  });

  return ranked.map((entry) => entry.doctor).toList(growable: false);
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

/// Nurses with map coordinates first, sorted nearest to farthest.
List<NurseModel> sortNursesByDistance(
  List<NurseModel> nurses,
  double userLatitude,
  double userLongitude,
) {
  final ranked = nurses
      .map(
        (nurse) => (
          nurse: nurse,
          distance: nurseDistanceKm(nurse, userLatitude, userLongitude),
        ),
      )
      .toList(growable: false);

  ranked.sort((a, b) {
    final distA = a.distance;
    final distB = b.distance;
    if (distA == null && distB == null) return 0;
    if (distA == null) return 1;
    if (distB == null) return -1;
    return distA.compareTo(distB);
  });

  return ranked.map((entry) => entry.nurse).toList(growable: false);
}

String? formatNearbyDistanceLabel(double? distanceKm) {
  if (distanceKm == null) return null;
  if (distanceKm < 1) return 'Less than 1 km away';
  return '${distanceKm.toStringAsFixed(distanceKm < 10 ? 1 : 0)} km away';
}
