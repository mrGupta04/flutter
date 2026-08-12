import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/services/dio_service.dart';

class AdminPatientDetailsScreen extends StatefulWidget {
  const AdminPatientDetailsScreen({
    super.key,
    required this.patientId,
    this.initialPatient,
  });

  final String patientId;
  final Map<String, dynamic>? initialPatient;

  @override
  State<AdminPatientDetailsScreen> createState() =>
      _AdminPatientDetailsScreenState();
}

class _AdminPatientDetailsScreenState extends State<AdminPatientDetailsScreen> {
  Map<String, dynamic>? _patient;
  bool _loading = true;
  bool _mutating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _patient = widget.initialPatient;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _patient == null;
      _error = null;
    });
    try {
      final response = await DioService().get(
        AppConstants.endpointAdminPatient(widget.patientId),
      );
      final body = response.data as Map<String, dynamic>;
      final data = body['data'];
      if (data is Map) {
        setState(() {
          _patient = Map<String, dynamic>.from(data);
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
          _error = 'Patient not found';
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  String get _name {
    final p = _patient;
    if (p == null) return 'Patient';
    final name = '${p['firstName'] ?? ''} ${p['lastName'] ?? ''}'.trim();
    return name.isEmpty ? 'Patient' : name;
  }

  bool get _blocked => _patient?['isBlocked'] == true;

  Future<void> _toggleBlock() async {
    if (_patient == null || _mutating) return;

    final reasonController = TextEditingController(
      text: _patient?['blockedReason']?.toString() ?? '',
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_blocked ? 'Unblock patient?' : 'Block patient?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _blocked
                  ? '$_name will be able to log in and use the app again.'
                  : '$_name will not be able to log in, reset password, or use the app with this account.',
            ),
            if (!_blocked) ...[
              const SizedBox(height: 14),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _blocked ? AppColors.success : AppColors.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_blocked ? 'Unblock' : 'Block'),
          ),
        ],
      ),
    );

    final reason = reasonController.text.trim();
    reasonController.dispose();
    if (confirmed != true || !mounted) return;

    final wasBlocked = _blocked;
    setState(() => _mutating = true);
    try {
      final endpoint = wasBlocked
          ? AppConstants.endpointAdminPatientUnblock(widget.patientId)
          : AppConstants.endpointAdminPatientBlock(widget.patientId);
      final response = await DioService().post(
        endpoint,
        data: wasBlocked
            ? const <String, dynamic>{}
            : {'reason': reason.isEmpty ? 'Blocked by admin' : reason},
      );
      final body = response.data as Map<String, dynamic>;
      final data = body['data'];
      if (data is Map) {
        setState(() {
          _patient = Map<String, dynamic>.from(data);
          _mutating = false;
        });
      } else {
        await _load();
        if (mounted) setState(() => _mutating = false);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasBlocked
                ? 'Patient unblocked'
                : 'Patient blocked — they can no longer use the app',
          ),
        ),
      );
    } catch (e) {
      setState(() => _mutating = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  String _fmtDate(dynamic value) {
    if (value == null) return '-';
    final dt = DateTime.tryParse(value.toString())?.toLocal();
    if (dt == null) return value.toString();
    return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.trim().isEmpty ? '-' : value,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _chipList(List<dynamic>? values) {
    final items = (values ?? const [])
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (items.isEmpty) {
      return [
        Text(
          'None',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ];
    }
    return [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items
            .map(
              (item) => Chip(
                label: Text(item),
                visualDensity: VisualDensity.compact,
                backgroundColor: AppColors.grey50,
              ),
            )
            .toList(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final patient = _patient;
    final photo = patient?['profilePicture']?.toString() ?? '';
    final medical = patient?['medicalProfile'] is Map
        ? Map<String, dynamic>.from(patient!['medicalProfile'] as Map)
        : <String, dynamic>{};
    final family = (patient?['familyMembers'] as List?) ?? const [];
    final addresses = (patient?['savedAddresses'] as List?) ?? const [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Patient profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading && patient == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null && patient == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
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
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 36,
                              backgroundColor:
                                  AppColors.primary.withValues(alpha: 0.12),
                              backgroundImage:
                                  photo.isNotEmpty ? NetworkImage(photo) : null,
                              child: photo.isEmpty
                                  ? Text(
                                      _name[0].toUpperCase(),
                                      style: AppTextStyles.headlineSmall
                                          .copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _name,
                                    style: AppTextStyles.titleLarge.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    patient?['email']?.toString() ?? '',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _blocked
                                          ? AppColors.error
                                              .withValues(alpha: 0.12)
                                          : AppColors.success
                                              .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      _blocked ? 'Blocked' : 'Active',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: _blocked
                                            ? AppColors.error
                                            : AppColors.success,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _section('Account', [
                        _row('Mobile', patient?['mobileNumber']?.toString() ?? ''),
                        _row('Age', '${patient?['age'] ?? '-'}'),
                        _row('Gender', patient?['gender']?.toString() ?? ''),
                        _row(
                          'Aadhaar',
                          patient?['aadhaarLast4'] == null
                              ? '-'
                              : 'XXXX XXXX ${patient?['aadhaarLast4']}',
                        ),
                        _row(
                          'Referral code',
                          patient?['referralCode']?.toString() ?? '',
                        ),
                        _row(
                          'Reward points',
                          '${patient?['rewardPoints'] ?? 0}',
                        ),
                        _row('Joined', _fmtDate(patient?['createdAt'])),
                        if (_blocked) ...[
                          _row(
                            'Blocked on',
                            _fmtDate(patient?['blockedAt']),
                          ),
                          _row(
                            'Block reason',
                            patient?['blockedReason']?.toString() ?? '',
                          ),
                        ],
                      ]),
                      _section('Medical profile', [
                        _row(
                          'Blood group',
                          medical['bloodGroup']?.toString() ?? '',
                        ),
                        Text(
                          'Allergies',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ..._chipList(medical['allergies'] as List?),
                        const SizedBox(height: 10),
                        Text(
                          'Chronic diseases',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ..._chipList(medical['chronicDiseases'] as List?),
                        const SizedBox(height: 10),
                        Text(
                          'Current medications',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ..._chipList(medical['currentMedications'] as List?),
                        const SizedBox(height: 10),
                        _row('Notes', medical['notes']?.toString() ?? ''),
                      ]),
                      _section(
                        'Family members',
                        family.isEmpty
                            ? [
                                Text(
                                  'No family members added',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ]
                            : family.map((raw) {
                                final m = Map<String, dynamic>.from(raw as Map);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    [
                                      m['name']?.toString() ?? 'Member',
                                      m['relationship']?.toString() ?? '',
                                      if (m['age'] != null) 'Age ${m['age']}',
                                    ].where((e) => e.toString().isNotEmpty).join(' · '),
                                    style: AppTextStyles.bodyMedium,
                                  ),
                                );
                              }).toList(),
                      ),
                      _section(
                        'Saved addresses',
                        addresses.isEmpty
                            ? [
                                Text(
                                  'No saved addresses',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ]
                            : addresses.map((raw) {
                                final a = Map<String, dynamic>.from(raw as Map);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        a['label']?.toString() ?? 'Address',
                                        style: AppTextStyles.bodyMedium
                                            .copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        [
                                          a['addressLine'],
                                          a['city'],
                                          a['state'],
                                          a['pincode'],
                                        ]
                                            .where(
                                              (e) =>
                                                  e != null &&
                                                  e.toString().trim().isNotEmpty,
                                            )
                                            .join(', '),
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                      ),
                      if ((patient?['aadhaarCardUrl']?.toString() ?? '')
                          .isNotEmpty)
                        _section('Documents', [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              patient!['aadhaarCardUrl'].toString(),
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Text(
                                'Could not load Aadhaar image',
                              ),
                            ),
                          ),
                        ]),
                    ],
                  ),
                ),
      bottomNavigationBar: patient == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: FilledButton.icon(
                  onPressed: _mutating ? null : _toggleBlock,
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        _blocked ? AppColors.success : AppColors.error,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  icon: _mutating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          _blocked
                              ? Icons.lock_open_rounded
                              : Icons.block_rounded,
                        ),
                  label: Text(_blocked ? 'Unblock patient' : 'Block patient'),
                ),
              ),
            ),
    );
  }
}
