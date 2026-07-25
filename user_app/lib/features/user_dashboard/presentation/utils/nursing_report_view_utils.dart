import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/utils/media_url_utils.dart';
import '../../../../data/repositories/patient_dashboard_repository.dart';

Future<void> openNursingReportPdf(
  BuildContext context, {
  required String bookingId,
  String? pdfUrl,
  PatientDashboardRepository? repository,
}) async {
  var resolved = MediaUrlUtils.resolve(pdfUrl);

  if (resolved.isEmpty && repository != null) {
    final freshUrl = await repository.fetchNursingReportPdfUrl(bookingId);
    resolved = MediaUrlUtils.resolve(freshUrl);
  }

  if (resolved.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nursing report PDF is not available yet.'),
        ),
      );
    }
    return;
  }

  final uri = Uri.parse(resolved);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the nursing report PDF.')),
      );
    }
  }
}

Future<void> shareNursingReportPdf({
  required String bookingId,
  String? pdfUrl,
  PatientDashboardRepository? repository,
}) async {
  var resolved = MediaUrlUtils.resolve(pdfUrl);
  if (resolved.isEmpty && repository != null) {
    final freshUrl = await repository.fetchNursingReportPdfUrl(bookingId);
    resolved = MediaUrlUtils.resolve(freshUrl);
  }
  if (resolved.isEmpty) return;
  await Share.share('Nursing visit report: $resolved');
}

Future<void> printNursingReportPdf({
  required String bookingId,
  String? pdfUrl,
  PatientDashboardRepository? repository,
}) async {
  var resolved = MediaUrlUtils.resolve(pdfUrl);
  if (resolved.isEmpty && repository != null) {
    final freshUrl = await repository.fetchNursingReportPdfUrl(bookingId);
    resolved = MediaUrlUtils.resolve(freshUrl);
  }
  if (resolved.isEmpty) return;
  final uri = Uri.parse(resolved);
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
