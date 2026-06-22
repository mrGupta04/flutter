import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/phone_countries.dart';
import '../../../../core/utils/validation_utils.dart';
import '../../../../shared/widgets/mobile_number_field.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/models/nurse_model.dart';
import '../../../../shared/widgets/profile_picture_picker.dart';
import '../../../../shared/widgets/registration_map_picker.dart';
import '../../provider/nurse_registration_provider.dart';

class NurseRegistrationScreen extends ConsumerStatefulWidget {
  const NurseRegistrationScreen({super.key});

  @override
  ConsumerState<NurseRegistrationScreen> createState() =>
      _NurseRegistrationScreenState();
}

class _NurseRegistrationScreenState
    extends ConsumerState<NurseRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _registrationController = TextEditingController();
  final _councilController = TextEditingController();
  final _experienceController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _specializationController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _shiftController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _countryCode = PhoneCountries.defaultDialCode;
  bool _availableForHomeVisit = false;
  double? _latitude;
  double? _longitude;
  Uint8List? _profileImageBytes;
  String? _profileImageFileName;

  @override
  void dispose() {
    for (final c in [
      _firstNameController,
      _lastNameController,
      _emailController,
      _mobileController,
      _registrationController,
      _councilController,
      _experienceController,
      _qualificationController,
      _specializationController,
      _addressController,
      _cityController,
      _stateController,
      _pincodeController,
      _shiftController,
      _passwordController,
      _confirmPasswordController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(nurseRegistrationProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Nurse registration')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Join as Nurse',
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Submit your details for admin verification. After approval, '
                'you will appear in the user app.',
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
              _sectionTitle('Personal details'),
              CustomTextField(
                controller: _firstNameController,
                label: 'First Name',
                hint: 'Enter first name',
                prefixIcon: Icons.person_outline_rounded,
                validator: _required,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _lastNameController,
                label: 'Last Name',
                hint: 'Enter last name',
                prefixIcon: Icons.person_outline_rounded,
                validator: _required,
              ),
              const SizedBox(height: 12),
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
              CustomTextField(
                controller: _passwordController,
                label: 'Password',
                hint: 'Create a strong password',
                prefixIcon: Icons.lock_outline_rounded,
                obscureText: true,
                validator: ValidationUtils.validatePassword,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _confirmPasswordController,
                label: 'Confirm Password',
                hint: 'Re-enter password',
                prefixIcon: Icons.lock_outline_rounded,
                obscureText: true,
                validator: (v) => ValidationUtils.validatePasswordMatch(
                  _passwordController.text,
                  v,
                ),
              ),
              const SizedBox(height: 18),
              _sectionTitle('Professional details'),
              CustomTextField(
                controller: _qualificationController,
                label: 'Qualification',
                hint: 'GNM / B.Sc Nursing / ANM',
                prefixIcon: Icons.school_outlined,
                validator: _required,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _registrationController,
                label: 'Registration Number',
                hint: 'Nursing council registration no.',
                prefixIcon: Icons.badge_outlined,
                validator: _required,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _councilController,
                label: 'Nursing Council',
                hint: 'State nursing council',
                prefixIcon: Icons.account_balance_outlined,
                validator: _required,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _experienceController,
                label: 'Years of Experience',
                hint: 'e.g. 3',
                prefixIcon: Icons.work_outline_rounded,
                keyboardType: TextInputType.number,
                validator: (value) {
                  final parsed = int.tryParse((value ?? '').trim());
                  if (parsed == null || parsed < 0) {
                    return 'Enter valid experience';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _specializationController,
                label: 'Specialization',
                hint: 'ICU, Pediatric, Home care, etc.',
                prefixIcon: Icons.medical_information_outlined,
                validator: _required,
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
                    'Tap the map or use current location to pin your work location.',
                webTitle: 'Work location',
              ),
              const SizedBox(height: 18),
              _sectionTitle('Availability'),
              CustomTextField(
                controller: _shiftController,
                label: 'Shift Availability',
                hint: 'Day / Night / Both',
                prefixIcon: Icons.schedule_outlined,
                validator: _required,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Available for home visit'),
                value: _availableForHomeVisit,
                onChanged: (v) => setState(() => _availableForHomeVisit = v),
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
                label: 'Submit Nurse Registration',
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

    final nurse = NurseModel(
      id: const Uuid().v4(),
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      mobileNumber: _mobileController.text.trim(),
      countryCode: _countryCode,
      qualification: _qualificationController.text.trim(),
      registrationNumber: _registrationController.text.trim(),
      nursingCouncil: _councilController.text.trim(),
      yearsOfExperience: int.parse(_experienceController.text.trim()),
      specialization: _specializationController.text.trim(),
      address: _addressController.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      pincode: _pincodeController.text.trim(),
      latitude: _latitude,
      longitude: _longitude,
      availableForHomeVisit: _availableForHomeVisit,
      shiftAvailability: _shiftController.text.trim(),
    );

    final ok = await ref.read(nurseRegistrationProvider.notifier).submit(
          nurse,
          password: _passwordController.text,
          profileImageBytes: _profileImageBytes,
          profileImageFileName: _profileImageFileName,
        );

    if (!mounted) return;
    if (ok) {
      context.go(AppConstants.routeNurseApplicationSubmitted);
    } else {
      SnackBarHelper.showError(
        context,
        ref.read(nurseRegistrationProvider).error ?? 'Registration failed',
      );
    }
  }
}
