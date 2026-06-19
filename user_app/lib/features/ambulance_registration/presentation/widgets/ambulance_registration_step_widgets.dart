import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/ambulance_constants.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/models/ambulance_driver_model.dart';
import '../../../../data/models/ambulance_vehicle_model.dart';
import '../../../../shared/widgets/profile_picture_picker.dart';
import '../../../../shared/widgets/registration_map_picker.dart';
import '../../provider/ambulance_registration_provider.dart';

Widget ambulanceStepScroll({required Widget child}) {
  return SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
    child: child,
  );
}

class AmbulanceStep1ServiceOwner extends ConsumerStatefulWidget {
  const AmbulanceStep1ServiceOwner({super.key, required this.formKey});
  final GlobalKey<FormState> formKey;

  @override
  ConsumerState<AmbulanceStep1ServiceOwner> createState() =>
      _AmbulanceStep1ServiceOwnerState();
}

class _AmbulanceStep1ServiceOwnerState
    extends ConsumerState<AmbulanceStep1ServiceOwner>
    with AutomaticKeepAliveClientMixin {
  late final TextEditingController _serviceName;
  late final TextEditingController _ownerName;
  late final TextEditingController _email;
  late final TextEditingController _mobile;
  late final TextEditingController _emergency;
  late final TextEditingController _license;
  late final TextEditingController _registration;
  late final TextEditingController _pan;
  late final TextEditingController _gst;
  late final TextEditingController _companyReg;
  Uint8List? _profileBytes;
  String? _profileFileName;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final s = ref.read(ambulanceRegistrationFormProvider);
    _serviceName = TextEditingController(text: s.serviceName);
    _ownerName = TextEditingController(text: s.ownerName);
    _email = TextEditingController(text: s.email);
    _mobile = TextEditingController(text: s.mobileNumber);
    _emergency = TextEditingController(text: s.emergencyContact);
    _license = TextEditingController(text: s.licenseNumber);
    _registration = TextEditingController(text: s.registrationNumber);
    _pan = TextEditingController(text: s.panNumber);
    _gst = TextEditingController(text: s.gstNumber);
    _companyReg = TextEditingController(text: s.companyRegistrationNumber);
    _profileBytes = s.profileImageBytes;
    _profileFileName = s.profileImageFileName;
    _syncToProvider();
    for (final c in [
      _serviceName, _ownerName, _email, _mobile,
      _emergency, _license, _registration,
      _pan, _gst, _companyReg,
    ]) {
      c.addListener(_syncToProvider);
    }
  }

  void _syncToProvider() {
    ref.read(ambulanceRegistrationFormProvider.notifier).updateServiceOwner(
          serviceName: _serviceName.text,
          ownerName: _ownerName.text,
          email: _email.text,
          mobileNumber: _mobile.text,
          emergencyContact: _emergency.text,
          licenseNumber: _license.text,
          registrationNumber: _registration.text,
          panNumber: _pan.text,
          gstNumber: _gst.text,
          companyRegistrationNumber: _companyReg.text,
        );
  }

  @override
  void dispose() {
    for (final c in [
      _serviceName, _ownerName, _email, _mobile,
      _emergency, _license, _registration,
      _pan, _gst, _companyReg,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ambulanceStepScroll(
      child: Form(
        key: widget.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Service & Owner Details', style: AppTextStyles.titleLarge),
            const SizedBox(height: 6),
            Text(
              'Company info, licenses, and account credentials',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ProfilePicturePicker(
              imageBytes: _profileBytes,
              onImagePicked: (bytes, fileName) {
                setState(() {
                  _profileBytes = bytes;
                  _profileFileName = fileName;
                });
                ref.read(ambulanceRegistrationFormProvider.notifier)
                    .setProfileImage(bytes: bytes, fileName: fileName);
              },
              onError: (msg) => SnackBarHelper.showError(context, msg),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _serviceName,
              label: 'Service / Company Name',
              hint: 'e.g. City Care Ambulance Services',
              prefixIcon: Icons.local_hospital_outlined,
              validator: _required,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _ownerName,
              label: 'Owner / Manager Name',
              hint: 'Full legal name',
              prefixIcon: Icons.person_outline_rounded,
              validator: _required,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _license,
              label: 'Ambulance Service License Number',
              hint: 'Government-issued license',
              prefixIcon: Icons.badge_outlined,
              validator: _required,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _registration,
              label: 'Company Registration Number',
              hint: 'CIN / LLP / proprietorship number',
              prefixIcon: Icons.confirmation_number_outlined,
              validator: _required,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _companyReg,
              label: 'Trade / Shop Establishment No.',
              hint: 'Optional local registration',
              prefixIcon: Icons.store_outlined,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _pan,
              label: 'PAN Number',
              hint: 'ABCDE1234F',
              prefixIcon: Icons.credit_card_outlined,
              validator: _required,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _gst,
              label: 'GST Number',
              hint: '22AAAAA0000A1Z5',
              prefixIcon: Icons.receipt_long_outlined,
            ),
            const SizedBox(height: 18),
            Text('Contact', style: AppTextStyles.titleMedium),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _email,
              label: 'Email',
              hint: 'example@email.com',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: _emailValidator,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _mobile,
              label: 'Mobile Number',
              hint: '10-digit mobile number',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: _mobileValidator,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _emergency,
              label: '24x7 Dispatch Number',
              hint: 'Emergency dispatch line',
              prefixIcon: Icons.emergency_outlined,
              keyboardType: TextInputType.phone,
              validator: _mobileValidator,
            ),
          ],
        ),
      ),
    );
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'This field is required' : null;

  String? _emailValidator(String? v) {
    final email = v?.trim() ?? '';
    if (email.isEmpty) return 'Email is required';
    if (!email.contains('@')) return 'Enter a valid email';
    return null;
  }

  String? _mobileValidator(String? v) {
    final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) return 'Enter a valid 10-digit number';
    return null;
  }
}

class AmbulanceStep2VehicleFleet extends ConsumerWidget {
  const AmbulanceStep2VehicleFleet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicles = ref.watch(ambulanceRegistrationFormProvider).vehicles;
    return ambulanceStepScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Vehicle Fleet', style: AppTextStyles.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Register each ambulance with plate number, type, and equipment',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          if (vehicles.isEmpty)
            _EmptyFleetCard(
              icon: Icons.directions_car_outlined,
              message: 'No vehicles added yet. Add at least one ambulance.',
            )
          else
            ...vehicles.asMap().entries.map((e) => _VehicleCard(
                  index: e.key,
                  vehicle: e.value,
                  onEdit: () => _showVehicleDialog(context, ref, e.key, e.value),
                  onDelete: () =>
                      ref.read(ambulanceRegistrationFormProvider.notifier)
                          .removeVehicle(e.key),
                )),
          const SizedBox(height: 16),
          CustomOutlineButton(
            label: 'Add Vehicle',
            icon: Icons.add_rounded,
            onPressed: () => _showVehicleDialog(context, ref, null, null),
          ),
        ],
      ),
    );
  }

  Future<void> _showVehicleDialog(
    BuildContext context,
    WidgetRef ref,
    int? index,
    AmbulanceVehicleModel? existing,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _VehicleFormSheet(
        index: index,
        existing: existing,
        onSave: (vehicle) {
          final notifier = ref.read(ambulanceRegistrationFormProvider.notifier);
          if (index != null) {
            notifier.updateVehicle(index, vehicle);
          } else {
            notifier.addVehicle(vehicle);
          }
        },
      ),
    );
  }
}

class _VehicleFormSheet extends StatefulWidget {
  const _VehicleFormSheet({
    required this.onSave,
    this.index,
    this.existing,
  });

  final int? index;
  final AmbulanceVehicleModel? existing;
  final void Function(AmbulanceVehicleModel vehicle) onSave;

  @override
  State<_VehicleFormSheet> createState() => _VehicleFormSheetState();
}

class _VehicleFormSheetState extends State<_VehicleFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _plate;
  late final TextEditingController _make;
  late final TextEditingController _model;
  late final TextEditingController _year;
  late final TextEditingController _color;
  late final TextEditingController _capacity;
  String? _vehicleType;
  bool _hasOxygen = false;
  bool _hasVentilator = false;
  bool _hasDefibrillator = false;
  bool _hasStretcher = true;
  bool _hasAed = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _plate = TextEditingController(text: e?.registrationNumber ?? '');
    _make = TextEditingController(text: e?.make ?? '');
    _model = TextEditingController(text: e?.model ?? '');
    _year = TextEditingController(text: e?.year?.toString() ?? '');
    _color = TextEditingController(text: e?.color ?? '');
    _capacity = TextEditingController(text: e?.capacity?.toString() ?? '');
    _vehicleType = e?.vehicleType;
    _hasOxygen = e?.hasOxygen ?? false;
    _hasVentilator = e?.hasVentilator ?? false;
    _hasDefibrillator = e?.hasDefibrillator ?? false;
    _hasStretcher = e?.hasStretcher ?? true;
    _hasAed = e?.hasAed ?? false;
  }

  @override
  void dispose() {
    _plate.dispose();
    _make.dispose();
    _model.dispose();
    _year.dispose();
    _color.dispose();
    _capacity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.existing == null ? 'Add Vehicle' : 'Edit Vehicle',
                style: AppTextStyles.titleLarge,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _plate,
                label: 'Registration / Plate Number',
                hint: 'e.g. MH12AB1234',
                prefixIcon: Icons.confirmation_number_outlined,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _vehicleType,
                decoration: InputDecoration(
                  labelText: 'Vehicle Type',
                  prefixIcon: const Icon(Icons.medical_services_outlined),
                  border: OutlineInputBorder(
                    borderRadius: AppDecorations.borderRadiusMd,
                  ),
                ),
                items: ambulanceVehicleTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _vehicleType = v),
                validator: (v) => v == null ? 'Select vehicle type' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _make,
                      label: 'Make',
                      hint: 'e.g. Force',
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: _model,
                      label: 'Model',
                      hint: 'e.g. Traveller',
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _year,
                      label: 'Year',
                      hint: '2022',
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final y = int.tryParse((v ?? '').trim());
                        if (y == null || y < 1990) return 'Invalid year';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: _color,
                      label: 'Color',
                      hint: 'White',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _capacity,
                label: 'Patient Capacity',
                hint: '1 or 2',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              Text('Medical Equipment', style: AppTextStyles.labelLarge),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Oxygen supply'),
                value: _hasOxygen,
                onChanged: (v) => setState(() => _hasOxygen = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Ventilator'),
                value: _hasVentilator,
                onChanged: (v) => setState(() => _hasVentilator = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Defibrillator'),
                value: _hasDefibrillator,
                onChanged: (v) => setState(() => _hasDefibrillator = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Stretcher'),
                value: _hasStretcher,
                onChanged: (v) => setState(() => _hasStretcher = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('AED'),
                value: _hasAed,
                onChanged: (v) => setState(() => _hasAed = v),
              ),
              const SizedBox(height: 16),
              CustomButton(
                label: widget.existing == null ? 'Add Vehicle' : 'Save Changes',
                onPressed: () {
                  if (!(_formKey.currentState?.validate() ?? false)) return;
                  widget.onSave(
                    AmbulanceVehicleModel(
                      id: widget.existing?.id ?? const Uuid().v4(),
                      registrationNumber: _plate.text.trim(),
                      vehicleType: _vehicleType!,
                      make: _make.text.trim(),
                      model: _model.text.trim(),
                      year: int.tryParse(_year.text.trim()),
                      color: _color.text.trim(),
                      capacity: int.tryParse(_capacity.text.trim()),
                      hasOxygen: _hasOxygen,
                      hasVentilator: _hasVentilator,
                      hasDefibrillator: _hasDefibrillator,
                      hasStretcher: _hasStretcher,
                      hasAed: _hasAed,
                    ),
                  );
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AmbulanceStep3Drivers extends ConsumerWidget {
  const AmbulanceStep3Drivers({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(ambulanceRegistrationFormProvider);
    return ambulanceStepScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Drivers & EMTs', style: AppTextStyles.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Add drivers with license, EMT certification, and vehicle assignment',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          if (form.drivers.isEmpty)
            _EmptyFleetCard(
              icon: Icons.person_outline_rounded,
              message: 'No drivers added yet. Add at least one driver/EMT.',
            )
          else
            ...form.drivers.asMap().entries.map((e) => _DriverCard(
                  index: e.key,
                  driver: e.value,
                  vehicles: form.vehicles,
                  onEdit: () => _showDriverDialog(context, ref, e.key, e.value),
                  onDelete: () =>
                      ref.read(ambulanceRegistrationFormProvider.notifier)
                          .removeDriver(e.key),
                )),
          const SizedBox(height: 16),
          CustomOutlineButton(
            label: 'Add Driver / EMT',
            icon: Icons.person_add_outlined,
            onPressed: () => _showDriverDialog(context, ref, null, null),
          ),
        ],
      ),
    );
  }

  Future<void> _showDriverDialog(
    BuildContext context,
    WidgetRef ref,
    int? index,
    AmbulanceDriverModel? existing,
  ) async {
    final vehicles = ref.read(ambulanceRegistrationFormProvider).vehicles;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _DriverFormSheet(
        index: index,
        existing: existing,
        vehicles: vehicles,
        onSave: (driver) {
          final notifier = ref.read(ambulanceRegistrationFormProvider.notifier);
          if (index != null) {
            notifier.updateDriver(index, driver);
          } else {
            notifier.addDriver(driver);
          }
        },
      ),
    );
  }
}

class _DriverFormSheet extends StatefulWidget {
  const _DriverFormSheet({
    required this.onSave,
    required this.vehicles,
    this.index,
    this.existing,
  });

  final int? index;
  final AmbulanceDriverModel? existing;
  final List<AmbulanceVehicleModel> vehicles;
  final void Function(AmbulanceDriverModel driver) onSave;

  @override
  State<_DriverFormSheet> createState() => _DriverFormSheetState();
}

class _DriverFormSheetState extends State<_DriverFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _mobile;
  late final TextEditingController _email;
  late final TextEditingController _dob;
  late final TextEditingController _licenseNo;
  late final TextEditingController _licenseExpiry;
  late final TextEditingController _emtNo;
  late final TextEditingController _emtExpiry;
  String? _assignedVehicleId;
  bool _backgroundConsent = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.fullName ?? '');
    _mobile = TextEditingController(text: e?.mobileNumber ?? '');
    _email = TextEditingController(text: e?.email ?? '');
    _dob = TextEditingController(text: e?.dateOfBirth ?? '');
    _licenseNo = TextEditingController(text: e?.drivingLicenseNumber ?? '');
    _licenseExpiry = TextEditingController(text: e?.drivingLicenseExpiry ?? '');
    _emtNo = TextEditingController(text: e?.emtCertificationNumber ?? '');
    _emtExpiry = TextEditingController(text: e?.emtCertificationExpiry ?? '');
    _assignedVehicleId = e?.assignedVehicleId;
    _backgroundConsent = e?.backgroundCheckConsent ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _mobile.dispose();
    _email.dispose();
    _dob.dispose();
    _licenseNo.dispose();
    _licenseExpiry.dispose();
    _emtNo.dispose();
    _emtExpiry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.existing == null ? 'Add Driver' : 'Edit Driver',
                style: AppTextStyles.titleLarge,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _name,
                label: 'Full Name',
                hint: 'Driver / EMT name',
                prefixIcon: Icons.person_outline_rounded,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _mobile,
                label: 'Mobile Number',
                hint: '10-digit number',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) {
                  final d = (v ?? '').replaceAll(RegExp(r'\D'), '');
                  if (d.length != 10) return 'Invalid mobile';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _email,
                label: 'Email (optional)',
                hint: 'driver@email.com',
                prefixIcon: Icons.email_outlined,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _dob,
                label: 'Date of Birth',
                hint: 'DD/MM/YYYY',
                prefixIcon: Icons.cake_outlined,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _licenseNo,
                label: 'Driving License Number',
                hint: 'DL number',
                prefixIcon: Icons.drive_eta_outlined,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _licenseExpiry,
                label: 'License Expiry Date',
                hint: 'DD/MM/YYYY',
                prefixIcon: Icons.event_outlined,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _emtNo,
                label: 'EMT / Paramedic Certificate No.',
                hint: 'Certification number',
                prefixIcon: Icons.medical_information_outlined,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _emtExpiry,
                label: 'EMT Certificate Expiry',
                hint: 'DD/MM/YYYY',
                prefixIcon: Icons.event_outlined,
              ),
              const SizedBox(height: 12),
              if (widget.vehicles.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: _assignedVehicleId,
                  decoration: InputDecoration(
                    labelText: 'Assigned Vehicle',
                    prefixIcon: const Icon(Icons.directions_car_outlined),
                    border: OutlineInputBorder(
                      borderRadius: AppDecorations.borderRadiusMd,
                    ),
                  ),
                  items: widget.vehicles
                      .map((v) => DropdownMenuItem(
                            value: v.id,
                            child: Text(v.displayLabel),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _assignedVehicleId = v),
                ),
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('I consent to background verification'),
                value: _backgroundConsent,
                onChanged: (v) =>
                    setState(() => _backgroundConsent = v ?? false),
              ),
              const SizedBox(height: 16),
              CustomButton(
                label: widget.existing == null ? 'Add Driver' : 'Save Changes',
                onPressed: () {
                  if (!(_formKey.currentState?.validate() ?? false)) return;
                  widget.onSave(
                    AmbulanceDriverModel(
                      id: widget.existing?.id ?? const Uuid().v4(),
                      fullName: _name.text.trim(),
                      mobileNumber: _mobile.text.trim(),
                      email: _email.text.trim(),
                      dateOfBirth: _dob.text.trim(),
                      drivingLicenseNumber: _licenseNo.text.trim(),
                      drivingLicenseExpiry: _licenseExpiry.text.trim(),
                      emtCertificationNumber: _emtNo.text.trim(),
                      emtCertificationExpiry: _emtExpiry.text.trim(),
                      assignedVehicleId: _assignedVehicleId,
                      backgroundCheckConsent: _backgroundConsent,
                    ),
                  );
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AmbulanceStep4Documents extends ConsumerWidget {
  const AmbulanceStep4Documents({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(ambulanceRegistrationFormProvider);
    return ambulanceStepScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Upload Documents', style: AppTextStyles.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Service licenses, vehicle RC/insurance, and driver credentials',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Text('Service Documents', style: AppTextStyles.titleMedium),
          const SizedBox(height: 8),
          ...AmbulanceServiceDocumentType.values.map(
            (type) => _DocumentUploadTile(
              label: type.label,
              isUploaded: form.serviceDocumentUrls.containsKey(type),
              onUpload: () => _pickAndUploadService(context, ref, type),
            ),
          ),
          if (form.vehicles.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Vehicle Documents', style: AppTextStyles.titleMedium),
            const SizedBox(height: 8),
            ...form.vehicles.expand((vehicle) => [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, top: 8),
                    child: Text(
                      vehicle.displayLabel,
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  ...AmbulanceVehicleDocumentType.values.map(
                    (type) => _DocumentUploadTile(
                      label: type.label,
                      isUploaded:
                          form.vehicleDocumentUrls[vehicle.id]?.containsKey(type) ??
                              false,
                      onUpload: () =>
                          _pickAndUploadVehicle(context, ref, vehicle.id, type),
                    ),
                  ),
                ]),
          ],
          if (form.drivers.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Driver Documents', style: AppTextStyles.titleMedium),
            const SizedBox(height: 8),
            ...form.drivers.expand((driver) => [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, top: 8),
                    child: Text(
                      driver.fullName.isNotEmpty
                          ? driver.fullName
                          : 'Driver ${driver.id.substring(0, 6)}',
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  ...AmbulanceDriverDocumentType.values.map(
                    (type) => _DocumentUploadTile(
                      label: type.label,
                      isUploaded:
                          form.driverDocumentUrls[driver.id]?.containsKey(type) ??
                              false,
                      onUpload: () =>
                          _pickAndUploadDriver(context, ref, driver.id, type),
                    ),
                  ),
                ]),
          ],
        ],
      ),
    );
  }

  Future<void> _pickAndUploadService(
    BuildContext context,
    WidgetRef ref,
    AmbulanceServiceDocumentType type,
  ) async {
    final bytes = await _pickFile(context);
    if (bytes == null) return;
    final url = await ref
        .read(ambulanceRegistrationFormProvider.notifier)
        .uploadServiceDocument(
          type: type,
          bytes: bytes.$1,
          filename: bytes.$2,
        );
    if (context.mounted) {
      if (url != null) {
        SnackBarHelper.showSuccess(context, '${type.label} uploaded');
      } else {
        SnackBarHelper.showError(context, 'Upload failed');
      }
    }
  }

  Future<void> _pickAndUploadVehicle(
    BuildContext context,
    WidgetRef ref,
    String vehicleId,
    AmbulanceVehicleDocumentType type,
  ) async {
    final bytes = await _pickFile(context);
    if (bytes == null) return;
    final url = await ref
        .read(ambulanceRegistrationFormProvider.notifier)
        .uploadVehicleDocument(
          vehicleId: vehicleId,
          type: type,
          bytes: bytes.$1,
          filename: bytes.$2,
        );
    if (context.mounted) {
      if (url != null) {
        SnackBarHelper.showSuccess(context, '${type.label} uploaded');
      } else {
        SnackBarHelper.showError(context, 'Upload failed');
      }
    }
  }

  Future<void> _pickAndUploadDriver(
    BuildContext context,
    WidgetRef ref,
    String driverId,
    AmbulanceDriverDocumentType type,
  ) async {
    final bytes = await _pickFile(context);
    if (bytes == null) return;
    final url = await ref
        .read(ambulanceRegistrationFormProvider.notifier)
        .uploadDriverDocument(
          driverId: driverId,
          type: type,
          bytes: bytes.$1,
          filename: bytes.$2,
        );
    if (context.mounted) {
      if (url != null) {
        SnackBarHelper.showSuccess(context, '${type.label} uploaded');
      } else {
        SnackBarHelper.showError(context, 'Upload failed');
      }
    }
  }

  Future<(Uint8List, String)?> _pickFile(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: AppConstants.allowedDocumentFormats,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final file = result.files.first;
    if (file.bytes == null) return null;
    if (file.bytes!.length > AppConstants.maxFileSize) {
      if (context.mounted) {
        SnackBarHelper.showError(context, 'File exceeds 10 MB limit');
      }
      return null;
    }
    return (file.bytes!, file.name);
  }
}

class AmbulanceStep5Location extends ConsumerStatefulWidget {
  const AmbulanceStep5Location({super.key, required this.formKey});
  final GlobalKey<FormState> formKey;

  @override
  ConsumerState<AmbulanceStep5Location> createState() =>
      _AmbulanceStep5LocationState();
}

class _AmbulanceStep5LocationState extends ConsumerState<AmbulanceStep5Location>
    with AutomaticKeepAliveClientMixin {
  late final TextEditingController _address;
  late final TextEditingController _city;
  late final TextEditingController _state;
  late final TextEditingController _pincode;
  late final TextEditingController _serviceArea;
  double? _lat;
  double? _lng;
  bool _available24x7 = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final s = ref.read(ambulanceRegistrationFormProvider);
    _address = TextEditingController(text: s.address);
    _city = TextEditingController(text: s.city);
    _state = TextEditingController(text: s.state);
    _pincode = TextEditingController(text: s.pincode);
    _serviceArea = TextEditingController(text: s.serviceArea);
    _lat = s.latitude;
    _lng = s.longitude;
    _available24x7 = s.available24x7;
    _sync();
    for (final c in [_address, _city, _state, _pincode, _serviceArea]) {
      c.addListener(_sync);
    }
  }

  void _sync() {
    ref.read(ambulanceRegistrationFormProvider.notifier).updateLocation(
          address: _address.text,
          city: _city.text,
          state: _state.text,
          pincode: _pincode.text,
          latitude: _lat,
          longitude: _lng,
          serviceArea: _serviceArea.text,
          available24x7: _available24x7,
        );
  }

  @override
  void dispose() {
    _address.dispose();
    _city.dispose();
    _state.dispose();
    _pincode.dispose();
    _serviceArea.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ambulanceStepScroll(
      child: Form(
        key: widget.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Location & Coverage', style: AppTextStyles.titleLarge),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _address,
              label: 'Base Address',
              hint: 'Full address',
              prefixIcon: Icons.home_outlined,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _city,
              label: 'City',
              hint: 'Your city',
              prefixIcon: Icons.location_city_outlined,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _state,
              label: 'State',
              hint: 'Your state',
              prefixIcon: Icons.map_outlined,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _pincode,
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
              emptyHint: 'Pin your base/dispatch location on the map.',
              webTitle: 'Base location',
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _serviceArea,
              label: 'Service Coverage Area',
              hint: 'Cities/areas you serve',
              prefixIcon: Icons.my_location_outlined,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Available 24x7'),
              value: _available24x7,
              onChanged: (v) {
                setState(() => _available24x7 = v);
                _sync();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class AmbulanceStep6BankDetails extends ConsumerStatefulWidget {
  const AmbulanceStep6BankDetails({super.key, required this.formKey});
  final GlobalKey<FormState> formKey;

  @override
  ConsumerState<AmbulanceStep6BankDetails> createState() =>
      _AmbulanceStep6BankDetailsState();
}

class _AmbulanceStep6BankDetailsState extends ConsumerState<AmbulanceStep6BankDetails>
    with AutomaticKeepAliveClientMixin {
  late final TextEditingController _holder;
  late final TextEditingController _account;
  late final TextEditingController _ifsc;
  late final TextEditingController _bankName;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final s = ref.read(ambulanceRegistrationFormProvider);
    _holder = TextEditingController(text: s.bankAccountHolderName);
    _account = TextEditingController(text: s.bankAccountNumber);
    _ifsc = TextEditingController(text: s.ifscCode);
    _bankName = TextEditingController(text: s.bankName);
    _sync();
    for (final c in [_holder, _account, _ifsc, _bankName]) {
      c.addListener(_sync);
    }
  }

  void _sync() {
    ref.read(ambulanceRegistrationFormProvider.notifier).updateBank(
          bankAccountHolderName: _holder.text,
          bankAccountNumber: _account.text,
          ifscCode: _ifsc.text,
          bankName: _bankName.text,
        );
  }

  @override
  void dispose() {
    _holder.dispose();
    _account.dispose();
    _ifsc.dispose();
    _bankName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final form = ref.watch(ambulanceRegistrationFormProvider);
    return ambulanceStepScroll(
      child: Form(
        key: widget.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bank & Payout Details', style: AppTextStyles.titleLarge),
            const SizedBox(height: 6),
            Text(
              'Account for trip settlements and payouts',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _holder,
              label: 'Account Holder Name',
              hint: 'As per bank records',
              prefixIcon: Icons.person_outline_rounded,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _account,
              label: 'Bank Account Number',
              hint: 'Account number',
              prefixIcon: Icons.account_balance_outlined,
              keyboardType: TextInputType.number,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _ifsc,
              label: 'IFSC Code',
              hint: 'e.g. SBIN0001234',
              prefixIcon: Icons.code_outlined,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _bankName,
              label: 'Bank Name',
              hint: 'e.g. State Bank of India',
              prefixIcon: Icons.account_balance_rounded,
            ),
            const SizedBox(height: 20),
            Text('Cancelled Cheque', style: AppTextStyles.titleMedium),
            const SizedBox(height: 8),
            _DocumentUploadTile(
              label: AmbulanceServiceDocumentType.cancelledCheque.label,
              isUploaded: form.serviceDocumentUrls
                  .containsKey(AmbulanceServiceDocumentType.cancelledCheque),
              onUpload: () async {
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: AppConstants.allowedDocumentFormats,
                  withData: true,
                );
                if (result == null || result.files.first.bytes == null) return;
                final file = result.files.first;
                final url = await ref
                    .read(ambulanceRegistrationFormProvider.notifier)
                    .uploadServiceDocument(
                      type: AmbulanceServiceDocumentType.cancelledCheque,
                      bytes: file.bytes!,
                      filename: file.name,
                    );
                if (context.mounted) {
                  if (url != null) {
                    SnackBarHelper.showSuccess(context, 'Cheque uploaded');
                  } else {
                    SnackBarHelper.showError(context, 'Upload failed');
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class AmbulanceStep7Review extends ConsumerWidget {
  const AmbulanceStep7Review({
    super.key,
    required this.onSubmit,
    required this.onEdit,
  });

  final VoidCallback onSubmit;
  final void Function(int step) onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(ambulanceRegistrationFormProvider);
    return ambulanceStepScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Review & Submit', style: AppTextStyles.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Confirm all details before admin verification',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          _ReviewSection(
            title: 'Service',
            onEdit: () => onEdit(1),
            rows: [
              form.serviceName,
              form.ownerName,
              form.licenseNumber,
              form.panNumber,
            ],
          ),
          _ReviewSection(
            title: 'Fleet (${form.vehicles.length} vehicles)',
            onEdit: () => onEdit(2),
            rows: form.vehicles.map((v) => v.displayLabel).toList(),
          ),
          _ReviewSection(
            title: 'Drivers (${form.drivers.length})',
            onEdit: () => onEdit(3),
            rows: form.drivers
                .map((d) => '${d.fullName} — ${d.drivingLicenseNumber}')
                .toList(),
          ),
          _ReviewSection(
            title: 'Location',
            onEdit: () => onEdit(5),
            rows: [
              '${form.address}, ${form.city}',
              form.serviceArea,
              form.available24x7 ? '24x7 available' : 'Limited hours',
            ],
          ),
          _ReviewSection(
            title: 'Bank',
            onEdit: () => onEdit(6),
            rows: [
              form.bankAccountHolderName,
              '****${form.bankAccountNumber.length > 4 ? form.bankAccountNumber.substring(form.bankAccountNumber.length - 4) : form.bankAccountNumber}',
              form.ifscCode,
            ],
          ),
          if (form.submitError != null) ...[
            const SizedBox(height: 12),
            Text(
              form.submitError!,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
          ],
          const SizedBox(height: 20),
          CustomButton(
            label: 'Submit for Verification',
            isLoading: form.isSubmitting,
            onPressed: onSubmit,
          ),
        ],
      ),
    );
  }
}

class _ReviewSection extends StatelessWidget {
  const _ReviewSection({
    required this.title,
    required this.onEdit,
    required this.rows,
  });

  final String title;
  final VoidCallback onEdit;
  final List<String> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppDecorations.borderRadiusMd,
        border: Border.all(color: AppColors.grey200),
      ),
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
          ...rows.where((r) => r.trim().isNotEmpty).map(
                (r) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    r,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({
    required this.index,
    required this.vehicle,
    required this.onEdit,
    required this.onDelete,
  });

  final int index;
  final AmbulanceVehicleModel vehicle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: const Icon(Icons.local_shipping_outlined, color: AppColors.primary),
        ),
        title: Text(vehicle.displayLabel),
        subtitle: Text('${vehicle.make} ${vehicle.model} • ${vehicle.year ?? ''}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.edit_outlined), onPressed: onEdit),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({
    required this.index,
    required this.driver,
    required this.vehicles,
    required this.onEdit,
    required this.onDelete,
  });

  final int index;
  final AmbulanceDriverModel driver;
  final List<AmbulanceVehicleModel> vehicles;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final assigned = vehicles
        .where((v) => v.id == driver.assignedVehicleId)
        .map((v) => v.registrationNumber)
        .firstOrNull;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: const Icon(Icons.person_outline, color: AppColors.primary),
        ),
        title: Text(driver.fullName),
        subtitle: Text(
          '${driver.drivingLicenseNumber}${assigned != null ? ' • $assigned' : ''}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.edit_outlined), onPressed: onEdit),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyFleetCard extends StatelessWidget {
  const _EmptyFleetCard({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: AppDecorations.borderRadiusMd,
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppColors.textSecondary),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _DocumentUploadTile extends StatelessWidget {
  const _DocumentUploadTile({
    required this.label,
    required this.isUploaded,
    required this.onUpload,
  });

  final String label;
  final bool isUploaded;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppDecorations.borderRadiusMd,
        border: Border.all(
          color: isUploaded ? AppColors.success : AppColors.grey200,
        ),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          isUploaded ? Icons.check_circle : Icons.upload_file_outlined,
          color: isUploaded ? AppColors.success : AppColors.textSecondary,
        ),
        title: Text(label, style: AppTextStyles.bodySmall),
        trailing: TextButton(
          onPressed: onUpload,
          child: Text(isUploaded ? 'Replace' : 'Upload'),
        ),
      ),
    );
  }
}
