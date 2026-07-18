import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/phone_countries.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validation_utils.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/models/scan_center_model.dart';
import '../../../../shared/widgets/mobile_number_field.dart';
import '../../../../shared/widgets/profile_picture_picker.dart';
import '../../../../shared/widgets/registration_location_input.dart';
import '../../../../shared/widgets/healthcare_ui.dart';
import '../../../../core/models/provider_type.dart';
import '../../../provider/provider/provider_status_sync.dart';
import '../../../scans/data/scan_registration_catalog.dart';
import '../../../scans/data/models/scan_procedure_model.dart';
import '../../provider/scan_registration_provider.dart';

const _totalSteps = 5;

class ScanRegistrationScreen extends ConsumerStatefulWidget {
  const ScanRegistrationScreen({super.key});

  @override
  ConsumerState<ScanRegistrationScreen> createState() =>
      _ScanRegistrationScreenState();
}

class _ScanRegistrationScreenState extends ConsumerState<ScanRegistrationScreen> {
  final _centerId = const Uuid().v4();
  int _step = 0;
  bool _acknowledged = false;

  // Step 1 — business
  final _centerNameController = TextEditingController();
  final _ownerController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _gstController = TextEditingController();
  final _licenseController = TextEditingController();
  final _hoursController = TextEditingController();
  String _countryCode = PhoneCountries.defaultDialCode;
  bool _homeVisit = true;
  bool _available24x7 = false;
  double? _latitude;
  double? _longitude;
  RegistrationLocationInputMode _locationMode =
      RegistrationLocationInputMode.manual;
  Uint8List? _logoBytes;
  String? _logoFileName;

  // Step 2 — documents
  final List<({String label, String type, Uint8List bytes, String filename})>
      _pendingDocs = [];
  final List<({Uint8List bytes, String filename})> _pendingImages = [];

  // Step 3 — tests
  final Map<String, ScanOfferedProcedure> _selectedScans = {};
  ScanCategory? _testCategoryFilter;

  // Step 4 — offers & slots
  bool _offerAvailable = false;
  String _discountType = 'percentage';
  final _discountValueController = TextEditingController();
  final _offerTitleController = TextEditingController();
  final _offerDescriptionController = TextEditingController();
  final _minimumBookingController = TextEditingController();
  DateTime? _offerValidFrom;
  DateTime? _offerValidTill;
  final List<ScanAppointmentSlot> _appointmentSlots = [
    const ScanAppointmentSlot(day: 'Mon–Sat', startTime: '8:00 AM', endTime: '8:00 PM'),
  ];

  @override
  void dispose() {
    for (final c in [
      _centerNameController,
      _ownerController,
      _emailController,
      _mobileController,
      _passwordController,
      _confirmPasswordController,
      _addressController,
      _cityController,
      _stateController,
      _pincodeController,
      _gstController,
      _licenseController,
      _hoursController,
      _discountValueController,
      _offerTitleController,
      _offerDescriptionController,
      _minimumBookingController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _next() {
    if (!_validateCurrentStep()) return;
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
    }
  }

  bool _validateCurrentStep() {
    switch (_step) {
      case 0:
        final nameError = ValidationUtils.validateOrganizationName(
          _centerNameController.text,
          fieldName: 'Scan center name',
        );
        if (nameError != null) {
          SnackBarHelper.showError(context, nameError);
          return false;
        }
        final ownerError = ValidationUtils.validateName(
          _ownerController.text,
          fieldName: 'Owner name',
        );
        if (ownerError != null) {
          SnackBarHelper.showError(context, ownerError);
          return false;
        }
        final emailError =
            ValidationUtils.validateEmail(_emailController.text.trim());
        if (emailError != null) {
          SnackBarHelper.showError(context, emailError);
          return false;
        }
        final mobileError = ValidationUtils.validatePhoneNumber(
          _mobileController.text.trim(),
          countryCode: _countryCode,
        );
        if (mobileError != null) {
          SnackBarHelper.showError(context, mobileError);
          return false;
        }
        final passwordError =
            ValidationUtils.validatePassword(_passwordController.text);
        if (passwordError != null) {
          SnackBarHelper.showError(context, passwordError);
          return false;
        }
        final confirmError = ValidationUtils.validatePasswordMatch(
          _passwordController.text,
          _confirmPasswordController.text,
        );
        if (confirmError != null) {
          SnackBarHelper.showError(context, confirmError);
          return false;
        }
        final addressError =
            ValidationUtils.validateAddress(_addressController.text);
        if (addressError != null) {
          SnackBarHelper.showError(context, addressError);
          return false;
        }
        final cityError = ValidationUtils.validateCity(_cityController.text);
        if (cityError != null) {
          SnackBarHelper.showError(context, cityError);
          return false;
        }
        final stateError = ValidationUtils.validateState(_stateController.text);
        if (stateError != null) {
          SnackBarHelper.showError(context, stateError);
          return false;
        }
        final pincodeError =
            ValidationUtils.validatePincode(_pincodeController.text);
        if (pincodeError != null) {
          SnackBarHelper.showError(context, pincodeError);
          return false;
        }
        final gstError =
            ValidationUtils.validateOptionalGstin(_gstController.text);
        if (gstError != null) {
          SnackBarHelper.showError(context, gstError);
          return false;
        }
        final licenseError = ValidationUtils.validateLicenseNumber(
          _licenseController.text,
          fieldName: 'License number',
        );
        if (licenseError != null) {
          SnackBarHelper.showError(context, licenseError);
          return false;
        }
        return true;
      case 1:
        if (_pendingDocs.isEmpty) {
          SnackBarHelper.showError(
            context,
            'Upload at least one license or registration document.',
          );
          return false;
        }
        return true;
      case 2:
        if (_selectedScans.isEmpty) {
          SnackBarHelper.showError(context, 'Select at least one scan service.');
          return false;
        }
        return true;
      case 3:
        if (_offerAvailable) {
          if (_discountValueController.text.trim().isEmpty) {
            SnackBarHelper.showError(context, 'Enter a discount value for the offer.');
            return false;
          }
          if (_offerTitleController.text.trim().isEmpty) {
            SnackBarHelper.showError(context, 'Offer title is required.');
            return false;
          }
        }
        return true;
      default:
        return true;
    }
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  Future<void> _pickDocument(String type, String label) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    setState(() {
      _pendingDocs.add((
        label: label,
        type: type,
        bytes: file.bytes!,
        filename: file.name,
      ));
    });
  }

  Future<void> _pickCenterImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    setState(() {
      _pendingImages.add((bytes: file.bytes!, filename: file.name));
    });
  }

  void _toggleTest(ScanRegistrationTemplate template, bool selected) {
    setState(() {
      if (selected) {
        _selectedScans[template.id] = ScanOfferedProcedure(
          scanId: template.id,
          scanName: template.name,
          categoryId: template.category.id,
          priceInr: template.defaultPrice,
          reportDeliveryTime: template.defaultReportTime,
          preparationInstructions: template.defaultPreparation,
          description: template.defaultDescription,
          fastingRequired: template.fastingRequired,
          homeVisitAvailable: template.homeVisitAvailable,
          onsiteOnly: template.onsiteOnly,
          prescriptionRequired: template.prescriptionRequired,
        );
      } else {
        _selectedScans.remove(template.id);
      }
    });
  }

  Future<void> _submit() async {
    if (!_acknowledged) {
      SnackBarHelper.showError(
        context,
        'Please acknowledge the terms before submitting.',
      );
      return;
    }
    if (_selectedScans.isEmpty) {
      SnackBarHelper.showError(context, 'Select at least one scan service.');
      return;
    }
    if (_licenseController.text.trim().isEmpty) {
      SnackBarHelper.showError(context, 'License number is required.');
      return;
    }

    final center = ScanCenterModel(
      id: _centerId,
      centerName: _centerNameController.text.trim(),
      ownerName: _ownerController.text.trim(),
      email: _emailController.text.trim(),
      mobileNumber: _mobileController.text.trim(),
      countryCode: _countryCode,
      address: _addressController.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      pincode: _pincodeController.text.trim(),
      latitude: _latitude,
      longitude: _longitude,
      gstNumber: _gstController.text.trim().isEmpty
          ? null
          : _gstController.text.trim(),
      licenseNumber: _licenseController.text.trim(),
      operatingHours: _hoursController.text.trim(),
      homeVisitAvailable: _homeVisit,
      available24x7: _available24x7,
      offeredScans: _selectedScans.values.toList(),
      appointmentSlots: _appointmentSlots,
      offers: _offerAvailable
          ? [
              ScanCenterOffer(
                id: const Uuid().v4(),
                offerAvailable: true,
                discountType: _discountType,
                discountValue: double.tryParse(_discountValueController.text),
                offerTitle: _offerTitleController.text.trim().isEmpty
                    ? 'Special offer'
                    : _offerTitleController.text.trim(),
                offerDescription: _offerDescriptionController.text.trim().isEmpty
                    ? null
                    : _offerDescriptionController.text.trim(),
                validFrom: _offerValidFrom,
                validTill: _offerValidTill,
                minimumBookingAmount: _minimumBookingController.text.trim().isEmpty
                    ? null
                    : int.tryParse(_minimumBookingController.text.trim()),
              ),
            ]
          : const [],
    );

    final ok = await ref.read(scanRegistrationProvider.notifier).submit(
          center,
          password: _passwordController.text,
          logoBytes: _logoBytes,
          logoFileName: _logoFileName,
          pendingDocuments: _pendingDocs
              .map((d) => (
                    bytes: d.bytes,
                    filename: d.filename,
                    type: d.type,
                    label: d.label,
                  ))
              .toList(),
          pendingImages: _pendingImages,
        );

    if (!mounted) return;
    if (ok) {
      ref.read(scanRegistrationProvider.notifier).setScanCenter(
            ref.read(scanRegistrationProvider).center!,
          );
      SnackBarHelper.showSuccess(
        context,
        AppConstants.successApplicationSubmitted,
      );
      await navigateAfterRegistration(context, ref, ProviderType.scanCenter);
    } else {
      final err = ref.read(scanRegistrationProvider).error;
      SnackBarHelper.showError(context, err ?? 'Registration failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final regState = ref.watch(scanRegistrationProvider);
    final stepTitles = [
      'Business details',
      'Documents & photos',
      'Scan services',
      'Offers & slots',
      'Review & submit',
    ];
    const stepSubtitles = [
      'Scan center details for admin verification',
      'Upload licenses and center photos',
      'Choose scan procedures and pricing',
      'Promotional offers and appointment slots',
      'Confirm details before submitting',
    ];

    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _back();
      },
      child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Scan center registration'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: _step > 0 ? _back : () => context.pop(),
        ),
      ),
      body: RegistrationStepPage(
        step: _step + 1,
        total: _totalSteps,
        title: stepTitles[_step],
        subtitle: stepSubtitles[_step],
        footer: RegistrationStepActions(
          showBack: _step > 0,
          onBack: _back,
          onContinue: _step == _totalSteps - 1 ? _submit : _next,
          continueLabel:
              _step == _totalSteps - 1 ? 'Submit application' : 'Continue',
          isLoading: regState.isSubmitting,
          isEnabled: _step != _totalSteps - 1 || _acknowledged,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: switch (_step) {
            0 => _buildBusinessStep(),
            1 => _buildDocumentsStep(),
            2 => _buildTestsStep(),
            3 => _buildOffersStep(),
            _ => _buildReviewStep(),
          },
        ),
      ),
    ),
    );
  }

  Widget _buildBusinessStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Register your scan center',
          style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Provide business details for admin verification.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        ProfilePicturePicker(
          imageBytes: _logoBytes,
          onImagePicked: (bytes, fileName) => setState(() {
            _logoBytes = bytes;
            _logoFileName = fileName;
          }),
          onError: (msg) => SnackBarHelper.showError(context, msg),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _centerNameController,
          label: 'Scan center name',
          prefixIcon: Icons.radar_rounded,
          validator: (v) => ValidationUtils.validateOrganizationName(
            v,
            fieldName: 'Scan center name',
          ),
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: _ownerController,
          label: 'Owner / Manager name',
          prefixIcon: Icons.person_outline_rounded,
          validator: (v) =>
              ValidationUtils.validateName(v, fieldName: 'Owner / manager name'),
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: _emailController,
          label: 'Email address',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.email_outlined,
          validator: ValidationUtils.validateEmail,
        ),
        const SizedBox(height: 12),
        MobileNumberField(
          mobileController: _mobileController,
          countryCode: _countryCode,
          onCountryCodeChanged: (c) => setState(() => _countryCode = c),
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: _passwordController,
          label: 'Password',
          obscureText: true,
          prefixIcon: Icons.lock_outline_rounded,
          validator: ValidationUtils.validatePassword,
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: _confirmPasswordController,
          label: 'Confirm password',
          obscureText: true,
          prefixIcon: Icons.lock_outline_rounded,
          validator: (v) => ValidationUtils.validatePasswordMatch(
            _passwordController.text,
            v,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Location',
          style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        RegistrationLocationBlock(
          mode: _locationMode,
          onModeChanged: (mode) => setState(() => _locationMode = mode),
          addressController: _addressController,
          cityController: _cityController,
          stateController: _stateController,
          pincodeController: _pincodeController,
          latitude: _latitude,
          longitude: _longitude,
          onLocationChanged: (lat, lng) => setState(() {
            _latitude = lat;
            _longitude = lng;
          }),
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: _gstController,
          label: 'GST number (optional)',
          prefixIcon: Icons.receipt_long_outlined,
          validator: ValidationUtils.validateOptionalGstin,
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: _licenseController,
          label: 'License / Certification number',
          prefixIcon: Icons.verified_outlined,
          validator: (v) => ValidationUtils.validateLicenseNumber(
            v,
            fieldName: 'License number',
          ),
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: _hoursController,
          label: 'Operating hours',
          hint: 'e.g. Mon–Sat 7 AM – 8 PM',
          prefixIcon: Icons.schedule_outlined,
          validator: (v) => ValidationUtils.validateRequired(
            v,
            fieldName: 'Operating hours',
            minLength: 3,
          ),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Home sample collection'),
          subtitle: const Text('Technician visits patient location'),
          value: _homeVisit,
          onChanged: (v) => setState(() => _homeVisit = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Emergency / 24×7 service'),
          value: _available24x7,
          onChanged: (v) => setState(() => _available24x7 = v),
        ),
      ],
    );
  }

  Widget _buildDocumentsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upload license & registration documents',
          style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        _DocUploadTile(
          label: 'Scan center license',
          uploaded: _pendingDocs.any((d) => d.type == 'license'),
          onTap: () => _pickDocument('license', 'Center License'),
        ),
        _DocUploadTile(
          label: 'Accreditation certificate (NABL / ISO)',
          uploaded: _pendingDocs.any((d) => d.type == 'accreditation'),
          onTap: () => _pickDocument('accreditation', 'Accreditation'),
        ),
        const SizedBox(height: 20),
        Text(
          'Center photos',
          style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _pickCenterImage,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: const Text('Add center image'),
        ),
        if (_pendingImages.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${_pendingImages.length} image(s) selected',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ),
      ],
    );
  }

  Widget _buildTestsStep() {
    final categories = _testCategoryFilter != null
        ? [_testCategoryFilter!]
        : ScanRegistrationCatalog.categories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select tests you offer',
          style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          '${_selectedScans.length} test(s) selected · configure price & delivery for each',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              FilterChip(
                label: const Text('All'),
                selected: _testCategoryFilter == null,
                onSelected: (_) => setState(() => _testCategoryFilter = null),
              ),
              const SizedBox(width: 6),
              ...ScanRegistrationCatalog.categories.map((c) {
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(c.label, style: const TextStyle(fontSize: 11)),
                    selected: _testCategoryFilter == c,
                    onSelected: (_) =>
                        setState(() => _testCategoryFilter = c),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...categories.expand((cat) {
          final tests = ScanRegistrationCatalog.byCategory(cat);
          return [
            Padding(
              padding: const EdgeInsets.only(bottom: 6, top: 8),
              child: Text(
                cat.label,
                style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ...tests.map((t) {
              final selected = _selectedScans.containsKey(t.id);
              final config = _selectedScans[t.id];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ExpansionTile(
                  leading: Checkbox(
                    value: selected,
                    onChanged: (v) => _toggleTest(t, v == true),
                  ),
                  title: Text(t.name, style: AppTextStyles.labelLarge),
                  subtitle: selected
                      ? Text(
                          '₹${config?.priceInr ?? t.defaultPrice} · '
                          '${config?.reportDeliveryTime ?? t.defaultReportTime}',
                        )
                      : Text(t.defaultDescription),
                  children: selected
                      ? [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: _TestConfigFields(
                              test: config!,
                              onChanged: (updated) => setState(
                                () => _selectedScans[t.id] = updated,
                              ),
                            ),
                          ),
                        ]
                      : const [],
                ),
              );
            }),
          ];
        }),
      ],
    );
  }

  Widget _buildOffersStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Offers & appointment slots',
          style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Offer available'),
          value: _offerAvailable,
          onChanged: (v) => setState(() => _offerAvailable = v),
        ),
        if (_offerAvailable) ...[
          DropdownButtonFormField<String>(
            value: _discountType,
            decoration: const InputDecoration(labelText: 'Discount type'),
            items: const [
              DropdownMenuItem(value: 'percentage', child: Text('Percentage')),
              DropdownMenuItem(value: 'flat', child: Text('Flat amount')),
            ],
            onChanged: (v) => setState(() => _discountType = v ?? 'percentage'),
          ),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _discountValueController,
            label: 'Discount value',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _offerTitleController,
            label: 'Offer title',
          ),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _offerDescriptionController,
            label: 'Offer description',
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _minimumBookingController,
            label: 'Minimum booking amount (optional)',
            keyboardType: TextInputType.number,
            prefixIcon: Icons.currency_rupee_rounded,
          ),
          const SizedBox(height: 8),
          _DatePickerTile(
            label: 'Valid from',
            value: _offerValidFrom,
            onPick: (date) => setState(() => _offerValidFrom = date),
          ),
          const SizedBox(height: 8),
          _DatePickerTile(
            label: 'Valid till',
            value: _offerValidTill,
            onPick: (date) => setState(() => _offerValidTill = date),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          'Appointment slots',
          style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        ..._appointmentSlots.map(
          (s) => ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text('${s.day}: ${s.startTime} – ${s.endTime}'),
            trailing: const Icon(Icons.check_circle, color: AppColors.primary, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review your application',
          style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        _ReviewRow('Center', _centerNameController.text),
        _ReviewRow('Owner', _ownerController.text),
        _ReviewRow('Email', _emailController.text),
        _ReviewRow('License', _licenseController.text),
        _ReviewRow('Address', _addressController.text),
        _ReviewRow('City', _cityController.text),
        _ReviewRow('State', _stateController.text),
        _ReviewRow('Pincode', _pincodeController.text),
        _ReviewRow('Scans offered', '${_selectedScans.length}'),
        _ReviewRow('Offer', _offerAvailable ? 'Yes' : 'No'),
        _ReviewRow('Documents', '${_pendingDocs.length}'),
        _ReviewRow('Center images', '${_pendingImages.length}'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'Your application will be reviewed by admin. Only approved scan centers '
            'appear in the user app.',
            style: AppTextStyles.bodySmall.copyWith(height: 1.4),
          ),
        ),
        const SizedBox(height: 16),
        RegistrationAcknowledgmentSection(
          value: _acknowledged,
          onChanged: (value) => setState(() => _acknowledged = value),
        ),
      ],
    );
  }
}

class _DocUploadTile extends StatelessWidget {
  const _DocUploadTile({
    required this.label,
    required this.uploaded,
    required this.onTap,
  });

  final String label;
  final bool uploaded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        uploaded ? Icons.check_circle_rounded : Icons.upload_file_outlined,
        color: uploaded ? AppColors.primary : AppColors.grey400,
      ),
      title: Text(label),
      subtitle: Text(uploaded ? 'Uploaded' : 'Tap to upload PDF or image'),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _TestConfigFields extends StatefulWidget {
  const _TestConfigFields({required this.test, required this.onChanged});

  final ScanOfferedProcedure test;
  final ValueChanged<ScanOfferedProcedure> onChanged;

  @override
  State<_TestConfigFields> createState() => _TestConfigFieldsState();
}

class _TestConfigFieldsState extends State<_TestConfigFields> {
  late final TextEditingController _priceController;
  late final TextEditingController _discountedController;
  late final TextEditingController _reportDeliveryController;
  late final TextEditingController _preparationController;

  static final _fieldStyle =
      AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary);

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(text: '${widget.test.priceInr}');
    _discountedController = TextEditingController(
      text: widget.test.discountedPriceInr?.toString() ?? '',
    );
    _reportDeliveryController = TextEditingController(
      text: widget.test.reportDeliveryTime ?? '',
    );
    _preparationController = TextEditingController(
      text: widget.test.preparationInstructions ?? '',
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    _discountedController.dispose();
    _reportDeliveryController.dispose();
    _preparationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _priceController,
                style: _fieldStyle,
                decoration: const InputDecoration(
                  labelText: 'Price (₹)',
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => widget.onChanged(
                  widget.test.copyWith(
                    priceInr: int.tryParse(v) ?? widget.test.priceInr,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _discountedController,
                style: _fieldStyle,
                decoration: const InputDecoration(
                  labelText: 'Discounted (₹)',
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => widget.onChanged(
                  widget.test.copyWith(
                    discountedPriceInr: v.isEmpty ? null : int.tryParse(v),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _reportDeliveryController,
          style: _fieldStyle,
          decoration: const InputDecoration(
            labelText: 'Report delivery time',
            isDense: true,
          ),
          onChanged: (v) => widget.onChanged(
            widget.test.copyWith(reportDeliveryTime: v.trim()),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _preparationController,
          style: _fieldStyle,
          decoration: const InputDecoration(
            labelText: 'Preparation instructions',
            isDense: true,
          ),
          maxLines: 2,
          onChanged: (v) => widget.onChanged(
            widget.test.copyWith(preparationInstructions: v.trim()),
          ),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: const Text('Home visit available'),
          value: widget.test.homeVisitAvailable,
          onChanged: (v) =>
              widget.onChanged(widget.test.copyWith(homeVisitAvailable: v)),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: const Text('Onsite only'),
          value: widget.test.onsiteOnly,
          onChanged: (v) =>
              widget.onChanged(widget.test.copyWith(onsiteOnly: v)),
        ),
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(child: Text(value, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  const _DatePickerTile({
    required this.label,
    required this.value,
    required this.onPick,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: AppTextStyles.labelLarge),
      subtitle: Text(
        value != null
            ? '${value!.day}/${value!.month}/${value!.year}'
            : 'Tap to select',
      ),
      trailing: const Icon(Icons.calendar_month_outlined),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) onPick(picked);
      },
    );
  }
}
