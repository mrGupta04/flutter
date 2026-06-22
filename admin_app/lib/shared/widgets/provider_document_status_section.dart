import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/provider_type.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/custom_widgets.dart';
import '../../data/models/doctor_document_model.dart';
import '../../data/repositories/doctor_registration_repository.dart';
import '../../data/repositories/nurse_registration_repository.dart';
import '../../data/repositories/ambulance_registration_repository.dart';
import '../../features/auth/provider/provider_auth_provider.dart';
import 'app_widgets.dart';

/// Doctor documents for status display and re-upload flows.
final doctorDocumentsProvider =
    FutureProvider.autoDispose<List<DoctorDocumentModel>>((ref) async {
  final auth = ref.watch(providerAuthProvider);
  if (auth.providerType != ProviderType.doctor || auth.entityId == null) {
    return [];
  }
  final response = await DoctorRegistrationRepository().getDocuments(
    doctorId: auth.entityId!,
  );
  return response.data ?? [];
});

final _nurseDocumentsProvider =
    FutureProvider.autoDispose<List<DoctorDocumentModel>>((ref) async {
  final auth = ref.watch(providerAuthProvider);
  if (auth.providerType != ProviderType.nurse || auth.entityId == null) {
    return [];
  }
  final response = await NurseRegistrationRepository().getDocuments(
    nurseId: auth.entityId!,
  );
  return response.data ?? [];
});

final _ambulanceDocumentsProvider =
    FutureProvider.autoDispose<List<DoctorDocumentModel>>((ref) async {
  final auth = ref.watch(providerAuthProvider);
  if (auth.providerType != ProviderType.ambulance || auth.entityId == null) {
    return [];
  }
  final response = await AmbulanceRegistrationRepository().getDocuments(
    ambulanceId: auth.entityId!,
  );
  return response.data ?? [];
});

class ProviderDocumentStatusSection extends ConsumerWidget {
  const ProviderDocumentStatusSection({
    super.key,
    this.onReuploadDocument,
    this.isUploading = false,
  });

  /// Called when the doctor taps re-upload on a rejected document.
  final Future<void> Function(DocumentType documentType)? onReuploadDocument;
  final bool isUploading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(providerAuthProvider);
    final AsyncValue<List<DoctorDocumentModel>> docsAsync =
        switch (auth.providerType) {
      ProviderType.doctor => ref.watch(doctorDocumentsProvider),
      ProviderType.nurse => ref.watch(_nurseDocumentsProvider),
      ProviderType.ambulance => ref.watch(_ambulanceDocumentsProvider),
      _ => const AsyncValue.data([]),
    };

    return docsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (documents) {
        if (documents.isEmpty) return const SizedBox.shrink();

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
            Text(
              'Your documents',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              onReuploadDocument != null
                  ? 'Verified documents are locked. If a document is rejected, read the admin message and tap re-upload to submit a corrected file.'
                  : 'Verified documents are locked. If a document is rejected, read the admin message and re-upload the corrected file from your profile.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            if (underReview.isNotEmpty)
              _StatusGroup(
                title: 'Under review',
                color: AppColors.warning,
                documents: underReview,
              ),
            if (rejected.isNotEmpty)
              _StatusGroup(
                title: 'Rejected — action needed',
                color: AppColors.error,
                documents: rejected,
                onReuploadDocument: onReuploadDocument,
                isUploading: isUploading,
              ),
            if (verified.isNotEmpty)
              _StatusGroup(
                title: 'Verified',
                color: AppColors.success,
                documents: verified,
              ),
          ],
        );
      },
    );
  }
}

class _StatusGroup extends StatelessWidget {
  const _StatusGroup({
    required this.title,
    required this.color,
    required this.documents,
    this.onReuploadDocument,
    this.isUploading = false,
  });

  final String title;
  final Color color;
  final List<DoctorDocumentModel> documents;
  final Future<void> Function(DocumentType documentType)? onReuploadDocument;
  final bool isUploading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title (${documents.length})',
            style: AppTextStyles.labelLarge.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ...documents.map(
            (doc) => _DocumentTile(
              document: doc,
              color: color,
              onReupload: doc.status == DocumentStatus.rejected &&
                      doc.documentType != null &&
                      onReuploadDocument != null
                  ? () => onReuploadDocument!(doc.documentType!)
                  : null,
              isUploading: isUploading,
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({
    required this.document,
    required this.color,
    this.onReupload,
    this.isUploading = false,
  });

  final DoctorDocumentModel document;
  final Color color;
  final VoidCallback? onReupload;
  final bool isUploading;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  document.status == DocumentStatus.rejected
                      ? Icons.error_outline
                      : document.status == DocumentStatus.verified
                          ? Icons.verified_outlined
                          : Icons.hourglass_top_outlined,
                  color: color,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    document.documentTypeDisplay,
                    style: AppTextStyles.titleSmall,
                  ),
                ),
                VerificationBadge(
                  status: document.statusDisplay,
                  backgroundColor: color,
                  textColor: color,
                ),
              ],
            ),
            if (document.rejectionReason?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(
                'Admin message: ${document.rejectionReason}',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
              ),
            ],
            if (onReupload != null) ...[
              const SizedBox(height: 12),
              CustomOutlineButton(
                label: 'Re-upload corrected file',
                icon: Icons.upload_file_rounded,
                isLoading: isUploading,
                isEnabled: !isUploading,
                onPressed: onReupload!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
