import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/nurse_constants.dart';
import '../../../../core/constants/phone_countries.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validation_utils.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../shared/widgets/mobile_number_field.dart';
import '../../../../shared/widgets/profile_picture_picker.dart';
import '../../../../shared/widgets/registration_map_picker.dart';
import '../../../doctor_registration/presentation/widgets/weekly_availability_picker.dart';
import '../../provider/nurse_registration_provider.dart';

Widget nurseStepScroll({required Widget child}) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
    child: child,
  );
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
    _profileBytes = s.profileImageBytes;
    _profileFileName = s.profileImageFileName;
    for (final c in [
      _firstName,
      _lastName,
      _email,
      _mobile,
      _password,
      _confirmPassword,
    ]) {
      c.addListener(_sync);
    }
  }

  void _sync() {
    ref.read(nurseRegistrationFormProvider.notifier).updatePersonal(
          firstName: _firstName.text,
          lastName: _lastName.text,
          gender: _selectedGender,
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
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _lastName,
              label: 'Last name',
              prefixIcon: Icons.person_outline_rounded,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: const InputDecoration(
                labelText: 'Gender',
                prefixIcon: Icon(Icons.wc_outlined),
              ),
              items: nurseGenders
                  .map(
                    (g) => DropdownMenuItem(value: g, child: Text(g)),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedGender = value);
                _sync();
              },
              validator: (v) =>
                  v == null || v.isEmpty ? 'Please select gender' : null,
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
  late final TextEditingController _registration;
  late final TextEditingController _council;
  late final TextEditingController _experience;
  late final TextEditingController _specialization;
  late final TextEditingController _homeVisitFee;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final s = ref.read(nurseRegistrationFormProvider);
    _qualification = TextEditingController(text: s.qualification);
    _registration = TextEditingController(text: s.registrationNumber);
    _council = TextEditingController(text: s.nursingCouncil);
    _experience = TextEditingController(text: s.yearsOfExperience);
    _specialization = TextEditingController(text: s.specialization);
    _homeVisitFee = TextEditingController(text: s.homeVisitFee);
    _sync();
    for (final c in [
      _qualification,
      _registration,
      _council,
      _experience,
      _specialization,
      _homeVisitFee,
    ]) {
      c.addListener(_sync);
    }
  }

  void _sync() {
    ref.read(nurseRegistrationFormProvider.notifier).updateProfessional(
          qualification: _qualification.text,
          registrationNumber: _registration.text,
          nursingCouncil: _council.text,
          yearsOfExperience: _experience.text,
          specialization: _specialization.text,
          homeVisitFee: _homeVisitFee.text,
        );
  }

  @override
  void dispose() {
    for (final c in [
      _qualification,
      _registration,
      _council,
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
            CustomTextField(
              controller: _qualification,
              label: 'Qualification',
              hint: 'GNM / B.Sc Nursing / ANM',
              prefixIcon: Icons.school_outlined,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _registration,
              label: 'Registration number',
              prefixIcon: Icons.badge_outlined,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _council,
              label: 'Nursing council',
              prefixIcon: Icons.account_balance_outlined,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _experience,
              label: 'Years of experience',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              prefixIcon: Icons.work_outline_rounded,
              validator: (v) {
                final n = int.tryParse((v ?? '').trim());
                if (n == null || n < 0) return 'Enter valid experience';
                return null;
              },
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _specialization,
              label: 'Specialization',
              hint: 'Elder care, post-op, pediatric, etc.',
              prefixIcon: Icons.medical_information_outlined,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _homeVisitFee,
              label: 'Home visit fee (₹)',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              prefixIcon: Icons.currency_rupee_rounded,
              validator: (v) {
                final fee = int.tryParse((v ?? '').trim());
                if (fee == null || fee < 1) {
                  return 'Enter a valid home visit fee';
                }
                if (fee > AppConstants.maxConsultationFee) {
                  return 'Fee cannot exceed ₹${AppConstants.maxConsultationFee}';
                }
                return null;
              },
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
    _sync();
    for (final c in [_address, _city, _state, _pincode]) {
      c.addListener(_sync);
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
              'Patients see your city. Distance is used when they request a home visit.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _address,
              label: 'Address',
              prefixIcon: Icons.home_outlined,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _city,
              label: 'City',
              prefixIcon: Icons.location_city_outlined,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _state,
              label: 'State',
              prefixIcon: Icons.map_outlined,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _pincode,
              label: 'Pincode',
              keyboardType: TextInputType.number,
              prefixIcon: Icons.pin_drop_outlined,
              validator: (v) =>
                  (v ?? '').trim().length == 6 ? null : 'Enter 6-digit pincode',
            ),
            const SizedBox(height: 16),
            RegistrationMapPicker(
              addressController: _address,
              cityController: _city,
              stateController: _state,
              pincodeController: _pincode,
              initialLatitude: _lat,
              initialLongitude: _lng,
              onLocationChanged: (lat, lng) {
                setState(() {
                  _lat = lat;
                  _lng = lng;
                });
                _sync();
              },
              emptyHint: 'Pin your base location on the map.',
              webTitle: 'Base location',
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
            'Admin will verify these before you appear in the patient app.',
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
  });

  final NurseDocumentType type;
  final bool uploaded;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(
          uploaded ? Icons.check_circle_rounded : Icons.upload_file_rounded,
          color: uploaded ? AppColors.success : AppColors.primary,
        ),
        title: Text(type.label),
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
      c.addListener(_sync);
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
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _account,
              label: 'Account number',
              keyboardType: TextInputType.number,
              prefixIcon: Icons.account_balance_wallet_outlined,
              validator: (v) =>
                  (v == null || v.trim().length < 6) ? 'Enter valid account' : null,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _ifsc,
              label: 'IFSC code',
              prefixIcon: Icons.tag_rounded,
              validator: (v) =>
                  (v == null || v.trim().length < 8) ? 'Enter valid IFSC' : null,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _bank,
              label: 'Bank name',
              prefixIcon: Icons.account_balance_outlined,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
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
  const NurseStep7Review({super.key, required this.onEditStep});

  final void Function(int step) onEditStep;

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
            title: 'Personal',
            lines: [
              '${form.firstName} ${form.lastName}'.trim(),
              if (form.gender != null && form.gender!.isNotEmpty)
                'Gender: ${form.gender}',
              if (form.mobileNumber.trim().isNotEmpty)
                '+${form.countryCode} ${form.mobileNumber.trim()}',
              form.email,
            ],
            onEdit: () => onEditStep(1),
          ),
          _ReviewSection(
            title: 'Professional',
            lines: [
              form.qualification,
              'Reg: ${form.registrationNumber}',
              form.specialization,
              'Home visit fee: ₹${form.homeVisitFee}',
            ],
            onEdit: () => onEditStep(2),
          ),
          _ReviewSection(
            title: 'Location',
            lines: [
              form.address,
              '${form.city}, ${form.state} ${form.pincode}'.trim(),
            ],
            onEdit: () => onEditStep(3),
          ),
          _ReviewSection(
            title: 'Documents',
            lines: NurseDocumentType.values
                .map((t) => '${t.label}: ${form.documentUrls.containsKey(t) || form.documentBytes.containsKey(t) ? 'Ready' : 'Missing'}')
                .toList(),
            onEdit: () => onEditStep(4),
          ),
          _ReviewSection(
            title: 'Payout',
            lines: [
              form.bankAccountHolderName,
              '${form.bankName} • ${form.ifscCode}',
            ],
            onEdit: () => onEditStep(5),
          ),
          _ReviewSection(
            title: 'Availability',
            lines: ['${form.selectedHomeAvailabilitySlots.length} slots selected'],
            onEdit: () => onEditStep(6),
          ),
        ],
      ),
    );
  }
}

class _ReviewSection extends StatelessWidget {
  const _ReviewSection({
    required this.title,
    required this.lines,
    required this.onEdit,
  });

  final String title;
  final List<String> lines;
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
            ...lines.where((l) => l.trim().isNotEmpty).map(
                  (l) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      l,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
