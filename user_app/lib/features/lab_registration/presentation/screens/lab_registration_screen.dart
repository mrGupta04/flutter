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
import '../../../../shared/widgets/registration_map_picker.dart';
import '../../../labs/data/lab_registration_catalog.dart';
import '../../provider/lab_registration_provider.dart';

const _totalSteps = 5;

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
  Uint8List? _logoBytes;
  String? _logoFileName;

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
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _next() {
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
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

    final lab = LabModel(
      id: _labId,
      labName: _labNameController.text.trim(),
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
      accreditation: _accreditationController.text.trim(),
      operatingHours: _hoursController.text.trim(),
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

    final ok = await ref.read(labRegistrationProvider.notifier).submit(
          lab,
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
      context.go(AppConstants.routeLabApplicationSubmitted);
    } else {
      final err = ref.read(labRegistrationProvider).error;
      SnackBarHelper.showError(context, err ?? 'Registration failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final regState = ref.watch(labRegistrationProvider);
    final stepTitles = [
      'Business details',
      'Documents & photos',
      'Tests & services',
      'Branches & collection',
      'Review & submit',
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Step ${_step + 1}/$_totalSteps · ${stepTitles[_step]}',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (_step + 1) / _totalSteps,
                  backgroundColor: AppColors.grey200,
                  color: AppColors.primary,
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: switch (_step) {
                0 => _buildBusinessStep(),
                1 => _buildDocumentsStep(),
                2 => _buildTestsStep(),
                3 => _buildBranchesStep(),
                _ => _buildReviewStep(),
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                if (_step > 0)
                  Expanded(
                    child: CustomOutlineButton(
                      label: 'Back',
                      onPressed: _back,
                    ),
                  ),
                if (_step > 0) const SizedBox(width: 10),
                Expanded(
                  flex: _step == 0 ? 1 : 1,
                  child: CustomButton(
                    label: _step == _totalSteps - 1 ? 'Submit application' : 'Continue',
                    isLoading: regState.isSubmitting,
                    onPressed: _step == _totalSteps - 1 ? _submit : _next,
                  ),
                ),
              ],
            ),
          ),
        ],
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
        const SizedBox(height: 16),
        CustomTextField(
          controller: _labNameController,
          label: 'Lab name',
          prefixIcon: Icons.biotech_outlined,
          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: _ownerController,
          label: 'Owner / Manager name',
          prefixIcon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: _emailController,
          label: 'Email address',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.email_outlined,
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
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: _confirmPasswordController,
          label: 'Confirm password',
          obscureText: true,
          prefixIcon: Icons.lock_outline_rounded,
        ),
        const SizedBox(height: 16),
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
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: _gstController,
          label: 'GST number (optional)',
          prefixIcon: Icons.receipt_long_outlined,
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: _licenseController,
          label: 'License / Certification number',
          prefixIcon: Icons.verified_outlined,
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: _accreditationController,
          label: 'Accreditation (NABL, ISO, etc.)',
          prefixIcon: Icons.workspace_premium_outlined,
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: _hoursController,
          label: 'Operating hours',
          hint: 'e.g. Mon–Sat 7 AM – 8 PM',
          prefixIcon: Icons.schedule_outlined,
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Home sample collection'),
          subtitle: const Text('Technician visits patient location'),
          value: _homeCollection,
          onChanged: (v) => setState(() => _homeCollection = v),
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
          'Upload license & accreditation documents',
          style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        _DocUploadTile(
          label: 'Lab license / certification',
          uploaded: _pendingDocs.any((d) => d.type == 'license'),
          onTap: () => _pickDocument('license', 'Lab License'),
        ),
        _DocUploadTile(
          label: 'Accreditation certificate (NABL / ISO)',
          uploaded: _pendingDocs.any((d) => d.type == 'accreditation'),
          onTap: () => _pickDocument('accreditation', 'Accreditation'),
        ),
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
              ...LabRegistrationCatalog.categories.map((c) {
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

  Widget _buildBranchesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Branches & home collection (optional)',
          style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: _pincodesController,
          label: 'Serviceable pincodes for home collection',
          hint: 'Comma-separated, e.g. 110001, 110002',
          prefixIcon: Icons.pin_drop_outlined,
          maxLines: 2,
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
          'Additional branches can be added after approval from your lab profile.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
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
        _ReviewRow('Lab', _labNameController.text),
        _ReviewRow('Owner', _ownerController.text),
        _ReviewRow('Email', _emailController.text),
        _ReviewRow('License', _licenseController.text),
        _ReviewRow('Accreditation', _accreditationController.text),
        _ReviewRow('City', _cityController.text),
        _ReviewRow('Tests offered', '${_selectedTests.length}'),
        _ReviewRow('Documents', '${_pendingDocs.length}'),
        _ReviewRow('Lab images', '${_pendingImages.length}'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'Your application will be reviewed by admin. Only approved labs '
            'appear in the user app.',
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
