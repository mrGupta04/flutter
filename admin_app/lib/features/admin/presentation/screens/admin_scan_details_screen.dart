import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/models/doctor_model.dart';
import '../../../../shared/widgets/shimmer_widgets.dart';
import '../../provider/admin_scan_provider.dart';

class AdminScanDetailsScreen extends ConsumerWidget {
  const AdminScanDetailsScreen({super.key, required this.scanCenterId});

  final String scanCenterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scanCenterDetailsProvider(scanCenterId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify scan center application'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _buildBody(context, ref, state),
      bottomNavigationBar: state.center != null && !state.isLoading
          ? _ActionBar(scanCenterId: scanCenterId, state: state)
          : null,
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    ScanCenterDetailsState state,
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
            .read(scanCenterDetailsProvider(scanCenterId).notifier)
            .fetchScanCenterDetails(scanCenterId),
      );
    }

    final center = state.center;
    if (center == null) {
      return const EmptyStateWidget(
        icon: Icons.radar_outlined,
        title: 'Scan center not found',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            center.centerName ?? 'Scan center',
            style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w800),
          ),
          if (center.documentRequestNote != null &&
              center.documentRequestNote!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.offerLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Document request: ${center.documentRequestNote}',
                style: AppTextStyles.bodySmall,
              ),
            ),
          ],
          const SizedBox(height: 20),
          _DetailRow('Owner', center.ownerName ?? '-'),
          _DetailRow('Email', center.email ?? '-'),
          _DetailRow('Mobile', center.mobileNumber ?? '-'),
          _DetailRow('License', center.licenseNumber ?? '-'),
          _DetailRow('GST', center.gstNumber ?? '-'),
          _DetailRow('Address', center.address ?? '-'),
          _DetailRow('City', center.city ?? '-'),
          _DetailRow('Operating hours', center.operatingHours ?? '-'),
          _DetailRow(
            'Home visit',
            center.homeVisitAvailable == true ? 'Yes' : 'No',
          ),
          _DetailRow('24×7', center.available24x7 == true ? 'Yes' : 'No'),
          _DetailRow('Scans offered', '${center.offeredScans?.length ?? 0}'),
          _DetailRow('Offers', '${center.offers?.length ?? 0}'),
          _DetailRow('Documents', '${center.documents?.length ?? 0}'),
          _DetailRow('Center images', '${center.centerImages?.length ?? 0}'),
          if (center.offeredScans != null && center.offeredScans!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Offered scans',
              style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ...center.offeredScans!.take(10).map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '• ${s.scanName} — ₹${s.discountedPriceInr ?? s.priceInr}',
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                ),
            if (center.offeredScans!.length > 10)
              Text(
                '+ ${center.offeredScans!.length - 10} more',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
          ],
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
  const _ActionBar({required this.scanCenterId, required this.state});

  final String scanCenterId;
  final ScanCenterDetailsState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final center = state.center!;
    final canModerate =
        center.verificationStatus != VerificationStatus.verified ||
            center.isApproved != true;

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
            if (canModerate)
              CustomButton(
                label: 'Approve scan center',
                icon: Icons.verified_rounded,
                isLoading: state.isApproving,
                onPressed: () async {
                  final ok = await ref
                      .read(scanCenterDetailsProvider(scanCenterId).notifier)
                      .approveScanCenter(scanCenterId: scanCenterId);
                  if (context.mounted && ok) {
                    SnackBarHelper.showSuccess(context, 'Scan center approved');
                    context.pop();
                  }
                },
              ),
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

  Future<void> _showRejectDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject scan center'),
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
        .read(scanCenterDetailsProvider(scanCenterId).notifier)
        .rejectScanCenter(scanCenterId: scanCenterId, reason: reason);
    if (context.mounted && ok) {
      SnackBarHelper.showSuccess(context, 'Scan center rejected');
      context.pop();
    }
  }

  Future<void> _showSuspendDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Suspend scan center'),
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
        .read(scanCenterDetailsProvider(scanCenterId).notifier)
        .suspendScanCenter(
          scanCenterId: scanCenterId,
          reason: reason.isEmpty ? null : reason,
        );
    if (context.mounted && ok) {
      SnackBarHelper.showSuccess(context, 'Scan center suspended');
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
            labelText: 'Message to scan center',
            hintText: 'e.g. Please upload updated license certificate',
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
        .read(scanCenterDetailsProvider(scanCenterId).notifier)
        .requestDocuments(scanCenterId: scanCenterId, note: note);
    if (context.mounted && ok) {
      SnackBarHelper.showSuccess(context, 'Document request sent');
    }
  }
}
