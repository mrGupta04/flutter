import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/media_url_utils.dart';
import '../../../../core/utils/user_auth_guard.dart';
import '../../../../core/utils/validation_utils.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/models/nurse_model.dart';
import '../../../../shared/widgets/bookable_slots_section.dart';
import '../../../doctor_registration/provider/nurse_profile_provider.dart';
import '../../../user_auth/provider/patient_auth_provider.dart';
import '../../../upcoming_meeting/provider/upcoming_meeting_timer_provider.dart';
import '../../provider/nurse_home_visit_provider.dart';

class NurseHomeVisitBookingScreen extends ConsumerStatefulWidget {
  const NurseHomeVisitBookingScreen({super.key, required this.nurseId});

  final String nurseId;

  @override
  ConsumerState<NurseHomeVisitBookingScreen> createState() =>
      _NurseHomeVisitBookingScreenState();
}

class _NurseHomeVisitBookingScreenState
    extends ConsumerState<NurseHomeVisitBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _reasonController = TextEditingController();
  final _couponController = TextEditingController();
  String? _selectedDateKey;
  double? _patientLatitude;
  double? _patientLongitude;
  bool _isFetchingLocation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureAuthAndPrefill());
  }

  Future<void> _ensureAuthAndPrefill() async {
    if (!await ensureUserLoggedIn(context)) {
      if (mounted) context.pop();
      return;
    }
    final user = ref.read(patientAuthProvider).user;
    if (user != null) {
      if (_nameController.text.isEmpty) _nameController.text = user.fullName;
      if (_emailController.text.isEmpty) _emailController.text = user.email;
      if (_mobileController.text.isEmpty && user.mobileNumber.isNotEmpty) {
        _mobileController.text = user.mobileNumber;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _reasonController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _useMyLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      final position =
          await LocationService.getCurrentPositionWithPrompt(context);
      if (!mounted) return;
      if (position == null) {
        SnackBarHelper.showError(
          context,
          'Location is required. Enable location services and try again.',
        );
        return;
      }
      setState(() {
        _patientLatitude = position.latitude;
        _patientLongitude = position.longitude;
      });
      SnackBarHelper.showSuccess(
        context,
        'Location captured. Add your address details below.',
      );
    } on LocationFailure catch (e) {
      if (mounted) SnackBarHelper.showError(context, e.message);
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  Future<void> _submit(NurseModel nurse) async {
    if (!await ensureUserLoggedIn(context)) return;
    if (!_formKey.currentState!.validate()) return;

    final ok = await ref
        .read(nurseHomeVisitBookingProvider(widget.nurseId).notifier)
        .submit(
          patientName: _nameController.text.trim(),
          patientMobile: _mobileController.text.trim(),
          patientEmail: _emailController.text.trim(),
          patientAddress: _addressController.text.trim(),
          patientCity: _cityController.text.trim(),
          patientPincode: _pincodeController.text.trim(),
          patientState: _stateController.text.trim(),
          visitReason: _reasonController.text.trim(),
          patientLatitude: _patientLatitude,
          patientLongitude: _patientLongitude,
          couponCode: _couponController.text.trim().isEmpty
              ? null
              : _couponController.text.trim(),
        );

    if (!mounted) return;
    if (ok) {
      final booking =
          ref.read(nurseHomeVisitBookingProvider(widget.nurseId)).booking;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Request sent'),
          content: Text(
            'Your home nursing visit request was sent to ${nurse.displayName}. '
            'The nurse will review your address — you can pay after approval.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.pop();
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
      ref.invalidate(nurseBookableSlotsProvider(widget.nurseId));
      if (booking != null) {
        ref
            .read(upcomingMeetingTimerProvider.notifier)
            .registerConsultationResult(booking);
      }
    } else {
      final err =
          ref.read(nurseHomeVisitBookingProvider(widget.nurseId)).error;
      SnackBarHelper.showError(context, err ?? 'Request failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final nurseAsync = ref.watch(nurseProfileProvider(widget.nurseId));
    final slotsAsync = ref.watch(nurseBookableSlotsProvider(widget.nurseId));
    final bookingState =
        ref.watch(nurseHomeVisitBookingProvider(widget.nurseId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Book nurse home visit')),
      body: nurseAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(
          message: e.toString().replaceFirst('Exception: ', ''),
          onRetry: () => ref.invalidate(nurseProfileProvider(widget.nurseId)),
        ),
        data: (nurse) => Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _NurseHeader(nurse: nurse),
                      const SizedBox(height: 16),
                      if (nurse.homeVisitFee != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: AppDecorations.borderRadiusMd,
                          ),
                          child: Text(
                            'Home visit fee: ₹${nurse.homeVisitFee}',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      slotsAsync.when(
                        skipLoadingOnReload: true,
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        error: (e, _) => AppErrorWidget(
                          message: e.toString().replaceFirst('Exception: ', ''),
                          onRetry: () => ref.invalidate(
                            nurseBookableSlotsProvider(widget.nurseId),
                          ),
                        ),
                        data: (slotsData) => BookableSlotsSection(
                          slotsData: slotsData,
                          selectedSlot: bookingState.selectedSlot,
                          selectedDateKey: _selectedDateKey,
                          isSlotSelectionBusy: bookingState.isReservingSlot,
                          onDateSelected: (dateKey) {
                            setState(() => _selectedDateKey = dateKey);
                          },
                          onSlotSelected: (slot) async {
                            await ref
                                .read(
                                  nurseHomeVisitBookingProvider(widget.nurseId)
                                      .notifier,
                                )
                                .selectSlot(slot);
                          },
                          emptyMessage:
                              'This nurse has not set home visit hours yet.',
                        ),
                      ),
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        onPressed:
                            _isFetchingLocation ? null : _useMyLocation,
                        icon: const Icon(Icons.my_location_rounded),
                        label: const Text('Use my live location'),
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: _nameController,
                        label: 'Full name',
                        prefixIcon: Icons.person_outline_rounded,
                        validator: (v) => ValidationUtils.validateName(v ?? ''),
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: _mobileController,
                        label: 'Mobile number',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (v) =>
                            ValidationUtils.validatePhoneNumber(v ?? ''),
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: _emailController,
                        label: 'Email',
                        prefixIcon: Icons.email_outlined,
                        validator: ValidationUtils.validateEmail,
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: _addressController,
                        label: 'Home address',
                        prefixIcon: Icons.home_outlined,
                        maxLines: 2,
                        validator: (v) =>
                            (v ?? '').trim().length < 5 ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: _cityController,
                        label: 'City',
                        prefixIcon: Icons.location_city_outlined,
                        validator: (v) =>
                            (v ?? '').trim().length < 2 ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: _stateController,
                        label: 'State',
                        prefixIcon: Icons.map_outlined,
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: _pincodeController,
                        label: 'Pincode',
                        prefixIcon: Icons.pin_drop_outlined,
                        validator: (v) =>
                            (v ?? '').trim().length == 6 ? null : 'Invalid',
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: _reasonController,
                        label: 'Care needed / reason for visit',
                        prefixIcon: Icons.notes_rounded,
                        maxLines: 3,
                        validator: (v) =>
                            (v ?? '').trim().length < 5 ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: _couponController,
                        label: 'Coupon code (optional)',
                        prefixIcon: Icons.local_offer_outlined,
                        hint: 'Applied when you pay after approval',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: CustomButton(
                  label: 'Request home visit',
                  isLoading: bookingState.isSubmitting,
                  onPressed: bookingState.selectedSlot == null
                      ? () {}
                      : () => _submit(nurse),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NurseHeader extends StatelessWidget {
  const _NurseHeader({required this.nurse});

  final NurseModel nurse;

  @override
  Widget build(BuildContext context) {
    final imageUrl = MediaUrlUtils.resolve(nurse.profilePicture);
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundImage: imageUrl.isNotEmpty
              ? CachedNetworkImageProvider(imageUrl)
              : null,
          child: imageUrl.isEmpty
              ? const Icon(Icons.health_and_safety_rounded)
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nurse.displayName,
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (nurse.specialization != null)
                Text(
                  nurse.specialization!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
