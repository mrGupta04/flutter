import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_lists.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validation_utils.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../shared/widgets/aadhaar_card_picker.dart';
import '../../../../shared/widgets/profile_picture_picker.dart';
import '../../../user_auth/provider/patient_auth_provider.dart';
import '../../provider/patient_dashboard_provider.dart';

class EditPatientProfileScreen extends ConsumerStatefulWidget {
  const EditPatientProfileScreen({super.key});

  @override
  ConsumerState<EditPatientProfileScreen> createState() =>
      _EditPatientProfileScreenState();
}

class _EditPatientProfileScreenState
    extends ConsumerState<EditPatientProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _mobileController;
  late final TextEditingController _ageController;
  late final TextEditingController _aadhaarController;
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  Uint8List? _profileBytes;
  String? _profileFileName;
  Uint8List? _aadhaarCardBytes;
  String? _aadhaarCardFileName;
  String? _gender;
  bool _changePassword = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(patientAuthProvider).user;
    _fullNameController = TextEditingController(text: user?.fullName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _mobileController = TextEditingController(text: user?.mobileNumber ?? '');
    _ageController = TextEditingController(
      text: user?.age != null ? '${user!.age}' : '',
    );
    _aadhaarController = TextEditingController();
    _gender = user?.gender;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _ageController.dispose();
    _aadhaarController.dispose();
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_changePassword) {
      if (_passwordController.text.length < 8) {
        SnackBarHelper.showError(context, 'Password must be at least 8 characters');
        return;
      }
      if (_passwordController.text != _confirmPasswordController.text) {
        SnackBarHelper.showError(context, 'Passwords do not match');
        return;
      }
    }

    final (firstName, lastName) = _splitFullName(_fullNameController.text);
    final aadhaarDigits =
        _aadhaarController.text.replaceAll(RegExp(r'\D'), '');
    final aadhaarNumber =
        aadhaarDigits.length == 12 ? aadhaarDigits : null;

    final ok = await ref.read(patientDashboardProvider.notifier).updateProfile(
          firstName: firstName,
          lastName: lastName,
          email: _emailController.text.trim(),
          mobileNumber: _mobileController.text.trim(),
          age: int.parse(_ageController.text.trim()),
          gender: _gender!,
          aadhaarNumber: aadhaarNumber,
          password: _changePassword ? _passwordController.text : null,
          profilePictureBytes: _profileBytes,
          profilePictureFileName: _profileFileName,
          aadhaarCardBytes: _aadhaarCardBytes,
          aadhaarCardFileName: _aadhaarCardFileName,
        );

    if (!mounted) return;
    if (ok) {
      SnackBarHelper.showSuccess(context, AppConstants.successProfileUpdated);
      context.pop(true);
    } else {
      final err = ref.read(patientDashboardProvider).error;
      SnackBarHelper.showError(context, err ?? 'Update failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final dash = ref.watch(patientDashboardProvider);
    final user = ref.watch(patientAuthProvider).user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Edit profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Update your details',
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Leave Aadhaar blank to keep current. Upload new photos only if you want to replace them.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
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
              if (user?.profilePicture != null &&
                  _profileBytes == null) ...[
                const SizedBox(height: 8),
                Text(
                  'Current photo is saved on your account.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 16),
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
              CustomTextField(
                controller: _mobileController,
                label: 'Mobile number',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: (v) =>
                    ValidationUtils.validatePhoneNumber(v ?? ''),
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
                initialValue: _gender,
                decoration: InputDecoration(
                  labelText: 'Gender',
                  prefixIcon: const Icon(Icons.wc_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: AppLists.genders
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) => setState(() => _gender = v),
                validator: (v) => ValidationUtils.validateGender(v),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _aadhaarController,
                label: 'Aadhaar number (optional — to change)',
                prefixIcon: Icons.badge_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(12),
                ],
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  return ValidationUtils.validateAadhaar(v);
                },
              ),
              if (user?.aadhaarLast4 != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Current: ${user!.aadhaarMaskedDisplay}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 16),
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
              SwitchListTile(
                title: const Text('Change password'),
                value: _changePassword,
                onChanged: (v) => setState(() => _changePassword = v),
              ),
              if (_changePassword) ...[
                CustomTextField(
                  controller: _passwordController,
                  label: 'New password',
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm new password',
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: true,
                ),
              ],
              const SizedBox(height: 24),
              CustomButton(
                label: 'Save changes',
                icon: Icons.check_rounded,
                isLoading: dash.isSavingProfile,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
