import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/phone_countries.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validation_utils.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/models/blood_bank_model.dart';
import '../../../../shared/widgets/mobile_number_field.dart';
import '../../../../shared/widgets/profile_picture_picker.dart';
import '../../../../shared/widgets/registration_location_input.dart';
import '../../../../shared/widgets/healthcare_ui.dart';
import '../../../../core/models/provider_type.dart';
import '../../../provider/provider/provider_status_sync.dart';
import '../../data/blood_bank_registration_catalog.dart';
import '../../provider/blood_bank_registration_provider.dart';

const _totalSteps = 5;

class BloodBankRegistrationScreen extends ConsumerStatefulWidget {
  const BloodBankRegistrationScreen({super.key});

  @override
  ConsumerState<BloodBankRegistrationScreen> createState() =>
      _BloodBankRegistrationScreenState();
}

class _BloodBankRegistrationScreenState
    extends ConsumerState<BloodBankRegistrationScreen> {
  final _bloodBankId = const Uuid().v4();
  int _step = 0;
  bool _acknowledged = false;

  // Step 1
  final _nameController = TextEditingController();
  final _ownerController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _licenseController = TextEditingController();
  final _govRegController = TextEditingController();
  final _gstController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _countryCode = PhoneCountries.defaultDialCode;
  double? _latitude;
  double? _longitude;
  RegistrationLocationInputMode _locationMode =
      RegistrationLocationInputMode.manual;
  Uint8List? _profileBytes;
  String? _profileFileName;
  Uint8List? _logoBytes;
  String? _logoFileName;

  // Step 2
  final _emergencyController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _landlineController = TextEditingController();
  final _emailSupportController = TextEditingController();
  final List<({String label, String type, Uint8List bytes, String filename})>
      _pendingDocs = [];
  final List<({Uint8List bytes, String filename})> _pendingGallery = [];

  // Step 3
  final _openingController = TextEditingController(text: '08:00');
  final _closingController = TextEditingController(text: '20:00');
  final Set<String> _selectedBloodGroups = {};
  final Set<String> _selectedFacilities = {};
  bool _available24x7 = false;
  bool _emergencySupply = true;
  bool _homeDelivery = false;
  bool _hospitalDelivery = false;
  bool _cashPayment = true;

  // Step 4
  final Map<String, BloodComponentPricing> _components = {};
  bool _offerAvailable = false;
  String _discountType = 'percentage';
  final _discountValueController = TextEditingController();
  final _offerTitleController = TextEditingController();
  final _offerDescriptionController = TextEditingController();
  final _minimumOrderController = TextEditingController();
  DateTime? _offerValidFrom;
  DateTime? _offerValidTill;
  final Set<String> _offerBloodTypes = {};

  @override
  void initState() {
    super.initState();
    for (final c in kBloodComponents) {
      _components[c['id']!] = BloodComponentPricing(
        componentId: c['id']!,
        componentName: c['name']!,
        priceInr: defaultComponentPrice(c['id']!),
        enabled: true,
      );
    }
  }

  @override
  void dispose() {
    for (final c in [
      _nameController,
      _ownerController,
      _emailController,
      _mobileController,
      _passwordController,
      _confirmPasswordController,
      _licenseController,
      _govRegController,
      _gstController,
      _addressController,
      _cityController,
      _stateController,
      _pincodeController,
      _descriptionController,
      _emergencyController,
      _whatsappController,
      _landlineController,
      _emailSupportController,
      _openingController,
      _closingController,
      _discountValueController,
      _offerTitleController,
      _offerDescriptionController,
      _minimumOrderController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _next() {
    if (!_validateCurrentStep()) return;
    if (_step < _totalSteps - 1) setState(() => _step++);
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  bool _validateCurrentStep() {
    switch (_step) {
      case 0:
        final nameError = ValidationUtils.validateOrganizationName(
          _nameController.text,
          fieldName: 'Blood bank name',
        );
        if (nameError != null) {
          SnackBarHelper.showError(context, nameError);
          return false;
        }
        final ownerError = ValidationUtils.validateName(
          _ownerController.text,
          fieldName: 'Owner / manager name',
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
        final licenseError = ValidationUtils.validateLicenseNumber(
          _licenseController.text,
          fieldName: 'Blood bank license number',
        );
        if (licenseError != null) {
          SnackBarHelper.showError(context, licenseError);
          return false;
        }
        final govRegError = ValidationUtils.validateLicenseNumber(
          _govRegController.text,
          fieldName: 'Government registration number',
        );
        if (govRegError != null) {
          SnackBarHelper.showError(context, govRegError);
          return false;
        }
        final gstError =
            ValidationUtils.validateOptionalGstin(_gstController.text);
        if (gstError != null) {
          SnackBarHelper.showError(context, gstError);
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
        if (_latitude == null || _longitude == null) {
          SnackBarHelper.showError(
            context,
            'Pin on the map or tap “Locate address on map” after entering your address.',
          );
          return false;
        }
        return true;
      case 1:
        if (_pendingDocs.isEmpty) {
          SnackBarHelper.showError(context, 'Upload at least one license document.');
          return false;
        }
        final emergencyError = ValidationUtils.validatePhoneNumber(
          _emergencyController.text.trim(),
        );
        if (emergencyError != null) {
          SnackBarHelper.showError(
            context,
            emergencyError.replaceFirst(
              'Mobile number',
              'Emergency contact',
            ),
          );
          return false;
        }
        final whatsappError = ValidationUtils.validateOptionalPhone(
          _whatsappController.text.trim(),
        );
        if (whatsappError != null) {
          SnackBarHelper.showError(context, whatsappError);
          return false;
        }
        final supportEmailError = ValidationUtils.validateOptionalEmail(
          _emailSupportController.text.trim(),
        );
        if (supportEmailError != null) {
          SnackBarHelper.showError(context, supportEmailError);
          return false;
        }
        return true;
      case 2:
        if (_selectedBloodGroups.isEmpty) {
          SnackBarHelper.showError(context, 'Select at least one blood group.');
          return false;
        }
        return true;
      case 3:
        if (_offerAvailable && _offerTitleController.text.trim().isEmpty) {
          SnackBarHelper.showError(context, 'Offer title is required.');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  Future<void> _pickDocument(String type, String label) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result == null || result.files.isEmpty || result.files.first.bytes == null) {
      return;
    }
    final file = result.files.first;
    setState(() {
      _pendingDocs.add((
        label: label,
        type: type,
        bytes: file.bytes!,
        filename: file.name,
      ));
    });
  }

  Future<void> _pickGalleryImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty || result.files.first.bytes == null) {
      return;
    }
    final file = result.files.first;
    setState(() {
      _pendingGallery.add((bytes: file.bytes!, filename: file.name));
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
    if (!_validateCurrentStep()) return;

    final bloodBank = BloodBankModel(
      id: _bloodBankId,
      institutionName: _nameController.text.trim(),
      ownerName: _ownerController.text.trim(),
      contactPerson: _ownerController.text.trim(),
      email: _emailController.text.trim(),
      mobileNumber: _mobileController.text.trim(),
      countryCode: _countryCode,
      licenseNumber: _licenseController.text.trim(),
      governmentRegistrationNumber: _govRegController.text.trim().isEmpty
          ? null
          : _govRegController.text.trim(),
      gstNumber: _gstController.text.trim().isEmpty
          ? null
          : _gstController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      address: _addressController.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      pincode: _pincodeController.text.trim(),
      latitude: _latitude,
      longitude: _longitude,
      emergencyContact: _emergencyController.text.trim(),
      whatsappNumber: _whatsappController.text.trim().isEmpty
          ? null
          : _whatsappController.text.trim(),
      landlineNumber: _landlineController.text.trim().isEmpty
          ? null
          : _landlineController.text.trim(),
      emailSupport: _emailSupportController.text.trim().isEmpty
          ? null
          : _emailSupportController.text.trim(),
      openingTime: _openingController.text.trim(),
      closingTime: _closingController.text.trim(),
      bloodGroupsAvailable: _selectedBloodGroups.toList(),
      facilities: _selectedFacilities.toList(),
      available24x7: _available24x7,
      emergencyBloodSupply: _emergencySupply,
      homeDeliveryAvailable: _homeDelivery,
      hospitalDeliveryAvailable: _hospitalDelivery,
      cashPaymentEnabled: _cashPayment,
      hasComponentSeparation: _selectedFacilities.contains('Blood Component Separation'),
      hasApheresis: _selectedFacilities.contains('Platelet Availability'),
      bloodComponents: _components.values.where((c) => c.enabled).toList(),
      offers: _offerAvailable
          ? [
              BloodBankOffer(
                id: const Uuid().v4(),
                offerAvailable: true,
                discountType: _discountType,
                discountValue: num.tryParse(_discountValueController.text.trim()),
                offerTitle: _offerTitleController.text.trim(),
                offerDescription: _offerDescriptionController.text.trim().isEmpty
                    ? null
                    : _offerDescriptionController.text.trim(),
                validFrom: _offerValidFrom,
                validTill: _offerValidTill,
                applicableBloodTypes: _offerBloodTypes.toList(),
                minimumOrderAmount:
                    int.tryParse(_minimumOrderController.text.trim()),
                active: true,
              ),
            ]
          : [],
    );

    final ok = await ref.read(bloodBankRegistrationProvider.notifier).submit(
          bloodBank,
          password: _passwordController.text,
          profileImageBytes: _profileBytes,
          profileImageFileName: _profileFileName,
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
          pendingGalleryImages: _pendingGallery,
        );

    if (!mounted) return;
    if (ok) {
      SnackBarHelper.showSuccess(
        context,
        AppConstants.successApplicationSubmitted,
      );
      await navigateAfterRegistration(context, ref, ProviderType.bloodBank);
    } else {
      SnackBarHelper.showError(
        context,
        ref.read(bloodBankRegistrationProvider).error ?? 'Registration failed',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final regState = ref.watch(bloodBankRegistrationProvider);
    const stepTitles = [
      'Basic information',
      'Contact & documents',
      'Working & facilities',
      'Pricing & offers',
      'Review & submit',
    ];
    const stepSubtitles = [
      'Blood bank details for admin verification',
      'Emergency contacts and required documents',
      'Hours, blood groups and facilities',
      'Component pricing and promotional offers',
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
        title: const Text('Blood bank registration'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: _step > 0 ? _back : () => Navigator.of(context).maybePop(),
        ),
      ),
      body: RegistrationStepPage(
        step: _step + 1,
        total: _totalSteps,
        title: stepTitles[_step],
        subtitle: stepSubtitles[_step],
        progressColor: const Color(0xFFB71C1C),
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
            0 => _buildBasicStep(),
            1 => _buildContactStep(),
            2 => _buildFacilitiesStep(),
            3 => _buildPricingStep(),
            _ => _buildReviewStep(),
          },
        ),
      ),
    ),
    );
  }

  Widget _buildBasicStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Register your blood bank',
            style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        ProfilePicturePicker(
          imageBytes: _profileBytes,
          onImagePicked: (b, f) => setState(() {
            _profileBytes = b;
            _profileFileName = f;
          }),
          onError: (m) => SnackBarHelper.showError(context, m),
        ),
        const SizedBox(height: 12),
        Text('Blood bank logo', style: AppTextStyles.labelLarge),
        const SizedBox(height: 8),
        ProfilePicturePicker(
          imageBytes: _logoBytes,
          onImagePicked: (b, f) => setState(() {
            _logoBytes = b;
            _logoFileName = f;
          }),
          onError: (m) => SnackBarHelper.showError(context, m),
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: _nameController,
          label: 'Blood bank name',
          prefixIcon: Icons.bloodtype_rounded,
          validator: (v) => ValidationUtils.validateOrganizationName(
            v,
            fieldName: 'Blood bank name',
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
          label: 'Email',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
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
        const SizedBox(height: 12),
        CustomTextField(
          controller: _licenseController,
          label: 'Blood bank license number',
          prefixIcon: Icons.badge_outlined,
          validator: (v) => ValidationUtils.validateLicenseNumber(
            v,
            fieldName: 'Blood bank license number',
          ),
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: _govRegController,
          label: 'Government registration number',
          prefixIcon: Icons.assignment_outlined,
          validator: (v) => ValidationUtils.validateLicenseNumber(
            v,
            fieldName: 'Government registration number',
          ),
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
          controller: _descriptionController,
          label: 'Description',
          maxLines: 3,
          prefixIcon: Icons.notes_outlined,
        ),
        const SizedBox(height: 12),
        RegistrationLocationBlock(
          mode: _locationMode,
          onModeChanged: (mode) => setState(() => _locationMode = mode),
          addressController: _addressController,
          cityController: _cityController,
          stateController: _stateController,
          pincodeController: _pincodeController,
          compactCityState: true,
          latitude: _latitude,
          longitude: _longitude,
          onLocationChanged: (lat, lng) => setState(() {
            _latitude = lat;
            _longitude = lng;
          }),
          mapEmptyHint: 'Pin your blood bank on the map.',
          mapWebTitle: 'Blood bank location',
        ),
      ],
    );
  }

  Widget _buildContactStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          controller: _emergencyController,
          label: 'Emergency contact',
          prefixIcon: Icons.emergency_rounded,
          keyboardType: TextInputType.phone,
          inputFormatters: ValidationUtils.mobileInputFormatters(),
          validator: ValidationUtils.validatePhoneNumber,
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: _whatsappController,
          label: 'WhatsApp number',
          prefixIcon: Icons.chat_rounded,
          keyboardType: TextInputType.phone,
          inputFormatters: ValidationUtils.mobileInputFormatters(),
          validator: ValidationUtils.validateOptionalPhone,
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: _landlineController,
          label: 'Landline (optional)',
          prefixIcon: Icons.phone_outlined,
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: _emailSupportController,
          label: 'Email support',
          prefixIcon: Icons.support_agent_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: ValidationUtils.validateOptionalEmail,
        ),
        const SizedBox(height: 20),
        Text('License & registration documents',
            style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(
              onPressed: () => _pickDocument('license', 'Blood bank license'),
              child: const Text('Upload license'),
            ),
            OutlinedButton(
              onPressed: () =>
                  _pickDocument('registration', 'Government registration'),
              child: const Text('Upload registration'),
            ),
          ],
        ),
        if (_pendingDocs.isNotEmpty) ...[
          const SizedBox(height: 8),
          ..._pendingDocs.map((d) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.insert_drive_file_outlined),
                title: Text(d.label),
                subtitle: Text(d.filename),
              )),
        ],
        const SizedBox(height: 20),
        Text('Gallery photos',
            style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _pickGalleryImage,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: const Text('Add facility photo'),
        ),
        if (_pendingGallery.isNotEmpty)
          Text('${_pendingGallery.length} photo(s) selected',
              style: AppTextStyles.bodySmall),
      ],
    );
  }

  Widget _buildFacilitiesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
                child: CustomTextField(
                    controller: _openingController, label: 'Opening time')),
            const SizedBox(width: 8),
            Expanded(
                child: CustomTextField(
                    controller: _closingController, label: 'Closing time')),
          ],
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Available 24×7'),
          value: _available24x7,
          onChanged: (v) => setState(() => _available24x7 = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Emergency blood supply'),
          value: _emergencySupply,
          onChanged: (v) => setState(() => _emergencySupply = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Home delivery'),
          value: _homeDelivery,
          onChanged: (v) => setState(() => _homeDelivery = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Hospital delivery'),
          value: _hospitalDelivery,
          onChanged: (v) => setState(() => _hospitalDelivery = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Cash payment accepted'),
          value: _cashPayment,
          onChanged: (v) => setState(() => _cashPayment = v),
        ),
        const SizedBox(height: 12),
        Text('Blood groups available',
            style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700)),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: kBloodGroups
              .map((g) => FilterChip(
                    label: Text(g),
                    selected: _selectedBloodGroups.contains(g),
                    onSelected: (s) => setState(() {
                      if (s) {
                        _selectedBloodGroups.add(g);
                      } else {
                        _selectedBloodGroups.remove(g);
                      }
                    }),
                  ))
              .toList(),
        ),
        const SizedBox(height: 16),
        Text('Facilities',
            style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700)),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: kBloodBankFacilities
              .map((f) => FilterChip(
                    label: Text(f),
                    selected: _selectedFacilities.contains(f),
                    onSelected: (s) => setState(() {
                      if (s) {
                        _selectedFacilities.add(f);
                      } else {
                        _selectedFacilities.remove(f);
                      }
                    }),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildPricingStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Blood component pricing',
            style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        ..._components.entries.map((e) {
          final c = e.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(c.componentName,
                      style: AppTextStyles.labelLarge.copyWith(
                          fontWeight: FontWeight.w600)),
                ),
                SizedBox(
                  width: 90,
                  child: TextFormField(
                    initialValue: '${c.priceInr}',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Price ₹',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      final price = int.tryParse(v) ?? c.priceInr;
                      _components[e.key] = c.copyWith(priceInr: price);
                    },
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 16),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Do you provide discounts?'),
          value: _offerAvailable,
          onChanged: (v) => setState(() => _offerAvailable = v),
        ),
        if (_offerAvailable) ...[
          DropdownButtonFormField<String>(
            value: _discountType,
            decoration: const InputDecoration(
              labelText: 'Discount type',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'percentage', child: Text('Percentage')),
              DropdownMenuItem(value: 'flat', child: Text('Flat amount')),
            ],
            onChanged: (v) => setState(() => _discountType = v ?? 'percentage'),
          ),
          const SizedBox(height: 12),
          CustomTextField(
              controller: _discountValueController,
              label: 'Discount value',
              keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          CustomTextField(
              controller: _offerTitleController, label: 'Offer title'),
          const SizedBox(height: 12),
          CustomTextField(
              controller: _offerDescriptionController,
              label: 'Offer description',
              maxLines: 2),
          const SizedBox(height: 12),
          CustomTextField(
              controller: _minimumOrderController,
              label: 'Minimum order amount',
              keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: kBloodGroups
                .map((g) => FilterChip(
                      label: Text(g),
                      selected: _offerBloodTypes.contains(g),
                      onSelected: (s) => setState(() {
                        if (s) {
                          _offerBloodTypes.add(g);
                        } else {
                          _offerBloodTypes.remove(g);
                        }
                      }),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildReviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Review your application',
            style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        _reviewRow('Blood bank', _nameController.text),
        _reviewRow('Owner', _ownerController.text),
        _reviewRow('Email', _emailController.text),
        _reviewRow('City', _cityController.text),
        _reviewRow('Blood groups', _selectedBloodGroups.join(', ')),
        _reviewRow('Facilities', '${_selectedFacilities.length} selected'),
        _reviewRow('Documents', '${_pendingDocs.length} uploaded'),
        _reviewRow('Gallery', '${_pendingGallery.length} photos'),
        _reviewRow('Components priced', '${_components.length}'),
        if (_offerAvailable)
          _reviewRow('Offer', _offerTitleController.text),
        const SizedBox(height: 16),
        Text(
          'By submitting, you agree to admin verification of your license and documents.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        RegistrationAcknowledgmentSection(
          value: _acknowledged,
          onChanged: (value) => setState(() => _acknowledged = value),
        ),
      ],
    );
  }

  Widget _reviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value.isEmpty ? '—' : value,
                style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
