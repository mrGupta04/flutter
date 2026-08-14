import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/repositories/lab_prescription_repository.dart';

class LabPrescriptionInboxScreen extends StatefulWidget {
  const LabPrescriptionInboxScreen({super.key});

  @override
  State<LabPrescriptionInboxScreen> createState() =>
      _LabPrescriptionInboxScreenState();
}

class _LabPrescriptionInboxScreenState
    extends State<LabPrescriptionInboxScreen> {
  final _repo = LabPrescriptionRepository();
  List<LabPrescriptionRequestItem> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await _repo.listInbox();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.success && res.data != null) {
        _items = res.data!;
      } else {
        _error = res.error ?? 'Failed to load';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Prescription requests'),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? AppErrorWidget(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _items.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 120),
                            Center(child: Text('No prescription requests yet.')),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            final quote = item.myQuotation;
                            return ListTile(
                              tileColor: AppColors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: AppColors.border),
                              ),
                              title: Text(
                                item.patientName ?? 'Patient',
                                style: AppTextStyles.titleSmall,
                              ),
                              subtitle: Text(
                                [
                                  item.status.replaceAll('_', ' '),
                                  if (quote?.quotedAmount != null)
                                    '₹${quote!.quotedAmount!.toStringAsFixed(0)}',
                                  quote?.status ?? 'PENDING',
                                  item.paymentStatus,
                                ].join(' · '),
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: () async {
                                await context.push(
                                  '${AppConstants.routeLabPrescriptionDetail}?id=${item.id}',
                                );
                                _load();
                              },
                            );
                          },
                        ),
                ),
    );
  }
}

class LabPrescriptionDetailScreen extends StatefulWidget {
  const LabPrescriptionDetailScreen({super.key, required this.requestId});

  final String requestId;

  @override
  State<LabPrescriptionDetailScreen> createState() =>
      _LabPrescriptionDetailScreenState();
}

class _LabPrescriptionDetailScreenState
    extends State<LabPrescriptionDetailScreen> {
  final _repo = LabPrescriptionRepository();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();
  final _etaController = TextEditingController();

  LabPrescriptionRequestItem? _item;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _priceController.dispose();
    _notesController.dispose();
    _etaController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await _repo.getById(widget.requestId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.success && res.data != null) {
        _item = res.data;
        final amount = res.data!.myQuotation?.quotedAmount;
        if (amount != null) {
          _priceController.text = amount.toStringAsFixed(0);
        }
        _notesController.text = res.data!.myQuotation?.labNotes ?? '';
        _etaController.text =
            res.data!.myQuotation?.estimatedCompletionTime ?? '';
      } else {
        _error = res.error ?? 'Failed to load';
      }
    });
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_priceController.text.trim());
    if (amount == null || amount <= 0) {
      SnackBarHelper.showError(context, 'Enter a valid total price.');
      return;
    }
    setState(() => _saving = true);
    final res = await _repo.submitQuote(
      requestId: widget.requestId,
      quotedAmount: amount,
      estimatedCompletionTime: _etaController.text.trim().isEmpty
          ? null
          : _etaController.text.trim(),
      labNotes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (!res.success) {
      SnackBarHelper.showError(context, res.error ?? 'Failed to submit');
      return;
    }
    SnackBarHelper.showSuccess(
      context,
      res.message ?? 'Quotation submitted',
    );
    await _load();
  }

  Future<void> _reject() async {
    setState(() => _saving = true);
    final res = await _repo.reject(
      requestId: widget.requestId,
      reason: 'Unable to provide service',
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (!res.success) {
      SnackBarHelper.showError(context, res.error ?? 'Failed to reject');
      return;
    }
    SnackBarHelper.showSuccess(context, 'Marked as unable to provide service');
    await _load();
  }

  Future<void> _openPrescription(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Prescription details'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? AppErrorWidget(message: _error!, onRetry: _load)
              : item == null
                  ? const Center(child: Text('Not found'))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                      children: [
                        Text(
                          'New Prescription Request',
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Patient: ${item.patientName ?? 'Patient'}'),
                        Text(
                          'Status: ${item.status} · Payment: ${item.paymentStatus}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.description_rounded),
                          title: const Text('View Prescription'),
                          subtitle: Text(
                            item.prescriptionFileName ??
                                item.prescriptionFileType.toUpperCase(),
                          ),
                          trailing: const Icon(Icons.open_in_new_rounded),
                          onTap: () =>
                              _openPrescription(item.prescriptionFileUrl),
                        ),
                        if (item.requestedTests.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text('Requested Tests',
                              style: AppTextStyles.titleSmall),
                          const SizedBox(height: 6),
                          ...item.requestedTests.map((t) => Text('• $t')),
                        ],
                        const SizedBox(height: 20),
                        if (item.paymentStatus == 'PAID') ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              item.canChat
                                  ? 'Selected and paid. Chat is available.'
                                  : 'Paid booking confirmed.',
                            ),
                          ),
                          if (item.canChat) ...[
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () => context.push(
                                '${AppConstants.routeProviderBookingChat}'
                                '?bookingId=${item.id}'
                                '&role=lab'
                                '&title=${Uri.encodeComponent(item.patientName ?? 'Patient')}'
                                '&chatPath=${Uri.encodeComponent(AppConstants.endpointLabPrescriptionChat(item.id))}',
                              ),
                              icon: const Icon(Icons.chat_rounded),
                              label: const Text('Chat with customer'),
                            ),
                          ],
                        ] else ...[
                          Text('Enter Price', style: AppTextStyles.titleSmall),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Total Price (₹)',
                              prefixText: '₹ ',
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _etaController,
                            decoration: const InputDecoration(
                              labelText: 'Estimated completion (optional)',
                              hintText: 'e.g. 24 hours',
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _notesController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Notes (optional)',
                              alignLabelWithHint: true,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _saving ? null : _submit,
                            child: Text(
                              _saving ? 'Submitting...' : 'Submit Quotation',
                            ),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton(
                            onPressed: _saving ? null : _reject,
                            child: const Text('Cannot provide service'),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Chat will be available after payment confirmation.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
    );
  }
}