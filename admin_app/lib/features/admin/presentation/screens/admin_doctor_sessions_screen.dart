import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/api_response_model.dart';
import '../../../../data/services/dio_service.dart';

/// Row-based admin view of consultation bookings by provider/service.
class AdminDoctorSessionsScreen extends StatefulWidget {
  const AdminDoctorSessionsScreen({
    super.key,
    required this.serviceType,
    this.providerType = 'doctor',
  });

  /// `online` | `home_visit` | `hospital_visit`
  final String serviceType;

  /// `doctor` | `nurse`
  final String providerType;

  @override
  State<AdminDoctorSessionsScreen> createState() =>
      _AdminDoctorSessionsScreenState();
}

class _AdminDoctorSessionsScreenState extends State<AdminDoctorSessionsScreen> {
  final _search = TextEditingController();
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  String? _error;

  bool get _isNurse => widget.providerType == 'nurse';

  String get _consultationType {
    if (_isNurse) return 'book_home';
    switch (widget.serviceType) {
      case 'home_visit':
        return 'book_home';
      case 'hospital_visit':
        return 'visit_site';
      default:
        return 'online_consult';
    }
  }

  String get _title {
    if (_isNurse) return 'Nurse home visit sessions';
    switch (widget.serviceType) {
      case 'home_visit':
        return 'Home visit sessions';
      case 'hospital_visit':
        return 'Hospital visit sessions';
      default:
        return 'Online doctor sessions';
    }
  }

  String get _providerLabel => _isNurse ? 'Nurse' : 'Doctor';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await DioService().get(
        AppConstants.endpointAdminConsultationBookings,
        queryParameters: {
          'providerType': widget.providerType,
          'consultationType': _consultationType,
          'pageSize': 100,
          if (_search.text.trim().isNotEmpty) 'q': _search.text.trim(),
        },
      );
      final body = response.data as Map<String, dynamic>;
      final list = extractApiList(body['data']);
      setState(() {
        _rows = list
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
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
    return DateFormat('dd MMM, hh:mm a').format(dt);
  }

  Color _outcomeColor(String outcome) {
    switch (outcome) {
      case 'successful':
        return AppColors.success;
      case 'defect':
        return AppColors.error;
      case 'cancelled':
      case 'refunded':
        return AppColors.warning;
      case 'in_progress':
        return AppColors.primary;
      default:
        return AppColors.textSecondary;
    }
  }

  String _outcomeLabel(String outcome) {
    switch (outcome) {
      case 'successful':
        return 'Successful';
      case 'defect':
        return 'Defect';
      case 'cancelled':
        return 'Cancelled';
      case 'refunded':
        return 'Refunded';
      case 'in_progress':
        return 'In progress';
      default:
        return outcome.replaceAll('_', ' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_title),
        actions: [
          TextButton(
            onPressed: () => context.push(
              _isNurse
                  ? AppConstants.routeAdminNurseList
                  : '${AppConstants.routeAdminDoctorList}?service=${widget.serviceType}',
            ),
            child: const Text('KYC apps'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: 'Search patient, mobile, doctor id…',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _load,
                ),
                filled: true,
                fillColor: AppColors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (_) => _load(),
            ),
          ),
          Expanded(
            child: _loading
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
                    : _rows.isEmpty
                        ? Center(
                            child: Text(
                              'No ${_title.toLowerCase()} yet',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                              itemCount: _rows.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final row = _rows[index];
                                final outcome =
                                    row['finalOutcome']?.toString() ?? 'pending';
                                return Material(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: () => context.push(
                                      '${AppConstants.routeAdminDoctorSessionDetails}/${row['id']}',
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _ClickableName(
                                                  label: 'Patient',
                                                  value: row['patientName']
                                                          ?.toString() ??
                                                      'Patient',
                                                  onTap: () => context.push(
                                                    '${AppConstants.routeAdminDoctorSessionDetails}/${row['id']}',
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: _ClickableName(
                                                  label: _providerLabel,
                                                  value: row['providerName']
                                                          ?.toString() ??
                                                      row['doctorName']
                                                          ?.toString() ??
                                                      _providerLabel,
                                                  onTap: () => context.push(
                                                    '${AppConstants.routeAdminDoctorSessionDetails}/${row['id']}',
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: [
                                              _Pill(
                                                label:
                                                    'Pay: ${row['paymentStatus'] ?? '—'}',
                                              ),
                                              _Pill(
                                                label:
                                                    '${row['doctorActionLabel'] ?? 'Doctor'}: ${_fmt(row['doctorActionAt'])}',
                                              ),
                                              _Pill(
                                                label:
                                                    '${row['patientActionLabel'] ?? 'Patient'}: ${_fmt(row['patientActionAt'])}',
                                              ),
                                              if ((_isNurse ||
                                                      widget.serviceType ==
                                                          'home_visit') &&
                                                  row['visitProgress'] != null)
                                                _Pill(
                                                  label:
                                                      'Progress: ${row['visitProgress']}',
                                                ),
                                              if (!_isNurse &&
                                                  widget.serviceType ==
                                                      'hospital_visit')
                                                _Pill(
                                                  label: row['appointmentVerifiedAt'] !=
                                                          null
                                                      ? 'Checked in'
                                                      : 'Not checked in',
                                                ),
                                              _Pill(
                                                label: _outcomeLabel(outcome),
                                                color: _outcomeColor(outcome),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            [
                                              'Slot ${_fmt(row['slotStart'])}',
                                              if (row['amount'] != null)
                                                '₹${row['amount']}',
                                              if ((_isNurse ||
                                                      widget.serviceType ==
                                                          'home_visit') &&
                                                  (row['patientAddress']
                                                          ?.toString()
                                                          .isNotEmpty ??
                                                      false))
                                                row['patientAddress']
                                                    .toString(),
                                              if (!_isNurse &&
                                                  widget.serviceType ==
                                                      'hospital_visit' &&
                                                  (row['clinicName']
                                                          ?.toString()
                                                          .isNotEmpty ??
                                                      false))
                                                row['clinicName'].toString(),
                                              'Tap for full details',
                                            ].join(' · '),
                                            style: AppTextStyles.bodySmall
                                                .copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _ClickableName extends StatelessWidget {
  const _ClickableName({
    required this.label,
    required this.value,
    this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              value,
              style: AppTextStyles.titleSmall.copyWith(
                color: onTap != null ? AppColors.primary : AppColors.textPrimary,
                decoration:
                    onTap != null ? TextDecoration.underline : null,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: c,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
