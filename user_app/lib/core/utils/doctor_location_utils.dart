import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/doctor_model.dart';

/// Opens the doctor's clinic location in Google Maps (app or browser).
Future<void> openDoctorInGoogleMaps(
  BuildContext context,
  DoctorModel doctor,
) async {
  final lat = doctor.latitude;
  final lng = doctor.longitude;

  Uri? uri;
  if (lat != null && lng != null) {
    uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
  } else {
    final address = _formatAddress(doctor);
    if (address.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Clinic location is not available for this doctor.'),
          ),
        );
      }
      return;
    }
    uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
    );
  }

  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched && context.mounted) {
    await launchUrl(uri, mode: LaunchMode.platformDefault);
  }
}

bool doctorHasMapLocation(DoctorModel doctor) {
  if (doctor.latitude != null && doctor.longitude != null) {
    return true;
  }
  return _formatAddress(doctor).isNotEmpty;
}

String _formatAddress(DoctorModel doctor) {
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
