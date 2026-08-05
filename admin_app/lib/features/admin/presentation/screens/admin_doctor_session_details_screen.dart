import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/services/dio_service.dart';

class AdminDoctorSessionDetailsScreen extends StatefulWidget {
  const AdminDoctorSessionDetailsScreen({
    super.key,
    required this.bookingId,
  });

  final String bookingId;

  @override
  State<AdminDoctorSessionDetailsScreen> createState() =>
      _AdminDoctorSessionDetailsScreenState();
}

class _AdminDoctorSessionDetailsScreenState
    extends State<AdminDoctorSessionDetailsScreen> {
  Map<String, dynamic>? _data;
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
    try {
      final response = await DioService().get(
        AppConstants.endpointAdminConsultationBooking(widget.bookingId),
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

  String _outcomeLabel(String outcome) {
    switch (outcome) {
      case 'successful':
        return 'Successful';
      case 'defect':
        return 'Defect / incomplete';
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

  void _showProfileSheet({
    required String title,
    required Map<String, dynamic> profile,
  }) {
    final entries = profile.entries
        .where((e) => e.value != null && e.value.toString().isNotEmpty)
        .toList();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.92,
          minChildSize: 0.4,
          builder: (context, controller) {
            return ListView(
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
                            e.value is List
                                ? (e.value as List).join(', ')
                                : e.value.toString(),
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final outcome = data?['finalOutcome']?.toString() ?? 'pending';
    final isNurse = data?['providerType']?.toString() == 'nurse';
    final doctor = data?['doctor'] is Map
        ? Map<String, dynamic>.from(data!['doctor'] as Map)
        : <String, dynamic>{};
    final nurse = data?['nurse'] is Map
        ? Map<String, dynamic>.from(data!['nurse'] as Map)
        : <String, dynamic>{};
    final provider = data?['provider'] is Map
        ? Map<String, dynamic>.from(data!['provider'] as Map)
        : (isNurse ? nurse : doctor);
    final patient = data?['patient'] is Map
        ? Map<String, dynamic>.from(data!['patient'] as Map)
        : <String, dynamic>{};
    final booking = data?['booking'] is Map
        ? Map<String, dynamic>.from(data!['booking'] as Map)
        : <String, dynamic>{};
    final providerLabel = isNurse ? 'Nurse' : 'Doctor';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Session details')),
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
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _outcomeColor(outcome).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              outcome == 'successful'
                                  ? Icons.check_circle_rounded
                                  : outcome == 'defect'
                                      ? Icons.error_rounded
                                      : Icons.info_rounded,
                              color: _outcomeColor(outcome),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Final status: ${_outcomeLabel(outcome)}',
                                style: AppTextStyles.titleSmall.copyWith(
                                  color: _outcomeColor(outcome),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _sectionTitle('Session summary'),
                      _infoCard([
                        ('Booking ID', data?['id']?.toString() ?? '—'),
                        (
                          'Service',
                          data?['consultationType']?.toString() ?? '—'
                        ),
                        (
                          'Payment status',
                          data?['paymentStatus']?.toString() ?? '—'
                        ),
                        ('Paid at', _fmt(data?['paidAt'])),
                        (
                          'Booking status',
                          data?['bookingStatus']?.toString() ?? '—'
                        ),
                        (
                          'Amount',
                          '₹${data?['amount'] ?? 0} ${data?['currency'] ?? 'INR'}'
                        ),
                        ('Slot start', _fmt(data?['slotStart'])),
                        ('Slot end', _fmt(data?['slotEnd'])),
                        (
                          data?['doctorActionLabel']?.toString() ??
                              'Doctor action',
                          _fmt(data?['doctorActionAt']),
                        ),
                        (
                          data?['patientActionLabel']?.toString() ??
                              'Patient action',
                          _fmt(data?['patientActionAt']),
                        ),
                        if (data?['consultationType'] == 'online_consult') ...[
                          ('Doctor joined', _fmt(data?['doctorJoinedAt'])),
                          ('User joined', _fmt(data?['patientJoinedAt'])),
                          ('Call started', _fmt(data?['videoCallStartedAt'])),
                          ('Call ended', _fmt(data?['videoCallEndedAt'])),
                        ],
                        if (data?['consultationType'] == 'book_home') ...[
                          (
                            '$providerLabel approved',
                            _fmt(data?['doctorApprovedAt']),
                          ),
                          (
                            '$providerLabel rejected',
                            _fmt(data?['doctorRejectedAt']),
                          ),
                          (
                            'Visit progress',
                            data?['visitProgress']?.toString() ?? '—',
                          ),
                          ('Visit started', _fmt(data?['visitStartedAt'])),
                          ('Visit completed', _fmt(data?['visitCompletedAt'])),
                          (
                            'Patient address',
                            data?['patientAddress']?.toString() ?? '—',
                          ),
                          (
                            'Patient city',
                            data?['patientCity']?.toString() ?? '—',
                          ),
                        ],
                        if (data?['consultationType'] == 'visit_site') ...[
                          (
                            '$providerLabel approved',
                            _fmt(data?['doctorApprovedAt']),
                          ),
                          (
                            '$providerLabel rejected',
                            _fmt(data?['doctorRejectedAt']),
                          ),
                          (
                            'Appointment code',
                            data?['appointmentCode']?.toString() ?? '—',
                          ),
                          (
                            'Patient checked in',
                            _fmt(data?['appointmentVerifiedAt']),
                          ),
                          (
                            'Clinic',
                            doctor['clinicName']?.toString() ?? '—',
                          ),
                        ],
                      ]),
                      const SizedBox(height: 16),
                      _sectionTitle('Profiles'),
                      _profileTile(
                        title: 'Patient profile',
                        subtitle: patient['name']?.toString() ??
                            data?['patientName']?.toString() ??
                            'Patient',
                        onTap: () => _showProfileSheet(
                          title: 'Patient profile',
                          profile: {
                            'Name': patient['name'] ?? data?['patientName'],
                            'Mobile': patient['mobileNumber'] ??
                                data?['patientMobile'],
                            'Email':
                                patient['email'] ?? data?['patientEmail'],
                            'Gender': patient['gender'],
                            'Date of birth': patient['dateOfBirth'],
                            'City': patient['city'],
                            'State': patient['state'],
                            'Patient ID': patient['id'] ?? data?['patientId'],
                            'Notes': booking['patientNotes'],
                            'Address': booking['patientAddress'],
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      _profileTile(
                        title: '$providerLabel profile',
                        subtitle: provider['name']?.toString() ??
                            data?['providerName']?.toString() ??
                            data?['doctorName']?.toString() ??
                            providerLabel,
                        onTap: () {
                          String? providerId = provider['id']?.toString();
                          providerId ??= data?['providerId']?.toString();
                          // Avoid `cond ? map?['k'] : ...` — Dart parses `map?` as ternary.
                          if (providerId == null || providerId.isEmpty) {
                            if (isNurse) {
                              providerId = data?['nurseId']?.toString();
                            } else {
                              providerId = data?['doctorId']?.toString();
                            }
                          }

                          final profile = <String, dynamic>{
                            'Name': provider['name'] ??
                                data?['providerName'] ??
                                data?['doctorName'],
                            'Email': provider['email'],
                            'Mobile': provider['mobileNumber'],
                            'Qualification': provider['qualification'],
                            'City': provider['city'],
                            'State': provider['state'],
                            'Verification': provider['verificationStatus'],
                            '$providerLabel ID': providerId,
                          };
                          if (!isNurse) {
                            profile['Specializations'] =
                                provider['specializations'];
                            profile['Clinic'] = provider['clinicName'];
                          } else {
                            profile['Experience'] =
                                provider['yearsOfExperience'];
                          }

                          showModalBottomSheet<void>(
                            context: context,
                            showDragHandle: true,
                            builder: (context) => SafeArea(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.badge_outlined),
                                    title: Text('View $providerLabel summary'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _showProfileSheet(
                                        title: '$providerLabel profile',
                                        profile: profile,
                                      );
                                    },
                                  ),
                                  if (providerId != null &&
                                      providerId.isNotEmpty)
                                    ListTile(
                                      leading: const Icon(
                                        Icons.open_in_new_rounded,
                                      ),
                                      title: Text(
                                        'Open full $providerLabel page',
                                      ),
                                      onTap: () {
                                        Navigator.pop(context);
                                        final path = isNurse
                                            ? '${AppConstants.routeAdminNurseDetails}/$providerId'
                                            : '${AppConstants.routeAdminDoctorDetails}/$providerId';
                                        context.push(path);
                                      },
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      if (booking.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _sectionTitle('Raw booking fields'),
                        _infoCard(
                          booking.entries
                              .where(
                                (e) =>
                                    e.value != null &&
                                    e.value.toString().isNotEmpty &&
                                    e.key != 'previousReports' &&
                                    e.key != 'statusHistory',
                              )
                              .map(
                                (e) => (
                                  e.key,
                                  e.value is DateTime ||
                                          (e.value is String &&
                                              DateTime.tryParse(
                                                    e.value.toString(),
                                                  ) !=
                                                  null)
                                      ? _fmt(e.value)
                                      : e.value.toString(),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _infoCard(List<(String, String)> rows) {
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

  Widget _profileTile({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.grey200),
        ),
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryLight,
          child: Icon(
            title.contains('Doctor')
                ? Icons.medical_services
                : title.contains('Nurse')
                    ? Icons.health_and_safety_rounded
                    : Icons.person,
            color: AppColors.primary,
          ),
        ),
        title: Text(title, style: AppTextStyles.titleSmall),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
