import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/models/doctor_document_model.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../widgets/admin_document_sections.dart';

class AdminEmbeddedDocumentsPanel extends ConsumerWidget {
  const AdminEmbeddedDocumentsPanel({
    super.key,
    required this.documents,
    required this.canReviewDocuments,
    required this.onVerify,
    required this.onReject,
    this.emptyMessage =
        'No documents uploaded yet. Ask the provider to complete registration.',
  });

  final List<DoctorDocumentModel> documents;
  final bool canReviewDocuments;
  final Future<bool> Function(DoctorDocumentModel document) onVerify;
  final Future<bool> Function(DoctorDocumentModel document, String reason)
      onReject;
  final String emptyMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allVerified = allDocumentsVerified(documents);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Documents', style: AppTextStyles.titleMedium),
            ),
            if (documents.isNotEmpty)
              Text(
                '${documents.where((d) => d.status == DocumentStatus.verified).length}/${documents.length} verified',
                style: AppTextStyles.labelMedium.copyWith(
                  color: allVerified ? AppColors.success : AppColors.warning,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Review each document below. Tap a card to open it, then verify or reject.',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        if (documents.isEmpty)
          InfoCard(
            icon: Icons.folder_open,
            title: 'No documents uploaded',
            subtitle: emptyMessage,
          )
        else
          AdminDocumentSections(
            documents: documents,
            canReviewDocuments: canReviewDocuments,
            onVerify: (doc, _) => onVerify(doc),
            onReject: (doc, reason) async {
              if (reason == null || reason.trim().isEmpty) return false;
              return onReject(doc, reason.trim());
            },
          ),
        if (!allVerified && canReviewDocuments && documents.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: InfoCard(
              icon: Icons.info_outline_rounded,
              title: 'Verify each document above',
              subtitle:
                  'After every document is verified, you can publish this provider on the user app.',
            ),
          ),
      ],
    );
  }
}

Future<bool> handleEmbeddedDocumentAction(
  BuildContext context, {
  required Future<bool> Function() action,
  required String successMessage,
  required String errorMessage,
  bool successIsErrorStyle = false,
}) async {
  final ok = await action();
  if (!context.mounted) return ok;
  if (ok) {
    if (successIsErrorStyle) {
      SnackBarHelper.showError(context, successMessage);
    } else {
      SnackBarHelper.showSuccess(context, successMessage);
    }
  } else {
    SnackBarHelper.showError(context, errorMessage);
  }
  return ok;
}
