import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/utils/media_url_utils.dart';
import '../../../../data/repositories/patient_dashboard_repository.dart';

Future<void> openPatientPrescriptionPdf(
  BuildContext context, {
  required String bookingId,
  String? prescriptionPdfUrl,
  PatientDashboardRepository? repository,
}) async {
  var resolved = MediaUrlUtils.resolvePrescriptionPdf(prescriptionPdfUrl);

  if (resolved.isEmpty && repository != null) {
    final freshUrl = await repository.fetchPrescriptionPdfUrl(bookingId);
    resolved = MediaUrlUtils.resolvePrescriptionPdf(freshUrl);
  }

  if (resolved.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prescription file is not available yet.'),
        ),
      );
    }
    return;
  }

  final uri = Uri.parse(resolved);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open the prescription PDF.'),
        ),
      );
    }
  }
}
