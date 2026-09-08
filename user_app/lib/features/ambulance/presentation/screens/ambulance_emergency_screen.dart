import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/user_location_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/user_auth_guard.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/models/ambulance_vehicle_types.dart';
import '../../../../data/repositories/ambulance_repository.dart';
import '../../../../features/select_location/location_selector_field.dart';
import '../../../../features/select_location/selected_location.dart';
import '../../../../features/user_auth/provider/patient_auth_provider.dart';

class AmbulanceEmergencyScreen extends ConsumerStatefulWidget {
  const AmbulanceEmergencyScreen({super.key});

  @override
  ConsumerState<AmbulanceEmergencyScreen> createState() =>
      _AmbulanceEmergencyScreenState();
}

class _AmbulanceEmergencyScreenState extends ConsumerState<AmbulanceEmergencyScreen> {
  final _repo = AmbulanceRepository();
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _condition = TextEditingController();
  final _contact = TextEditingController();
  SelectedLocationResult? _pickup;
  SelectedLocationResult? _drop;
  String _destinationType = 'hospital';
  String _vehicleType = 'als';
  String _category = 'other';
  String _conscious = 'unknown';
  String? _gender;
  bool _oxygen = false;
  bool _ventilator = false;
  bool _cardiac = false;
  bool _icu = false;
  bool _submitting = false;
  List<Map<String, dynamic>> _hospitals = [];
  Map<String, dynamic>? _estimate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prefill());
  }

  Future<void> _prefill() async {
    final user = ref.read(patientAuthProvider).user;
    if (user != null) {
      _name.text = user.fullName;
      _contact.text = user.mobileNumber ?? '';
    }
    final location = ref.read(userLocationProvider);
    if (location.hasCoordinates) {
      setState(() {
        _pickup = SelectedLocationResult(
          addressLine: location.displayPlaceCity ?? location.displayCity,
          city: location.city,
          latitude: location.latitude,
          longitude: location.longitude,
        );
      });
      final hospitals = await _repo.getHospitals(
        latitude: location.latitude,
        longitude: location.longitude,
      );
      if (mounted && hospitals.data != null) {
        setState(() => _hospitals = hospitals.data!);
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _condition.dispose();
    _contact.dispose();
    super.dispose();
  }

  Future<void> _refreshEstimate() async {
    if (_pickup?.latitude == null) return;
    final estimate = await _repo.estimateFare({
      'vehicleType': _vehicleType,
      'pickupLatitude': _pickup?.latitude,
      'pickupLongitude': _pickup?.longitude,
      'dropLatitude': _drop?.latitude,
      'dropLongitude': _drop?.longitude,
      'isEmergency': true,
      'oxygen': _oxygen,
      'ventilator': _ventilator,
      'cardiacMonitor': _cardiac,
      'icuSupport': _icu,
    });
    if (mounted) setState(() => _estimate = estimate.data);
  }

  Future<void> _submit() async {
    final loggedIn = await ensureUserLoggedIn(context);
    if (!loggedIn || !mounted) return;
    if (_pickup == null || _name.text.trim().length < 2) {
      SnackBarHelper.showError(context, 'Patient name and pickup location are required');
      return;
    }
    setState(() => _submitting = true);
    final user = ref.read(patientAuthProvider).user;
    final response = await _repo.createEmergency({
      'patientName': _name.text.trim(),
      'patientMobile': _contact.text.trim().isEmpty
          ? user?.mobileNumber
          : _contact.text.trim(),
      'patientAge': int.tryParse(_age.text.trim()),
      'patientGender': _gender,
      'patientCondition': _condition.text.trim(),
      'consciousState': _conscious,
      'emergencyCategory': _category,
      'contactPerson': user?.fullName,
      'contactPhone': _contact.text.trim(),
      'pickupAddress': _pickup!.displayLine,
      'pickupCity': _pickup!.city,
      'pickupLatitude': _pickup!.latitude,
      'pickupLongitude': _pickup!.longitude,
      'dropAddress': _drop?.displayLine,
      'dropCity': _drop?.city,
      'dropLatitude': _drop?.latitude,
      'dropLongitude': _drop?.longitude,
      'destinationType': _destinationType,
      'destinationHospitalName': _drop?.label,
      'vehicleTypeRequested': _vehicleType,
      'oxygen': _oxygen,
      'ventilator': _ventilator,
      'cardiacMonitor': _cardiac,
      'icuSupport': _icu,
    });
    if (!mounted) return;
    setState(() => _submitting = false);
    if (response.success && response.data != null) {
      context.go('${AppConstants.routeAmbulanceTrack}?bookingId=${response.data!.id}');
    } else {
      SnackBarHelper.showError(context, response.error ?? 'Could not request ambulance');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency ambulance')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Text(
            'Transportation request only — not a diagnosis or medical advice.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          LocationSelectorField(
            label: 'Pickup location',
            hint: 'Search for area, street name...',
            value: _pickup,
            onChanged: (value) {
              setState(() => _pickup = value);
              _refreshEstimate();
            },
          ),
          const SizedBox(height: 16),
          Text('Destination', style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['hospital', 'home', 'clinic', 'other'].map((type) {
              return ChoiceChip(
                label: Text(type[0].toUpperCase() + type.substring(1)),
                selected: _destinationType == type,
                onSelected: (_) => setState(() => _destinationType = type),
              );
            }).toList(),
          ),
          if (_destinationType == 'hospital' && _hospitals.isNotEmpty) ...[
            const SizedBox(height: 8),
            ..._hospitals.take(5).map(
              (hospital) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(hospital['name']?.toString() ?? 'Hospital'),
                subtitle: Text(hospital['address']?.toString() ?? ''),
                trailing: hospital['distanceKm'] != null
                    ? Text('${hospital['distanceKm']} km')
                    : null,
                onTap: () => setState(() {
                  _drop = SelectedLocationResult(
                    addressLine: hospital['address']?.toString() ?? hospital['name'].toString(),
                    label: hospital['name']?.toString(),
                    city: hospital['city']?.toString(),
                    latitude: (hospital['latitude'] as num?)?.toDouble(),
                    longitude: (hospital['longitude'] as num?)?.toDouble(),
                  );
                }),
              ),
            ),
          ],
          LocationSelectorField(
            label: 'Destination location',
            hint: 'Hospital, home, clinic or other',
            value: _drop,
            onChanged: (value) {
              setState(() => _drop = value);
              _refreshEstimate();
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(controller: _name, label: 'Patient name'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: CustomTextField(controller: _age, label: 'Age', keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _gender,
                  decoration: const InputDecoration(labelText: 'Gender'),
                  items: const [
                    DropdownMenuItem(value: 'female', child: Text('Female')),
                    DropdownMenuItem(value: 'male', child: Text('Male')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (value) => setState(() => _gender = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _category,
            decoration: const InputDecoration(labelText: 'Emergency category (for dispatch only)'),
            items: const [
              DropdownMenuItem(value: 'accident', child: Text('Accident')),
              DropdownMenuItem(value: 'breathing_difficulty', child: Text('Breathing difficulty')),
              DropdownMenuItem(value: 'chest_pain', child: Text('Chest pain')),
              DropdownMenuItem(value: 'unconsciousness', child: Text('Unconsciousness')),
              DropdownMenuItem(value: 'trauma', child: Text('Trauma')),
              DropdownMenuItem(value: 'pregnancy', child: Text('Pregnancy-related emergency')),
              DropdownMenuItem(value: 'critical_illness', child: Text('Critical illness')),
              DropdownMenuItem(value: 'other', child: Text('Other')),
            ],
            onChanged: (value) => setState(() => _category = value ?? 'other'),
          ),
          const SizedBox(height: 12),
          CustomTextField(controller: _condition, label: 'Patient condition (optional)', maxLines: 2),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _conscious,
            decoration: const InputDecoration(labelText: 'Conscious / unconscious'),
            items: const [
              DropdownMenuItem(value: 'conscious', child: Text('Conscious')),
              DropdownMenuItem(value: 'unconscious', child: Text('Unconscious')),
              DropdownMenuItem(value: 'unknown', child: Text('Unknown')),
            ],
            onChanged: (value) => setState(() => _conscious = value ?? 'unknown'),
          ),
          const SizedBox(height: 12),
          CustomTextField(controller: _contact, label: 'Contact phone', keyboardType: TextInputType.phone),
          const SizedBox(height: 16),
          Text('Ambulance requirement', style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700)),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ambulanceVehicleTypes.map((type) {
              return ChoiceChip(
                label: Text(type.chipLabel),
                selected: _vehicleType == type.id,
                onSelected: (_) => setState(() => _vehicleType = type.id),
              );
            }).toList(),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _oxygen,
            onChanged: (v) => setState(() => _oxygen = v ?? false),
            title: const Text('Oxygen required'),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _ventilator,
            onChanged: (v) => setState(() => _ventilator = v ?? false),
            title: const Text('Ventilator required'),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _cardiac,
            onChanged: (v) => setState(() => _cardiac = v ?? false),
            title: const Text('Cardiac monitor required'),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _icu,
            onChanged: (v) => setState(() => _icu = v ?? false),
            title: const Text('ICU support required'),
          ),
          if (_estimate?['fare'] is Map) ...[
            const SizedBox(height: 16),
            Text(
              'Estimated fare',
              style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              '₹${(_estimate!['fare'] as Map)['total']} · nearest free ambulance rate',
            ),
            Text(
              _estimate?['disclaimer']?.toString() ?? '',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 16),
          CustomButton(
            label: 'Request now',
            isLoading: _submitting,
            isEnabled: !_submitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
