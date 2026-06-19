import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/models/doctor_model.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../../../shared/widgets/shimmer_widgets.dart';
import '../../provider/admin_blood_bank_provider.dart';

class AdminBloodBankDetailsScreen extends ConsumerWidget {
  const AdminBloodBankDetailsScreen({super.key, required this.bloodBankId});

  final String bloodBankId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bloodBankDetailsProvider(bloodBankId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify blood bank application'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _buildBody(context, ref, state),
      bottomNavigationBar: state.bloodBank != null && !state.isLoading
          ? _ActionBar(bloodBankId: bloodBankId, state: state)
          : null,
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    BloodBankDetailsState state,
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
            .read(bloodBankDetailsProvider(bloodBankId).notifier)
            .fetchBloodBankDetails(bloodBankId),
      );
    }

    final bloodBank = state.bloodBank;
    if (bloodBank == null) {
      return const EmptyStateWidget(
        icon: Icons.bloodtype_outlined,
        title: 'Blood bank not found',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            bloodBank.institutionName ?? 'Blood bank',
            style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 20),
          _DetailRow('License', bloodBank.licenseNumber ?? '-'),
          _DetailRow('Contact person', bloodBank.contactPerson ?? '-'),
          _DetailRow('Email', bloodBank.email ?? '-'),
          _DetailRow('Mobile', bloodBank.mobileNumber ?? '-'),
          _DetailRow('Emergency', bloodBank.emergencyContact ?? '-'),
          _DetailRow('Address', bloodBank.address ?? '-'),
          _DetailRow('City', bloodBank.city ?? '-'),
          _DetailRow('State', bloodBank.state ?? '-'),
          _DetailRow('Pincode', bloodBank.pincode ?? '-'),
          _DetailRow(
            'Blood groups',
            (bloodBank.bloodGroupsAvailable ?? []).join(', '),
          ),
          _DetailRow('Apheresis', bloodBank.hasApheresis == true ? 'Yes' : 'No'),
          _DetailRow(
            'Component separation',
            bloodBank.hasComponentSeparation == true ? 'Yes' : 'No',
          ),
          _DetailRow('24x7', bloodBank.available24x7 == true ? 'Yes' : 'No'),
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
            child: Text(label,
                style: AppTextStyles.labelMedium
                    .copyWith(color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: AppTextStyles.bodyMedium
                    .copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _ActionBar extends ConsumerWidget {
  const _ActionBar({required this.bloodBankId, required this.state});
  final String bloodBankId;
  final BloodBankDetailsState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bloodBank = state.bloodBank!;
    final status = bloodBank.verificationStatus;
    final canApprove = status != VerificationStatus.verified &&
        status != VerificationStatus.rejected;

    if (!canApprove) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: InfoCard(
            icon: Icons.verified_rounded,
            title: status == VerificationStatus.verified
                ? 'Published on user app'
                : 'Application processed',
            subtitle: 'This application is no longer pending review.',
          ),
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomButton(
              label: 'Verify & publish',
              icon: Icons.verified_rounded,
              isLoading: state.isApproving,
              onPressed: () async {
                final ok = await ref
                    .read(bloodBankDetailsProvider(bloodBankId).notifier)
                    .approveBloodBank(bloodBankId: bloodBankId);
                if (context.mounted && ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Blood bank verified — now live on user app'),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 8),
            CustomOutlineButton(
              label: 'Reject',
              isLoading: state.isRejecting,
              onPressed: () => _showRejectDialog(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRejectDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject application'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Reason for rejection'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (reason == null || reason.isEmpty || !context.mounted) return;
    await ref.read(bloodBankDetailsProvider(bloodBankId).notifier).rejectBloodBank(
          bloodBankId: bloodBankId,
          reason: reason,
        );
  }
}
