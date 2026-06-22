import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/phone_countries.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/models/blood_bank_model.dart';
import '../../../../shared/widgets/mobile_number_field.dart';
import '../../../../shared/widgets/profile_picture_picker.dart';
import '../../../../shared/widgets/registration_map_picker.dart';
import '../../provider/blood_bank_registration_provider.dart';

class BloodBankRegistrationScreen extends ConsumerStatefulWidget {
  const BloodBankRegistrationScreen({super.key});

  @override
  ConsumerState<BloodBankRegistrationScreen> createState() =>
      _BloodBankRegistrationScreenState();
}

class _BloodBankRegistrationScreenState
    extends ConsumerState<BloodBankRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _institutionController = TextEditingController();
  final _licenseController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emergencyController = TextEditingController();
  String _countryCode = PhoneCountries.defaultDialCode;
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _bloodGroupsController = TextEditingController();
  bool _hasApheresis = false;
  bool _hasComponentSeparation = false;
  bool _available24x7 = false;
  double? _latitude;
  double? _longitude;
  Uint8List? _profileImageBytes;
  String? _profileImageFileName;

  @override
  void dispose() {
    for (final c in [
      _institutionController,
      _licenseController,
      _contactPersonController,
      _emailController,
      _mobileController,
      _emergencyController,
      _addressController,
      _cityController,
      _stateController,
      _pincodeController,
      _bloodGroupsController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bloodBankRegistrationProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Blood bank registration')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Register Blood Bank',
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Submit your institution details for admin verification. '
                'After approval, you will appear in the patient marketplace.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 18),
              ProfilePicturePicker(
                imageBytes: _profileImageBytes,
                onImagePicked: (bytes, fileName) {
                  setState(() {
                    _profileImageBytes = bytes;
                    _profileImageFileName = fileName;
                  });
                },
                onError: (msg) => SnackBarHelper.showError(context, msg),
              ),
              const SizedBox(height: 18),
              _sectionTitle('Institution details'),
              CustomTextField(
                controller: _institutionController,
                label: 'Institution Name',
                hint: 'e.g. City Blood Centre',
                prefixIcon: Icons.bloodtype_outlined,
                validator: _required,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _licenseController,
                label: 'License Number',
                hint: 'Blood bank license number',
                prefixIcon: Icons.badge_outlined,
                validator: _required,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _contactPersonController,
                label: 'Contact Person',
                hint: 'In-charge name',
                prefixIcon: Icons.person_outline_rounded,
                validator: _required,
              ),
              const SizedBox(height: 18),
              _sectionTitle('Contact'),
              CustomTextField(
                controller: _emailController,
                label: 'Email',
                hint: 'example@email.com',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: _emailValidator,
              ),
              const SizedBox(height: 12),
              MobileNumberField(
                mobileController: _mobileController,
                countryCode: _countryCode,
                onCountryCodeChanged: (code) =>
                    setState(() => _countryCode = code),
                label: 'Mobile Number',
              ),
              const SizedBox(height: 12),
              MobileNumberField(
                mobileController: _emergencyController,
                countryCode: _countryCode,
                onCountryCodeChanged: (code) =>
                    setState(() => _countryCode = code),
                label: 'Emergency Contact',
                hint: '24x7 helpline',
              ),
              const SizedBox(height: 18),
              _sectionTitle('Location'),
              CustomTextField(
                controller: _addressController,
                label: 'Address',
                hint: 'Full address',
                prefixIcon: Icons.home_outlined,
                validator: _required,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _cityController,
                label: 'City',
                hint: 'Your city',
                prefixIcon: Icons.location_city_outlined,
                validator: _required,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _stateController,
                label: 'State',
                hint: 'Your state',
                prefixIcon: Icons.map_outlined,
                validator: _required,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _pincodeController,
                label: 'Pincode',
                hint: '6-digit pincode',
                prefixIcon: Icons.pin_drop_outlined,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if ((v ?? '').trim().length != 6) return 'Enter valid pincode';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text('Map Location', style: AppTextStyles.titleMedium),
              const SizedBox(height: 8),
              RegistrationMapPicker(
                addressController: _addressController,
                cityController: _cityController,
                stateController: _stateController,
                pincodeController: _pincodeController,
                initialLatitude: _latitude,
                initialLongitude: _longitude,
                onLocationChanged: (lat, lng) => setState(() {
                  _latitude = lat;
                  _longitude = lng;
                }),
                emptyHint:
                    'Tap the map or use current location to pin your facility.',
                webTitle: 'Facility location',
              ),
              const SizedBox(height: 18),
              _sectionTitle('Services'),
              CustomTextField(
                controller: _bloodGroupsController,
                label: 'Blood Groups Available',
                hint: 'A+, B+, O+, AB+ (comma separated)',
                prefixIcon: Icons.water_drop_outlined,
                validator: _required,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Apheresis facility'),
                value: _hasApheresis,
                onChanged: (v) => setState(() => _hasApheresis = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Component separation'),
                value: _hasComponentSeparation,
                onChanged: (v) => setState(() => _hasComponentSeparation = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Available 24x7'),
                value: _available24x7,
                onChanged: (v) => setState(() => _available24x7 = v),
              ),
              if (state.error != null) ...[
                const SizedBox(height: 12),
                Text(
                  state.error!,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
                ),
              ],
              const SizedBox(height: 18),
              CustomButton(
                label: 'Submit Blood Bank Registration',
                isLoading: state.isSubmitting,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }

  String? _required(String? value) =>
      (value == null || value.trim().isEmpty) ? 'This field is required' : null;

  String? _emailValidator(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email is required';
    if (!email.contains('@')) return 'Enter a valid email';
    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_profileImageBytes == null) {
      SnackBarHelper.showError(context, 'Please upload a profile picture.');
      return;
    }

    if (_latitude == null || _longitude == null) {
      SnackBarHelper.showError(
        context,
        'Please select your location on the map.',
      );
      return;
    }

    final bloodGroups = _bloodGroupsController.text
        .split(',')
        .map((s) => s.trim().toUpperCase())
        .where((s) => s.isNotEmpty)
        .toList();

    final bloodBank = BloodBankModel(
      id: const Uuid().v4(),
      institutionName: _institutionController.text.trim(),
      licenseNumber: _licenseController.text.trim(),
      contactPerson: _contactPersonController.text.trim(),
      email: _emailController.text.trim(),
      mobileNumber: _mobileController.text.trim(),
      countryCode: _countryCode,
      emergencyContact: _emergencyController.text.trim(),
      address: _addressController.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      pincode: _pincodeController.text.trim(),
      latitude: _latitude,
      longitude: _longitude,
      bloodGroupsAvailable: bloodGroups,
      hasApheresis: _hasApheresis,
      hasComponentSeparation: _hasComponentSeparation,
      available24x7: _available24x7,
    );

    final ok = await ref.read(bloodBankRegistrationProvider.notifier).submit(
          bloodBank,
          profileImageBytes: _profileImageBytes,
          profileImageFileName: _profileImageFileName,
        );

    if (!mounted) return;
    if (ok) {
      context.go(AppConstants.routeBloodBankApplicationSubmitted);
    } else {
      SnackBarHelper.showError(
        context,
        ref.read(bloodBankRegistrationProvider).error ?? 'Registration failed',
      );
    }
  }
}
