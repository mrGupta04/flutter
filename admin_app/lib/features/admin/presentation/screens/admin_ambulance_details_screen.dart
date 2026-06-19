import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/models/ambulance_driver_model.dart';
import '../../../../data/models/ambulance_vehicle_model.dart';
import '../../../../data/models/doctor_document_model.dart';
import '../../../../data/models/doctor_model.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../../../shared/widgets/shimmer_widgets.dart';
import '../../provider/admin_ambulance_provider.dart';
import '../utils/admin_ambulance_documents_helper.dart';
import '../widgets/admin_document_sections.dart';

class AdminAmbulanceDetailsScreen extends ConsumerWidget {
  const AdminAmbulanceDetailsScreen({super.key, required this.ambulanceId});

  final String ambulanceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ambulanceDetailsProvider(ambulanceId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify ambulance application'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _buildBody(context, ref, state),
      bottomNavigationBar: state.ambulance != null && !state.isLoading
          ? _ActionBar(
              ambulanceId: ambulanceId,
              state: state,
              documents: mergeAmbulanceDocuments(
                state.ambulance!,
                state.documents,
              ),
            )
          : null,
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    AmbulanceDetailsState state,
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
            .read(ambulanceDetailsProvider(ambulanceId).notifier)
            .fetchAmbulanceDetails(ambulanceId),
      );
    }

    final ambulance = state.ambulance;
    if (ambulance == null) {
      return const EmptyStateWidget(
        icon: Icons.local_shipping_outlined,
        title: 'Ambulance not found',
      );
    }

    final documents =
        mergeAmbulanceDocuments(ambulance, state.documents);
    final canReviewDocuments = ambulance.verificationStatus !=
            VerificationStatus.verified &&
        ambulance.verificationStatus != VerificationStatus.rejected;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ambulance.serviceName ?? 'Ambulance',
            style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 20),
          _SectionTitle('Service & Owner'),
          _DetailRow('Owner', ambulance.ownerName ?? '-'),
          _DetailRow('Email', ambulance.email ?? '-'),
          _DetailRow('Mobile', ambulance.mobileNumber ?? '-'),
          _DetailRow('Emergency', ambulance.emergencyContact ?? '-'),
          _DetailRow('License', ambulance.licenseNumber ?? '-'),
          _DetailRow('Registration', ambulance.registrationNumber ?? '-'),
          _DetailRow('PAN', ambulance.panNumber ?? '-'),
          _DetailRow('GST', ambulance.gstNumber ?? '-'),
          _DetailRow('Company Reg.', ambulance.companyRegistrationNumber ?? '-'),
          const SizedBox(height: 16),
          _SectionTitle('Fleet (${ambulance.vehicles?.length ?? ambulance.vehicleCount ?? 0} vehicles)'),
          if (ambulance.vehicles != null && ambulance.vehicles!.isNotEmpty)
            ...ambulance.vehicles!.map((v) => _VehicleDetailCard(vehicle: v))
          else
            _DetailRow('Types', (ambulance.vehicleTypes ?? []).join(', ')),
          const SizedBox(height: 16),
          _SectionTitle('Drivers (${ambulance.drivers?.length ?? 0})'),
          if (ambulance.drivers != null && ambulance.drivers!.isNotEmpty)
            ...ambulance.drivers!.map((d) => _DriverDetailCard(driver: d))
          else
            const Text('No driver records'),
          const SizedBox(height: 16),
          _SectionTitle('Location & Coverage'),
          _DetailRow('Address', ambulance.address ?? '-'),
          _DetailRow('City', ambulance.city ?? '-'),
          _DetailRow('State', ambulance.state ?? '-'),
          _DetailRow('Pincode', ambulance.pincode ?? '-'),
          _DetailRow('Service area', ambulance.serviceArea ?? '-'),
          _DetailRow('24x7', ambulance.available24x7 == true ? 'Yes' : 'No'),
          const SizedBox(height: 16),
          _SectionTitle('Bank Details'),
          _DetailRow('Holder', ambulance.bankAccountHolderName ?? '-'),
          _DetailRow('Account', ambulance.bankAccountNumber != null
              ? '****${ambulance.bankAccountNumber!.length > 4 ? ambulance.bankAccountNumber!.substring(ambulance.bankAccountNumber!.length - 4) : ambulance.bankAccountNumber}'
              : '-'),
          _DetailRow('IFSC', ambulance.ifscCode ?? '-'),
          _DetailRow('Bank', ambulance.bankName ?? '-'),
          const SizedBox(height: 20),
          Text('Documents', style: AppTextStyles.titleMedium),
          const SizedBox(height: 12),
          if (documents.isEmpty)
            const InfoCard(
              icon: Icons.folder_open,
              title: 'No documents',
              subtitle: 'Uploaded documents will appear here',
            )
          else
            AdminDocumentSections(
              documents: documents,
              canReviewDocuments: canReviewDocuments,
              onVerify: (doc, _) async {
                final id = doc.id;
                if (id == null || id.isEmpty) return false;
                return ref
                    .read(ambulanceDetailsProvider(ambulanceId).notifier)
                    .verifyDocument(ambulanceId: ambulanceId, documentId: id);
              },
              onReject: (doc, reason) async {
                final id = doc.id;
                if (id == null || id.isEmpty || reason == null) return false;
                return ref
                    .read(ambulanceDetailsProvider(ambulanceId).notifier)
                    .rejectDocument(
                      ambulanceId: ambulanceId,
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
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _VehicleDetailCard extends StatelessWidget {
  const _VehicleDetailCard({required this.vehicle});
  final AmbulanceVehicleModel vehicle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              vehicle.displayLabel,
              style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              '${vehicle.make} ${vehicle.model} (${vehicle.year ?? ''}) • ${vehicle.color}',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            if (vehicle.hasOxygen == true ||
                vehicle.hasVentilator == true ||
                vehicle.hasDefibrillator == true)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  [
                    if (vehicle.hasOxygen == true) 'O₂',
                    if (vehicle.hasVentilator == true) 'Ventilator',
                    if (vehicle.hasDefibrillator == true) 'Defibrillator',
                    if (vehicle.hasStretcher == true) 'Stretcher',
                    if (vehicle.hasAed == true) 'AED',
                  ].join(' • '),
                  style: AppTextStyles.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DriverDetailCard extends StatelessWidget {
  const _DriverDetailCard({required this.driver});
  final AmbulanceDriverModel driver;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              driver.fullName,
              style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'DL: ${driver.drivingLicenseNumber} • ${driver.mobileNumber}',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            if (driver.emtCertificationNumber.isNotEmpty)
              Text(
                'EMT: ${driver.emtCertificationNumber}',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
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
  const _ActionBar({
    required this.ambulanceId,
    required this.state,
    required this.documents,
  });
  final String ambulanceId;
  final AmbulanceDetailsState state;
  final List<DoctorDocumentModel> documents;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = state.ambulance?.verificationStatus;
    final canAct = (status == VerificationStatus.pending ||
            status == VerificationStatus.underReview) &&
        allDocumentsVerified(documents);

    if (status == VerificationStatus.verified ||
        status == VerificationStatus.rejected) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: AppColors.white,
        child: SafeArea(
          top: false,
          child: Text(
            status == VerificationStatus.verified
                ? 'This application is already approved.'
                : 'This application was rejected.',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (!canAct) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: AppColors.white,
        child: SafeArea(
          top: false,
          child: InfoCard(
            icon: Icons.info_outline_rounded,
            title: 'All documents must be verified',
            subtitle:
                'Verify each uploaded document before approving this ambulance service.',
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
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
        child: CustomButton(
          label: 'Verify & publish',
          icon: Icons.verified_rounded,
          onPressed: () => _approve(context, ref),
        ),
      ),
    );
  }

  Future<void> _approve(BuildContext context, WidgetRef ref) async {
    final ok = await ref
        .read(ambulanceDetailsProvider(ambulanceId).notifier)
        .approveAmbulance(ambulanceId: ambulanceId);
    if (context.mounted) {
      if (ok) {
        SnackBarHelper.showSuccess(context, 'Ambulance approved');
        context.pop();
      } else {
        SnackBarHelper.showError(context, 'Approval failed');
      }
    }
  }

}
