import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_lists.dart';
import '../../../../core/constants/nurse_constants.dart';
import '../../../../core/constants/phone_countries.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/text_controller_utils.dart';
import '../../../../core/utils/validation_utils.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../shared/widgets/gender_radio_field.dart';
import '../../../../shared/widgets/healthcare_ui.dart';
import '../../../../shared/widgets/mobile_number_field.dart';
import '../../../../shared/widgets/profile_picture_picker.dart';
import '../../../../shared/widgets/registration_location_input.dart';
import '../../../doctor_registration/presentation/widgets/weekly_availability_picker.dart';
import '../../provider/nurse_registration_provider.dart';

Widget nurseStepScroll({required Widget child}) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
    child: child,
  );
}

class _NurseSearchableMultiSelectPicker extends StatefulWidget {
  const _NurseSearchableMultiSelectPicker({
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
  State<_NurseSearchableMultiSelectPicker> createState() =>
      _NurseSearchableMultiSelectPickerState();
}

class _NurseSearchableMultiSelectPickerState
    extends State<_NurseSearchableMultiSelectPicker> {
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
              separatorBuilder: (_, _) => const Divider(
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

class _NurseChipMultiSelect extends StatelessWidget {
  const _NurseChipMultiSelect({
    required this.label,
    required this.helperText,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final String helperText;
  final List<String> options;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          helperText,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selected.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              showCheckmark: false,
              onSelected: (value) {
                final next = List<String>.from(selected);
                if (value) {
                  next.add(option);
                } else {
                  next.remove(option);
                }
                onChanged(next);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _NurseDateOfBirthTile extends StatelessWidget {
  const _NurseDateOfBirthTile({
    required this.value,
    required this.onChanged,
  });

  final DateTime? value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text('Date of birth', style: AppTextStyles.labelLarge),
      subtitle: Text(
        value != null
            ? '${value!.day}/${value!.month}/${value!.year}'
            : 'Tap to select',
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
      ),
      trailing: const Icon(Icons.calendar_month_outlined),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime(1995),
          firstDate: DateTime(1950),
          lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
        );
        if (picked != null) onChanged(picked);
      },
    );
  }
}

class NurseStep1Personal extends ConsumerStatefulWidget {
  const NurseStep1Personal({super.key, required this.formKey});
  final GlobalKey<FormState> formKey;

  @override
  ConsumerState<NurseStep1Personal> createState() => _NurseStep1PersonalState();
}

class _NurseStep1PersonalState extends ConsumerState<NurseStep1Personal>
    with AutomaticKeepAliveClientMixin {
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  String? _selectedGender;
  late final TextEditingController _email;
  late final TextEditingController _mobile;
  late final TextEditingController _password;
  late final TextEditingController _confirmPassword;
  late final TextEditingController _emergencyName;
  late final TextEditingController _emergencyMobile;
  DateTime? _dateOfBirth;
  List<String> _languages = [];
  Uint8List? _profileBytes;
  String? _profileFileName;
  String _countryCode = PhoneCountries.defaultDialCode;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final s = ref.read(nurseRegistrationFormProvider);
    _firstName = TextEditingController(text: s.firstName);
    _lastName = TextEditingController(text: s.lastName);
    _selectedGender = s.gender;
    _email = TextEditingController(text: s.email);
    _mobile = TextEditingController(text: s.mobileNumber);
    _countryCode = s.countryCode;
    _password = TextEditingController(text: s.password);
    _confirmPassword = TextEditingController(text: s.confirmPassword);
    _emergencyName = TextEditingController(text: s.emergencyContactName);
    _emergencyMobile = TextEditingController(text: s.emergencyContactNumber);
    _dateOfBirth = s.dateOfBirth;
    _languages = List<String>.from(s.languagesSpoken);
    _profileBytes = s.profileImageBytes;
    _profileFileName = s.profileImageFileName;
    for (final c in [
      _firstName,
      _lastName,
      _email,
      _mobile,
      _password,
      _confirmPassword,
      _emergencyName,
      _emergencyMobile,
    ]) {
      addTextChangeListener(c, (_) => _sync());
    }
  }

  void _sync() {
    ref.read(nurseRegistrationFormProvider.notifier).updatePersonal(
          firstName: _firstName.text,
          lastName: _lastName.text,
          gender: _selectedGender,
          dateOfBirth: _dateOfBirth,
          languagesSpoken: _languages,
          emergencyContactName: _emergencyName.text,
          emergencyContactNumber: _emergencyMobile.text,
          email: _email.text,
          mobileNumber: _mobile.text,
          countryCode: _countryCode,
          password: _password.text,
          confirmPassword: _confirmPassword.text,
          profileImageBytes: _profileBytes,
          profileImageFileName: _profileFileName,
        );
  }

  @override
  void dispose() {
    for (final c in [
      _firstName,
      _lastName,
      _email,
      _mobile,
      _password,
      _confirmPassword,
      _emergencyName,
      _emergencyMobile,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return nurseStepScroll(
      child: Form(
        key: widget.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal details',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Home visit nurses need a verified profile photo and login.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ProfilePicturePicker(
              imageBytes: _profileBytes,
              onImagePicked: (bytes, fileName) {
                setState(() {
                  _profileBytes = bytes;
                  _profileFileName = fileName;
                });
                _sync();
              },
              onError: (msg) => SnackBarHelper.showError(context, msg),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _firstName,
              label: 'First name',
              prefixIcon: Icons.person_outline_rounded,
              validator: (v) =>
                  ValidationUtils.validateName(v, fieldName: 'First name'),
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _lastName,
              label: 'Last name',
              prefixIcon: Icons.person_outline_rounded,
              validator: (v) =>
                  ValidationUtils.validateName(v, fieldName: 'Last name'),
            ),
            const SizedBox(height: 12),
            GenderRadioField(
              value: _selectedGender,
              options: nurseGenders,
              onChanged: (value) {
                setState(() => _selectedGender = value);
                _sync();
              },
              validator: (v) =>
                  v == null || v.isEmpty ? 'Please select gender' : null,
            ),
            const SizedBox(height: 12),
            _NurseDateOfBirthTile(
              value: _dateOfBirth,
              onChanged: (date) {
                setState(() => _dateOfBirth = date);
                _sync();
              },
            ),
            const SizedBox(height: 12),
            _NurseSearchableMultiSelectPicker(
              label: 'Languages spoken',
              hint: 'Search language',
              helperText: 'Search and tap to add. You can select more than one.',
              prefixIcon: Icons.translate_rounded,
              options: AppLists.languages,
              selected: _languages,
              onChanged: (values) {
                setState(() => _languages = values);
                _sync();
              },
            ),
            const SizedBox(height: 18),
            Text(
              'Emergency contact',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _emergencyName,
              label: 'Emergency contact name',
              prefixIcon: Icons.contact_emergency_outlined,
              validator: (v) => ValidationUtils.validateName(
                v,
                fieldName: 'Emergency contact name',
              ),
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _emergencyMobile,
              label: 'Emergency contact mobile',
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
              inputFormatters: ValidationUtils.mobileInputFormatters(),
              validator: ValidationUtils.validatePhoneNumber,
            ),
            const SizedBox(height: 18),
            Text(
              'Contact & login',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            MobileNumberField(
              mobileController: _mobile,
              countryCode: _countryCode,
              onCountryCodeChanged: (code) {
                setState(() => _countryCode = code);
                _sync();
              },
              label: 'Mobile number',
              hint: '10-digit mobile number',
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _email,
              label: 'Email',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: ValidationUtils.validateEmail,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _password,
              label: 'Password',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: true,
              validator: ValidationUtils.validatePassword,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _confirmPassword,
              label: 'Confirm password',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: true,
              validator: (v) => ValidationUtils.validatePasswordMatch(
                _password.text,
                v,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NurseStep2Professional extends ConsumerStatefulWidget {
  const NurseStep2Professional({super.key, required this.formKey});
  final GlobalKey<FormState> formKey;

  @override
  ConsumerState<NurseStep2Professional> createState() =>
      _NurseStep2ProfessionalState();
}

class _NurseStep2ProfessionalState extends ConsumerState<NurseStep2Professional>
    with AutomaticKeepAliveClientMixin {
  late final TextEditingController _qualification;
  late final TextEditingController _qualificationOther;
  late final TextEditingController _registration;
  late final TextEditingController _council;
  late final TextEditingController _nuid;
  late final TextEditingController _experience;
  late final TextEditingController _specialization;
  late final TextEditingController _homeVisitFee;
  String? _selectedQualification;
  List<String> _selectedSkills = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final s = ref.read(nurseRegistrationFormProvider);
    _qualification = TextEditingController(text: s.qualification);
    _qualificationOther = TextEditingController(text: s.qualificationOther);
    _registration = TextEditingController(text: s.registrationNumber);
    _council = TextEditingController(text: s.nursingCouncil);
    _nuid = TextEditingController(text: s.nuid);
    _experience = TextEditingController(text: s.yearsOfExperience);
    _specialization = TextEditingController(text: s.specialization);
    _homeVisitFee = TextEditingController(text: s.homeVisitFee);
    _selectedQualification = nurseQualifications.contains(s.qualification)
        ? s.qualification
        : (s.qualification.isNotEmpty ? 'Other' : null);
    _selectedSkills = List<String>.from(s.nursingSkills);
    _sync();
    for (final c in [
      _qualification,
      _qualificationOther,
      _registration,
      _council,
      _nuid,
      _experience,
      _specialization,
      _homeVisitFee,
    ]) {
      addTextChangeListener(c, (_) => _sync());
    }
  }

  void _sync() {
    ref.read(nurseRegistrationFormProvider.notifier).updateProfessional(
          qualification: _selectedQualification ?? _qualification.text,
          qualificationOther: _qualificationOther.text,
          registrationNumber: _registration.text,
          nursingCouncil: _council.text,
          nuid: _nuid.text,
          yearsOfExperience: _experience.text,
          specialization: _specialization.text,
          nursingSkills: _selectedSkills,
          homeVisitFee: _homeVisitFee.text,
        );
  }

  @override
  void dispose() {
    for (final c in [
      _qualification,
      _qualificationOther,
      _registration,
      _council,
      _nuid,
      _experience,
      _specialization,
      _homeVisitFee,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return nurseStepScroll(
      child: Form(
        key: widget.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Professional details',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'You will offer home nursing visits only. Set your per-visit fee.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedQualification,
              decoration: const InputDecoration(
                labelText: 'Qualification',
                prefixIcon: Icon(Icons.school_outlined),
              ),
              items: nurseQualifications
                  .map((q) => DropdownMenuItem(value: q, child: Text(q)))
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedQualification = value);
                _sync();
              },
              validator: (v) =>
                  v == null || v.isEmpty ? 'Select qualification' : null,
            ),
            if (_selectedQualification == 'Other') ...[
              const SizedBox(height: 12),
              CustomTextField(
                controller: _qualificationOther,
                label: 'Specify qualification',
                prefixIcon: Icons.school_outlined,
                validator: (v) => ValidationUtils.validateOrganizationName(
                  v,
                  fieldName: 'Qualification',
                ),
              ),
            ],
            const SizedBox(height: 12),
            CustomTextField(
              controller: _registration,
              label: 'State nursing council registration number',
              prefixIcon: Icons.badge_outlined,
              validator: ValidationUtils.validateMedicalRegNumber,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _nuid,
              label: 'NUID (optional)',
              hint: 'Nurse Unique ID from INC / NRTS',
              prefixIcon: Icons.fingerprint_outlined,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _council,
              label: 'State nursing council',
              prefixIcon: Icons.account_balance_outlined,
              validator: (v) => ValidationUtils.validateOrganizationName(
                v,
                fieldName: 'Nursing council',
              ),
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _experience,
              label: 'Years of experience',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              prefixIcon: Icons.work_outline_rounded,
              validator: ValidationUtils.validateYearsOfExperience,
            ),
            const SizedBox(height: 12),
            _NurseChipMultiSelect(
              label: 'Clinical skills & services',
              helperText: 'Select the home visit services you can provide.',
              options: nurseClinicalSkills,
              selected: _selectedSkills,
              onChanged: (values) {
                setState(() => _selectedSkills = values);
                _sync();
              },
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _specialization,
              label: 'Specialization',
              hint: 'Elder care, post-op, pediatric, etc.',
              prefixIcon: Icons.medical_information_outlined,
              validator: (v) => ValidationUtils.validateRequired(
                v,
                fieldName: 'Specialization',
                minLength: 2,
              ),
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _homeVisitFee,
              label: 'Home visit fee (₹)',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              prefixIcon: Icons.currency_rupee_rounded,
              validator: ValidationUtils.validateConsultationFee,
            ),
          ],
        ),
      ),
    );
  }
}

class NurseStep3Location extends ConsumerStatefulWidget {
  const NurseStep3Location({super.key, required this.formKey});
  final GlobalKey<FormState> formKey;

  @override
  ConsumerState<NurseStep3Location> createState() => _NurseStep3LocationState();
}

class _NurseStep3LocationState extends ConsumerState<NurseStep3Location>
    with AutomaticKeepAliveClientMixin {
  late final TextEditingController _address;
  late final TextEditingController _city;
  late final TextEditingController _state;
  late final TextEditingController _pincode;
  double? _lat;
  double? _lng;
  int? _serviceRadiusKm;
  RegistrationLocationInputMode _locationMode =
      RegistrationLocationInputMode.map;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final s = ref.read(nurseRegistrationFormProvider);
    _address = TextEditingController(text: s.address);
    _city = TextEditingController(text: s.city);
    _state = TextEditingController(text: s.state);
    _pincode = TextEditingController(text: s.pincode);
    _lat = s.latitude;
    _lng = s.longitude;
    _serviceRadiusKm = s.serviceRadiusKm;
    _sync();
    for (final c in [_address, _city, _state, _pincode]) {
      addTextChangeListener(c, (_) => _sync());
    }
  }

  void _sync() {
    ref.read(nurseRegistrationFormProvider.notifier).updateLocation(
          address: _address.text,
          city: _city.text,
          stateValue: _state.text,
          pincode: _pincode.text,
          latitude: _lat,
          longitude: _lng,
          serviceRadiusKm: _serviceRadiusKm,
        );
  }

  @override
  void dispose() {
    for (final c in [_address, _city, _state, _pincode]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return nurseStepScroll(
      child: Form(
        key: widget.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Base location',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Patients see your city. Add your base by typing or using GPS, then choose how far you travel for home visits.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            RegistrationLocationBlock(
              mode: _locationMode,
              onModeChanged: (mode) => setState(() => _locationMode = mode),
              addressController: _address,
              cityController: _city,
              stateController: _state,
              pincodeController: _pincode,
              latitude: _lat,
              longitude: _lng,
              onLocationChanged: (lat, lng) {
                setState(() {
                  _lat = lat;
                  _lng = lng;
                });
                _sync();
              },
              mapEmptyHint: 'Pin your base location on the map.',
              mapWebTitle: 'Base location',
              footer: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Home visit radius',
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'How far can you travel? Patients within this distance can request you.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FormField<int>(
                    initialValue: _serviceRadiusKm,
                    validator: (v) =>
                        v == null ? 'Select how far you can travel' : null,
                    builder: (field) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: nurseServiceRadiusOptions.map((km) {
                              final selected = _serviceRadiusKm == km;
                              return ChoiceChip(
                                label: Text('$km km'),
                                selected: selected,
                                selectedColor: AppColors.primaryLight,
                                labelStyle: AppTextStyles.labelMedium.copyWith(
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                                side: BorderSide(
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.grey300,
                                ),
                                onSelected: (_) {
                                  setState(() => _serviceRadiusKm = km);
                                  field.didChange(km);
                                  _sync();
                                },
                              );
                            }).toList(),
                          ),
                          if (field.hasError) ...[
                            const SizedBox(height: 8),
                            Text(
                              field.errorText!,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NurseStep4Documents extends ConsumerWidget {
  const NurseStep4Documents({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(nurseRegistrationFormProvider);
    return nurseStepScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upload documents',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Upload license, ID, and compliance documents. Items marked * are required.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ...NurseDocumentType.values
              .where((t) => t != NurseDocumentType.cancelledCheque)
              .map(
                (type) => _DocumentTile(
                  type: type,
                  required: requiredNurseDocuments.contains(type),
                  uploaded: form.documentUrls.containsKey(type) ||
                      form.documentBytes.containsKey(type),
                  onPick: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
                      withData: true,
                    );
                    final file = result?.files.single;
                    if (file?.bytes == null) return;
                    ref
                        .read(nurseRegistrationFormProvider.notifier)
                        .setDocumentBytes(
                          type,
                          file!.bytes!,
                          file.name,
                        );
                  },
                ),
              ),
        ],
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({
    required this.type,
    required this.uploaded,
    required this.onPick,
    this.required = false,
  });

  final NurseDocumentType type;
  final bool uploaded;
  final VoidCallback onPick;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(
          uploaded ? Icons.check_circle_rounded : Icons.upload_file_rounded,
          color: uploaded ? AppColors.success : AppColors.primary,
        ),
        title: Text(required ? '${type.label} *' : type.label),
        subtitle: Text(uploaded ? 'Selected' : 'Tap to upload'),
        trailing: TextButton(onPressed: onPick, child: const Text('Upload')),
      ),
    );
  }
}

class NurseStep5Bank extends ConsumerStatefulWidget {
  const NurseStep5Bank({super.key, required this.formKey});
  final GlobalKey<FormState> formKey;

  @override
  ConsumerState<NurseStep5Bank> createState() => _NurseStep5BankState();
}

class _NurseStep5BankState extends ConsumerState<NurseStep5Bank>
    with AutomaticKeepAliveClientMixin {
  late final TextEditingController _holder;
  late final TextEditingController _account;
  late final TextEditingController _ifsc;
  late final TextEditingController _bank;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final s = ref.read(nurseRegistrationFormProvider);
    _holder = TextEditingController(text: s.bankAccountHolderName);
    _account = TextEditingController(text: s.bankAccountNumber);
    _ifsc = TextEditingController(text: s.ifscCode);
    _bank = TextEditingController(text: s.bankName);
    _sync();
    for (final c in [_holder, _account, _ifsc, _bank]) {
      addTextChangeListener(c, (_) => _sync());
    }
  }

  void _sync() {
    ref.read(nurseRegistrationFormProvider.notifier).updateBank(
          bankAccountHolderName: _holder.text,
          bankAccountNumber: _account.text,
          ifscCode: _ifsc.text,
          bankName: _bank.text,
        );
  }

  @override
  void dispose() {
    for (final c in [_holder, _account, _ifsc, _bank]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return nurseStepScroll(
      child: Form(
        key: widget.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payout details',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _holder,
              label: 'Account holder name',
              prefixIcon: Icons.person_outline_rounded,
              validator: ValidationUtils.validateAccountHolderName,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _account,
              label: 'Account number',
              keyboardType: TextInputType.number,
              prefixIcon: Icons.account_balance_wallet_outlined,
              validator: ValidationUtils.validateAccountNumber,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _ifsc,
              label: 'IFSC code',
              prefixIcon: Icons.tag_rounded,
              validator: ValidationUtils.validateIfscCode,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _bank,
              label: 'Bank name',
              prefixIcon: Icons.account_balance_outlined,
              validator: ValidationUtils.validateBankName,
            ),
            const SizedBox(height: 16),
            _DocumentTile(
              type: NurseDocumentType.cancelledCheque,
              uploaded: ref.watch(nurseRegistrationFormProvider).documentUrls
                      .containsKey(NurseDocumentType.cancelledCheque) ||
                  ref
                      .watch(nurseRegistrationFormProvider)
                      .documentBytes
                      .containsKey(NurseDocumentType.cancelledCheque),
              onPick: () async {
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.image,
                  withData: true,
                );
                final file = result?.files.single;
                if (file?.bytes == null) return;
                ref.read(nurseRegistrationFormProvider.notifier).setDocumentBytes(
                      NurseDocumentType.cancelledCheque,
                      file!.bytes!,
                      file.name,
                    );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class NurseStep6Availability extends ConsumerWidget {
  const NurseStep6Availability({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(nurseRegistrationFormProvider);
    return nurseStepScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Home visit availability',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Select when you can visit patients at home (Sun–Sat, 8 AM–6 PM).',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          WeeklyAvailabilityPicker(
            selectedSlots: form.selectedHomeAvailabilitySlots,
            onToggle: (day, hour, selected) {
              final key = '${day}_$hour';
              ref
                  .read(nurseRegistrationFormProvider.notifier)
                  .toggleAvailabilitySlot(key, selected);
            },
            weekLabel: 'Weekly home visit slots',
          ),
        ],
      ),
    );
  }
}

class NurseStep7Review extends ConsumerWidget {
  const NurseStep7Review({
    super.key,
    required this.onEditStep,
    required this.acknowledged,
    required this.onAcknowledgedChanged,
  });

  final void Function(int step) onEditStep;
  final bool acknowledged;
  final ValueChanged<bool> onAcknowledgedChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(nurseRegistrationFormProvider);
    return nurseStepScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review & submit',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _ReviewSection(
            title: 'Personal Information',
            items: [
              _ReviewItem(
                'Name',
                '${form.firstName} ${form.lastName}'.trim(),
              ),
              if (form.gender != null && form.gender!.isNotEmpty)
                _ReviewItem('Gender', form.gender!),
              if (form.dateOfBirth != null)
                _ReviewItem(
                  'Date of Birth',
                  FormattingUtils.formatDate(form.dateOfBirth!),
                ),
              _ReviewItem(
                'Languages',
                form.languagesSpoken.isNotEmpty
                    ? form.languagesSpoken.join(', ')
                    : '-',
              ),
              if (form.emergencyContactName.trim().isNotEmpty)
                _ReviewItem(
                  'Emergency contact',
                  '${form.emergencyContactName} (${form.emergencyContactNumber})',
                ),
              if (form.mobileNumber.trim().isNotEmpty)
                _ReviewItem(
                  'Mobile',
                  ValidationUtils.formatInternationalPhone(
                    form.mobileNumber,
                    countryCode: form.countryCode,
                  ),
                ),
              _ReviewItem('Email', form.email),
            ],
            onEdit: () => onEditStep(1),
          ),
          _ReviewSection(
            title: 'Professional Details',
            items: [
              _ReviewItem('Qualification', form.resolvedQualification),
              _ReviewItem('Reg. Number', form.registrationNumber),
              if (form.nuid.trim().isNotEmpty) _ReviewItem('NUID', form.nuid),
              _ReviewItem('Council', form.nursingCouncil),
              _ReviewItem('Specialization', form.specialization),
              if (form.nursingSkills.isNotEmpty)
                _ReviewItem(
                  'Clinical skills',
                  form.nursingSkills.join(', '),
                ),
              _ReviewItem('Home visit fee', '₹${form.homeVisitFee}'),
            ],
            onEdit: () => onEditStep(2),
          ),
          _ReviewSection(
            title: 'Address',
            items: [
              _ReviewItem('Address', form.address),
              _ReviewItem(
                'City / State',
                '${form.city}, ${form.state}'.trim(),
              ),
              _ReviewItem('Pincode', form.pincode),
              if (form.serviceRadiusKm != null)
                _ReviewItem(
                  'Service radius',
                  '${form.serviceRadiusKm} km',
                ),
            ],
            onEdit: () => onEditStep(3),
          ),
          _ReviewSection(
            title: 'Documents',
            items: NurseDocumentType.values
                .map(
                  (t) => _ReviewItem(
                    t.label,
                    form.documentUrls.containsKey(t) ||
                            form.documentBytes.containsKey(t)
                        ? 'Ready'
                        : 'Missing',
                  ),
                )
                .toList(),
            onEdit: () => onEditStep(4),
          ),
          _ReviewSection(
            title: 'Payout',
            items: [
              _ReviewItem('Account holder', form.bankAccountHolderName),
              _ReviewItem('Bank', form.bankName),
              _ReviewItem('IFSC', form.ifscCode),
            ],
            onEdit: () => onEditStep(5),
          ),
          _ReviewSection(
            title: 'Availability',
            items: [
              _ReviewItem(
                'Home visit slots',
                '${form.selectedHomeAvailabilitySlots.length} selected',
              ),
            ],
            onEdit: () => onEditStep(6),
          ),
          const SizedBox(height: 8),
          RegistrationAcknowledgmentSection(
            value: acknowledged,
            onChanged: onAcknowledgedChanged,
          ),
        ],
      ),
    );
  }
}

class _ReviewItem {
  const _ReviewItem(this.label, this.value);

  final String label;
  final String value;
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(onPressed: onEdit, child: const Text('Edit')),
              ],
            ),
            const Divider(height: 20),
            ...items.map(
              (item) => Padding(
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
                        item.value.trim().isEmpty ? '-' : item.value,
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
