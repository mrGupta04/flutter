import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/phone_countries.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validation_utils.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/models/lab_model.dart';
import '../../../../shared/widgets/mobile_number_field.dart';
import '../../../../shared/widgets/profile_picture_picker.dart';
import '../../../../shared/widgets/registration_location_input.dart';
import '../../../../shared/widgets/healthcare_ui.dart';
import '../../../../core/models/provider_type.dart';
import '../../../provider/provider/provider_status_sync.dart';
import '../../../labs/data/lab_registration_catalog.dart';
import '../../data/lab_registration_constants.dart';
import '../../provider/lab_registration_provider.dart';

const _totalSteps = 8;

class LabRegistrationScreen extends ConsumerStatefulWidget {
  const LabRegistrationScreen({super.key});

  @override
  ConsumerState<LabRegistrationScreen> createState() =>
      _LabRegistrationScreenState();
}

class _LabRegistrationScreenState extends ConsumerState<LabRegistrationScreen> {
  final _labId = const Uuid().v4();
  int _step = 0;

  // Step 1 — business
  final _labNameController = TextEditingController();
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
  final _accreditationController = TextEditingController();
  final _hoursController = TextEditingController();
  String _countryCode = PhoneCountries.defaultDialCode;
  bool _homeCollection = true;
  bool _available24x7 = false;
  double? _latitude;
  double? _longitude;
  RegistrationLocationInputMode _locationMode =
      RegistrationLocationInputMode.manual;
  Uint8List? _logoBytes;
  String? _logoFileName;
  Uint8List? _coverBytes;
  String? _coverFileName;
  String? _labType;
  final _yearController = TextEditingController();
  final _registrationNumberController = TextEditingController();
  final _nablController = TextEditingController();
  final _otherCertsController = TextEditingController();
  final _buildingController = TextEditingController();
  final _streetController = TextEditingController();
  final _areaController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _openingTimeController = TextEditingController(text: '7:00 AM');
  final _closingTimeController = TextEditingController(text: '8:00 PM');
  bool _emergencyService = false;
  final Set<String> _facilities = {};
  final Set<String> _supportedCategories = {};
  final Map<String, LabWorkingDay> _workingDays = {
    for (final d in LabRegistrationConstants.weekDays)
      d: LabWorkingDay(day: d, isOpen: d != 'Sunday'),
  };

  // Step 2 — documents
  final List<({String label, String type, Uint8List bytes, String filename})>
      _pendingDocs = [];
  final List<({Uint8List bytes, String filename})> _pendingImages = [];

  // Step 3 — tests
  final Map<String, LabOfferedTest> _selectedTests = {};
  LabRegistrationCategory? _testCategoryFilter;

  // Step 4 — branches & areas
  final List<LabBranch> _branches = [];
  final _pincodesController = TextEditingController();
  final List<LabHomeVisitSlot> _homeSlots = [
    const LabHomeVisitSlot(day: 'Mon–Sat', startTime: '7:00 AM', endTime: '7:00 PM'),
  ];

  // Packages, imaging, staff, bank
  final List<LabHealthPackageReg> _healthPackages = [];
  final List<LabOfferedScanReg> _offeredScans = [];
  final List<LabStaffMemberReg> _staffMembers = [];
  bool _imagingEnabled = false;
  final _accountHolderController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _ifscController = TextEditingController();
  final _upiController = TextEditingController();
  final _serviceCitiesController = TextEditingController();
  final _serviceAreasController = TextEditingController();
  final _radiusController = TextEditingController(text: '10');
  final Map<String, String> _testSampleTypes = {};
  final Map<String, bool> _testFasting = {};

  @override
  void dispose() {
    for (final c in [
      _labNameController,
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
      _accreditationController,
      _hoursController,
      _pincodesController,
      _yearController,
      _registrationNumberController,
      _nablController,
      _otherCertsController,
      _buildingController,
      _streetController,
      _areaController,
      _landmarkController,
      _openingTimeController,
      _closingTimeController,
      _accountHolderController,
      _bankNameController,
      _accountNumberController,
      _ifscController,
      _upiController,
      _serviceCitiesController,
      _serviceAreasController,
      _radiusController,
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
        final labNameError = ValidationUtils.validateOrganizationName(
          _labNameController.text,
          fieldName: 'Lab name',
        );
        if (labNameError != null) {
          SnackBarHelper.showError(context, labNameError);
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
        final pincodeError =
            ValidationUtils.validatePincode(_pincodeController.text);
        if (pincodeError != null) {
          SnackBarHelper.showError(context, pincodeError);
          return false;
        }
        if (_yearController.text.trim().isNotEmpty) {
          final yearError = ValidationUtils.validateYear(
            _yearController.text,
            fieldName: 'Year established',
            minYear: 1950,
          );
          if (yearError != null) {
            SnackBarHelper.showError(context, yearError);
            return false;
          }
        }
        final gstError =
            ValidationUtils.validateOptionalGstin(_gstController.text);
        if (gstError != null) {
          SnackBarHelper.showError(context, gstError);
          return false;
        }
        return true;
      case 1:
        if (_facilities.isEmpty) {
          SnackBarHelper.showError(context, 'Select at least one facility.');
          return false;
        }
        if (_supportedCategories.isEmpty) {
          SnackBarHelper.showError(context, 'Select at least one test category.');
          return false;
        }
        return true;
      case 2:
        final requiredTypes = [
          'registration_certificate',
          'owner_id',
          'address_proof',
          'pan_card',
        ];
        for (final type in requiredTypes) {
          if (!_pendingDocs.any((d) => d.type == type)) {
            SnackBarHelper.showError(context, 'Upload all required documents.');
            return false;
          }
        }
        return true;
      case 3:
        if (_selectedTests.isEmpty) {
          SnackBarHelper.showError(context, 'Select at least one diagnostic test.');
          return false;
        }
        return true;
      case 7:
        final holderError =
            ValidationUtils.validateAccountHolderName(_accountHolderController.text);
        if (holderError != null) {
          SnackBarHelper.showError(context, holderError);
          return false;
        }
        final bankError =
            ValidationUtils.validateBankName(_bankNameController.text);
        if (bankError != null) {
          SnackBarHelper.showError(context, bankError);
          return false;
        }
        final accountError =
            ValidationUtils.validateAccountNumber(_accountNumberController.text);
        if (accountError != null) {
          SnackBarHelper.showError(context, accountError);
          return false;
        }
        final ifscError = ValidationUtils.validateIfscCode(_ifscController.text);
        if (ifscError != null) {
          SnackBarHelper.showError(context, ifscError);
          return false;
        }
        final upiError =
            ValidationUtils.validateOptionalUpiId(_upiController.text);
        if (upiError != null) {
          SnackBarHelper.showError(context, upiError);
          return false;
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

  Future<void> _pickLabImage() async {
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

  void _toggleTest(LabRegistrationTestTemplate template, bool selected) {
    setState(() {
      if (selected) {
        _selectedTests[template.id] = LabOfferedTest(
          testId: template.id,
          testName: template.name,
          categoryId: template.category.id,
          priceInr: template.defaultPrice,
          reportDeliveryTime: template.defaultReportTime,
          preparationInstructions: template.defaultPreparation,
          description: template.defaultDescription,
        );
      } else {
        _selectedTests.remove(template.id);
      }
    });
  }

  Future<void> _submit() async {
    if (_selectedTests.isEmpty) {
      SnackBarHelper.showError(context, 'Select at least one diagnostic test.');
      return;
    }
    if (_licenseController.text.trim().isEmpty) {
      SnackBarHelper.showError(context, 'License number is required.');
      return;
    }

    final operatingHours =
        '${_openingTimeController.text.trim()} – ${_closingTimeController.text.trim()}';

    final lab = LabModel(
      id: _labId,
      labName: _labNameController.text.trim(),
      ownerName: _ownerController.text.trim(),
      email: _emailController.text.trim(),
      mobileNumber: _mobileController.text.trim(),
      countryCode: _countryCode,
      address: _composeAddress(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      pincode: _pincodeController.text.trim(),
      latitude: _latitude,
      longitude: _longitude,
      gstNumber: _gstController.text.trim().isEmpty
          ? null
          : _gstController.text.trim(),
      licenseNumber: _licenseController.text.trim(),
      accreditation: _accreditationController.text.trim().isEmpty
          ? _nablController.text.trim()
          : _accreditationController.text.trim(),
      operatingHours: operatingHours,
      homeCollectionAvailable: _homeCollection,
      available24x7: _available24x7,
      offeredTests: _selectedTests.values.toList(),
      branches: _branches,
      serviceablePincodes: _pincodesController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      homeVisitSlots: _homeSlots,
    );

    final extras = LabRegistrationExtras(
      labType: _labType,
      yearEstablished: int.tryParse(_yearController.text.trim()),
      registrationNumber: _registrationNumberController.text.trim().isEmpty
          ? null
          : _registrationNumberController.text.trim(),
      nablAccreditationNumber: _nablController.text.trim().isEmpty
          ? null
          : _nablController.text.trim(),
      otherCertifications: _otherCertsController.text.trim().isEmpty
          ? null
          : _otherCertsController.text.trim(),
      buildingName: _buildingController.text.trim().isEmpty
          ? null
          : _buildingController.text.trim(),
      street: _streetController.text.trim().isEmpty
          ? null
          : _streetController.text.trim(),
      area: _areaController.text.trim().isEmpty
          ? null
          : _areaController.text.trim(),
      landmark: _landmarkController.text.trim().isEmpty
          ? null
          : _landmarkController.text.trim(),
      openingTime: _openingTimeController.text.trim(),
      closingTime: _closingTimeController.text.trim(),
      workingDays: _workingDays.values.toList(),
      emergencyServiceAvailable: _emergencyService,
      facilities: _facilities.toList(),
      supportedCategories: _supportedCategories.toList(),
      healthPackages: _healthPackages,
      offeredScans: _imagingEnabled ? _offeredScans : const [],
      staffMembers: _staffMembers,
      bankDetails: LabBankDetailsReg(
        accountHolderName: _accountHolderController.text.trim(),
        bankName: _bankNameController.text.trim(),
        accountNumber: _accountNumberController.text.trim(),
        ifscCode: _ifscController.text.trim(),
        upiId: _upiController.text.trim().isEmpty
            ? null
            : _upiController.text.trim(),
      ),
      serviceCities: _serviceCitiesController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      serviceAreas: _serviceAreasController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      homeCollectionRadiusKm: double.tryParse(_radiusController.text.trim()),
    );

    final offeredTestsPayload = _selectedTests.entries.map((entry) {
      final test = entry.value;
      return test.toRegistrationJson(
        sampleType: _testSampleTypes[entry.key] ?? 'Blood',
        fastingRequired: _testFasting[entry.key] ?? false,
      );
    }).toList();

    final ok = await ref.read(labRegistrationProvider.notifier).submit(
          lab,
          password: _passwordController.text,
          extras: extras,
          offeredTestsPayload: offeredTestsPayload,
          logoBytes: _logoBytes,
          logoFileName: _logoFileName,
          coverBytes: _coverBytes,
          coverFileName: _coverFileName,
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
      SnackBarHelper.showSuccess(
        context,
        AppConstants.successApplicationSubmitted,
      );
      await navigateAfterRegistration(context, ref, ProviderType.lab);
    } else {
      final err = ref.read(labRegistrationProvider).error;
      SnackBarHelper.showError(context, err ?? 'Registration failed');
    }
  }

  String _composeAddress() {
    final parts = [
      _buildingController.text.trim(),
      _streetController.text.trim(),
      _areaController.text.trim(),
      _landmarkController.text.trim(),
      _addressController.text.trim(),
    ].where((p) => p.isNotEmpty);
    return parts.join(', ');
  }

  Future<void> _pickCoverImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    setState(() {
      _coverBytes = file.bytes;
      _coverFileName = file.name;
    });
  }

  void _addCustomTest() {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final nameCtrl = TextEditingController();
        final priceCtrl = TextEditingController(text: '499');
        var sampleType = LabRegistrationConstants.sampleTypes.first;
        var fasting = false;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Add custom test'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Test name'),
                  ),
                  TextField(
                    controller: priceCtrl,
                    decoration: const InputDecoration(labelText: 'Price (₹)'),
                    keyboardType: TextInputType.number,
                  ),
                  DropdownButtonFormField<String>(
                    value: sampleType,
                    items: LabRegistrationConstants.sampleTypes
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) =>
                        setDialogState(() => sampleType = v ?? sampleType),
                    decoration: const InputDecoration(labelText: 'Sample type'),
                  ),
                  SwitchListTile(
                    title: const Text('Fasting required'),
                    value: fasting,
                    onChanged: (v) => setDialogState(() => fasting = v),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final id = const Uuid().v4();
                  setState(() {
                    _selectedTests[id] = LabOfferedTest(
                      testId: id,
                      testName: nameCtrl.text.trim(),
                      categoryId: 'custom',
                      priceInr: int.tryParse(priceCtrl.text.trim()) ?? 499,
                      reportDeliveryTime: '24 hours',
                    );
                    _testSampleTypes[id] = sampleType;
                    _testFasting[id] = fasting;
                  });
                  Navigator.pop(ctx);
                },
                child: const Text('Add'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _addHealthPackage() {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final nameCtrl = TextEditingController();
        final originalCtrl = TextEditingController(text: '2999');
        final discountCtrl = TextEditingController(text: '2499');
        return AlertDialog(
          title: const Text('Create health package'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Package name'),
              ),
              TextField(
                controller: originalCtrl,
                decoration: const InputDecoration(labelText: 'Original price'),
              ),
              TextField(
                controller: discountCtrl,
                decoration: const InputDecoration(labelText: 'Offer price'),
              ),
              Text('Includes ${_selectedTests.length} selected tests'),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                setState(() {
                  _healthPackages.add(LabHealthPackageReg(
                    id: const Uuid().v4(),
                    name: nameCtrl.text.trim(),
                    testIds: _selectedTests.keys.toList(),
                    originalPriceInr: int.tryParse(originalCtrl.text.trim()) ?? 2999,
                    discountedPriceInr: int.tryParse(discountCtrl.text.trim()) ?? 2499,
                    reportDeliveryTime: '48 hours',
                  ));
                });
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _addStaffMember() {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final nameCtrl = TextEditingController();
        final mobileCtrl = TextEditingController();
        var role = LabRegistrationConstants.staffRoles.first;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Add staff member'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: role,
                  items: LabRegistrationConstants.staffRoles
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => role = v ?? role),
                  decoration: const InputDecoration(labelText: 'Role'),
                ),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: mobileCtrl,
                  decoration: const InputDecoration(labelText: 'Mobile'),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton(
                onPressed: () {
                  setState(() {
                    _staffMembers.add(LabStaffMemberReg(
                      id: const Uuid().v4(),
                      role: role,
                      name: nameCtrl.text.trim(),
                      mobile: mobileCtrl.text.trim(),
                    ));
                  });
                  Navigator.pop(ctx);
                },
                child: const Text('Add'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final regState = ref.watch(labRegistrationProvider);
    final stepTitles = [
      'Basic information',
      'Facilities & categories',
      'Documents',
      'Tests & pricing',
      'Packages & imaging',
      'Staff',
      'Service area',
      'Bank & review',
    ];
    const stepSubtitles = [
      'Business details for admin verification',
      'Select facilities and test categories',
      'Upload licenses and lab photos',
      'Choose tests and set pricing',
      'Add packages and imaging services',
      'Add lab staff members',
      'Branches, pincodes and home visit slots',
      'Bank details and final review',
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Lab registration'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
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
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: switch (_step) {
            0 => _buildBusinessStep(),
            1 => _buildFacilitiesStep(),
            2 => _buildDocumentsStep(),
            3 => _buildTestsStep(),
            4 => _buildPackagesStep(),
            5 => _buildStaffStep(),
            6 => _buildBranchesStep(),
            _ => _buildBankReviewStep(),
          },
        ),
      ),
    );
  }

  Widget _buildBusinessStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Register your diagnostic laboratory',
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
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _pickCoverImage,
          icon: const Icon(Icons.image_outlined),
          label: Text(_coverBytes != null ? 'Cover image selected' : 'Upload cover / banner'),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _labType,
          decoration: const InputDecoration(
            labelText: 'Laboratory type',
            prefixIcon: Icon(Icons.category_outlined),
          ),
          items: LabRegistrationConstants.labTypes
              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
              .toList(),
          onChanged: (v) => setState(() => _labType = v),
        ),
        CustomTextField(
          controller: _labNameController,
          label: 'Lab name',
          prefixIcon: Icons.biotech_outlined,
          validator: (v) => ValidationUtils.validateOrganizationName(
            v,
            fieldName: 'Lab name',
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
          'Address details',
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
          extraManualTop: Column(
            children: [
              CustomTextField(
                controller: _buildingController,
                label: 'Building name',
                prefixIcon: Icons.business_outlined,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _streetController,
                label: 'Street',
                prefixIcon: Icons.signpost_outlined,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _areaController,
                      label: 'Area',
                      prefixIcon: Icons.location_city_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomTextField(
                      controller: _landmarkController,
                      label: 'Landmark',
                      prefixIcon: Icons.place_outlined,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _yearController,
                label: 'Year established',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.calendar_today_outlined,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  return ValidationUtils.validateYear(
                    v,
                    fieldName: 'Year established',
                    minYear: 1950,
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CustomTextField(
                controller: _registrationNumberController,
                label: 'Registration number',
                prefixIcon: Icons.numbers_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: _nablController,
          label: 'NABL accreditation (optional)',
          prefixIcon: Icons.workspace_premium_outlined,
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: _otherCertsController,
          label: 'Other certifications',
          prefixIcon: Icons.verified_outlined,
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
        const SizedBox(height: 16),
        Text('Working details', style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _openingTimeController,
                label: 'Opening time',
                prefixIcon: Icons.schedule_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CustomTextField(
                controller: _closingTimeController,
                label: 'Closing time',
                prefixIcon: Icons.schedule_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...LabRegistrationConstants.weekDays.map((day) {
          final wd = _workingDays[day]!;
          return SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(day),
            value: wd.isOpen,
            onChanged: (v) => setState(() {
              _workingDays[day] = LabWorkingDay(
                day: day,
                isOpen: v,
                openingTime: wd.openingTime,
                closingTime: wd.closingTime,
              );
            }),
          );
        }),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Home sample collection'),
          subtitle: const Text('Technician visits patient location'),
          value: _homeCollection,
          onChanged: (v) => setState(() => _homeCollection = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Emergency service'),
          value: _emergencyService,
          onChanged: (v) => setState(() => _emergencyService = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('24×7 available'),
          value: _available24x7,
          onChanged: (v) => setState(() => _available24x7 = v),
        ),
      ],
    );
  }

  Widget _buildFacilitiesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Facilities & test categories',
          style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          'Select all facilities and diagnostic categories your lab supports.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        Text('Facilities', style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: LabRegistrationConstants.facilities.map((f) {
            final selected = _facilities.contains(f);
            return FilterChip(
              label: Text(f, style: const TextStyle(fontSize: 12)),
              selected: selected,
              showCheckmark: false,
              onSelected: (v) => setState(() {
                if (v) {
                  _facilities.add(f);
                } else {
                  _facilities.remove(f);
                }
              }),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Text('Test categories', style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: LabRegistrationConstants.testCategories.map((c) {
            final selected = _supportedCategories.contains(c);
            return FilterChip(
              label: Text(c, style: const TextStyle(fontSize: 12)),
              selected: selected,
              showCheckmark: false,
              onSelected: (v) => setState(() {
                if (v) {
                  _supportedCategories.add(c);
                } else {
                  _supportedCategories.remove(c);
                }
              }),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDocumentsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upload verification documents',
          style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          'Admin will verify these before your lab goes live.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        ...LabRegistrationConstants.requiredDocuments.map((doc) {
          final (type, label) = doc;
          final optional = label.contains('Optional');
          return _DocUploadTile(
            label: optional ? label : label,
            uploaded: _pendingDocs.any((d) => d.type == type),
            onTap: () => _pickDocument(type, label),
          );
        }),
        const SizedBox(height: 20),
        Text(
          'Laboratory photos',
          style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _pickLabImage,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: const Text('Add lab image'),
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
        : LabRegistrationCatalog.categories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select tests you offer',
          style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          '${_selectedTests.length} test(s) selected · configure price & delivery for each',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _addCustomTest,
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('Add custom test'),
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
                showCheckmark: false,
                onSelected: (_) => setState(() => _testCategoryFilter = null),
              ),
              const SizedBox(width: 6),
              ...LabRegistrationCatalog.categories.map((c) {
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(c.label, style: const TextStyle(fontSize: 11)),
                    selected: _testCategoryFilter == c,
                    showCheckmark: false,
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
          final tests = LabRegistrationCatalog.byCategory(cat);
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
              final selected = _selectedTests.containsKey(t.id);
              final config = _selectedTests[t.id];
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
                                () => _selectedTests[t.id] = updated,
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

  Widget _buildPackagesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Health packages & imaging',
          style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          'Create bundled packages and configure scan/imaging services.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                'Health packages (${_healthPackages.length})',
                style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            TextButton.icon(
              onPressed: _selectedTests.isEmpty ? null : _addHealthPackage,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add package'),
            ),
          ],
        ),
        if (_healthPackages.isEmpty)
          Text(
            'No packages yet. Select tests first, then bundle them.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          )
        else
          ..._healthPackages.map(
            (p) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(p.name),
                subtitle: Text(
                  '${p.testIds.length} tests · ₹${p.discountedPriceInr} (was ₹${p.originalPriceInr})',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => setState(() => _healthPackages.remove(p)),
                ),
              ),
            ),
          ),
        const SizedBox(height: 20),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Imaging & diagnostic services'),
          subtitle: const Text('MRI, CT, X-Ray, Ultrasound, etc.'),
          value: _imagingEnabled,
          onChanged: (v) => setState(() => _imagingEnabled = v),
        ),
        if (_imagingEnabled) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: LabRegistrationConstants.imagingServices.map((scan) {
              final added = _offeredScans.any((s) => s.scanName == scan);
              return FilterChip(
                label: Text(scan, style: const TextStyle(fontSize: 12)),
                selected: added,
                showCheckmark: false,
                onSelected: (v) => setState(() {
                  if (v) {
                    _offeredScans.add(LabOfferedScanReg(
                      id: const Uuid().v4(),
                      scanName: scan,
                      priceInr: 1500,
                      reportDeliveryTime: '24 hours',
                      appointmentDurationMinutes: 30,
                    ));
                  } else {
                    _offeredScans.removeWhere((s) => s.scanName == scan);
                  }
                }),
              );
            }).toList(),
          ),
          if (_offeredScans.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                '${_offeredScans.length} imaging service(s) configured with default pricing.',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildStaffStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Staff management',
          style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          'Add pathologists, technicians, phlebotomists, and other staff.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _addStaffMember,
          icon: const Icon(Icons.person_add_outlined),
          label: const Text('Add staff member'),
        ),
        const SizedBox(height: 12),
        if (_staffMembers.isEmpty)
          Text(
            'Staff is optional during registration — you can add more after approval.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          )
        else
          ..._staffMembers.map(
            (s) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(s.name.isNotEmpty ? s.name[0].toUpperCase() : '?'),
                ),
                title: Text(s.name),
                subtitle: Text('${s.role} · ${s.mobile}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => setState(() => _staffMembers.remove(s)),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBranchesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Service area & collection',
          style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: _serviceCitiesController,
          label: 'Service cities',
          hint: 'Comma-separated, e.g. Delhi, Noida',
          prefixIcon: Icons.location_city_outlined,
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: _serviceAreasController,
          label: 'Service areas / localities',
          hint: 'Comma-separated areas',
          prefixIcon: Icons.map_outlined,
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: _pincodesController,
          label: 'Pincode coverage',
          hint: 'Comma-separated, e.g. 110001, 110002',
          prefixIcon: Icons.pin_drop_outlined,
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: _radiusController,
          label: 'Home collection radius (km)',
          keyboardType: TextInputType.number,
          prefixIcon: Icons.radar_outlined,
        ),
        const SizedBox(height: 16),
        Text(
          'Home visit time slots',
          style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        ..._homeSlots.map(
          (s) => ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text('${s.day}: ${s.startTime} – ${s.endTime}'),
            trailing: const Icon(Icons.check_circle, color: AppColors.primary, size: 18),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Additional branches can be added after approval from your lab dashboard.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildBankReviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bank details',
          style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: _accountHolderController,
          label: 'Account holder name',
          prefixIcon: Icons.account_balance_outlined,
          validator: ValidationUtils.validateAccountHolderName,
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: _bankNameController,
          label: 'Bank name',
          prefixIcon: Icons.account_balance_wallet_outlined,
          validator: ValidationUtils.validateBankName,
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: _accountNumberController,
          label: 'Account number',
          keyboardType: TextInputType.number,
          prefixIcon: Icons.numbers_outlined,
          validator: ValidationUtils.validateAccountNumber,
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: _ifscController,
          label: 'IFSC code',
          prefixIcon: Icons.code_outlined,
          validator: ValidationUtils.validateIfscCode,
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: _upiController,
          label: 'UPI ID (optional)',
          prefixIcon: Icons.payment_outlined,
          validator: ValidationUtils.validateOptionalUpiId,
        ),
        const SizedBox(height: 12),
        _DocUploadTile(
          label: 'Cancelled cheque',
          uploaded: _pendingDocs.any((d) => d.type == 'cancelled_cheque'),
          onTap: () => _pickDocument('cancelled_cheque', 'Cancelled Cheque'),
        ),
        const SizedBox(height: 24),
        Text(
          'Review your application',
          style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        _ReviewRow('Lab', _labNameController.text),
        _ReviewRow('Type', _labType ?? '—'),
        _ReviewRow('Owner', _ownerController.text),
        _ReviewRow('Email', _emailController.text),
        _ReviewRow('City', _cityController.text),
        _ReviewRow('Facilities', '${_facilities.length}'),
        _ReviewRow('Categories', '${_supportedCategories.length}'),
        _ReviewRow('Tests offered', '${_selectedTests.length}'),
        _ReviewRow('Health packages', '${_healthPackages.length}'),
        _ReviewRow('Imaging services', _imagingEnabled ? '${_offeredScans.length}' : 'None'),
        _ReviewRow('Staff', '${_staffMembers.length}'),
        _ReviewRow('Documents', '${_pendingDocs.length}'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'Your application will be reviewed by admin. Only approved labs '
            'appear in Find Care → Labs for patients to book tests and scans.',
            style: AppTextStyles.bodySmall.copyWith(height: 1.4),
          ),
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

class _TestConfigFields extends StatelessWidget {
  const _TestConfigFields({required this.test, required this.onChanged});

  final LabOfferedTest test;
  final ValueChanged<LabOfferedTest> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: '${test.priceInr}',
                decoration: const InputDecoration(
                  labelText: 'Price (₹)',
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => onChanged(
                  test.copyWith(priceInr: int.tryParse(v) ?? test.priceInr),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                initialValue: test.discountedPriceInr?.toString() ?? '',
                decoration: const InputDecoration(
                  labelText: 'Discounted (₹)',
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => onChanged(
                  test.copyWith(
                    discountedPriceInr: v.isEmpty ? null : int.tryParse(v),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: test.reportDeliveryTime ?? '',
          decoration: const InputDecoration(
            labelText: 'Report delivery time',
            isDense: true,
          ),
          onChanged: (v) =>
              onChanged(test.copyWith(reportDeliveryTime: v.trim())),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: test.preparationInstructions ?? '',
          decoration: const InputDecoration(
            labelText: 'Preparation instructions',
            isDense: true,
          ),
          maxLines: 2,
          onChanged: (v) =>
              onChanged(test.copyWith(preparationInstructions: v.trim())),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: const Text('Home collection'),
          value: test.homeCollectionAvailable,
          onChanged: (v) =>
              onChanged(test.copyWith(homeCollectionAvailable: v)),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: const Text('Onsite collection'),
          value: test.onsiteCollectionAvailable,
          onChanged: (v) =>
              onChanged(test.copyWith(onsiteCollectionAvailable: v)),
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
