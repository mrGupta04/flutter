import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/services/dio_service.dart';

class ProviderEarningsScreen extends ConsumerStatefulWidget {
  const ProviderEarningsScreen({
    super.key,
    required this.role,
  });

  /// `doctor` or `nurse`
  final String role;

  @override
  ConsumerState<ProviderEarningsScreen> createState() =>
      _ProviderEarningsScreenState();
}

class _ProviderEarningsScreenState extends ConsumerState<ProviderEarningsScreen> {
  Map<String, dynamic>? _summary;
  List<Map<String, dynamic>> _bookings = [];
  bool _loading = true;
  String? _error;
  DateTimeRange? _range;

  String get _endpoint => widget.role == 'nurse'
      ? AppConstants.endpointNurseEarnings
      : AppConstants.endpointDoctorEarnings;

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
        _endpoint,
        queryParameters: {
          if (_range != null) 'from': _range!.start.toUtc().toIso8601String(),
          if (_range != null) 'to': _range!.end.toUtc().toIso8601String(),
        },
      );
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      setState(() {
        _summary = data['summary'] as Map<String, dynamic>? ?? {};
        _bookings = (data['bookings'] as List<dynamic>? ?? [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _loading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _error = e.response?.data is Map
            ? ((e.response!.data as Map)['error'] ?? e.message).toString()
            : e.message;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange: _range ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          ),
    );
    if (picked != null) {
      setState(() => _range = picked);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final dateFmt = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings'),
        actions: [
          IconButton(
            tooltip: 'Filter dates',
            onPressed: _pickRange,
            icon: const Icon(Icons.date_range),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _stat(
                            'Collected',
                            currency.format(_summary?['collected'] ?? 0),
                          ),
                          _stat(
                            'Pending settlement',
                            currency.format(_summary?['pendingSettlement'] ?? 0),
                          ),
                          _stat(
                            'Refunded',
                            currency.format(_summary?['refunded'] ?? 0),
                          ),
                          _stat(
                            'Bookings',
                            '${_summary?['bookingCount'] ?? 0}',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Recent paid bookings',
                        style: AppTextStyles.titleSmall.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_bookings.isEmpty)
                        Text(
                          'No paid bookings in this range',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        )
                      else
                        ..._bookings.map((b) {
                          final paidAt = b['paidAt'] != null
                              ? DateTime.tryParse(b['paidAt'].toString())
                              : null;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(b['patientName']?.toString() ?? 'Patient'),
                              subtitle: Text(
                                [
                                  b['consultationType']?.toString() ?? '',
                                  if (paidAt != null) dateFmt.format(paidAt.toLocal()),
                                  b['paymentStatus']?.toString() ?? '',
                                ].where((e) => e.isNotEmpty).join(' · '),
                              ),
                              trailing: Text(
                                currency.format(b['amountPaid'] ?? 0),
                                style: AppTextStyles.labelLarge.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
    );
  }

  Widget _stat(String label, String value) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
