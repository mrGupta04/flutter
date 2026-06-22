import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_lists.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/phone_countries.dart';
import '../../../../core/utils/validation_utils.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../shared/widgets/aadhaar_card_picker.dart';
import '../../../../shared/widgets/mobile_number_field.dart';
import '../../../../shared/widgets/profile_picture_picker.dart';
import '../../provider/patient_auth_provider.dart';

class UserRegisterScreen extends ConsumerStatefulWidget {
  const UserRegisterScreen({super.key, this.redirect});

  final String? redirect;

  @override
  ConsumerState<UserRegisterScreen> createState() =>
      _UserRegisterScreenState();
}

class _UserRegisterScreenState extends ConsumerState<UserRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _aadhaarController = TextEditingController();
  final _ageController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  Uint8List? _profileBytes;
  String _profileFileName = 'profile.jpg';
  Uint8List? _aadhaarCardBytes;
  String _aadhaarCardFileName = 'aadhaar.jpg';
  String? _gender;
  String _countryCode = PhoneCountries.defaultDialCode;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _aadhaarController.dispose();
    _ageController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  (String firstName, String? lastName) _splitFullName(String full) {
    final parts = full.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return ('', null);
    if (parts.length == 1) return (parts.first, null);
    return (parts.first, parts.sublist(1).join(' '));
  }

  Future<void> _submit() async {
    if (_profileBytes == null || _profileBytes!.isEmpty) {
      SnackBarHelper.showError(context, 'Profile picture is required');
      return;
    }
    if (_aadhaarCardBytes == null || _aadhaarCardBytes!.isEmpty) {
      SnackBarHelper.showError(context, 'Aadhaar card photo is required');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final (firstName, lastName) = _splitFullName(_fullNameController.text);
    final aadhaar =
        _aadhaarController.text.replaceAll(RegExp(r'\D'), '');

    final ok = await ref.read(patientAuthProvider.notifier).register(
          firstName: firstName,
          lastName: lastName,
          email: _emailController.text.trim(),
          mobileNumber: _mobileController.text.trim(),
          countryCode: _countryCode,
          password: _passwordController.text,
          age: int.parse(_ageController.text.trim()),
          gender: _gender!,
          aadhaarNumber: aadhaar,
          profilePictureBytes: _profileBytes!.toList(),
          profilePictureFileName: _profileFileName,
          aadhaarCardBytes: _aadhaarCardBytes!.toList(),
          aadhaarCardFileName: _aadhaarCardFileName,
        );

    if (!mounted) return;
    if (ok) {
      _finishSuccess();
    } else {
      final err = ref.read(patientAuthProvider).error;
      SnackBarHelper.showError(context, err ?? 'Registration failed');
    }
  }

  void _finishSuccess() {
    final redirect = widget.redirect;
    if (redirect != null && redirect.isNotEmpty) {
      context.go(redirect);
    } else {
      context.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(patientAuthProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Create account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Register to book care',
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'All fields are required to create your patient account.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              ProfilePicturePicker(
                imageBytes: _profileBytes,
                onImagePicked: (bytes, name) {
                  setState(() {
                    _profileBytes = bytes;
                    _profileFileName = name;
                  });
                },
                onError: (msg) => SnackBarHelper.showError(context, msg),
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _fullNameController,
                label: 'Full name',
                prefixIcon: Icons.person_outline_rounded,
                validator: (v) => ValidationUtils.validateName(v ?? ''),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _emailController,
                label: 'Email',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => ValidationUtils.validateEmail(v ?? ''),
              ),
              const SizedBox(height: 12),
              MobileNumberField(
                mobileController: _mobileController,
                countryCode: _countryCode,
                onCountryCodeChanged: (code) =>
                    setState(() => _countryCode = code),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _aadhaarController,
                label: 'Aadhaar number',
                prefixIcon: Icons.badge_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(12),
                ],
                validator: (v) => ValidationUtils.validateAadhaar(v ?? ''),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _ageController,
                label: 'Age',
                prefixIcon: Icons.cake_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                validator: (v) => ValidationUtils.validateAge(v ?? ''),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: InputDecoration(
                  labelText: 'Gender',
                  prefixIcon: const Icon(Icons.wc_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: AppLists.genders
                    .map(
                      (g) => DropdownMenuItem(value: g, child: Text(g)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _gender = v),
                validator: (v) => ValidationUtils.validateGender(v),
              ),
              const SizedBox(height: 20),
              AadhaarCardPicker(
                imageBytes: _aadhaarCardBytes,
                onImagePicked: (bytes, name) {
                  setState(() {
                    _aadhaarCardBytes = bytes;
                    _aadhaarCardFileName = name;
                  });
                },
                onError: (msg) => SnackBarHelper.showError(context, msg),
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _passwordController,
                label: 'Password',
                prefixIcon: Icons.lock_outline_rounded,
                obscureText: true,
                validator: (v) {
                  if (v == null || v.length < 8) {
                    return 'At least 8 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _confirmPasswordController,
                label: 'Confirm password',
                prefixIcon: Icons.lock_outline_rounded,
                obscureText: true,
                validator: (v) {
                  if (v != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              CustomButton(
                label: 'Create account',
                icon: Icons.person_add_alt_1_rounded,
                isLoading: auth.isLoading,
                onPressed: _submit,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  final redirect = widget.redirect;
                  final q = redirect != null
                      ? '?redirect=${Uri.encodeComponent(redirect)}'
                      : '';
                  context.push('${AppConstants.routeUserLogin}$q');
                },
                child: const Text('Already have an account? Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
