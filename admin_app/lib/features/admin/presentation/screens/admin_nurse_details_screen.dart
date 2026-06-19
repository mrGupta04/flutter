import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/models/doctor_document_model.dart';
import '../../../../data/models/doctor_model.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../widgets/admin_document_sections.dart';
import '../../../../shared/widgets/shimmer_widgets.dart';
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
      ),
      body: _buildBody(context, ref, state),
      bottomNavigationBar: state.nurse != null && !state.isLoading
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
    if (state.isLoading) {
      return const SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: ShimmerProfileHeader(),
      );
    }

    if (state.error != null) {
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            nurse.displayName,
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Status: ${_statusLabel(nurse.verificationStatus)}',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          _DetailRow('Email', nurse.email ?? '-'),
          _DetailRow('Mobile', nurse.mobileNumber ?? '-'),
          _DetailRow('Qualification', nurse.qualification ?? '-'),
          _DetailRow('Registration No.', nurse.registrationNumber ?? '-'),
          _DetailRow('Nursing Council', nurse.nursingCouncil ?? '-'),
          _DetailRow(
            'Experience',
            nurse.yearsOfExperience != null
                ? '${nurse.yearsOfExperience} years'
                : '-',
          ),
          _DetailRow('Specialization', nurse.specialization ?? '-'),
          _DetailRow('Address', nurse.address ?? '-'),
          _DetailRow('City', nurse.city ?? '-'),
          _DetailRow('State', nurse.state ?? '-'),
          _DetailRow('Pincode', nurse.pincode ?? '-'),
          _DetailRow('Shift', nurse.shiftAvailability ?? '-'),
          _DetailRow(
            'Home visit',
            nurse.availableForHomeVisit == true ? 'Yes' : 'No',
          ),
          const SizedBox(height: 20),
          Text('Documents', style: AppTextStyles.titleMedium),
          const SizedBox(height: 12),
          if (state.documents.isEmpty)
            const InfoCard(
              icon: Icons.image_outlined,
              title: 'No profile document',
              subtitle: 'Profile picture will appear here for verification',
            )
          else
            AdminDocumentSections(
              documents: state.documents,
              canReviewDocuments: nurse.verificationStatus !=
                      VerificationStatus.verified &&
                  nurse.verificationStatus != VerificationStatus.rejected,
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
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  String _statusLabel(VerificationStatus? status) {
    switch (status) {
      case VerificationStatus.verified:
        return 'Approved';
      case VerificationStatus.rejected:
        return 'Rejected';
      case VerificationStatus.underReview:
      case VerificationStatus.pending:
      default:
        return 'Needs review';
    }
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
            width: 120,
            child: Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
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
    final canApprove = !isVerified &&
        !isRejected &&
        (status == VerificationStatus.underReview ||
            status == VerificationStatus.pending) &&
        allDocumentsVerified(documents);

    if (!canApprove) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: InfoCard(
            icon: isVerified
                ? Icons.verified_rounded
                : Icons.info_outline_rounded,
            title: isVerified
                ? 'Published on user app'
                : 'Application processed',
            subtitle: isVerified
                ? 'This nurse is visible to patients in the 1mg Care app.'
                : 'This application is no longer pending review.',
          ),
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: CustomButton(
          label: 'Verify & publish',
          icon: Icons.verified_rounded,
          isLoading: state.isApproving,
          onPressed: () async {
            final ok = await ref
                .read(nurseDetailsProvider(nurseId).notifier)
                .approveNurse(nurseId: nurseId);
            if (context.mounted && ok) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Nurse verified — now live on user app'),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
