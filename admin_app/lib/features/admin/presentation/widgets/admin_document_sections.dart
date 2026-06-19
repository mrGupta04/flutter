import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/doctor_document_model.dart';
import 'admin_document_viewer.dart';

typedef DocumentActionCallback = Future<bool> Function(
  DoctorDocumentModel document,
  String? rejectionReason,
);

class AdminDocumentSections extends StatelessWidget {
  const AdminDocumentSections({
    super.key,
    required this.documents,
    required this.canReviewDocuments,
    this.onVerify,
    this.onReject,
  });

  final List<DoctorDocumentModel> documents;
  final bool canReviewDocuments;
  final DocumentActionCallback? onVerify;
  final DocumentActionCallback? onReject;

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) {
      return const SizedBox.shrink();
    }

    final underReview = documents
        .where(
          (d) =>
              d.status == DocumentStatus.pending ||
              d.status == DocumentStatus.underReview ||
              d.status == null,
        )
        .toList();
    final rejected =
        documents.where((d) => d.status == DocumentStatus.rejected).toList();
    final verified =
        documents.where((d) => d.status == DocumentStatus.verified).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (underReview.isNotEmpty) ...[
          _SectionHeader(
            title: 'Under review',
            count: underReview.length,
            color: AppColors.warning,
          ),
          ...underReview.map(
            (doc) => AdminDocumentPreviewCard(
              document: doc,
              canReview: canReviewDocuments,
              onVerify: onVerify == null ? null : () => onVerify!(doc, null),
              onReject: onReject == null
                  ? null
                  : (reason) => onReject!(doc, reason),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (rejected.isNotEmpty) ...[
          _SectionHeader(
            title: 'Rejected',
            count: rejected.length,
            color: AppColors.error,
          ),
          ...rejected.map(
            (doc) => AdminDocumentPreviewCard(
              document: doc,
              canReview: canReviewDocuments,
              onVerify: onVerify == null ? null : () => onVerify!(doc, null),
              onReject: onReject == null
                  ? null
                  : (reason) => onReject!(doc, reason),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (verified.isNotEmpty) ...[
          _SectionHeader(
            title: 'Verified',
            count: verified.length,
            color: AppColors.success,
          ),
          ...verified.map(
            (doc) => AdminDocumentPreviewCard(
              document: doc,
              canReview: false,
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.count,
    required this.color,
  });

  final String title;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$title ($count)',
            style: AppTextStyles.titleSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

bool allDocumentsVerified(List<DoctorDocumentModel> documents) {
  if (documents.isEmpty) return false;
  return documents.every((d) => d.status == DocumentStatus.verified);
}
