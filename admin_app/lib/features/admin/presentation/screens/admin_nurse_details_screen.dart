import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/phone_countries.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validation_utils.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/models/doctor_document_model.dart';
import '../../../../data/models/doctor_model.dart';
import '../../../../data/models/nurse_model.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../../../shared/widgets/shimmer_widgets.dart';
import '../widgets/admin_document_sections.dart';
import '../../provider/admin_nurse_provider.dart';

class AdminNurseDetailsScreen extends ConsumerWidget {
  const AdminNurseDetailsScreen({super.key, required this.nurseId});

  final String nurseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(nurseDetailsProvider(nurseId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify nurse application'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (state.isLoading && state.nurse != null)
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
      body: _buildBody(context, ref, state),
      bottomNavigationBar: state.nurse != null
          ? _ActionBar(
              nurseId: nurseId,
              state: state,
              documents: state.documents,
            )
          : null,
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    NurseDetailsState state,
  ) {
    if (state.isLoading && state.nurse == null) {
      return const SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: ShimmerProfileHeader(),
      );
    }

    if (state.error != null && state.nurse == null) {
      return AppErrorWidget(
        message: state.error!,
        onRetry: () => ref
            .read(nurseDetailsProvider(nurseId).notifier)
            .fetchNurseDetails(nurseId),
      );
    }

    final nurse = state.nurse;
    if (nurse == null) {
      return const EmptyStateWidget(
        icon: Icons.person_off_outlined,
        title: 'Nurse not found',
      );
    }

    final canReviewDocuments = nurse.verificationStatus !=
            VerificationStatus.verified &&
        nurse.verificationStatus != VerificationStatus.rejected;
    final allVerified = allDocumentsVerified(state.documents);

    return RefreshIndicator(
      onRefresh: () => ref
          .read(nurseDetailsProvider(nurseId).notifier)
          .fetchNurseDetails(nurseId),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProfileHeader(nurse: nurse),
            const SizedBox(height: 24),
            _Section(
              title: 'Personal Information',
              children: [
                _DetailRow('Name', nurse.displayName),
                _DetailRow('Email', nurse.email ?? '-'),
                _DetailRow(
                  'Mobile',
                  nurse.mobileNumber != null && nurse.mobileNumber!.isNotEmpty
                      ? ValidationUtils.formatInternationalPhone(
                          nurse.mobileNumber!,
                          countryCode: nurse.countryCode ??
                              PhoneCountries.defaultDialCode,
                        )
                      : '-',
                ),
                _DetailRow('Gender', nurse.gender ?? '-'),
                _DetailRow(
                  'Date of Birth',
                  nurse.dateOfBirth != null
                      ? FormattingUtils.formatDate(nurse.dateOfBirth!)
                      : '-',
                ),
                _DetailRow(
                  'Languages',
                  nurse.languagesSpoken?.isNotEmpty == true
                      ? nurse.languagesSpoken!.join(', ')
                      : '-',
                ),
                if (nurse.emergencyContactName?.trim().isNotEmpty == true)
                  _DetailRow(
                    'Emergency contact',
                    '${nurse.emergencyContactName}'
                    '${nurse.emergencyContactNumber?.trim().isNotEmpty == true ? ' (${nurse.emergencyContactNumber})' : ''}',
                  ),
              ],
            ),
            _Section(
              title: 'Professional Details',
              children: [
                _DetailRow('Reg. Number', nurse.registrationNumber ?? '-'),
                _DetailRow('Council', nurse.nursingCouncil ?? '-'),
                if (nurse.nuid?.trim().isNotEmpty == true)
                  _DetailRow('NUID', nurse.nuid!),
                _DetailRow('Qualification', nurse.qualification ?? '-'),
                _DetailRow(
                  'Experience',
                  nurse.yearsOfExperience != null
                      ? FormattingUtils.formatExperience(
                          nurse.yearsOfExperience!,
                        )
                      : '-',
                ),
                _DetailRow('Specialization', nurse.specialization ?? '-'),
                _DetailRow(
                  'Clinical skills',
                  nurse.nursingSkills?.isNotEmpty == true
                      ? nurse.nursingSkills!.join(', ')
                      : '-',
                ),
                _DetailRow(
                  'Home visit',
                  nurse.availableForHomeVisit == true ? 'Yes' : 'No',
                ),
                if (nurse.homeVisitFee != null)
                  _DetailRow(
                    'Home visit fee',
                    FormattingUtils.formatConsultationFee(nurse.homeVisitFee!),
                  ),
              ],
            ),
            _Section(
              title: 'Address',
              children: [
                _DetailRow('Address', nurse.address ?? '-'),
                _DetailRow('City', nurse.city ?? '-'),
                _DetailRow('State', nurse.state ?? '-'),
                _DetailRow('Pincode', nurse.pincode ?? '-'),
                if (nurse.serviceRadiusKm != null)
                  _DetailRow(
                    'Service radius',
                    '${nurse.serviceRadiusKm} km',
                  ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Text('Documents', style: AppTextStyles.titleMedium),
                ),
                if (state.documents.isNotEmpty)
                  Text(
                    '${state.documents.where((d) => d.status == DocumentStatus.verified).length}/${state.documents.length} verified',
                    style: AppTextStyles.labelMedium.copyWith(
                      color:
                          allVerified ? AppColors.success : AppColors.warning,
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
            if (state.documents.isEmpty)
              const InfoCard(
                icon: Icons.folder_open,
                title: 'No documents uploaded',
                subtitle:
                    'Profile picture and certificates will appear here for verification.',
              )
            else
              AdminDocumentSections(
                documents: state.documents,
                canReviewDocuments: canReviewDocuments,
                onVerify: (doc, _) async {
                  final id = doc.id;
                  if (id == null || id.isEmpty) return false;
                  return ref
                      .read(nurseDetailsProvider(nurseId).notifier)
                      .verifyDocument(nurseId: nurseId, documentId: id);
                },
                onReject: (doc, reason) async {
                  final id = doc.id;
                  if (id == null || id.isEmpty || reason == null) return false;
                  return ref
                      .read(nurseDetailsProvider(nurseId).notifier)
                      .rejectDocument(
                        nurseId: nurseId,
                        documentId: id,
                        reason: reason,
                      );
                },
              ),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.nurse});

  final NurseModel nurse;

  @override
  Widget build(BuildContext context) {
    final status = nurse.verificationStatus;
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
    final hasNetworkPhoto = nurse.profilePicture != null &&
        nurse.profilePicture!.startsWith('http');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: AppColors.primaryLight,
              backgroundImage:
                  hasNetworkPhoto ? NetworkImage(nurse.profilePicture!) : null,
              child: hasNetworkPhoto
                  ? null
                  : const Icon(Icons.person, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 12),
            Text(nurse.displayName, style: AppTextStyles.headlineSmall),
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
          SizedBox(
            width: 128,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: AppTextStyles.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBar extends ConsumerWidget {
  const _ActionBar({
    required this.nurseId,
    required this.state,
    required this.documents,
  });

  final String nurseId;
  final NurseDetailsState state;
  final List<DoctorDocumentModel> documents;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nurse = state.nurse!;
    final status = nurse.verificationStatus;
    final isVerified = status == VerificationStatus.verified;
    final isRejected = status == VerificationStatus.rejected;
    final verifiedCount =
        documents.where((d) => d.status == DocumentStatus.verified).length;
    final totalCount = documents.length;
    final allDocsVerified = allDocumentsVerified(documents);
    final canApprove = !isVerified &&
        !isRejected &&
        (status == VerificationStatus.underReview ||
            status == VerificationStatus.pending) &&
        allDocsVerified;

    if (isVerified || isRejected) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: CompactVerifiedBanner(
            message: isVerified ? 'Live on patient app' : 'Review complete',
            icon: isVerified
                ? Icons.verified_rounded
                : Icons.info_outline_rounded,
            color: isVerified ? AppColors.success : AppColors.textSecondary,
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
              isLoading: state.isApproving,
              isEnabled: canApprove && !state.isApproving,
              onPressed: canApprove && !state.isApproving
                  ? () async {
                      final ok = await ref
                          .read(nurseDetailsProvider(nurseId).notifier)
                          .approveNurse(nurseId: nurseId);
                      if (context.mounted && ok) {
                        SnackBarHelper.showSuccess(
                          context,
                          AppConstants.adminApprovalSuccess,
                        );
                      }
                    }
                  : () {},
            ),
          ],
        ),
      ),
    );
  }
}
