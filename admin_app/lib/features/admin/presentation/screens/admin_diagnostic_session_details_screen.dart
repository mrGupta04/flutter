import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/services/dio_service.dart';

class AdminDiagnosticSessionDetailsScreen extends StatefulWidget {
  const AdminDiagnosticSessionDetailsScreen({
    super.key,
    required this.kind,
    required this.bookingId,
  });

  final String kind;
  final String bookingId;

  @override
  State<AdminDiagnosticSessionDetailsScreen> createState() =>
      _AdminDiagnosticSessionDetailsScreenState();
}

class _AdminDiagnosticSessionDetailsScreenState
    extends State<AdminDiagnosticSessionDetailsScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  bool get _isLab => widget.kind != 'scan';
  String get _providerLabel => _isLab ? 'Lab' : 'Scan center';
  String get _sampleLabel =>
      _isLab ? 'Sample collected' : 'Scan performed';

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
    try {
      final response = await DioService().get(
        AppConstants.endpointAdminDiagnosticBooking(
          _isLab ? 'lab' : 'scan',
          widget.bookingId,
        ),
      );
      final body = response.data as Map<String, dynamic>;
      setState(() {
        _data = Map<String, dynamic>.from(body['data'] as Map? ?? {});
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  String _fmt(dynamic value) {
    if (value == null || value.toString().isEmpty) return '—';
    final dt = DateTime.tryParse(value.toString())?.toLocal();
    if (dt == null) return value.toString();
    return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
  }

  String _yesNo(bool? value, dynamic at) =>
      value == true ? 'Yes · ${_fmt(at)}' : 'No';

  void _showProfile(String title, Map<String, dynamic> profile) {
    final entries = profile.entries
        .where((e) => e.value != null && e.value.toString().isNotEmpty)
        .toList();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Text(title, style: AppTextStyles.headlineSmall),
            const SizedBox(height: 12),
            ...entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 130,
                      child: Text(
                        e.key,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        e.value.toString(),
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final patient = data?['patient'] is Map
        ? Map<String, dynamic>.from(data!['patient'] as Map)
        : <String, dynamic>{};
    final provider = data?['provider'] is Map
        ? Map<String, dynamic>.from(data!['provider'] as Map)
        : <String, dynamic>{};
    final outcome = data?['finalOutcome']?.toString() ?? 'pending';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('$_providerLabel session details')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _load,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        'Final status: ${outcome.replaceAll('_', ' ')}',
                        style: AppTextStyles.titleSmall.copyWith(
                          fontWeight: FontWeight.w800,
                          color: outcome == 'successful'
                              ? AppColors.success
                              : outcome == 'defect'
                                  ? AppColors.error
                                  : AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _card([
                        ('Booking ID', data?['id']?.toString() ?? '—'),
                        (
                          'Service',
                          data?['serviceLabel']?.toString() ?? '—'
                        ),
                        (
                          'Payment status',
                          data?['paymentStatus']?.toString() ?? '—'
                        ),
                        (
                          'Booking status',
                          data?['bookingStatus']?.toString() ?? '—'
                        ),
                        ('Amount', '₹${data?['amount'] ?? 0}'),
                        ('Scheduled', _fmt(data?['scheduledDate'])),
                        ('Time slot', data?['timeSlot']?.toString() ?? '—'),
                        if (_isLab)
                          (
                            'Collection',
                            data?['collectionType']?.toString() ?? '—'
                          ),
                        (
                          _sampleLabel,
                          _yesNo(
                            data?['sampleCollected'] as bool?,
                            data?['sampleCollectedAt'],
                          ),
                        ),
                        (
                          'Report submitted',
                          _yesNo(
                            data?['reportSubmitted'] as bool?,
                            data?['reportSubmittedAt'],
                          ),
                        ),
                        (
                          'Accepted by user',
                          _yesNo(
                            data?['acceptedByUser'] as bool?,
                            data?['reportAcceptedByUserAt'],
                          ),
                        ),
                        (
                          'Report URL',
                          data?['reportUrl']?.toString() ?? '—'
                        ),
                      ]),
                      const SizedBox(height: 16),
                      Text(
                        'Profiles',
                        style: AppTextStyles.titleSmall
                            .copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        tileColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: AppColors.grey200),
                        ),
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: const Text('Patient profile'),
                        subtitle: Text(
                          patient['name']?.toString() ??
                              data?['patientName']?.toString() ??
                              'Patient',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showProfile('Patient profile', {
                          'Name': patient['name'] ?? data?['patientName'],
                          'Mobile':
                              patient['mobileNumber'] ?? data?['patientMobile'],
                          'Email': patient['email'] ?? data?['patientEmail'],
                          'City': patient['city'],
                          'State': patient['state'],
                          'Patient ID': patient['id'] ?? data?['patientId'],
                        }),
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        tileColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: AppColors.grey200),
                        ),
                        leading: CircleAvatar(
                          child: Icon(
                            _isLab ? Icons.biotech : Icons.radar,
                          ),
                        ),
                        title: Text('$_providerLabel profile'),
                        subtitle: Text(
                          provider['name']?.toString() ??
                              data?['providerName']?.toString() ??
                              _providerLabel,
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          final id = provider['id']?.toString() ??
                              data?['providerId']?.toString();
                          showModalBottomSheet<void>(
                            context: context,
                            showDragHandle: true,
                            builder: (context) => SafeArea(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    title: Text('View $_providerLabel summary'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _showProfile('$_providerLabel profile', {
                                        'Name': provider['name'] ??
                                            data?['providerName'],
                                        'Email': provider['email'],
                                        'Mobile': provider['mobileNumber'],
                                        'City': provider['city'],
                                        'State': provider['state'],
                                        'Verification':
                                            provider['verificationStatus'],
                                        'ID': id,
                                      });
                                    },
                                  ),
                                  if (id != null && id.isNotEmpty)
                                    ListTile(
                                      title: Text('Open full $_providerLabel page'),
                                      onTap: () {
                                        Navigator.pop(context);
                                        context.push(
                                          _isLab
                                              ? '${AppConstants.routeAdminLabDetails}/$id'
                                              : '${AppConstants.routeAdminScanDetails}/$id',
                                        );
                                      },
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _card(List<(String, String)> rows) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        children: [
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 140,
                    child: Text(
                      row.$1,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(row.$2, style: AppTextStyles.bodyMedium),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
