import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_lists.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/text_controller_utils.dart';
import '../../../../core/utils/validation_utils.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/models/models.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../../shared/widgets/gender_radio_field.dart';
import '../../../../shared/widgets/healthcare_ui.dart';
import '../../../../shared/widgets/registration_location_input.dart';
import '../../../../shared/widgets/mobile_number_field.dart';
import '../../provider/registration_provider.dart';
import 'weekly_availability_picker.dart';

/// Padded content wrapper for registration step forms (parent provides scroll).
Widget registrationStepScroll({required Widget child}) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
    child: child,
  );
}

class Step1PersonalInfo extends ConsumerStatefulWidget {
  const Step1PersonalInfo({super.key, required this.formKey});

  final GlobalKey<FormState> formKey;

  @override
  ConsumerState<Step1PersonalInfo> createState() => _Step1PersonalInfoState();
}

class _Step1PersonalInfoState extends ConsumerState<Step1PersonalInfo>
    with AutomaticKeepAliveClientMixin {
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _mobileController;
  late TextEditingController _aadhaarController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  late TextEditingController _dobController;
  String? _selectedGender;
  Uint8List? _profileBytes;
  String? _profilePath;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final formState = ref.read(registrationFormProvider);
    _fullNameController = TextEditingController(text: formState.fullName);
    _emailController = TextEditingController(text: formState.email);
    _mobileController = TextEditingController(text: formState.mobileNumber);
    _aadhaarController = TextEditingController(
      text: _formatAadhaar(formState.aadhaarNumber),
    );
    _passwordController = TextEditingController(text: formState.password);
    _confirmPasswordController =
        TextEditingController(text: formState.confirmPassword);
    _dobController = TextEditingController(
      text: formState.dateOfBirth != null
          ? FormattingUtils.formatDate(formState.dateOfBirth!)
          : '',
    );
    _selectedGender = formState.gender;
    _profileBytes = formState.profileImageBytes;
    _profilePath = formState.profileImagePath;

    addTextChangeListener(_fullNameController, (text) {
      ref
          .read(registrationFormProvider.notifier)
          .updatePersonalInfo(fullName: text);
    });
    addTextChangeListener(_emailController, (text) {
      ref
          .read(registrationFormProvider.notifier)
          .updatePersonalInfo(email: text);
    });
    addTextChangeListener(_mobileController, (text) {
      ref
          .read(registrationFormProvider.notifier)
          .updatePersonalInfo(mobileNumber: text);
    });
    addTextChangeListener(_aadhaarController, (text) {
      final digits = text.replaceAll(RegExp(r'\D'), '');
      ref.read(registrationFormProvider.notifier).updateAadhaarNumber(digits);
    });
    addTextChangeListener(_passwordController, (text) {
      ref
          .read(registrationFormProvider.notifier)
          .updatePersonalInfo(password: text);
    });
    addTextChangeListener(_confirmPasswordController, (text) {
      ref.read(registrationFormProvider.notifier).updatePersonalInfo(
            confirmPassword: text,
          );
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _aadhaarController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  String _formatAadhaar(String digits) {
    if (digits.isEmpty) return '';
    final buf = StringBuffer();
    for (var i = 0; i < digits.length && i < 12; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    return buf.toString();
  }

  Future<void> _pickDob() async {
    final initialDate = DateTime.now().subtract(const Duration(days: 365 * 30));
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _dobController.text = FormattingUtils.formatDate(picked);
      ref
          .read(registrationFormProvider.notifier)
          .updatePersonalInfo(dateOfBirth: picked);
    }
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    final bytes = await file.readAsBytes();
    if (bytes.length > AppConstants.maxProfileImageSize) {
      if (mounted) {
        SnackBarHelper.showError(
          context,
          'Profile image size exceeds ${AppConstants.maxProfileImageSize ~/ (1024 * 1024)} MB.',
        );
      }
      return;
    }

    final name = file.name.isNotEmpty ? file.name : 'profile.jpg';

    setState(() {
      _profileBytes = bytes;
      _profilePath = null;
    });

    ref.read(registrationFormProvider.notifier).setProfileImage(
          bytes: bytes,
          fileName: name,
        );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // Only watch country code — watching the full form rebuilds every keystroke
    // and accidentally selects text in focused fields.
    final countryCode = ref.watch(
      registrationFormProvider.select((s) => s.countryCode),
    );

    return registrationStepScroll(
      child: Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Personal Information', style: AppTextStyles.titleLarge),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _fullNameController,
            label: 'Full Name',
            hint: 'Dr. Aditi Sharma',
            prefixIcon: Icons.person,
            validator: ValidationUtils.validateName,
          ),
          const SizedBox(height: 16),
          MobileNumberField(
            mobileController: _mobileController,
            countryCode: countryCode,
            onCountryCodeChanged: (code) => ref
                .read(registrationFormProvider.notifier)
                .updatePersonalInfo(countryCode: code),
            label: 'Mobile number',
            hint: '10-digit mobile number',
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _aadhaarController,
            label: 'Aadhaar number',
            hint: 'XXXX XXXX XXXX',
            prefixIcon: Icons.badge_outlined,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(12),
              _AadhaarInputFormatter(),
            ],
            validator: ValidationUtils.validateAadhaar,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'doctor@example.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: ValidationUtils.validateEmail,
          ),
          const SizedBox(height: 12),
          if (AppConstants.skipVerification)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.warning,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Email verification is temporarily disabled for testing. Enter any valid email to continue.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            const _EmailVerificationSection(),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _passwordController,
            label: 'Password',
            hint: 'Create a strong password',
            prefixIcon: Icons.lock_outline,
            obscureText: true,
            suffixIcon: Icons.visibility,
            validator: ValidationUtils.validatePassword,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            hint: 'Re-enter password',
            prefixIcon: Icons.lock_outline,
            obscureText: true,
            suffixIcon: Icons.visibility,
            validator: (value) => ValidationUtils.validatePasswordMatch(
              _passwordController.text,
              value,
            ),
          ),
          const SizedBox(height: 16),
          GenderRadioField(
            value: _selectedGender,
            options: AppLists.genders,
            onChanged: (value) {
              setState(() {
                _selectedGender = value;
              });
              ref
                  .read(registrationFormProvider.notifier)
                  .updatePersonalInfo(gender: value);
            },
            validator: (value) =>
                value == null || value.isEmpty ? 'Please select a gender' : null,
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _pickDob,
            child: AbsorbPointer(
              child: CustomTextField(
                controller: _dobController,
                label: 'Date of Birth',
                hint: 'Select date',
                prefixIcon: Icons.calendar_today_outlined,
                suffixIcon: Icons.edit_calendar,
                validator: ValidationUtils.validateDateOfBirth,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Profile Picture', style: AppTextStyles.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              _ProfilePreview(
                imageBytes: _profileBytes,
                imagePath: _profilePath,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomOutlineButton(
                  label: 'Upload Photo',
                  onPressed: _pickProfileImage,
                  icon: Icons.upload,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'JPG, PNG, or WEBP. Max ${AppConstants.maxProfileImageSize ~/ (1024 * 1024)} MB.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class _EmailVerificationSection extends ConsumerStatefulWidget {
  const _EmailVerificationSection();

  @override
  ConsumerState<_EmailVerificationSection> createState() =>
      _EmailVerificationSectionState();
}

class _EmailVerificationSectionState
    extends ConsumerState<_EmailVerificationSection> {
  late TextEditingController _otpController;

  @override
  void initState() {
    super.initState();
    _otpController = TextEditingController();
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final success = await ref
        .read(registrationFormProvider.notifier)
        .sendEmailVerificationOtp();
    if (!mounted) return;
    final formState = ref.read(registrationFormProvider);
    if (success) {
      SnackBarHelper.showSuccess(
        context,
        formState.emailVerificationMessage ?? 'Verification code sent.',
      );
    } else if (formState.emailVerificationError != null) {
      SnackBarHelper.showError(context, formState.emailVerificationError!);
    }
  }

  Future<void> _verifyOtp() async {
    final success = await ref
        .read(registrationFormProvider.notifier)
        .verifyEmailVerificationOtp(_otpController.text);
    if (!mounted) return;
    final formState = ref.read(registrationFormProvider);
    if (success) {
      SnackBarHelper.showSuccess(
        context,
        formState.emailVerificationMessage ?? 'Email verified.',
      );
    } else if (formState.emailVerificationError != null) {
      SnackBarHelper.showError(context, formState.emailVerificationError!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(registrationFormProvider);

    if (formState.emailVerified) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(Icons.verified_rounded, color: AppColors.success, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Email verified: ${formState.verifiedEmail}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.card(context: context, elevated: false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Verify your email', style: AppTextStyles.titleMedium),
          const SizedBox(height: 6),
          Text(
            'We will email a 6-digit code to the address above. Check your inbox and spam folder.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          CustomOutlineButton(
            label: formState.isSendingEmailOtp
                ? 'Sending code...'
                : 'Send verification code',
            onPressed: () { _sendOtp(); },
            isLoading: formState.isSendingEmailOtp,
            icon: Icons.mail_outline_rounded,
          ),
          const SizedBox(height: 12),
          CustomTextField(
            controller: _otpController,
            label: 'Verification code',
            hint: '6-digit code',
            prefixIcon: Icons.pin_outlined,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            validator: ValidationUtils.validateOtp,
          ),
          const SizedBox(height: 12),
          CustomButton(
            label: formState.isVerifyingEmailOtp ? 'Verifying...' : 'Verify email',
            onPressed: () { _verifyOtp(); },
            isLoading: formState.isVerifyingEmailOtp,
            icon: Icons.verified_user_outlined,
          ),
          if (formState.emailVerificationMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              formState.emailVerificationMessage!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class Step2ProfessionalDetails extends ConsumerStatefulWidget {
  const Step2ProfessionalDetails({super.key, required this.formKey});

  final GlobalKey<FormState> formKey;

  @override
  ConsumerState<Step2ProfessionalDetails> createState() =>
      _Step2ProfessionalDetailsState();
}

class _Step2ProfessionalDetailsState
    extends ConsumerState<Step2ProfessionalDetails>
    with AutomaticKeepAliveClientMixin {
  late TextEditingController _regNumberController;
  late TextEditingController _councilController;
  late TextEditingController _qualificationController;
  late TextEditingController _experienceController;
  late TextEditingController _clinicController;
  late TextEditingController _onlineFeeController;
  late TextEditingController _homeFeeController;
  late TextEditingController _visitSiteFeeController;
  late TextEditingController _onlineOfferFeeController;
  late TextEditingController _homeOfferFeeController;
  late TextEditingController _visitSiteOfferFeeController;
  late TextEditingController _bioController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final formState = ref.read(registrationFormProvider);
    _regNumberController =
        TextEditingController(text: formState.medicalRegistrationNumber);
    _councilController =
        TextEditingController(text: formState.medicalCouncilName);
    _qualificationController =
        TextEditingController(text: formState.qualification);
    _experienceController =
        TextEditingController(text: formState.yearsOfExperience);
    _clinicController = TextEditingController(text: formState.clinicName);
    _onlineFeeController =
        TextEditingController(text: formState.onlineConsultFee);
    _homeFeeController = TextEditingController(text: formState.homeVisitFee);
    _visitSiteFeeController =
        TextEditingController(text: formState.visitSiteFee);
    _onlineOfferFeeController =
        TextEditingController(text: formState.onlineConsultOfferFee);
    _homeOfferFeeController =
        TextEditingController(text: formState.homeVisitOfferFee);
    _visitSiteOfferFeeController =
        TextEditingController(text: formState.visitSiteOfferFee);
    _bioController = TextEditingController(text: formState.bio);

    addTextChangeListener(_regNumberController, (_) => _syncProfessionalDetails());
    addTextChangeListener(_councilController, (_) => _syncProfessionalDetails());
    addTextChangeListener(
      _qualificationController,
      (_) => _syncProfessionalDetails(),
    );
    addTextChangeListener(
      _experienceController,
      (_) => _syncProfessionalDetails(),
    );
    addTextChangeListener(_clinicController, (_) => _syncProfessionalDetails());
    addTextChangeListener(_onlineFeeController, (_) => _syncConsultationFees());
    addTextChangeListener(_homeFeeController, (_) => _syncConsultationFees());
    addTextChangeListener(
      _visitSiteFeeController,
      (_) => _syncConsultationFees(),
    );
    addTextChangeListener(
      _onlineOfferFeeController,
      (_) => _syncConsultationFees(),
    );
    addTextChangeListener(
      _homeOfferFeeController,
      (_) => _syncConsultationFees(),
    );
    addTextChangeListener(
      _visitSiteOfferFeeController,
      (_) => _syncConsultationFees(),
    );
    addTextChangeListener(_bioController, (_) => _syncProfessionalDetails());
  }

  void _syncConsultationFees() {
    ref.read(registrationFormProvider.notifier).updateConsultationFees(
          onlineConsultFee: _onlineFeeController.text,
          homeVisitFee: _homeFeeController.text,
          visitSiteFee: _visitSiteFeeController.text,
          onlineConsultOfferFee: _onlineOfferFeeController.text,
          homeVisitOfferFee: _homeOfferFeeController.text,
          visitSiteOfferFee: _visitSiteOfferFeeController.text,
        );
  }

  void _syncProfessionalDetails() {
    ref.read(registrationFormProvider.notifier).updateProfessionalDetails(
          medicalRegistrationNumber: _regNumberController.text,
          medicalCouncilName: _councilController.text,
          qualification: _qualificationController.text,
          yearsOfExperience: _experienceController.text,
          clinicName: _clinicController.text,
          bio: _bioController.text,
        );
  }

  @override
  void dispose() {
    _regNumberController.dispose();
    _councilController.dispose();
    _qualificationController.dispose();
    _experienceController.dispose();
    _clinicController.dispose();
    _onlineFeeController.dispose();
    _homeFeeController.dispose();
    _visitSiteFeeController.dispose();
    _onlineOfferFeeController.dispose();
    _homeOfferFeeController.dispose();
    _visitSiteOfferFeeController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final formState = ref.watch(registrationFormProvider);

    return registrationStepScroll(
      child: Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Professional Details', style: AppTextStyles.titleLarge),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _regNumberController,
            label: 'Medical Registration Number',
            hint: 'MR/2024/001',
            prefixIcon: Icons.badge_outlined,
            validator: ValidationUtils.validateMedicalRegNumber,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _councilController,
            label: 'Medical Council Name',
            hint: 'Medical Council of India',
            prefixIcon: Icons.account_balance_outlined,
            validator: (v) => ValidationUtils.validateOrganizationName(
              v,
              fieldName: 'Medical council name',
            ),
          ),
          const SizedBox(height: 20),
          _SearchableMultiSelectPicker(
            label: 'Specializations',
            hint: 'Search specialization',
            prefixIcon: Icons.medical_services_outlined,
            helperText: 'Search and tap to add. You can select more than one.',
            options: AppLists.specializations,
            selected: formState.specializations,
            onChanged: (values) {
              ref.read(registrationFormProvider.notifier).setSpecializations(values);
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _qualificationController,
            label: 'Qualification',
            hint: 'MBBS, MD',
            prefixIcon: Icons.school_outlined,
            validator: (v) => ValidationUtils.validateOrganizationName(
              v,
              fieldName: 'Qualification',
            ),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _experienceController,
            label: 'Years of Experience',
            hint: '5',
            prefixIcon: Icons.trending_up_outlined,
            keyboardType: TextInputType.number,
            validator: ValidationUtils.validateYearsOfExperience,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _clinicController,
            label: 'Hospital / Clinic Name',
            hint: 'Sunrise Clinic',
            prefixIcon: Icons.local_hospital_outlined,
            validator: (v) => ValidationUtils.validateOrganizationName(
              v,
              fieldName: 'Hospital / clinic name',
            ),
          ),
          const SizedBox(height: 16),
          _SearchableMultiSelectPicker(
            label: 'Languages spoken',
            hint: 'Search language',
            helperText: 'Search and tap to add. You can select more than one.',
            options: AppLists.languages,
            selected: formState.languagesSpoken,
            onChanged: (values) {
              ref.read(registrationFormProvider.notifier).setLanguages(values);
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _bioController,
            label: 'About / Bio',
            hint: 'Share your experience and areas of focus',
            prefixIcon: Icons.description_outlined,
            maxLines: 4,
            minLines: 3,
            validator: ValidationUtils.validateBio,
          ),
          const SizedBox(height: 24),
          _ConsultationOptionsPicker(
            offersOnlineConsult: formState.offersOnlineConsult,
            offersBookHome: formState.offersBookHome,
            offersVisitSite: formState.offersVisitSite,
            onToggleOnline: (selected) {
              ref.read(registrationFormProvider.notifier).setConsultationOptions(
                    online: selected,
                    home: formState.offersBookHome,
                    visit: formState.offersVisitSite,
                  );
            },
            onToggleBookHome: (selected) {
              ref.read(registrationFormProvider.notifier).setConsultationOptions(
                    online: formState.offersOnlineConsult,
                    home: selected,
                    visit: formState.offersVisitSite,
                  );
            },
            onToggleVisitSite: (selected) {
              ref.read(registrationFormProvider.notifier).setConsultationOptions(
                    online: formState.offersOnlineConsult,
                    home: formState.offersBookHome,
                    visit: selected,
                  );
            },
          ),
          if (formState.hasConsultationOptionSelected) ...[
            const SizedBox(height: 20),
            _ConsultationFeesSection(
              offersOnlineConsult: formState.offersOnlineConsult,
              offersBookHome: formState.offersBookHome,
              offersVisitSite: formState.offersVisitSite,
              onlineFeeController: _onlineFeeController,
              homeFeeController: _homeFeeController,
              visitSiteFeeController: _visitSiteFeeController,
              onlineOfferFeeController: _onlineOfferFeeController,
              homeOfferFeeController: _homeOfferFeeController,
              visitSiteOfferFeeController: _visitSiteOfferFeeController,
            ),
          ],
        ],
      ),
    ),
    );
  }
}

class Step3ClinicAddress extends ConsumerStatefulWidget {
  const Step3ClinicAddress({super.key, required this.formKey});

  final GlobalKey<FormState> formKey;

  @override
  ConsumerState<Step3ClinicAddress> createState() => _Step3ClinicAddressState();
}

class _Step3ClinicAddressState extends ConsumerState<Step3ClinicAddress>
    with AutomaticKeepAliveClientMixin {
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _pincodeController;
  RegistrationLocationInputMode _locationMode =
      RegistrationLocationInputMode.manual;

  @override
  bool get wantKeepAlive => true;

  Future<void> _pickHospitalPhoto(int photoIndex) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    final bytes = await file.readAsBytes();
    if (bytes.length > AppConstants.maxProfileImageSize) {
      if (mounted) {
        SnackBarHelper.showError(
          context,
          'Photo size exceeds ${AppConstants.maxProfileImageSize ~/ (1024 * 1024)} MB.',
        );
      }
      return;
    }

    final name = file.name.isNotEmpty ? file.name : 'hospital_$photoIndex.jpg';
    final notifier = ref.read(registrationFormProvider.notifier);
    notifier.setHospitalPhoto(
      photoIndex: photoIndex,
      bytes: bytes,
      fileName: name,
    );

    final ok = await notifier.uploadHospitalPhoto(photoIndex);
    if (!mounted) return;

    if (ok) {
      SnackBarHelper.showSuccess(context, 'Hospital photo $photoIndex uploaded');
    } else {
      final error = ref.read(registrationFormProvider).submitError ??
          'Upload failed. Check that the backend is running.';
      SnackBarHelper.showError(context, error);
    }
  }

  @override
  void initState() {
    super.initState();
    final formState = ref.read(registrationFormProvider);
    _addressController = TextEditingController(text: formState.address);
    _cityController = TextEditingController(text: formState.city);
    _stateController = TextEditingController(text: formState.state);
    _pincodeController = TextEditingController(text: formState.pincode);

    addTextChangeListener(_addressController, (_) => _syncAddress());
    addTextChangeListener(_cityController, (_) => _syncAddress());
    addTextChangeListener(_stateController, (_) => _syncAddress());
    addTextChangeListener(_pincodeController, (_) => _syncAddress());
  }

  void _syncAddress() {
    ref.read(registrationFormProvider.notifier).updateAddress(
          address: _addressController.text,
          city: _cityController.text,
          stateName: _stateController.text,
          pincode: _pincodeController.text,
        );
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final formState = ref.watch(registrationFormProvider);

    return registrationStepScroll(
      child: Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Clinic Address', style: AppTextStyles.titleLarge),
          const SizedBox(height: 16),
          RegistrationLocationBlock(
            mode: _locationMode,
            onModeChanged: (mode) => setState(() => _locationMode = mode),
            addressController: _addressController,
            cityController: _cityController,
            stateController: _stateController,
            pincodeController: _pincodeController,
            addressMaxLines: 2,
            latitude: formState.latitude,
            longitude: formState.longitude,
            onLocationChanged: (lat, lng) => ref
                .read(registrationFormProvider.notifier)
                .setLocation(latitude: lat, longitude: lng),
            onAddressResolved: ({
              required address,
              required city,
              required state,
              required pincode,
            }) =>
                ref.read(registrationFormProvider.notifier).updateAddress(
                      address: address,
                      city: city,
                      stateName: state,
                      pincode: pincode,
                    ),
            mapEmptyHint:
                'Tap the map or use current location to pin your clinic.',
            mapWebTitle: 'Clinic map location',
          ),
          const SizedBox(height: 24),
          Text('Hospital Photos', style: AppTextStyles.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Upload $doctorHospitalPhotoCount clear photos of your hospital or clinic. These appear on your public profile and do not require admin verification.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: doctorHospitalPhotoSlots.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemBuilder: (context, index) {
              final photoIndex = doctorHospitalPhotoSlots[index];
              final uploadedUrl = formState.hospitalPhotoUrls[photoIndex];
              final previewBytes = formState.hospitalPhotoBytes[photoIndex];
              final isUploaded = uploadedUrl != null && uploadedUrl.isNotEmpty;
              final progress =
                  formState.hospitalPhotoUploadProgress[photoIndex] ?? 0;

              return _HospitalPhotoUploadTile(
                label: 'Photo ${index + 1}',
                imageBytes: previewBytes,
                imageUrl: isUploaded ? uploadedUrl : null,
                uploaded: isUploaded,
                progress: progress,
                onTap: () => _pickHospitalPhoto(photoIndex),
              );
            },
          ),
        ],
      ),
    ),
    );
  }
}

class Step4DocumentUpload extends ConsumerStatefulWidget {
  const Step4DocumentUpload({super.key, required this.formKey});

  final GlobalKey<FormState> formKey;

  @override
  ConsumerState<Step4DocumentUpload> createState() => _Step4DocumentUploadState();
}

class _Step4DocumentUploadState extends ConsumerState<Step4DocumentUpload>
    with AutomaticKeepAliveClientMixin {
  final Map<DocumentType, Uint8List?> _previewBytes = {};
  final Map<DocumentType, String> _fileNames = {};

  @override
  bool get wantKeepAlive => true;

  Future<void> _pickFile(DocumentType type) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: AppConstants.allowedDocumentFormats,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    if (file.size > AppConstants.maxFileSize) {
      if (mounted) {
        SnackBarHelper.showError(
          context,
          'File size exceeds ${AppConstants.maxFileSize ~/ (1024 * 1024)} MB.',
        );
      }
      return;
    }

    final bytes = file.bytes;
    final path = file.path;
    if (bytes == null && (path == null || path.isEmpty)) {
      if (mounted) {
        SnackBarHelper.showError(
          context,
          'Unable to read the selected file. Try again.',
        );
      }
      return;
    }

    setState(() {
      if (bytes != null) {
        _previewBytes[type] = bytes;
      }
      _fileNames[type] = file.name;
    });

    final notifier = ref.read(registrationFormProvider.notifier);
    if (bytes != null) {
      notifier.setDocumentFile(
        type: type,
        bytes: bytes,
        fileName: file.name,
      );
    } else {
      notifier.setDocumentPath(type, path!);
    }

    final ok = await notifier.uploadDocument(type);
    if (!mounted) return;

    if (ok) {
      SnackBarHelper.showSuccess(context, '${file.name} uploaded');
    } else {
      final error = ref.read(registrationFormProvider).submitError ??
          'Upload failed. Check that the backend is running.';
      SnackBarHelper.showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final formState = ref.watch(registrationFormProvider);

    return registrationStepScroll(
      child: Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Document Upload', style: AppTextStyles.titleLarge),
          const SizedBox(height: 12),
          Text(
            'Upload clear scans or photos of the required documents.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          _DocumentUploadTile(
            title: 'Medical License',
            documentType: DocumentType.medicalLicense,
            fileName: _fileNames[DocumentType.medicalLicense],
            previewBytes: _previewBytes[DocumentType.medicalLicense],
            progress: formState.uploadProgress[DocumentType.medicalLicense] ?? 0,
            uploaded: formState.uploadedDocuments.containsKey(
              DocumentType.medicalLicense,
            ),
            onSelect: () => _pickFile(DocumentType.medicalLicense),
            onUpload: () => ref
                .read(registrationFormProvider.notifier)
                .uploadDocument(DocumentType.medicalLicense),
          ),
          _DocumentUploadTile(
            title: 'Aadhaar Card',
            documentType: DocumentType.aadhaarCard,
            fileName: _fileNames[DocumentType.aadhaarCard],
            previewBytes: _previewBytes[DocumentType.aadhaarCard],
            progress: formState.uploadProgress[DocumentType.aadhaarCard] ?? 0,
            uploaded: formState.uploadedDocuments.containsKey(
              DocumentType.aadhaarCard,
            ),
            onSelect: () => _pickFile(DocumentType.aadhaarCard),
            onUpload: () => ref
                .read(registrationFormProvider.notifier)
                .uploadDocument(DocumentType.aadhaarCard),
          ),
          _DocumentUploadTile(
            title: 'Degree Certificate',
            documentType: DocumentType.degreeCertificate,
            fileName: _fileNames[DocumentType.degreeCertificate],
            previewBytes: _previewBytes[DocumentType.degreeCertificate],
            progress: formState.uploadProgress[DocumentType.degreeCertificate] ?? 0,
            uploaded: formState.uploadedDocuments.containsKey(
              DocumentType.degreeCertificate,
            ),
            onSelect: () => _pickFile(DocumentType.degreeCertificate),
            onUpload: () => ref
                .read(registrationFormProvider.notifier)
                .uploadDocument(DocumentType.degreeCertificate),
          ),
          _DocumentUploadTile(
            title: 'Clinic Proof',
            documentType: DocumentType.clinicProof,
            fileName: _fileNames[DocumentType.clinicProof],
            previewBytes: _previewBytes[DocumentType.clinicProof],
            progress: formState.uploadProgress[DocumentType.clinicProof] ?? 0,
            uploaded: formState.uploadedDocuments.containsKey(
              DocumentType.clinicProof,
            ),
            onSelect: () => _pickFile(DocumentType.clinicProof),
            onUpload: () => ref
                .read(registrationFormProvider.notifier)
                .uploadDocument(DocumentType.clinicProof),
          ),
          if (formState.submitError != null) ...[
            const SizedBox(height: 12),
            Text(
              formState.submitError!,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
          ],
        ],
      ),
    ),
    );
  }
}

class Step5BankDetails extends ConsumerStatefulWidget {
  const Step5BankDetails({super.key, required this.formKey});

  final GlobalKey<FormState> formKey;

  @override
  ConsumerState<Step5BankDetails> createState() => _Step5BankDetailsState();
}

class _Step5BankDetailsState extends ConsumerState<Step5BankDetails>
    with AutomaticKeepAliveClientMixin {
  late TextEditingController _accountController;
  late TextEditingController _ifscController;
  late TextEditingController _upiController;
  Uint8List? _chequeBytes;
  String? _chequeFileName;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final formState = ref.read(registrationFormProvider);
    _accountController =
        TextEditingController(text: formState.bankAccountNumber);
    _ifscController = TextEditingController(text: formState.ifscCode);
    _upiController = TextEditingController(text: formState.upiId);
    _chequeBytes = formState.documentBytes[DocumentType.cancelledCheque];
    _chequeFileName = formState.documentFileNames[DocumentType.cancelledCheque];

    addTextChangeListener(_accountController, (text) {
      ref.read(registrationFormProvider.notifier).updateBankDetails(
            bankAccountNumber: text,
          );
    });
    addTextChangeListener(_ifscController, (text) {
      ref
          .read(registrationFormProvider.notifier)
          .updateBankDetails(ifscCode: text);
    });
    addTextChangeListener(_upiController, (text) {
      ref
          .read(registrationFormProvider.notifier)
          .updateBankDetails(upiId: text);
    });
  }

  @override
  void dispose() {
    _accountController.dispose();
    _ifscController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  Future<void> _pickChequePhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    final bytes = await file.readAsBytes();
    if (bytes.length > AppConstants.maxFileSize) {
      if (mounted) {
        SnackBarHelper.showError(
          context,
          'Image size exceeds ${AppConstants.maxFileSize ~/ (1024 * 1024)} MB.',
        );
      }
      return;
    }

    final name = file.name.isNotEmpty ? file.name : 'cheque.jpg';
    setState(() {
      _chequeBytes = bytes;
      _chequeFileName = name;
    });

    ref.read(registrationFormProvider.notifier).setDocumentFile(
          type: DocumentType.cancelledCheque,
          bytes: bytes,
          fileName: name,
        );

    final ok = await ref
        .read(registrationFormProvider.notifier)
        .uploadDocument(DocumentType.cancelledCheque);
    if (!mounted) return;

    if (ok) {
      SnackBarHelper.showSuccess(context, 'Cheque photo uploaded');
    } else {
      final error = ref.read(registrationFormProvider).submitError ??
          'Upload failed. Check that the backend is running.';
      SnackBarHelper.showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final formState = ref.watch(registrationFormProvider);
    final chequeUploaded = formState.uploadedDocuments
        .containsKey(DocumentType.cancelledCheque);
    final chequeProgress =
        formState.uploadProgress[DocumentType.cancelledCheque] ?? 0;

    return registrationStepScroll(
      child: Form(
        key: widget.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Payout details', style: AppTextStyles.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Enter your bank account and UPI details. Both are required for payouts.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Preferred payout method',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<PayoutMethod>(
              segments: const [
                ButtonSegment(
                  value: PayoutMethod.bank,
                  label: Text('Bank'),
                  icon: Icon(Icons.account_balance_rounded, size: 18),
                ),
                ButtonSegment(
                  value: PayoutMethod.upi,
                  label: Text('UPI'),
                  icon: Icon(Icons.qr_code_2_rounded, size: 18),
                ),
              ],
              selected: {formState.payoutMethod},
              onSelectionChanged: (value) {
                ref.read(registrationFormProvider.notifier).updateBankDetails(
                      payoutMethod: value.first,
                    );
              },
            ),
            const SizedBox(height: 20),
            CustomTextField(
              controller: _accountController,
              label: 'Account number',
              hint: 'Enter bank account number',
              prefixIcon: Icons.account_balance_rounded,
              keyboardType: TextInputType.number,
              validator: ValidationUtils.validateAccountNumber,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _ifscController,
              label: 'IFSC code',
              hint: 'e.g. HDFC0001234',
              prefixIcon: Icons.code_rounded,
              validator: ValidationUtils.validateIfscCode,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _upiController,
              label: 'UPI ID',
              hint: 'e.g. yourname@oksbi or 9876543210@paytm',
              prefixIcon: Icons.qr_code_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: ValidationUtils.validateUpiId,
            ),
            const SizedBox(height: 8),
            Text(
              'Use the UPI ID linked to your practice bank account.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Cancelled cheque photo',
              style: AppTextStyles.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload a clear photo of a cancelled cheque or bank passbook page showing account number & IFSC.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTap: _pickChequePhoto,
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: AppDecorations.borderRadiusMd,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: _chequeBytes != null && _chequeBytes!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: AppDecorations.borderRadiusMd,
                          child: Image.memory(
                            _chequeBytes!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            children: [
                              Icon(
                                Icons.receipt_long_rounded,
                                size: 48,
                                color: AppColors.grey400,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap to upload cheque photo',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
            if (_chequeFileName != null) ...[
              const SizedBox(height: 8),
              Text(
                _chequeFileName!,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
            const SizedBox(height: 16),
            CustomOutlineButton(
              label: chequeUploaded ? 'Cheque uploaded' : 'Upload cheque photo',
              icon: chequeUploaded
                  ? Icons.check_circle_rounded
                  : Icons.cloud_upload_outlined,
              onPressed: (_chequeBytes == null && _chequeFileName == null)
                  ? () {}
                  : () => ref
                      .read(registrationFormProvider.notifier)
                      .uploadDocument(DocumentType.cancelledCheque),
              isEnabled:
                  _chequeBytes != null || _chequeFileName != null,
            ),
            if (chequeProgress > 0 && chequeProgress < 1) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(value: chequeProgress),
            ],
            if (formState.submitError != null) ...[
              const SizedBox(height: 12),
              Text(
                formState.submitError!,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class Step6WeeklyAvailability extends ConsumerWidget {
  const Step6WeeklyAvailability({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(registrationFormProvider);
    final weekStart = _currentWeekSunday();
    final weekLabel =
        'Week of ${_formatShortDate(weekStart)} – ${_formatShortDate(weekStart.add(const Duration(days: 6)))}';
    final showOnline = formState.offersOnlineConsult;
    final showClinic = formState.offersVisitSite;
    final showHome = formState.offersBookHome;
    final showAnyPicker = showOnline || showClinic || showHome;
    final blockedForOnline = {
      ...formState.selectedClinicAvailabilitySlots,
      ...formState.selectedHomeAvailabilitySlots,
    };
    final blockedForClinic = {
      ...formState.selectedOnlineAvailabilitySlots,
      ...formState.selectedHomeAvailabilitySlots,
    };
    final blockedForHome = {
      ...formState.selectedOnlineAvailabilitySlots,
      ...formState.selectedClinicAvailabilitySlots,
    };

    return registrationStepScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Weekly availability',
            subtitle:
                'Set separate schedules for online consult, clinic visits, and home visits (Sunday–Saturday, 8 AM–6 PM). The same hour cannot be used for more than one type.',
          ),
          if (!showAnyPicker)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.grey50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Text(
                'Select at least one consultation option in the previous step to set your weekly schedule.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
          if (showOnline) ...[
            _AvailabilityTypeHeader(
              icon: Icons.videocam_rounded,
              title: 'Online consult slots',
              subtitle:
                  'When patients can book video / chat consultations with you.',
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            WeeklyAvailabilityPicker(
              weekLabel: weekLabel,
              selectedSlots: formState.selectedOnlineAvailabilitySlots,
              blockedSlots: blockedForOnline,
              onToggle: (day, hour, selected) => ref
                  .read(registrationFormProvider.notifier)
                  .toggleOnlineAvailabilitySlot(day, hour, selected),
            ),
          ],
          if (showOnline && (showClinic || showHome)) const SizedBox(height: 28),
          if (showClinic) ...[
            _AvailabilityTypeHeader(
              icon: Icons.local_hospital_rounded,
              title: 'Clinic visit slots',
              subtitle:
                  'When patients can book in-person appointments at your clinic (including weekends).',
              color: AppColors.accent,
            ),
            const SizedBox(height: 12),
            WeeklyAvailabilityPicker(
              weekLabel: weekLabel,
              selectedSlots: formState.selectedClinicAvailabilitySlots,
              blockedSlots: blockedForClinic,
              selectedColor: AppColors.accent,
              onToggle: (day, hour, selected) => ref
                  .read(registrationFormProvider.notifier)
                  .toggleClinicAvailabilitySlot(day, hour, selected),
            ),
          ],
          if (showClinic && showHome) const SizedBox(height: 28),
          if (showHome) ...[
            _AvailabilityTypeHeader(
              icon: Icons.home_rounded,
              title: 'Home visit slots',
              subtitle:
                  'When you are available to visit patients at their home.',
              color: AppColors.secondary,
            ),
            const SizedBox(height: 12),
            WeeklyAvailabilityPicker(
              weekLabel: weekLabel,
              selectedSlots: formState.selectedHomeAvailabilitySlots,
              blockedSlots: blockedForHome,
              selectedColor: AppColors.secondary,
              onToggle: (day, hour, selected) => ref
                  .read(registrationFormProvider.notifier)
                  .toggleHomeAvailabilitySlot(day, hour, selected),
            ),
          ],
        ],
      ),
    );
  }

  DateTime _currentWeekSunday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return today.subtract(Duration(days: today.weekday % 7));
  }

  String _formatShortDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

class _AvailabilityTypeHeader extends StatelessWidget {
  const _AvailabilityTypeHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class Step7ReviewSubmit extends ConsumerStatefulWidget {
  const Step7ReviewSubmit({
    super.key,
    required this.onSubmit,
    required this.onEdit,
  });

  final Future<void> Function() onSubmit;
  final void Function(int step) onEdit;

  @override
  ConsumerState<Step7ReviewSubmit> createState() => _Step7ReviewSubmitState();
}

class _Step7ReviewSubmitState extends ConsumerState<Step7ReviewSubmit> {
  bool _acknowledged = false;

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(registrationFormProvider);
    final registrationState = ref.watch(doctorRegistrationProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Review & Submit',
            subtitle: 'Confirm your details before submitting.',
          ),
          _ReviewSection(
            title: 'Personal Information',
            onEdit: () => widget.onEdit(1),
            items: [
              _ReviewItem('Full Name', formState.fullName),
              _ReviewItem(
                'Mobile',
                ValidationUtils.formatInternationalPhone(
                  formState.mobileNumber,
                  countryCode: formState.countryCode,
                ),
              ),
              _ReviewItem('Aadhaar', formState.aadhaarMaskedDisplay),
              _ReviewItem('Email', formState.email),
              _ReviewItem(
                'Email verified',
                formState.emailVerified ? 'Yes' : 'No',
              ),
              _ReviewItem('Gender', formState.gender ?? '-'),
              _ReviewItem(
                'Date of Birth',
                formState.dateOfBirth != null
                    ? FormattingUtils.formatDate(formState.dateOfBirth!)
                    : '-',
              ),
            ],
          ),
          _ReviewSection(
            title: 'Professional Details',
            onEdit: () => widget.onEdit(2),
            items: [
              _ReviewItem(
                'Medical Reg. No',
                formState.medicalRegistrationNumber,
              ),
              _ReviewItem('Council', formState.medicalCouncilName),
              _ReviewItem(
                'Specializations',
                formState.specializations.join(', '),
              ),
              _ReviewItem('Qualification', formState.qualification),
              _ReviewItem('Experience', formState.yearsOfExperience),
              _ReviewItem('Clinic', formState.clinicName),
              if (formState.offersOnlineConsult)
                _ReviewItem('Online fee (INR)', formState.onlineConsultFee),
              if (formState.offersOnlineConsult &&
                  formState.onlineConsultOfferFee.trim().isNotEmpty)
                _ReviewItem(
                  'Online offer (INR)',
                  formState.onlineConsultOfferFee,
                ),
              if (formState.offersVisitSite)
                _ReviewItem('Hospital visit fee (INR)', formState.visitSiteFee),
              if (formState.offersVisitSite &&
                  formState.visitSiteOfferFee.trim().isNotEmpty)
                _ReviewItem(
                  'Hospital visit offer (INR)',
                  formState.visitSiteOfferFee,
                ),
              if (formState.offersBookHome)
                _ReviewItem('Home visit fee (INR)', formState.homeVisitFee),
              if (formState.offersBookHome &&
                  formState.homeVisitOfferFee.trim().isNotEmpty)
                _ReviewItem(
                  'Home visit offer (INR)',
                  formState.homeVisitOfferFee,
                ),
              _ReviewItem(
                'Languages',
                formState.languagesSpoken.join(', '),
              ),
              _ReviewItem(
                'Consultation options',
                [
                  if (formState.offersOnlineConsult) 'Online',
                  if (formState.offersVisitSite) 'Visit hospital',
                  if (formState.offersBookHome) 'Book home',
                ].join(', '),
              ),
            ],
          ),
          _ReviewSection(
            title: 'Clinic Address',
            onEdit: () => widget.onEdit(3),
            items: [
              _ReviewItem('Address', formState.address),
              _ReviewItem('City', formState.city),
              _ReviewItem('State', formState.state),
              _ReviewItem('Pincode', formState.pincode),
              _ReviewItem(
                'Hospital photos',
                '${formState.uploadedHospitalPhotoCount}/$doctorHospitalPhotoCount uploaded',
              ),
            ],
          ),
          _ReviewSection(
            title: 'Documents',
            onEdit: () => widget.onEdit(4),
            items: [
              _ReviewItem(
                'Medical License',
                formState.uploadedDocuments.containsKey(
                        DocumentType.medicalLicense)
                    ? 'Uploaded'
                    : 'Pending',
              ),
              _ReviewItem(
                'Aadhaar Card',
                formState.uploadedDocuments.containsKey(DocumentType.aadhaarCard)
                    ? 'Uploaded'
                    : 'Pending',
              ),
              _ReviewItem(
                'Degree Certificate',
                formState.uploadedDocuments.containsKey(
                        DocumentType.degreeCertificate)
                    ? 'Uploaded'
                    : 'Pending',
              ),
              _ReviewItem(
                'Clinic Proof',
                formState.uploadedDocuments.containsKey(DocumentType.clinicProof)
                    ? 'Uploaded'
                    : 'Pending',
              ),
            ],
          ),
          _ReviewSection(
            title: 'Weekly availability',
            onEdit: () => widget.onEdit(6),
            items: [
              if (formState.offersOnlineConsult)
                _ReviewItem(
                  'Online consult slots',
                  '${formState.selectedOnlineAvailabilityCount} hour(s) this week',
                ),
              if (formState.offersVisitSite)
                _ReviewItem(
                  'Clinic visit slots',
                  '${formState.selectedClinicAvailabilityCount} hour(s) this week',
                ),
              if (formState.offersBookHome)
                _ReviewItem(
                  'Home visit slots',
                  '${formState.selectedHomeAvailabilityCount} hour(s) this week',
                ),
            ],
          ),
          _ReviewSection(
            title: 'Payout details',
            onEdit: () => widget.onEdit(5),
            items: [
              _ReviewItem('Payout method', formState.payoutMethod.label),
              _ReviewItem('Account number', formState.bankAccountNumber),
              _ReviewItem('IFSC code', formState.ifscCode.toUpperCase()),
              _ReviewItem('UPI ID', formState.upiId),
              _ReviewItem(
                'Cancelled cheque',
                formState.uploadedDocuments
                        .containsKey(DocumentType.cancelledCheque)
                    ? 'Uploaded'
                    : 'Pending',
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ModernCard(
              child: RegistrationAcknowledgmentSection(
                value: _acknowledged,
                onChanged: (value) => setState(() => _acknowledged = value),
              ),
            ),
          ),
          const SizedBox(height: 8),
          CustomButton(
            label: 'Submit Application',
            isLoading: registrationState.isLoading || formState.isSubmitting,
            isEnabled: _acknowledged,
            onPressed: () async => widget.onSubmit(),
          ),
          if (registrationState.error != null) ...[
            const SizedBox(height: 12),
            Text(
              registrationState.error!,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
          ],
        ],
      ),
    );
  }
}

class _HospitalPhotoUploadTile extends StatelessWidget {
  const _HospitalPhotoUploadTile({
    required this.label,
    required this.imageBytes,
    required this.imageUrl,
    required this.uploaded,
    required this.progress,
    required this.onTap,
  });

  final String label;
  final Uint8List? imageBytes;
  final String? imageUrl;
  final bool uploaded;
  final double progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasPreview = (imageBytes != null && imageBytes!.isNotEmpty) ||
        (imageUrl != null && imageUrl!.isNotEmpty);
    final isUploading = progress > 0 && progress < 1;

    return Material(
      color: AppColors.grey50,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: isUploading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: uploaded
                  ? AppColors.success.withValues(alpha: 0.5)
                  : AppColors.grey300,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasPreview)
                ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Image(
                    image: imageBytes != null
                        ? MemoryImage(imageBytes!)
                        : NetworkImage(imageUrl!) as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo_outlined,
                      size: 32,
                      color: AppColors.primary.withValues(alpha: 0.7),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              if (isUploading)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Center(
                    child: CircularProgressIndicator(
                      value: progress > 0 ? progress : null,
                      color: AppColors.white,
                    ),
                  ),
                ),
              if (uploaded)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: AppColors.white,
                    ),
                  ),
                ),
              Positioned(
                left: 8,
                bottom: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    label,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfilePreview extends StatelessWidget {
  const _ProfilePreview({
    required this.imageBytes,
    required this.imagePath,
  });

  final Uint8List? imageBytes;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final hasImage = (imageBytes != null && imageBytes!.isNotEmpty) ||
        (imagePath != null && imagePath!.isNotEmpty);

    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.grey100,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: ClipOval(
        child: hasImage
            ? Image(
                image: imageBytes != null
                    ? MemoryImage(imageBytes!)
                    : NetworkImage(imagePath!) as ImageProvider,
                fit: BoxFit.cover,
              )
            : Icon(
                Icons.person,
                size: 48,
                color: AppColors.grey400,
              ),
      ),
    );
  }
}

/// Fee inputs shown only for selected consultation options.
class _ConsultationFeesSection extends StatelessWidget {
  const _ConsultationFeesSection({
    required this.offersOnlineConsult,
    required this.offersBookHome,
    required this.offersVisitSite,
    required this.onlineFeeController,
    required this.homeFeeController,
    required this.visitSiteFeeController,
    required this.onlineOfferFeeController,
    required this.homeOfferFeeController,
    required this.visitSiteOfferFeeController,
  });

  final bool offersOnlineConsult;
  final bool offersBookHome;
  final bool offersVisitSite;
  final TextEditingController onlineFeeController;
  final TextEditingController homeFeeController;
  final TextEditingController visitSiteFeeController;
  final TextEditingController onlineOfferFeeController;
  final TextEditingController homeOfferFeeController;
  final TextEditingController visitSiteOfferFeeController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Consultation fees',
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Set a regular fee and an optional offer/discount price for each type you offer.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        if (offersOnlineConsult) ...[
          const SizedBox(height: 16),
          CustomTextField(
            controller: onlineFeeController,
            label: 'Online consult fee (INR)',
            hint: '500',
            prefixIcon: Icons.videocam_outlined,
            keyboardType: TextInputType.number,
            validator: ValidationUtils.validateConsultationFee,
          ),
          const SizedBox(height: 12),
          CustomTextField(
            controller: onlineOfferFeeController,
            label: 'Online offer price (optional)',
            hint: '399',
            prefixIcon: Icons.local_offer_outlined,
            keyboardType: TextInputType.number,
            validator: (v) => ValidationUtils.validateOptionalOfferFee(
              v,
              onlineFeeController.text,
            ),
          ),
        ],
        if (offersVisitSite) ...[
          const SizedBox(height: 16),
          CustomTextField(
            controller: visitSiteFeeController,
            label: 'Hospital visit fee (INR)',
            hint: '600',
            prefixIcon: Icons.local_hospital_outlined,
            keyboardType: TextInputType.number,
            validator: ValidationUtils.validateConsultationFee,
          ),
          const SizedBox(height: 12),
          CustomTextField(
            controller: visitSiteOfferFeeController,
            label: 'Hospital visit offer price (optional)',
            hint: '499',
            prefixIcon: Icons.local_offer_outlined,
            keyboardType: TextInputType.number,
            validator: (v) => ValidationUtils.validateOptionalOfferFee(
              v,
              visitSiteFeeController.text,
            ),
          ),
        ],
        if (offersBookHome) ...[
          const SizedBox(height: 16),
          CustomTextField(
            controller: homeFeeController,
            label: 'Home visit fee (INR)',
            hint: '800',
            prefixIcon: Icons.home_outlined,
            keyboardType: TextInputType.number,
            validator: ValidationUtils.validateConsultationFee,
          ),
          const SizedBox(height: 12),
          CustomTextField(
            controller: homeOfferFeeController,
            label: 'Home visit offer price (optional)',
            hint: '699',
            prefixIcon: Icons.local_offer_outlined,
            keyboardType: TextInputType.number,
            validator: (v) => ValidationUtils.validateOptionalOfferFee(
              v,
              homeFeeController.text,
            ),
          ),
        ],
      ],
    );
  }
}

/// Toggle buttons for online consult, clinic visit, and home visit.
class _ConsultationOptionsPicker extends StatelessWidget {
  const _ConsultationOptionsPicker({
    required this.offersOnlineConsult,
    required this.offersBookHome,
    required this.offersVisitSite,
    required this.onToggleOnline,
    required this.onToggleBookHome,
    required this.onToggleVisitSite,
  });

  final bool offersOnlineConsult;
  final bool offersBookHome;
  final bool offersVisitSite;
  final ValueChanged<bool> onToggleOnline;
  final ValueChanged<bool> onToggleBookHome;
  final ValueChanged<bool> onToggleVisitSite;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Consultation options',
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Choose how patients can book with you. Tap to select at least one.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ConsultationOptionButton(
                icon: Icons.videocam_rounded,
                title: 'Online',
                subtitle: 'Video consult',
                selected: offersOnlineConsult,
                onTap: () => onToggleOnline(!offersOnlineConsult),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ConsultationOptionButton(
                icon: Icons.local_hospital_rounded,
                title: 'Visit hospital',
                subtitle: 'Clinic appointment',
                selected: offersVisitSite,
                onTap: () => onToggleVisitSite(!offersVisitSite),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ConsultationOptionButton(
                icon: Icons.home_rounded,
                title: 'Book home',
                subtitle: 'Home visit',
                selected: offersBookHome,
                onTap: () => onToggleBookHome(!offersBookHome),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ConsultationOptionButton extends StatelessWidget {
  const _ConsultationOptionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryLight : AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.grey200,
          width: selected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    size: 26,
                    color: selected ? AppColors.primary : AppColors.textSecondary,
                  ),
                  if (selected)
                    Positioned(
                      right: -10,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 10,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.primaryDark : AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelSmall.copyWith(
                  fontSize: 9,
                  color: AppColors.textSecondary,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Searchable field to find and add items; selected values shown as removable chips.
class _SearchableMultiSelectPicker extends StatefulWidget {
  const _SearchableMultiSelectPicker({
    required this.label,
    required this.hint,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.prefixIcon,
    this.helperText,
  });

  final String label;
  final String hint;
  final IconData? prefixIcon;
  final String? helperText;
  final List<String> options;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  @override
  State<_SearchableMultiSelectPicker> createState() =>
      _SearchableMultiSelectPickerState();
}

class _SearchableMultiSelectPickerState
    extends State<_SearchableMultiSelectPicker> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _available => widget.options
      .where((option) => !widget.selected.contains(option))
      .toList(growable: false);

  List<String> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    final available = _available;
    if (query.isEmpty) return available;
    return available
        .where((option) => option.toLowerCase().contains(query))
        .toList(growable: false);
  }

  void _addOption(String value) {
    widget.onChanged([...widget.selected, value]);
    _searchController.clear();
    setState(() {});
  }

  void _removeOption(String value) {
    widget.onChanged(
      widget.selected.where((item) => item != value).toList(growable: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final query = _searchController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.selected.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.selected.map(_selectedChip).toList(),
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: _searchController,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            helperText: widget.helperText,
            prefixIcon:
                widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
            suffixIcon: query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  )
                : const Icon(Icons.search_rounded),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        if (_available.isEmpty)
          Text(
            'All options added',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          )
        else if (query.isNotEmpty && filtered.isEmpty)
          Text(
            'No results found for "$query"',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          )
        else
          Container(
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.grey200),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: AppColors.divider,
              ),
              itemBuilder: (context, index) {
                final option = filtered[index];
                return ListTile(
                  dense: true,
                  title: Text(
                    option,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.add_circle_outline_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  onTap: () => _addOption(option),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _selectedChip(String item) {
    return InputChip(
      label: Text(
        item,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.primaryDark,
          fontWeight: FontWeight.w600,
        ),
      ),
      deleteIcon: const Icon(
        Icons.close_rounded,
        size: 18,
        color: AppColors.primaryDark,
      ),
      onDeleted: () => _removeOption(item),
      backgroundColor: AppColors.primaryLight,
      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
    );
  }
}

class _DocumentUploadTile extends StatelessWidget {
  const _DocumentUploadTile({
    required this.title,
    required this.documentType,
    required this.fileName,
    required this.previewBytes,
    required this.progress,
    required this.uploaded,
    required this.onSelect,
    required this.onUpload,
  });

  final String title;
  final DocumentType documentType;
  final String? fileName;
  final Uint8List? previewBytes;
  final double progress;
  final bool uploaded;
  final VoidCallback onSelect;
  final VoidCallback onUpload;

  bool get _isPdf => fileName?.toLowerCase().endsWith('.pdf') ?? false;

  @override
  Widget build(BuildContext context) {
    final showPreview = previewBytes != null && previewBytes!.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _isPdf ? Icons.picture_as_pdf : Icons.insert_drive_file,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.labelLarge),
                      const SizedBox(height: 4),
                      Text(
                        fileName ?? 'No file selected',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (uploaded)
                  const Icon(Icons.verified, color: AppColors.success),
              ],
            ),
            if (showPreview && !_isPdf) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  previewBytes!,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            if (progress > 0 && progress < 1) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(value: progress),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CustomOutlineButton(
                    label: 'Select File',
                    onPressed: onSelect,
                    icon: Icons.upload_file,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    label: uploaded ? 'Uploaded' : 'Upload',
                    onPressed: uploaded ? () {} : onUpload,
                    isEnabled: !uploaded,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewSection extends StatelessWidget {
  const _ReviewSection({
    required this.title,
    required this.items,
    required this.onEdit,
  });

  final String title;
  final List<_ReviewItem> items;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ModernCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: AppTextStyles.titleSmall),
                TextButton(
                  onPressed: onEdit,
                  style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                  child: const Text('Edit'),
                ),
              ],
            ),
            const Divider(height: 20),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 128,
                        child: Text(
                          item.label,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.value.isEmpty ? '-' : item.value,
                          style: AppTextStyles.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _ReviewItem {
  _ReviewItem(this.label, this.value);

  final String label;
  final String value;
}

class _AadhaarInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 12) {
      return oldValue;
    }
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    final formatted = buf.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
