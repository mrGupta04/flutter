import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/india_geography.dart';
import '../../core/services/geocoding_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/custom_widgets.dart';
import '../../data/models/patient_user_model.dart';
import '../../data/repositories/patient_auth_repository.dart';
import '../../shared/widgets/address_autocomplete_field.dart';
import '../user_auth/provider/patient_auth_provider.dart';
import 'location_map_picker_page.dart';
import 'location_permission_handler.dart';
import 'selected_location.dart';

class AddAddressScreen extends ConsumerStatefulWidget {
  const AddAddressScreen({super.key, this.existing});

  final SavedAddressModel? existing;

  @override
  ConsumerState<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends ConsumerState<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _house = TextEditingController();
  final _area = TextEditingController();
  final _landmark = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _pincode = TextEditingController();
  final _contact = TextEditingController();
  final _phone = TextEditingController();
  String _type = 'Home';
  double? _lat;
  double? _lng;
  bool _saving = false;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _house.text = existing.addressLine;
      _city.text = existing.city ?? '';
      _state.text = existing.state ?? '';
      _pincode.text = existing.pincode ?? '';
      _landmark.text = existing.landmark ?? '';
      _contact.text = existing.contactName ?? '';
      _phone.text = existing.phone ?? '';
      _type = existing.label;
      _lat = existing.latitude;
      _lng = existing.longitude;
    } else {
      final user = ref.read(patientAuthProvider).user;
      _contact.text = user?.fullName ?? '';
      _phone.text = user?.mobileNumber ?? '';
    }
  }

  @override
  void dispose() {
    _house.dispose();
    _area.dispose();
    _landmark.dispose();
    _city.dispose();
    _state.dispose();
    _pincode.dispose();
    _contact.dispose();
    _phone.dispose();
    super.dispose();
  }

  String get _addressLine {
    final parts = [
      _house.text.trim(),
      _area.text.trim(),
    ].where((p) => p.isNotEmpty);
    return parts.join(', ');
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    final captured = await LocationPermissionHandler.capture(context);
    if (!mounted) return;
    setState(() => _locating = false);
    if (captured == null) return;
    final resolved = captured.resolved;
    setState(() {
      _lat = captured.latitude;
      _lng = captured.longitude;
      if (resolved != null) {
        if (_house.text.trim().isEmpty) _house.text = resolved.address;
        if (_city.text.trim().isEmpty) _city.text = resolved.city;
        if (_state.text.trim().isEmpty) _state.text = resolved.state;
        if (_pincode.text.trim().isEmpty) _pincode.text = resolved.pincode;
        if (_area.text.trim().isEmpty && resolved.place.isNotEmpty) {
          _area.text = resolved.place;
        }
      }
    });
  }

  Future<void> _pickOnMap() async {
    final result = await Navigator.of(context).push<SelectedLocationResult>(
      MaterialPageRoute(
        builder: (_) => LocationMapPickerPage(
          initialLatitude: _lat,
          initialLongitude: _lng,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _lat = result.latitude;
      _lng = result.longitude;
      if (_house.text.trim().isEmpty) {
        _house.text = result.addressLine;
      }
      _city.text = result.city ?? _city.text;
      _state.text = result.state ?? _state.text;
      _pincode.text = result.pincode ?? _pincode.text;
    });
    if (result.hasCoordinates) {
      try {
        final resolved = await GeocodingService.reverseGeocode(
          latitude: result.latitude!,
          longitude: result.longitude!,
        );
        if (!mounted) return;
        setState(() {
          if (_house.text.trim().isEmpty) _house.text = resolved.address;
          if (_city.text.trim().isEmpty) _city.text = resolved.city;
          if (_state.text.trim().isEmpty) _state.text = resolved.state;
          if (_pincode.text.trim().isEmpty) _pincode.text = resolved.pincode;
        });
      } catch (_) {}
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final line = _addressLine;
    if (line.length < 5) {
      SnackBarHelper.showError(context, 'Enter house and area details');
      return;
    }
    setState(() => _saving = true);
    final model = SavedAddressModel(
      id: widget.existing?.id ?? '',
      label: _type,
      addressLine: line,
      city: _city.text.trim().isEmpty ? null : _city.text.trim(),
      state: _state.text.trim().isEmpty ? null : _state.text.trim(),
      pincode: _pincode.text.trim().isEmpty ? null : _pincode.text.trim(),
      landmark:
          _landmark.text.trim().isEmpty ? null : _landmark.text.trim(),
      contactName:
          _contact.text.trim().isEmpty ? null : _contact.text.trim(),
      phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      latitude: _lat,
      longitude: _lng,
      isDefault: widget.existing?.isDefault ?? false,
    );
    final res = await PatientAuthRepository().saveAddress(model);
    if (!mounted) return;
    setState(() => _saving = false);
    if (!res.success || res.data == null) {
      SnackBarHelper.showError(context, res.error ?? 'Could not save address');
      return;
    }
    ref.read(patientAuthProvider.notifier).setUser(res.data!);
    SavedAddressModel saved = model;
    final list = res.data!.savedAddresses;
    if (model.id.isNotEmpty) {
      saved = list.firstWhere((a) => a.id == model.id, orElse: () => model);
    } else if (list.isNotEmpty) {
      saved = list.last;
    }
    Navigator.pop(context, SelectedLocationResult.fromSaved(saved));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Add Address' : 'Edit Address'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            CustomTextField(
              controller: _house,
              label: 'House / Flat / Building',
              prefixIcon: Icons.home_outlined,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _area,
              label: 'Area / Street',
              prefixIcon: Icons.signpost_outlined,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _landmark,
              label: 'Landmark',
              prefixIcon: Icons.flag_outlined,
            ),
            const SizedBox(height: 12),
            AddressAutocompleteField(
              controller: _city,
              label: 'City',
              hint: 'e.g. Bengaluru',
              options: IndiaGeography.districtsFor(state: _state.text),
            ),
            const SizedBox(height: 12),
            AddressAutocompleteField(
              controller: _state,
              label: 'State',
              hint: 'e.g. Karnataka',
              options: IndiaGeography.states,
              onSelected: (_) => setState(() {}),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _pincode,
              label: 'Pincode',
              prefixIcon: Icons.pin_outlined,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _contact,
              label: 'Contact name',
              prefixIcon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _phone,
              label: 'Phone number',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Address type',
              style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final type in const ['Home', 'Work', 'Other'])
                  ChoiceChip(
                    label: Text(type),
                    selected: _type == type,
                    onSelected: (_) => setState(() => _type = type),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _locating ? null : _useCurrentLocation,
              icon: _locating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location_rounded),
              label: Text(_locating ? 'Detecting…' : 'Use my current location'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickOnMap,
              icon: const Icon(Icons.map_outlined),
              label: const Text('Select on map'),
            ),
            const SizedBox(height: 20),
            CustomButton(
              label: 'Save Address',
              isLoading: _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
