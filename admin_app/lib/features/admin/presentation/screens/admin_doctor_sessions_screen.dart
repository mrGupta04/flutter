import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/widgets/accidental_selection_binder.dart';
import '../../../../data/models/api_response_model.dart';
import '../../../../data/services/dio_service.dart';
import '../../../../shared/widgets/admin_adaptive_shell.dart';

/// Row-based admin view of consultation bookings by provider/service.
class AdminDoctorSessionsScreen extends StatefulWidget {
  const AdminDoctorSessionsScreen({
    super.key,
    required this.serviceType,
    this.providerType = 'doctor',
    this.embedded = false,
    this.scrollHeader,
  });

  /// `online` | `home_visit` | `hospital_visit`
  final String serviceType;

  /// `doctor` | `nurse`
  final String providerType;

  /// When true, renders list content only (no Scaffold / AppBar).
  final bool embedded;

  /// Optional hub header that scrolls away with the list (not sticky).
  final Widget? scrollHeader;

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
      case 'pending':
        return 'Pending';
      default:
        return outcome.replaceAll('_', ' ');
    }
  }

  Color _paymentColor(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'paid':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'failed':
        return AppColors.error;
      case 'refunded':
        return AppColors.offer;
      default:
        return AppColors.textSecondary;
    }
  }

  String _paymentLabel(String? status) {
    final value = (status ?? '—').trim();
    if (value.isEmpty || value == '—') return 'Pay: —';
    return 'Pay: ${value.replaceAll('_', ' ')}';
  }

  /// Green when the timestamp exists; muted grey when not joined yet.
  Color _joinColor(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return AppColors.textSecondary;
    }
    return AppColors.success;
  }

  Widget _searchField({required bool embedded}) {
    return Padding(
      padding: embedded
          ? const EdgeInsets.fromLTRB(16, 8, 16, 8)
          : const EdgeInsets.only(bottom: 8),
      child: CaretOnTapTextField(
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
    );
  }

  Widget _kycAppsButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: () => context.push(
            _isNurse
                ? AppConstants.routeAdminNurseList
                : '${AppConstants.routeAdminDoctorList}?service=${widget.serviceType}',
          ),
          child: const Text('KYC apps'),
        ),
      ),
    );
  }

  Widget _sessionCard(Map<String, dynamic> row) {
    return _SessionCard(
      row: row,
      providerLabel: _providerLabel,
      isNurse: _isNurse,
      serviceType: widget.serviceType,
      outcomeLabel: _outcomeLabel,
      outcomeColor: _outcomeColor,
      paymentLabel: _paymentLabel,
      paymentColor: _paymentColor,
      joinColor: _joinColor,
      formatDate: _fmt,
      onTap: () => context.push(
        '${AppConstants.routeAdminDoctorSessionDetails}/${row['id']}',
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
              _isNurse
                  ? AppConstants.routeAdminNurseList
                  : '${AppConstants.routeAdminDoctorList}?service=${widget.serviceType}',
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

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.row,
    required this.providerLabel,
    required this.isNurse,
    required this.serviceType,
    required this.outcomeLabel,
    required this.outcomeColor,
    required this.paymentLabel,
    required this.paymentColor,
    required this.joinColor,
    required this.formatDate,
    required this.onTap,
  });

  final Map<String, dynamic> row;
  final String providerLabel;
  final bool isNurse;
  final String serviceType;
  final String Function(String) outcomeLabel;
  final Color Function(String) outcomeColor;
  final String Function(String?) paymentLabel;
  final Color Function(String?) paymentColor;
  final Color Function(dynamic) joinColor;
  final String Function(dynamic) formatDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final outcome = row['finalOutcome']?.toString() ?? 'pending';
    final payment = row['paymentStatus']?.toString();
    final providerActionAt = row['doctorActionAt'];
    final patientActionAt = row['patientActionAt'];
    final providerActionLabel =
        row['doctorActionLabel']?.toString() ?? '$providerLabel action';
    final patientActionLabel =
        row['patientActionLabel']?.toString() ?? 'Patient action';
    final address = row['patientAddress']?.toString().trim() ?? '';
    final clinic = row['clinicName']?.toString().trim() ?? '';
    final progress = row['visitProgress']?.toString();
    final showVisitProgress =
        (isNurse || serviceType == 'home_visit') && progress != null;
    final showHospitalCheckIn = !isNurse && serviceType == 'hospital_visit';
    final checkedIn = row['appointmentVerifiedAt'] != null;

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _NameBlock(
                      label: 'Patient',
                      value: row['patientName']?.toString() ?? 'Patient',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _NameBlock(
                      label: providerLabel,
                      value: row['providerName']?.toString() ??
                          row['doctorName']?.toString() ??
                          providerLabel,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: _Pill(
                  label: outcomeLabel(outcome),
                  color: outcomeColor(outcome),
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              _DetailRow(
                label: 'Payment',
                child: _Pill(
                  label: paymentLabel(payment).replaceFirst('Pay: ', ''),
                  color: paymentColor(payment),
                ),
              ),
              _DetailRow(
                label: providerActionLabel,
                child: _StatusValue(
                  text: formatDate(providerActionAt),
                  color: joinColor(providerActionAt),
                ),
              ),
              _DetailRow(
                label: patientActionLabel,
                child: _StatusValue(
                  text: formatDate(patientActionAt),
                  color: joinColor(patientActionAt),
                ),
              ),
              if (showVisitProgress)
                _DetailRow(
                  label: 'Visit progress',
                  child: _Pill(
                    label: progress!.replaceAll('_', ' '),
                    color: AppColors.primary,
                  ),
                ),
              if (showHospitalCheckIn)
                _DetailRow(
                  label: 'Check-in',
                  child: _Pill(
                    label: checkedIn ? 'Checked in' : 'Not checked in',
                    color:
                        checkedIn ? AppColors.success : AppColors.warning,
                  ),
                ),
              const SizedBox(height: 4),
              const Divider(height: 1),
              const SizedBox(height: 10),
              _DetailRow(
                label: 'Slot',
                child: Text(
                  formatDate(row['slotStart']),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _DetailRow(
                label: 'Amount',
                child: Text(
                  row['amount'] != null ? '₹${row['amount']}' : '—',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if ((isNurse || serviceType == 'home_visit') &&
                  address.isNotEmpty)
                _DetailRow(
                  label: 'Address',
                  child: Text(
                    address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              if (showHospitalCheckIn && clinic.isNotEmpty)
                _DetailRow(
                  label: 'Clinic',
                  child: Text(
                    clinic,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              const SizedBox(height: 6),
              Text(
                'Tap for full details',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NameBlock extends StatelessWidget {
  const _NameBlock({required this.label, required this.value});

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
            height: 1.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.titleSmall.copyWith(
            color: AppColors.primary,
            decoration: TextDecoration.underline,
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 128,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusValue extends StatelessWidget {
  const _StatusValue({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final missing = text == '—';
    return Text(
      text,
      style: AppTextStyles.bodySmall.copyWith(
        color: missing ? AppColors.textSecondary : color,
        fontWeight: FontWeight.w700,
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
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.labelSmall.copyWith(
          color: c,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
      ),
    );
  }
}
