import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/custom_widgets.dart';
import '../../data/models/previous_report_model.dart';

const int maxPreviousReportsPerBooking = 5;

class PreviousReportsPicker extends StatelessWidget {
  const PreviousReportsPicker({
    super.key,
    required this.reports,
    required this.onChanged,
    this.enabled = true,
  });

  final List<PendingPreviousReport> reports;
  final ValueChanged<List<PendingPreviousReport>> onChanged;
  final bool enabled;

  Future<void> _pickFiles(BuildContext context) async {
    if (!enabled) return;
    if (reports.length >= maxPreviousReportsPerBooking) {
      SnackBarHelper.showError(
        context,
        'You can attach up to $maxPreviousReportsPerBooking reports.',
      );
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
      allowMultiple: true,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final updated = List<PendingPreviousReport>.from(reports);
    for (final file in result.files) {
      if (updated.length >= maxPreviousReportsPerBooking) break;
      if (file.size > AppConstants.maxFileSize) {
        if (context.mounted) {
          SnackBarHelper.showError(
            context,
            '${file.name} exceeds ${AppConstants.maxFileSize ~/ (1024 * 1024)} MB.',
          );
        }
        continue;
      }
      final bytes = file.bytes;
      if (bytes == null) {
        if (context.mounted) {
          SnackBarHelper.showError(
            context,
            'Could not read ${file.name}. Try again.',
          );
        }
        continue;
      }
      updated.add(
        PendingPreviousReport(
          bytes: bytes,
          fileName: file.name,
          mimeType: file.extension != null ? _mimeForExt(file.extension!) : null,
        ),
      );
    }

    onChanged(updated);
  }

  String? _mimeForExt(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Previous reports (optional)',
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              '${reports.length}/$maxPreviousReportsPerBooking',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Upload lab reports, prescriptions, or scan results so your doctor can review them before the consult.',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        if (reports.isNotEmpty) ...[
          ...reports.asMap().entries.map((entry) {
            final index = entry.key;
            final report = entry.value;
            final isPdf = report.fileName.toLowerCase().endsWith('.pdf');
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  Icon(
                    isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      report.fileName,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove',
                    onPressed: enabled
                        ? () {
                            final updated =
                                List<PendingPreviousReport>.from(reports)
                                  ..removeAt(index);
                            onChanged(updated);
                          }
                        : null,
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 4),
        ],
        OutlinedButton.icon(
          onPressed: enabled ? () => _pickFiles(context) : null,
          icon: const Icon(Icons.upload_file_rounded),
          label: Text(
            reports.isEmpty ? 'Attach reports' : 'Add more reports',
          ),
        ),
      ],
    );
  }
}
