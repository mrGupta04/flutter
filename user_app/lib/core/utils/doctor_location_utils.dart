import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/doctor_model.dart';
import '../widgets/custom_widgets.dart';

/// Opens the doctor's clinic in Google Maps search (pin / place).
Future<void> openDoctorInGoogleMaps(
  BuildContext context,
  DoctorModel doctor,
) async {
  final uri = _doctorMapsSearchUri(doctor);
  if (uri == null) {
    if (context.mounted) {
      SnackBarHelper.showError(
        context,
        'Clinic location is not available for this doctor.',
      );
    }
    return;
  }
  await _launchMapsUri(uri);
}

/// Opens Google Maps turn-by-turn directions to the doctor's hospital/clinic.
/// Uses the user's live GPS as the starting point inside Google Maps.
Future<void> openDoctorDirectionsInGoogleMaps(
  BuildContext context,
  DoctorModel doctor,
) async {
  final uri = _doctorMapsDirectionsUri(doctor);
  if (uri == null) {
    if (context.mounted) {
      SnackBarHelper.showError(
        context,
        'Clinic location is not available for this doctor.',
      );
    }
    return;
  }
  await _launchMapsUri(uri);
}

bool doctorHasMapLocation(DoctorModel doctor) {
  if (doctor.latitude != null && doctor.longitude != null) {
    return true;
  }
  return formatDoctorClinicAddress(doctor).isNotEmpty;
}

bool doctorHasCoordinates(DoctorModel doctor) =>
    doctor.latitude != null && doctor.longitude != null;

String formatDoctorClinicAddress(DoctorModel doctor) {
  return [
    doctor.clinicName,
    doctor.address,
    doctor.city,
    doctor.state,
    doctor.pincode,
  ]
      .where((part) => part != null && part.toString().trim().isNotEmpty)
      .map((part) => part.toString().trim())
      .join(', ');
}

Uri? _doctorMapsSearchUri(DoctorModel doctor) {
  final lat = doctor.latitude;
  final lng = doctor.longitude;
  if (lat != null && lng != null) {
    return Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
  }
  final address = formatDoctorClinicAddress(doctor);
  if (address.isEmpty) return null;
  return Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
  );
}

Uri? _doctorMapsDirectionsUri(DoctorModel doctor) {
  final lat = doctor.latitude;
  final lng = doctor.longitude;
  if (lat != null && lng != null) {
    return Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=$lat,$lng'
      '&travelmode=driving',
    );
  }
  final address = formatDoctorClinicAddress(doctor);
  if (address.isEmpty) return null;
  return Uri.parse(
    'https://www.google.com/maps/dir/?api=1'
    '&destination=${Uri.encodeComponent(address)}'
    '&travelmode=driving',
  );
}

Future<void> _launchMapsUri(Uri uri) async {
  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched) {
    await launchUrl(uri, mode: LaunchMode.platformDefault);
  }
}
