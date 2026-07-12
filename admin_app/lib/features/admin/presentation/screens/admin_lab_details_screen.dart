import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/models/doctor_model.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../../../shared/widgets/shimmer_widgets.dart';
import '../utils/embedded_documents_helper.dart';
import '../widgets/admin_document_sections.dart';
import '../widgets/admin_embedded_documents_panel.dart';
import '../../provider/admin_lab_provider.dart';

class AdminLabDetailsScreen extends ConsumerWidget {
  const AdminLabDetailsScreen({super.key, required this.labId});

  final String labId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(labDetailsProvider(labId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify lab application'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _buildBody(context, ref, state),
      bottomNavigationBar: state.lab != null && !state.isLoading
          ? _ActionBar(labId: labId, state: state)
          : null,
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, LabDetailsState state) {
    if (state.isLoading) {
      return const SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: ShimmerProfileHeader(),
      );
    }

    if (state.error != null) {
      return AppErrorWidget(
        message: state.error!,
        onRetry: () =>
            ref.read(labDetailsProvider(labId).notifier).fetchLabDetails(labId),
      );
    }

    final lab = state.lab;
    if (lab == null) {
      return const EmptyStateWidget(
        icon: Icons.biotech_outlined,
        title: 'Lab not found',
      );
    }

    final documents = labDocumentsToAdminDocs(lab.documents);
    final canReviewDocuments = lab.verificationStatus !=
            VerificationStatus.verified &&
        lab.verificationStatus != VerificationStatus.rejected;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lab.labName ?? 'Diagnostic lab',
            style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w800),
          ),
          if (lab.documentRequestNote != null &&
              lab.documentRequestNote!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.offerLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Document request: ${lab.documentRequestNote}',
                style: AppTextStyles.bodySmall,
              ),
            ),
          ],
          const SizedBox(height: 20),
          _DetailRow('Owner', lab.ownerName ?? '-'),
          _DetailRow('Email', lab.email ?? '-'),
          _DetailRow('Mobile', lab.mobileNumber ?? '-'),
          _DetailRow('License', lab.licenseNumber ?? '-'),
          _DetailRow('Accreditation', lab.accreditation ?? '-'),
          _DetailRow('GST', lab.gstNumber ?? '-'),
          _DetailRow('Address', lab.address ?? '-'),
          _DetailRow('City', lab.city ?? '-'),
          _DetailRow('Operating hours', lab.operatingHours ?? '-'),
          _DetailRow(
            'Home collection',
            lab.homeCollectionAvailable == true ? 'Yes' : 'No',
          ),
          _DetailRow('24×7', lab.available24x7 == true ? 'Yes' : 'No'),
          _DetailRow('Tests offered', '${lab.offeredTests?.length ?? 0}'),
          _DetailRow('Lab images', '${lab.labImages?.length ?? 0}'),
          const SizedBox(height: 20),
          AdminEmbeddedDocumentsPanel(
            documents: documents,
            canReviewDocuments: canReviewDocuments,
            emptyMessage:
                'This lab has not uploaded registration documents yet.',
            onVerify: (doc) => handleEmbeddedDocumentAction(
              context,
              action: () => ref
                  .read(labDetailsProvider(labId).notifier)
                  .verifyDocument(labId: labId, documentId: doc.id ?? ''),
              successMessage: 'Document verified',
              errorMessage: ref.read(labDetailsProvider(labId)).error ??
                  'Could not verify document',
            ),
            onReject: (doc, reason) => handleEmbeddedDocumentAction(
              context,
              action: () => ref
                  .read(labDetailsProvider(labId).notifier)
                  .rejectDocument(
                    labId: labId,
                    documentId: doc.id ?? '',
                    reason: reason,
                  ),
              successMessage:
                  'Document rejected — provider will see your message',
              errorMessage: ref.read(labDetailsProvider(labId)).error ??
                  'Could not reject document',
              successIsErrorStyle: true,
            ),
          ),
          if (lab.offeredTests != null && lab.offeredTests!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Offered tests',
              style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ...lab.offeredTests!.take(10).map(
                  (t) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '• ${t.testName} — ₹${t.discountedPriceInr ?? t.priceInr}',
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                ),
            if (lab.offeredTests!.length > 10)
              Text(
                '+ ${lab.offeredTests!.length - 10} more',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
          ],
          const SizedBox(height: 120),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(child: Text(value, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }
}

class _ActionBar extends ConsumerWidget {
  const _ActionBar({required this.labId, required this.state});

  final String labId;
  final LabDetailsState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lab = state.lab!;
    final canModerate = lab.verificationStatus != VerificationStatus.verified ||
        lab.isApproved != true;
    final documents = labDocumentsToAdminDocs(lab.documents);
    final allDocsVerified = allDocumentsVerified(documents);
    final canApprove = canModerate && allDocsVerified && documents.isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canModerate) ...[
              if (!allDocsVerified && documents.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InfoCard(
                    icon: Icons.info_outline_rounded,
                    title: 'Verify all documents first',
                    subtitle:
                        'Approve is enabled after every uploaded document is verified.',
                  ),
                ),
              CustomButton(
                label: 'Approve lab',
                icon: Icons.verified_rounded,
                isLoading: state.isApproving,
                isEnabled: canApprove,
                onPressed: () => _approveLab(context, ref),
              ),
            ],
            if (canModerate) const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: CustomOutlineButton(
                    label: 'Reject',
                    isLoading: state.isRejecting,
                    onPressed: () => _showRejectDialog(context, ref),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomOutlineButton(
                    label: 'Suspend',
                    isLoading: state.isSuspending,
                    onPressed: () => _showSuspendDialog(context, ref),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            CustomOutlineButton(
              label: 'Request documents',
              isLoading: state.isRequestingDocs,
              onPressed: () => _showRequestDocsDialog(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveLab(BuildContext context, WidgetRef ref) async {
    final ok = await ref
        .read(labDetailsProvider(labId).notifier)
        .approveLab(labId: labId);
    if (context.mounted && ok) {
      SnackBarHelper.showSuccess(
        context,
        AppConstants.adminApprovalSuccess,
      );
      context.pop();
    }
  }

  Future<void> _showRejectDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject lab'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Rejection reason',
            hintText: 'Required',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (reason == null || reason.isEmpty) return;
    final ok = await ref
        .read(labDetailsProvider(labId).notifier)
        .rejectLab(labId: labId, reason: reason);
    if (context.mounted && ok) {
      SnackBarHelper.showSuccess(context, 'Lab rejected');
      context.pop();
    }
  }

  Future<void> _showSuspendDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Suspend lab'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Reason (optional)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Suspend'),
          ),
        ],
      ),
    );
    if (reason == null) return;
    final ok = await ref
        .read(labDetailsProvider(labId).notifier)
        .suspendLab(labId: labId, reason: reason.isEmpty ? null : reason);
    if (context.mounted && ok) {
      SnackBarHelper.showSuccess(context, 'Lab suspended');
      context.pop();
    }
  }

  Future<void> _showRequestDocsDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request additional documents'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Message to lab',
            hintText: 'e.g. Please upload updated NABL certificate',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Send request'),
          ),
        ],
      ),
    );
    if (note == null || note.isEmpty) return;
    final ok = await ref
        .read(labDetailsProvider(labId).notifier)
        .requestDocuments(labId: labId, note: note);
    if (context.mounted && ok) {
      SnackBarHelper.showSuccess(context, 'Document request sent');
    }
  }
}
