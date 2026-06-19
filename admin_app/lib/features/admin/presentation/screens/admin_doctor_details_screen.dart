import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validation_utils.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/models/doctor_document_model.dart';
import '../../../../data/models/doctor_model.dart';
import '../utils/admin_documents_helper.dart';
import '../widgets/admin_document_sections.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../../../shared/widgets/shimmer_widgets.dart';
import '../../../doctor_registration/provider/verified_doctors_provider.dart';
import '../../provider/admin_provider.dart';

/// Admin doctor detail — review documents and approve or reject.
class AdminDoctorDetailsScreen extends ConsumerWidget {
  const AdminDoctorDetailsScreen({
    super.key,
    required this.doctorId,
    this.initialDoctor,
  });

  final String doctorId;
  final DoctorModel? initialDoctor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(doctorDetailsProvider(doctorId));
    final doctor = state.doctor ?? initialDoctor;
    final documents = doctor == null
        ? const <DoctorDocumentModel>[]
        : mergeAdminDocuments(doctor, state.documents);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify doctor application'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (state.isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(context, ref, state, doctor, documents),
      bottomNavigationBar: doctor != null
          ? _ActionBar(
              doctorId: doctorId,
              state: state,
              documents: documents,
            )
          : null,
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    DoctorDetailsState state,
    DoctorModel? doctor,
    List<DoctorDocumentModel> documents,
  ) {
    if (state.isLoading && doctor == null) {
      return const SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: ShimmerProfileHeader(),
      );
    }

    if (state.error != null && doctor == null) {
      return AppErrorWidget(
        message: state.error!,
        onRetry: () => ref
            .read(doctorDetailsProvider(doctorId).notifier)
            .fetchDoctorDetails(doctorId),
      );
    }

    if (doctor == null) {
      return const EmptyStateWidget(
        icon: Icons.person_off_outlined,
        title: 'Doctor not found',
      );
    }
    final canReviewDocuments = doctor.verificationStatus !=
            VerificationStatus.verified &&
        doctor.verificationStatus != VerificationStatus.rejected;
    final allVerified = allDocumentsVerified(documents);

    return RefreshIndicator(
      onRefresh: () => ref
          .read(doctorDetailsProvider(doctorId).notifier)
          .fetchDoctorDetails(doctorId),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProfileHeader(doctor: doctor),
          const SizedBox(height: 24),
          _Section(
            title: 'Personal Information',
            children: [
              _DetailRow('Name', doctor.fullName),
              _DetailRow('Email', doctor.email ?? '-'),
              _DetailRow('Mobile', doctor.mobileNumber ?? '-'),
              _DetailRow('Gender', doctor.gender ?? '-'),
              _DetailRow(
                'Aadhaar',
                doctor.aadhaarLast4 != null
                    ? 'XXXX-XXXX-${doctor.aadhaarLast4}'
                    : '-',
              ),
            ],
          ),
          _Section(
            title: 'Professional Details',
            children: [
              _DetailRow('Reg. Number', doctor.medicalRegistrationNumber ?? '-'),
              _DetailRow('Council', doctor.medicalCouncilName ?? '-'),
              _DetailRow(
                'Specializations',
                doctor.specializations?.join(', ') ?? '-',
              ),
              _DetailRow(
                'Experience',
                doctor.yearsOfExperience != null
                    ? FormattingUtils.formatExperience(doctor.yearsOfExperience!)
                    : '-',
              ),
              _DetailRow('Qualification', doctor.qualification ?? '-'),
              _DetailRow(
                'Languages',
                doctor.languagesSpoken?.isNotEmpty == true
                    ? doctor.languagesSpoken!.join(', ')
                    : '-',
              ),
              if (doctor.bio != null && doctor.bio!.trim().isNotEmpty)
                _DetailRow('About', doctor.bio!),
              _DetailRow('Clinic', doctor.clinicName ?? '-'),
              _DetailRow(
                'Fee',
                doctor.consultationFee != null
                    ? FormattingUtils.formatConsultationFee(
                        doctor.consultationFee!,
                      )
                    : '-',
              ),
            ],
          ),
          _Section(
            title: 'Address',
            children: [
              _DetailRow('Address', doctor.address ?? '-'),
              _DetailRow('City', doctor.city ?? '-'),
              _DetailRow('State', doctor.state ?? '-'),
              _DetailRow('Pincode', doctor.pincode ?? '-'),
            ],
          ),
          if (doctor.payoutMethod == PayoutMethod.upi ||
              doctor.bankAccountNumber != null ||
              doctor.ifscCode != null ||
              doctor.upiId != null ||
              doctor.cancelledChequeUrl != null)
            _Section(
              title: 'Payout details',
              children: [
                _DetailRow('Method', doctor.payoutMethod.label),
                if (doctor.payoutMethod == PayoutMethod.upi)
                  _DetailRow('UPI ID', doctor.upiId ?? '-')
                else ...[
                  _DetailRow('Account', doctor.bankAccountNumber ?? '-'),
                  _DetailRow('IFSC', doctor.ifscCode ?? '-'),
                ],
              ],
            ),
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
              title: state.isLoading ? 'Loading documents…' : 'No documents uploaded',
              subtitle: state.isLoading
                  ? 'Fetching files from the registration…'
                  : 'This doctor has not uploaded license, ID, or certificate files yet.',
            )
          else
            AdminDocumentSections(
              documents: documents,
              canReviewDocuments: canReviewDocuments,
              onVerify: (doc, _) async {
                final ok = await ref
                    .read(doctorDetailsProvider(doctorId).notifier)
                    .verifyDocument(
                      doctorId: doctorId,
                      documentId: doc.id ?? '',
                      documentType: doc.documentType,
                    );
                if (!context.mounted) return ok;
                if (ok) {
                  SnackBarHelper.showSuccess(context, 'Document verified');
                } else {
                  final err = ref.read(doctorDetailsProvider(doctorId)).error;
                  SnackBarHelper.showError(
                    context,
                    err ?? 'Could not verify document. Pull to refresh and try again.',
                  );
                }
                return ok;
              },
              onReject: (doc, reason) async {
                if (reason == null || reason.trim().isEmpty) return false;
                final ok = await ref
                    .read(doctorDetailsProvider(doctorId).notifier)
                    .rejectDocument(
                      doctorId: doctorId,
                      documentId: doc.id ?? '',
                      documentType: doc.documentType,
                      reason: reason,
                    );
                if (!context.mounted) return ok;
                if (ok) {
                  SnackBarHelper.showError(
                    context,
                    'Document rejected — provider will see your message',
                  );
                } else {
                  final err = ref.read(doctorDetailsProvider(doctorId)).error;
                  SnackBarHelper.showError(
                    context,
                    err ?? 'Could not reject document. Pull to refresh and try again.',
                  );
                }
                return ok;
              },
            ),
          if (!allVerified && canReviewDocuments && documents.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: InfoCard(
                icon: Icons.info_outline_rounded,
                title: 'Verify each document above',
                subtitle:
                    'After every document is verified, you can publish this doctor on the user app.',
              ),
            ),
          const SizedBox(height: 120),
        ],
      ),
    ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.doctor});

  final DoctorModel doctor;

  @override
  Widget build(BuildContext context) {
    final status = doctor.verificationStatus;
    final statusLabel = switch (status) {
      VerificationStatus.verified => 'Approved',
      VerificationStatus.rejected => 'Rejected',
      VerificationStatus.underReview => 'Needs review',
      _ => 'Needs review',
    };
    final statusColor = switch (status) {
      VerificationStatus.verified => AppColors.success,
      VerificationStatus.rejected => AppColors.error,
      VerificationStatus.underReview => AppColors.warning,
      _ => AppColors.pending,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: AppColors.primaryLight,
              backgroundImage: doctor.profilePicture != null &&
                      doctor.profilePicture!.startsWith('http')
                  ? NetworkImage(doctor.profilePicture!)
                  : null,
              child: doctor.profilePicture == null
                  ? const Icon(Icons.person, size: 48, color: AppColors.primary)
                  : null,
            ),
            const SizedBox(height: 12),
            Text(doctor.fullName, style: AppTextStyles.headlineSmall),
            const SizedBox(height: 8),
            VerificationBadge(
              status: statusLabel,
              backgroundColor: statusColor,
              textColor: statusColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.titleMedium),
            const Divider(height: 24),
            ...children,
          ],
        ),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value, style: AppTextStyles.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _ActionBar extends ConsumerWidget {
  const _ActionBar({
    required this.doctorId,
    required this.state,
    required this.documents,
  });

  final String doctorId;
  final DoctorDetailsState state;
  final List<DoctorDocumentModel> documents;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(doctorDetailsProvider(doctorId).notifier);
    final status = state.doctor?.verificationStatus;
    final isVerified = status == VerificationStatus.verified;
    final isRejected = status == VerificationStatus.rejected;

    final isPendingReview = !isVerified &&
        !isRejected &&
        (status == VerificationStatus.underReview ||
            status == VerificationStatus.pending);
    final verifiedCount =
        documents.where((d) => d.status == DocumentStatus.verified).length;
    final totalCount = documents.length;
    final allDocsVerified = allDocumentsVerified(documents);
    final canApprove = isPendingReview && allDocsVerified;

    if (isVerified) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: InfoCard(
            icon: Icons.verified_rounded,
            title: 'Published on user app',
            subtitle:
                'This doctor is visible to patients in the 1mg Care app.',
          ),
        ),
      );
    }

    if (isRejected) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: InfoCard(
            icon: Icons.info_outline_rounded,
            title: 'Application rejected',
            subtitle: state.doctor?.rejectionReason?.trim().isNotEmpty == true
                ? state.doctor!.rejectionReason!
                : 'This application is no longer pending review.',
          ),
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (totalCount > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  allDocsVerified
                      ? 'All $totalCount documents verified — ready to publish'
                      : '$verifiedCount of $totalCount documents verified',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: allDocsVerified
                        ? AppColors.success
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            CustomButton(
              label: 'Verify & publish on user app',
              icon: Icons.verified_rounded,
              onPressed: canApprove && !state.isApproving
                  ? () => _approve(context, ref, notifier)
                  : () {},
              isLoading: state.isApproving,
              isEnabled: canApprove && !state.isApproving,
            ),
            if (!canApprove && totalCount == 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Waiting for uploaded documents from the doctor.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              )
            else if (!canApprove)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Open each document above and tap Verify before publishing.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _approve(
    BuildContext context,
    WidgetRef ref,
    DoctorDetailsNotifier notifier,
  ) async {
    final success = await notifier.approveDoctor(
      doctorId: doctorId,
      notes: 'Approved by admin',
    );
    if (success) {
      ref.invalidate(verifiedDoctorsProvider);
      final listState = ref.read(adminDoctorsListProvider);
      await ref.read(adminDoctorsListProvider.notifier).fetchDoctors(
            status: listState.selectedStatus,
            page: listState.currentPage,
          );
    }
    if (context.mounted) {
      SnackBarHelper.showSuccess(
        context,
        success
            ? 'Doctor verified — now live on the user app'
            : 'Verification failed',
      );
    }
  }

}
