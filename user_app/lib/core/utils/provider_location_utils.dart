import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/nurse_model.dart';

/// Opens a nurse's base location in Google Maps.
Future<void> openNurseInGoogleMaps(
  BuildContext context,
  NurseModel nurse,
) async {
  final lat = nurse.latitude;
  final lng = nurse.longitude;

  Uri? uri;
  if (lat != null && lng != null) {
    uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
  } else {
    final address = _formatNurseAddress(nurse);
    if (address.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location is not available for this nurse.'),
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

bool nurseHasMapLocation(NurseModel nurse) {
  if (nurse.latitude != null && nurse.longitude != null) return true;
  return _formatNurseAddress(nurse).isNotEmpty;
}

String _formatNurseAddress(NurseModel nurse) {
  return [
    nurse.address,
    nurse.city,
    nurse.state,
    nurse.pincode,
  ]
      .where((part) => part != null && part.toString().trim().isNotEmpty)
      .map((part) => part.toString().trim())
      .join(', ');
}
