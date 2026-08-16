import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../shared/widgets/user_adaptive_scaffold.dart';
import '../../../../shared/widgets/user_app_footer.dart';
import '../../data/models/prescription_request_model.dart';
import '../../data/prescription_quote_payment_flow.dart';
import '../../provider/prescription_requests_provider.dart';

class PrescriptionRequestDetailScreen extends ConsumerStatefulWidget {
  const PrescriptionRequestDetailScreen({super.key, required this.requestId});

  final String requestId;

  @override
  ConsumerState<PrescriptionRequestDetailScreen> createState() =>
      _PrescriptionRequestDetailScreenState();
}

class _PrescriptionRequestDetailScreenState
    extends ConsumerState<PrescriptionRequestDetailScreen> {
  bool _paying = false;
  bool _selecting = false;
  String? _selectedQuotationId;

  Future<void> _refresh() async {
    ref.invalidate(prescriptionRequestDetailProvider(widget.requestId));
  }

  Future<void> _openPrescription(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _selectAndMaybePay(PrescriptionRequestModel request) async {
    final quotationId = _selectedQuotationId ?? request.selectedQuotationId;
    if (quotationId == null) {
      SnackBarHelper.showError(context, 'Select a lab quotation first.');
      return;
    }

    setState(() => _selecting = true);
    try {
      if (request.selectedQuotationId != quotationId) {
        final res = await ref
            .read(prescriptionRequestRepositoryProvider)
            .selectLab(requestId: request.id, quotationId: quotationId);
        if (!res.success) {
          throw Exception(res.error ?? 'Failed to select lab');
        }
      }
      await _refresh();
      if (!mounted) return;
      await _pay();
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(
        context,
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _selecting = false);
    }
  }

  Future<void> _pay() async {
    setState(() => _paying = true);
    final flow = PrescriptionQuotePaymentFlow();
    try {
      await flow.pay(requestId: widget.requestId);
      if (!mounted) return;
      SnackBarHelper.showSuccess(
        context,
        'Payment successful. Booking confirmed and chat enabled.',
      );
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(
        context,
        e.toString().replaceFirst('Exception: ', ''),
      );
      await _refresh();
    } finally {
      flow.dispose();
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(
      prescriptionRequestDetailProvider(widget.requestId),
    );

    return UserAdaptiveScaffold(
      currentTab: UserNavTab.labs,
      backgroundColor: AppColors.background,
      constrainBody: true,
      appBar: AppBar(
        title: const Text('Prescription request'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: _refresh,
        ),
        data: (request) {
          if (request == null) {
            return const Center(child: Text('Request not found'));
          }
          final quoted = request.activeQuotations;
          final cheapestId = request.cheapestQuoted?.id;
          final selectedId = _selectedQuotationId ??
              request.selectedQuotationId ??
              cheapestId;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                Text(
                  'Prescription #${request.id.length > 8 ? request.id.substring(0, 8) : request.id}',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Status: ${request.status.replaceAll('_', ' ')} · Payment: ${request.paymentStatus}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.description_rounded),
                  title: const Text('View prescription'),
                  subtitle: Text(request.prescriptionFileName ??
                      request.prescriptionFileType.toUpperCase()),
                  trailing: const Icon(Icons.open_in_new_rounded),
                  onTap: () => _openPrescription(request.prescriptionFileUrl),
                ),
                if (request.requestedTests.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Requested tests', style: AppTextStyles.titleSmall),
                  const SizedBox(height: 6),
                  ...request.requestedTests.map(
                    (t) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• ${t.name}'),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Text('Quotation comparison', style: AppTextStyles.titleSmall),
                const SizedBox(height: 8),
                if (quoted.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      'No quotations have been received yet.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                else
                  ...quoted.map((q) {
                    final isCheapest = q.id == cheapestId;
                    final selected = (selectedId ?? '') == q.id;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : (isCheapest
                                  ? AppColors.success
                                  : AppColors.border),
                          width: selected || isCheapest ? 1.5 : 1,
                        ),
                      ),
                      child: RadioListTile<String>(
                        value: q.id,
                        groupValue: selectedId,
                        onChanged: request.paymentStatus == 'PAID'
                            ? null
                            : (v) => setState(() => _selectedQuotationId = v),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                q.labName,
                                style: AppTextStyles.titleSmall,
                              ),
                            ),
                            if (isCheapest)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Lowest',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            [
                              '₹${(q.quotedAmount ?? 0).toStringAsFixed(0)}',
                              if (q.rating != null)
                                '⭐ ${q.rating!.toStringAsFixed(1)}',
                              if (q.distanceKm != null)
                                '${q.distanceKm!.toStringAsFixed(1)} km',
                              if (q.estimatedCompletionTime != null)
                                q.estimatedCompletionTime!,
                            ].join(' · '),
                          ),
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 16),
                if (request.paymentStatus != 'PAID') ...[
                  ElevatedButton(
                    onPressed: (_paying || _selecting || quoted.isEmpty)
                        ? null
                        : () => _selectAndMaybePay(request),
                    child: Text(
                      _paying || _selecting
                          ? 'Processing...'
                          : 'Select lab & Pay Now',
                    ),
                  ),
                  if (request.canPay && request.selectedQuotationId != null) ...[
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: _paying ? null : _pay,
                      child: const Text('Retry payment'),
                    ),
                  ],
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Booking confirmed. Chat with the selected lab is now available.',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: request.canChat
                        ? () => context.push(
                              '${AppConstants.routeBookingChat}?bookingId=${request.id}&title=${Uri.encodeComponent('Lab chat')}&chatPath=${Uri.encodeComponent(AppConstants.endpointPrescriptionChat(request.id))}',
                            )
                        : null,
                    icon: const Icon(Icons.chat_rounded),
                    label: const Text('Open chat'),
                  ),
                ],
                if (!request.canChat && request.paymentStatus != 'PAID') ...[
                  const SizedBox(height: 12),
                  Text(
                    'Chat will be available after payment confirmation.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}