import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/phone_countries.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/user_auth_guard.dart';
import '../../../../core/utils/validation_utils.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/models/ambulance_model.dart';
import '../../../../data/repositories/ambulance_repository.dart';
import '../../../user_auth/provider/patient_auth_provider.dart';

Future<void> showAmbulanceActionSheet(
  BuildContext context, {
  required AmbulanceModel ambulance,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => AmbulanceActionSheet(ambulance: ambulance),
  );
}

class AmbulanceActionSheet extends ConsumerStatefulWidget {
  const AmbulanceActionSheet({super.key, required this.ambulance});

  final AmbulanceModel ambulance;

  @override
  ConsumerState<AmbulanceActionSheet> createState() =>
      _AmbulanceActionSheetState();
}

class _AmbulanceActionSheetState extends ConsumerState<AmbulanceActionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _pickupController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;
  bool _showRequestForm = false;
  double? _pickupLat;
  double? _pickupLng;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(patientAuthProvider).user;
      if (user != null) {
        _nameController.text = user.fullName;
        _mobileController.text = user.mobileNumber;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _pickupController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String? get _dialNumber {
    final emergency = widget.ambulance.emergencyContact?.trim();
    if (emergency != null && emergency.isNotEmpty) return emergency;
    final mobile = widget.ambulance.mobileNumber?.trim();
    if (mobile != null && mobile.isNotEmpty) return mobile;
    return null;
  }

  Future<void> _callNow() async {
    final number = _dialNumber;
    if (number == null) {
      SnackBarHelper.showError(context, 'Phone number not available');
      return;
    }
    final digits = number.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$digits');
    if (!await launchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _useCurrentLocation() async {
    final position =
        await LocationService.getCurrentPositionWithPrompt(context);
    if (!mounted) return;
    if (position == null) {
      SnackBarHelper.showError(
        context,
        'Could not get your location. Please type the pickup address.',
      );
      return;
    }
    setState(() {
      _pickupLat = position.latitude;
      _pickupLng = position.longitude;
      if (_pickupController.text.trim().isEmpty) {
        _pickupController.text =
            'Near GPS ${position.latitude.toStringAsFixed(5)}, '
            '${position.longitude.toStringAsFixed(5)} — add landmark';
      }
    });
    SnackBarHelper.showSuccess(context, 'Location attached to request');
  }

  Future<void> _submitRequest() async {
    final loggedIn = await ensureUserLoggedIn(
      context,
      message:
          'Please log in so the ambulance service can reach you and track this request.',
    );
    if (!loggedIn || !mounted) return;
    if (!_formKey.currentState!.validate()) return;

    final ambulanceId = widget.ambulance.id;
    if (ambulanceId == null || ambulanceId.isEmpty) {
      SnackBarHelper.showError(context, 'Invalid ambulance service');
      return;
    }

    setState(() => _isSubmitting = true);
    final user = ref.read(patientAuthProvider).user;
    final response = await AmbulanceRepository().requestAmbulance(
      ambulanceId: ambulanceId,
      patientName: _nameController.text.trim(),
      patientMobile: _mobileController.text.trim(),
      patientEmail: user?.email,
      patientId: user?.id,
      pickupAddress: _pickupController.text.trim(),
      pickupLatitude: _pickupLat,
      pickupLongitude: _pickupLng,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      isEmergency: true,
      countryCode: user?.countryCode ?? PhoneCountries.defaultDialCode,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (response.success) {
      Navigator.of(context).pop();
      SnackBarHelper.showSuccess(
        context,
        response.message ??
            'Ambulance requested. Call them now if this is urgent.',
      );
    } else {
      SnackBarHelper.showError(
        context,
        response.error ?? 'Could not submit ambulance request',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.ambulance;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final vehicles = a.vehicleTypes ?? [];

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.92,
        ),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  a.serviceName ?? 'Ambulance service',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  [
                    if (a.city != null && a.city!.isNotEmpty) a.city!,
                    if (a.available24x7 == true) '24×7 available',
                    if (vehicles.isNotEmpty) vehicles.join(', '),
                  ].join(' · '),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (a.address != null && a.address!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    a.address!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'In a medical emergency, call the ambulance immediately. '
                    'You can also send a request with your pickup location.',
                    style: AppTextStyles.bodySmall.copyWith(height: 1.35),
                  ),
                ),
                const SizedBox(height: 16),
                CustomButton(
                  label: _dialNumber == null
                      ? 'Phone number unavailable'
                      : 'Call now',
                  icon: Icons.phone_in_talk_rounded,
                  isEnabled: _dialNumber != null,
                  onPressed: _callNow,
                ),
                const SizedBox(height: 10),
                CustomOutlineButton(
                  label: _showRequestForm
                      ? 'Hide request form'
                      : 'Send pickup request',
                  icon: Icons.local_shipping_outlined,
                  onPressed: () =>
                      setState(() => _showRequestForm = !_showRequestForm),
                ),
                if (_showRequestForm) ...[
                  const SizedBox(height: 20),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CustomTextField(
                          controller: _nameController,
                          label: 'Patient name',
                          prefixIcon: Icons.person_outline_rounded,
                          validator: (v) =>
                              ValidationUtils.validateName(v ?? ''),
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          controller: _mobileController,
                          label: 'Mobile number',
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (v) =>
                              ValidationUtils.validatePhoneNumber(v),
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          controller: _pickupController,
                          label: 'Pickup address',
                          prefixIcon: Icons.place_outlined,
                          maxLines: 2,
                          validator: (v) {
                            if (v == null || v.trim().length < 5) {
                              return 'Enter a clear pickup address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: _useCurrentLocation,
                            icon: const Icon(Icons.my_location_rounded, size: 18),
                            label: const Text('Use current location'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        CustomTextField(
                          controller: _notesController,
                          label: 'Notes (optional)',
                          prefixIcon: Icons.notes_rounded,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),
                        CustomButton(
                          label: 'Request ambulance',
                          icon: Icons.send_rounded,
                          isLoading: _isSubmitting,
                          onPressed: _submitRequest,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
