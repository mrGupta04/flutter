import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/repositories/blood_bank_repository.dart';
import '../../data/blood_bank_catalog.dart';

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
    'submitted',
    'document_verification',
    'availability_check',
    'approved',
    'blood_reserved',
    'ready_for_collection',
    'completed',
  ];

  static const _stepLabels = {
    'submitted': 'Request Submitted',
    'document_verification': 'Documents Verified',
    'availability_check': 'Blood Availability Confirmed',
    'approved': 'Request Approved',
    'blood_reserved': 'Blood Reserved',
    'ready_for_collection': 'Ready for Collection',
    'completed': 'Completed',
  };

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
      _error = res.success ? null : (res.error ?? 'Unable to load this request.');
      _data = res.data;
    });
  }

  String get _status => (_data?['status'] as String?) ?? 'submitted';

  bool get _isClosed =>
      ['cancelled', 'completed', 'rejected', 'expired', 'collected', 'delivered']
          .contains(_status);

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

  Future<void> _confirmCollection() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm collection?'),
        content: const Text('Confirm only after the blood bank has issued the reserved units.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Not yet')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm')),
        ],
      ),
    );
    if (ok != true) return;
    final res = await _repo.confirmCollection(widget.requestId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res.error ?? res.message ?? 'Collection confirmed')),
    );
    _load();
  }

  Future<void> _call(String? number) async {
    if (number == null || number.isEmpty) return;
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _directions(Map<String, dynamic>? bank) async {
    final lat = (bank?['latitude'] as num?)?.toDouble();
    final lng = (bank?['longitude'] as num?)?.toDouble();
    if (lat == null || lng == null) return;
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  int _stepIndex(String status) {
    if (['collected', 'delivered', 'completed'].contains(status)) return _steps.length - 1;
    if (status == 'blood_bank_notified' || status == 'pending') return 0;
    if (status == 'under_review') return 1;
    if (status == 'partially_available' || status == 'accepted') return 3;
    final index = _steps.indexOf(status);
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final reservation = (_data?['reservation'] as Map?)?.cast<String, dynamic>();
    final documents = (_data?['documents'] as List?) ?? const [];
    final currentIndex = _stepIndex(_status);
    final bank = (_data?['bloodBank'] as Map?)?.cast<String, dynamic>();

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
                        widget.requestId,
                        style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_data?['patientName'] ?? 'Patient'} · ${_data?['bloodGroup'] ?? ''} · ${bloodComponentLabel(_data?['componentType'] as String?)}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                      ),
                      const SizedBox(height: 6),
                      Text('${_data?['units'] ?? ''} units · ${_data?['hospitalName'] ?? ''}'),
                      const SizedBox(height: 6),
                      Chip(label: Text(_status.replaceAll('_', ' '))),
                      if (_data?['urgency'] == 'emergency' || _data?['isEmergency'] == true)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'Emergency request. Contact the blood bank directly if you need immediate confirmation.',
                            style: TextStyle(color: Color(0xFFB71C1C)),
                          ),
                        ),
                      if (reservation != null) ...[
                        const SizedBox(height: 16),
                        Card(
                          color: const Color(0xFFE8F5E9),
                          child: ListTile(
                            title: const Text('Blood Reserved', style: TextStyle(fontWeight: FontWeight.w800)),
                            subtitle: Text(
                              'Reservation ID: ${reservation['id'] ?? _data?['reservationId'] ?? '-'}\n'
                              '${_data?['bloodGroup']} ${bloodComponentLabel(_data?['componentType'] as String?)}\n'
                              '${reservation['quantity'] ?? _data?['approvedUnits'] ?? _data?['units']} units\n'
                              'Reserved until: ${reservation['expiresAt'] ?? _data?['reservationExpiresAt'] ?? '-'}',
                            ),
                            isThreeLine: true,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      const Text('Timeline', style: TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      ..._steps.asMap().entries.map((entry) {
                        final done = currentIndex > entry.key ||
                            ['completed', 'collected', 'delivered'].contains(_status);
                        final active = currentIndex == entry.key;
                        return ListTile(
                          dense: true,
                          leading: Icon(
                            done
                                ? Icons.check_circle
                                : active
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                            color: done || active ? AppColors.success : AppColors.grey400,
                          ),
                          title: Text(_stepLabels[entry.value] ?? entry.value.replaceAll('_', ' ')),
                        );
                      }),
                      if (documents.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text('Documents', style: TextStyle(fontWeight: FontWeight.w800)),
                        ...documents.map((doc) {
                          final item = Map<String, dynamic>.from(doc as Map);
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.attach_file_rounded),
                            title: Text(item['name'] as String? ?? 'Document'),
                            subtitle: Text(item['type'] as String? ?? ''),
                          );
                        }),
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
                      OutlinedButton.icon(
                        onPressed: () => _call(
                          (_data?['bloodBankPhone'] ?? bank?['mobileNumber'] ?? bank?['emergencyContact'])
                              as String?,
                        ),
                        icon: const Icon(Icons.call_outlined),
                        label: const Text('Contact blood bank'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => _directions(bank),
                        icon: const Icon(Icons.directions_outlined),
                        label: const Text('View directions'),
                      ),
                      if (['ready_for_collection', 'blood_ready'].contains(_status)) ...[
                        const SizedBox(height: 8),
                        FilledButton(
                          onPressed: _confirmCollection,
                          child: const Text('Confirm collection'),
                        ),
                      ],
                      if (!_isClosed) ...[
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: _cancel,
                          child: const Text('Cancel request'),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }
}
