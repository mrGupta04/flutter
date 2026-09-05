import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/repositories/blood_bank_repository.dart';

class BloodRequestDetailScreen extends StatefulWidget {
  const BloodRequestDetailScreen({super.key, required this.requestId});

  final String requestId;

  @override
  State<BloodRequestDetailScreen> createState() => _BloodRequestDetailScreenState();
}

class _BloodRequestDetailScreenState extends State<BloodRequestDetailScreen> {
  final _repo = BloodBankRepository();
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;

  static const _steps = [
    'pending',
    'blood_bank_notified',
    'under_review',
    'accepted',
    'blood_reserved',
    'ready_for_collection',
    'collected',
    'completed',
  ];

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
    final res = await _repo.getRequestDetails(widget.requestId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = res.success ? null : res.error;
      _data = res.data;
    });
  }

  Future<void> _cancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel request?'),
        content: const Text('This will release any reserved units if a reservation exists.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Cancel request')),
        ],
      ),
    );
    if (ok != true) return;
    final res = await _repo.cancelRequest(widget.requestId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res.message ?? res.error ?? 'Updated')),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final status = (_data?['status'] as String?) ?? 'pending';
    final history = (_data?['statusHistory'] as List?) ?? const [];
    final currentIndex = _steps.indexOf(status);

    return Scaffold(
      appBar: AppBar(title: const Text('Request details')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? AppErrorWidget(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    children: [
                      Text(
                        '${_data?['bloodGroup'] ?? ''} · ${_data?['componentType'] ?? ''} · ${_data?['units'] ?? ''} units',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                      ),
                      const SizedBox(height: 6),
                      Text(_data?['hospitalName'] ?? ''),
                      const SizedBox(height: 6),
                      Chip(label: Text(status.replaceAll('_', ' '))),
                      const SizedBox(height: 20),
                      const Text('Timeline', style: TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      ..._steps.asMap().entries.map((entry) {
                        final done = currentIndex >= entry.key ||
                            ['completed', 'collected', 'delivered'].contains(status);
                        final active = entry.value == status;
                        return ListTile(
                          dense: true,
                          leading: Icon(
                            done || active ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: done || active ? AppColors.success : AppColors.grey400,
                          ),
                          title: Text(entry.value.replaceAll('_', ' ')),
                        );
                      }),
                      if (history.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Updates: ${history.length}',
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                      const SizedBox(height: 20),
                      if (_data?['chatEnabled'] == true)
                        FilledButton.icon(
                          onPressed: () => context.push(
                            '${AppConstants.routeBookingChat}?bookingId=${widget.requestId}&title=Blood%20bank&chatPath=/blood-bank/bookings/${widget.requestId}/chat',
                          ),
                          icon: const Icon(Icons.chat_outlined),
                          label: const Text('Chat with blood bank'),
                        ),
                      const SizedBox(height: 8),
                      if (!['cancelled', 'completed', 'rejected', 'expired'].contains(status))
                        OutlinedButton(
                          onPressed: _cancel,
                          child: const Text('Cancel request'),
                        ),
                    ],
                  ),
                ),
    );
  }
}
