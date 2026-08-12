import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../data/models/api_response_model.dart';
import '../../../../data/services/dio_service.dart';
import '../../../../shared/widgets/admin_adaptive_shell.dart';

/// Admin sessions for Lab / MRI (scan) bookings.
class AdminDiagnosticSessionsScreen extends StatefulWidget {
  const AdminDiagnosticSessionsScreen({
    super.key,
    required this.kind,
    this.embedded = false,
    this.scrollHeader,
  });

  /// `lab` | `scan`
  final String kind;

  /// When true, renders list content only (no Scaffold / AppBar).
  final bool embedded;

  /// Optional hub header that scrolls away with the list (not sticky).
  final Widget? scrollHeader;

  @override
  State<AdminDiagnosticSessionsScreen> createState() =>
      _AdminDiagnosticSessionsScreenState();
}

class _AdminDiagnosticSessionsScreenState
    extends State<AdminDiagnosticSessionsScreen> {
  final _search = TextEditingController();
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  String? _error;

  bool get _isLab => widget.kind != 'scan';

  String get _title =>
      _isLab ? 'Diagnostic lab sessions' : 'MRI / scan sessions';

  String get _providerLabel => _isLab ? 'Lab' : 'Scan center';

  String get _sampleLabel =>
      _isLab ? 'Sample collected' : 'Scan performed';

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
        AppConstants.endpointAdminDiagnosticBookings,
        queryParameters: {
          'kind': _isLab ? 'lab' : 'scan',
          'pageSize': 100,
          if (_search.text.trim().isNotEmpty) 'q': _search.text.trim(),
        },
      );
      final body = response.data as Map<String, dynamic>;
      final list = extractApiList(body['data']);
      setState(() {
        _rows =
            list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
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

  Color _flagColor(bool ok) => ok ? AppColors.success : AppColors.textSecondary;

  Widget _searchField({required bool embedded}) {
    return Padding(
      padding: embedded
          ? const EdgeInsets.fromLTRB(16, 8, 16, 8)
          : const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: _search,
        decoration: InputDecoration(
          hintText: 'Search patient, mobile, $_providerLabel…',
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
    );
  }

  Widget _kycAppsButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: () => context.push(
            _isLab
                ? AppConstants.routeAdminLabList
                : AppConstants.routeAdminScanList,
          ),
          child: const Text('KYC apps'),
        ),
      ),
    );
  }

  Widget _sessionCard(Map<String, dynamic> row) {
    final outcome = row['finalOutcome']?.toString() ?? 'pending';
    final sample = row['sampleCollected'] == true;
    final report = row['reportSubmitted'] == true;
    final accepted = row['acceptedByUser'] == true;
    final kind = _isLab ? 'lab' : 'scan';
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push(
          '${AppConstants.routeAdminDiagnosticSessionDetails}/$kind/${row['id']}',
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _NameCol(
                      label: 'Patient',
                      value: row['patientName']?.toString() ?? 'Patient',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _NameCol(
                      label: _providerLabel,
                      value: row['providerName']?.toString() ?? _providerLabel,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                row['serviceLabel']?.toString() ?? '',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Pill(label: 'Pay: ${row['paymentStatus'] ?? '—'}'),
                  _Pill(
                    label: sample
                        ? '$_sampleLabel: ${_fmt(row['sampleCollectedAt'])}'
                        : '$_sampleLabel: No',
                    color: _flagColor(sample),
                  ),
                  _Pill(
                    label: report
                        ? 'Report submitted: ${_fmt(row['reportSubmittedAt'])}'
                        : 'Report submitted: No',
                    color: _flagColor(report),
                  ),
                  _Pill(
                    label: accepted
                        ? 'Accepted by user: ${_fmt(row['reportAcceptedByUserAt'])}'
                        : 'Accepted by user: No',
                    color: _flagColor(accepted),
                  ),
                  _Pill(
                    label: _outcomeLabel(outcome),
                    color: _outcomeColor(outcome),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Slot ${_fmt(row['scheduledDate'])} ${row['timeSlot'] ?? ''} · ₹${row['amount'] ?? 0} · Tap for details',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _embeddedScrollBody() {
    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (widget.scrollHeader != null)
            SliverToBoxAdapter(child: widget.scrollHeader),
          SliverToBoxAdapter(child: _searchField(embedded: true)),
          SliverToBoxAdapter(child: _kycAppsButton()),
          if (_loading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
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
              ),
            )
          else if (_rows.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  'No ${_title.toLowerCase()} yet',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            ResponsiveCardSliver(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
              spacing: 8,
              itemCount: _rows.length,
              itemBuilder: (context, index) => _sessionCard(_rows[index]),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return ColoredBox(
        color: AppColors.background,
        child: _embeddedScrollBody(),
      );
    }

    final content = Column(
      children: [
        _searchField(embedded: false),
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
                          child: ResponsiveCardList(
                            padding: const EdgeInsets.only(bottom: 24),
                            spacing: 8,
                            desktopColumns: 2,
                            largeDesktopColumns: 2,
                            itemCount: _rows.length,
                            itemBuilder: (context, index) =>
                                _sessionCard(_rows[index]),
                          ),
                        ),
        ),
      ],
    );

    return AdminAdaptiveShell(
      section: AdminNavSection.providers,
      constrainBody: false,
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_title),
        actions: [
          TextButton(
            onPressed: () => context.push(
              _isLab
                  ? AppConstants.routeAdminLabList
                  : AppConstants.routeAdminScanList,
            ),
            child: const Text('KYC apps'),
          ),
        ],
      ),
      body: ResponsivePage(
        padding: ResponsiveUtils.pagePadding(context),
        child: content,
      ),
    );
  }
}

class _NameCol extends StatelessWidget {
  const _NameCol({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
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
            color: AppColors.primary,
            decoration: TextDecoration.underline,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
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
