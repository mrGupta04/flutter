import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/user_auth_guard.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/repositories/ambulance_repository.dart';
import '../../../../features/select_location/location_selector_field.dart';
import '../../../../features/select_location/selected_location.dart';
import '../../../../features/user_auth/provider/patient_auth_provider.dart';

class AmbulanceScheduledScreen extends ConsumerStatefulWidget {
  const AmbulanceScheduledScreen({super.key});

  @override
  ConsumerState<AmbulanceScheduledScreen> createState() =>
      _AmbulanceScheduledScreenState();
}

class _AmbulanceScheduledScreenState extends ConsumerState<AmbulanceScheduledScreen> {
  final _repo = AmbulanceRepository();
  final _name = TextEditingController();
  final _mobile = TextEditingController();
  final _notes = TextEditingController();
  SelectedLocationResult? _pickup;
  SelectedLocationResult? _drop;
  DateTime? _scheduledAt;
  String _vehicleType = 'patient_transport';
  bool _oxygen = false;
  bool _wheelchair = false;
  bool _submitting = false;
  Map<String, dynamic>? _estimate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authUser = ref.read(patientAuthProvider).user;
      if (authUser != null) {
        _name.text = authUser.fullName;
        _mobile.text = authUser.mobileNumber ?? '';
      }
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _mobile.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      initialDate: DateTime.now().add(const Duration(hours: 2)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 2))),
    );
    if (time == null) return;
    setState(() {
      _scheduledAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
    await _refreshEstimate();
  }

  Future<void> _refreshEstimate() async {
    final estimate = await _repo.estimateFare({
      'vehicleType': _vehicleType,
      'pickupLatitude': _pickup?.latitude,
      'pickupLongitude': _pickup?.longitude,
      'dropLatitude': _drop?.latitude,
      'dropLongitude': _drop?.longitude,
      'isEmergency': false,
      'oxygen': _oxygen,
      'wheelchair': _wheelchair,
    });
    if (mounted) setState(() => _estimate = estimate.data);
  }

  Future<void> _submit() async {
    final loggedIn = await ensureUserLoggedIn(context);
    if (!loggedIn || !mounted) return;
    if (_pickup == null || _scheduledAt == null || _name.text.trim().length < 2) {
      SnackBarHelper.showError(context, 'Pickup, schedule and patient name are required');
      return;
    }
    setState(() => _submitting = true);
    final response = await _repo.createScheduled({
      'patientName': _name.text.trim(),
      'patientMobile': _mobile.text.trim(),
      'pickupAddress': _pickup!.displayLine,
      'pickupCity': _pickup!.city,
      'pickupLatitude': _pickup!.latitude,
      'pickupLongitude': _pickup!.longitude,
      'dropAddress': _drop?.displayLine,
      'dropLatitude': _drop?.latitude,
      'dropLongitude': _drop?.longitude,
      'scheduledAt': _scheduledAt!.toIso8601String(),
      'vehicleTypeRequested': _vehicleType,
      'notes': _notes.text.trim(),
      'oxygen': _oxygen,
      'wheelchair': _wheelchair,
      'isEmergency': false,
    });
    if (!mounted) return;
    setState(() => _submitting = false);
    if (response.success && response.data != null) {
      context.go('${AppConstants.routeAmbulanceTripDetail}?id=${response.data!.id}');
    } else {
      SnackBarHelper.showError(context, response.error ?? 'Could not create booking');
    }
  }

  @override
  Widget build(BuildContext context) {
    final fare = _estimate?['fare'] as Map<String, dynamic>?;
    return Scaffold(
      appBar: AppBar(title: const Text('Book ambulance')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          LocationSelectorField(
            label: 'Pickup',
            value: _pickup,
            onChanged: (value) {
              setState(() => _pickup = value);
              _refreshEstimate();
            },
          ),
          const SizedBox(height: 12),
          LocationSelectorField(
            label: 'Destination',
            value: _drop,
            onChanged: (value) {
              setState(() => _drop = value);
              _refreshEstimate();
            },
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Date & time'),
            subtitle: Text(
              _scheduledAt == null
                  ? 'Select date and time'
                  : DateFormat('dd MMM yyyy, hh:mm a').format(_scheduledAt!),
            ),
            trailing: const Icon(Icons.schedule),
            onTap: _pickDateTime,
          ),
          CustomTextField(controller: _name, label: 'Patient name'),
          const SizedBox(height: 12),
          CustomTextField(controller: _mobile, label: 'Contact phone', keyboardType: TextInputType.phone),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _vehicleType,
            decoration: const InputDecoration(labelText: 'Ambulance type'),
            items: const [
              DropdownMenuItem(value: 'patient_transport', child: Text('Patient Transport')),
              DropdownMenuItem(value: 'basic', child: Text('Basic Ambulance')),
              DropdownMenuItem(value: 'bls', child: Text('Basic Life Support')),
              DropdownMenuItem(value: 'als', child: Text('Advanced Life Support')),
              DropdownMenuItem(value: 'icu', child: Text('ICU Ambulance')),
              DropdownMenuItem(value: 'neonatal', child: Text('Neonatal Ambulance')),
            ],
            onChanged: (value) {
              setState(() => _vehicleType = value ?? 'patient_transport');
              _refreshEstimate();
            },
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _oxygen,
            onChanged: (v) {
              setState(() => _oxygen = v ?? false);
              _refreshEstimate();
            },
            title: const Text('Oxygen required'),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _wheelchair,
            onChanged: (v) {
              setState(() => _wheelchair = v ?? false);
              _refreshEstimate();
            },
            title: const Text('Wheelchair support'),
          ),
          CustomTextField(controller: _notes, label: 'Notes (optional)', maxLines: 2),
          if (fare != null) ...[
            const SizedBox(height: 16),
            Text('Fare estimate', style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w800)),
            Text('Base fare  ₹${fare['baseFare']}'),
            Text('Distance    ₹${fare['distanceCharge']}'),
            Text('Type        ₹${fare['typeCharge']}'),
            Text('Extras      ₹${fare['equipmentCharge']}'),
            Text(
              'Total       ₹${fare['total']}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            Text(
              _estimate?['disclaimer']?.toString() ?? '',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 20),
          CustomButton(
            label: 'Request booking',
            isLoading: _submitting,
            isEnabled: !_submitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
