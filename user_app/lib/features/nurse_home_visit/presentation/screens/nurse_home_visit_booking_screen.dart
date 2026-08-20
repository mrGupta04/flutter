import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/live_address_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/media_url_utils.dart';
import '../../../../core/utils/user_auth_guard.dart';
import '../../../../core/utils/validation_utils.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/models/doctor_model.dart';
import '../../../../data/models/nurse_model.dart';
import '../../../../shared/widgets/bookable_slots_section.dart';
import '../../../../shared/widgets/care_provider_listing_cards.dart';
import '../../../../shared/widgets/full_screen_image_viewer.dart';
import '../../../../shared/widgets/nurse_feedback_sheet.dart';
import '../../../doctor_registration/provider/nurse_profile_provider.dart';
import '../../../user_auth/provider/patient_auth_provider.dart';
import '../../../user_dashboard/provider/patient_dashboard_provider.dart';
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
    if (mounted && _addressController.text.trim().isEmpty) {
      await _fillFromLiveLocation(promptIfNeeded: false);
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

  Future<void> _fillFromLiveLocation({bool promptIfNeeded = true}) async {
    setState(() => _isFetchingLocation = true);
    try {
      final captured = await LiveAddressService.capture(
        context,
        promptIfNeeded: promptIfNeeded,
      );
      if (!mounted) return;
      if (captured == null) {
        if (promptIfNeeded) {
          SnackBarHelper.showError(
            context,
            'Location is required. Enable location services and try again.',
          );
        }
        return;
      }

      _applyCapturedAddress(captured, overwrite: promptIfNeeded);
      if (promptIfNeeded) {
        SnackBarHelper.showSuccess(
          context,
          captured.hasAddress
              ? 'Live location captured and address filled.'
              : 'Location pinned. Enter the remaining address details.',
        );
      }
    } on LocationFailure catch (e) {
      if (mounted && promptIfNeeded) SnackBarHelper.showError(context, e.message);
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  void _applyCapturedAddress(
    CapturedLiveAddress captured, {
    required bool overwrite,
  }) {
    _patientLatitude = captured.latitude;
    _patientLongitude = captured.longitude;
    final resolved = captured.resolved;
    if (resolved == null) {
      setState(() {});
      return;
    }
    if (overwrite || _addressController.text.trim().isEmpty) {
      _addressController.text = resolved.address;
    }
    if (overwrite || _cityController.text.trim().isEmpty) {
      if (resolved.city.isNotEmpty) _cityController.text = resolved.city;
    }
    if (overwrite || _stateController.text.trim().isEmpty) {
      if (resolved.state.isNotEmpty) _stateController.text = resolved.state;
    }
    if (overwrite || _pincodeController.text.trim().isEmpty) {
      if (resolved.pincode.isNotEmpty) {
        _pincodeController.text = resolved.pincode;
      }
    }
    setState(() {});
  }

  Future<void> _useMyLocation() => _fillFromLiveLocation(promptIfNeeded: true);

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
      if (booking != null) {
        ref
            .read(upcomingMeetingTimerProvider.notifier)
            .registerConsultationResult(booking);
        ref.invalidate(nurseBookableSlotsProvider(widget.nurseId));
        await ref.read(patientDashboardProvider.notifier).loadBookings();
        if (!mounted) return;
        context.go(
          '${AppConstants.routeNurseBookingStatus}?bookingId=${Uri.encodeComponent(booking.id)}',
        );
        return;
      }
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
      await ref.read(patientDashboardProvider.notifier).loadBookings();
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

    ref.listen(nurseBookableSlotsProvider(widget.nurseId), (previous, next) {
      final visitState =
          ref.read(nurseHomeVisitBookingProvider(widget.nurseId));
      final selected = visitState.selectedSlot;
      if (selected == null) return;
      if (visitState.slotHoldId != null && visitState.slotHoldId!.isNotEmpty) {
        return;
      }
      next.whenData((slotsData) {
        final stillAvailable = slotsData.slots.any(
          (slot) => slot.slotKey == selected.slotKey,
        );
        if (!stillAvailable && mounted) {
          ref
              .read(nurseHomeVisitBookingProvider(widget.nurseId).notifier)
              .selectSlot(null);
          SnackBarHelper.showError(
            context,
            'Your selected slot is no longer available. Please choose another.',
          );
        }
      });
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Book nurse')),
      body: nurseAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(
          message: e.toString().replaceFirst('Exception: ', ''),
          onRetry: () => ref.invalidate(nurseProfileProvider(widget.nurseId)),
        ),
        data: (nurse) => Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(nurseBookableSlotsProvider(widget.nurseId));
                  await ref
                      .read(nurseBookableSlotsProvider(widget.nurseId).future);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _NurseBookingProfileHeader(nurse: nurse),
                        const SizedBox(height: 20),
                        slotsAsync.when(
                          skipLoadingOnReload: true,
                          loading: () => const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (e, _) => AppErrorWidget(
                            message:
                                e.toString().replaceFirst('Exception: ', ''),
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
                              if (bookingState.selectedSlot?.dateKey !=
                                  dateKey) {
                                ref
                                    .read(
                                      nurseHomeVisitBookingProvider(
                                        widget.nurseId,
                                      ).notifier,
                                    )
                                    .selectSlot(null);
                              }
                            },
                            onSlotSelected: (slot) async {
                              await ref
                                  .read(
                                    nurseHomeVisitBookingProvider(
                                      widget.nurseId,
                                    ).notifier,
                                  )
                                  .selectSlot(slot);
                              if (!mounted) return;
                              final err = ref
                                  .read(
                                    nurseHomeVisitBookingProvider(
                                      widget.nurseId,
                                    ),
                                  )
                                  .error;
                              if (err != null && mounted) {
                                SnackBarHelper.showError(context, err);
                              }
                            },
                            emptyMessage:
                                'This nurse has not set home visit hours yet, '
                                'or all slots are booked. Try another nurse or time.',
                          ),
                        ),
                      const SizedBox(height: 24),
                      Text(
                        'Patient details',
                        style: AppTextStyles.titleSmall.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Share your contact and address for the home visit. Tap below to pin GPS and auto-fill the form.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed:
                            _isFetchingLocation ? null : _useMyLocation,
                        icon: _isFetchingLocation
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.my_location_rounded),
                        label: Text(
                          _isFetchingLocation
                              ? 'Getting live location…'
                              : _patientLatitude != null
                                  ? 'Update from live location'
                                  : 'Use my live location',
                        ),
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
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: CustomButton(
                  label: bookingState.selectedSlot != null
                      ? 'Request home visit'
                      : 'Select visit time',
                  isEnabled: bookingState.selectedSlot != null &&
                      !bookingState.isReservingSlot,
                  isLoading: bookingState.isSubmitting ||
                      bookingState.isReservingSlot,
                  onPressed: () => _submit(nurse),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NurseBookingProfileHeader extends StatelessWidget {
  const _NurseBookingProfileHeader({required this.nurse});

  final NurseModel nurse;

  @override
  Widget build(BuildContext context) {
    final imageUrl = MediaUrlUtils.resolve(nurse.profilePicture);
    final isVerified =
        nurse.verificationStatus == VerificationStatus.verified;
    final skills = nurse.nursingSkills
            ?.where((s) => s.trim().isNotEmpty)
            .map((s) => s.trim())
            .toList() ??
        const <String>[];
    final languages = nurse.languagesSpoken
            ?.where((s) => s.trim().isNotEmpty)
            .map((s) => s.trim())
            .toList() ??
        const <String>[];
    final locationParts = <String>[
      if (nurse.city?.trim().isNotEmpty == true) nurse.city!.trim(),
      if (nurse.state?.trim().isNotEmpty == true) nurse.state!.trim(),
    ];
    final locationLine = locationParts.join(', ');
    final ratingLabel = nurse.hasRating && (nurse.ratingCount ?? 0) > 0
        ? '${nurse.cardDisplayRating.toStringAsFixed(1)} (${nurse.ratingCount})'
        : nurse.cardDisplayRating.toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppDecorations.borderRadiusLg,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: imageUrl.isNotEmpty
                      ? () => showFullScreenNetworkImage(
                            context,
                            imageUrl: imageUrl,
                            title: nurse.displayName,
                          )
                      : null,
                  borderRadius: BorderRadius.circular(14),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 88,
                      height: 88,
                      child: imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => _profilePlaceholder(),
                              errorWidget: (_, __, ___) => _profilePlaceholder(),
                            )
                          : _profilePlaceholder(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
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
                    const SizedBox(height: 4),
                    Text(
                      nurse.cardDesignationLabel,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: kNurseCardAccent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (nurse.cardQualificationSubtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        nurse.cardQualificationSubtitle!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _ProfileChip(
                          icon: Icons.star_rounded,
                          label: ratingLabel,
                          iconColor: AppColors.tertiary,
                          onTap: nurse.id != null && nurse.id!.isNotEmpty
                              ? () => showNurseFeedbackSheet(
                                    context,
                                    nurse: nurse,
                                  )
                              : null,
                        ),
                        if (isVerified)
                          const _ProfileChip(
                            icon: Icons.verified_rounded,
                            label: 'Verified',
                            iconColor: kNurseCardAccent,
                          ),
                        if (nurse.isLiveNow)
                          const _ProfileChip(
                            icon: Icons.circle,
                            label: 'Available now',
                            iconColor: AppColors.success,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.home_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Home visit',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: AppDecorations.borderRadiusMd,
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  if (nurse.effectiveHomeVisitFee != null)
                    Expanded(
                      child: _ProfileStatColumn(
                        icon: Icons.currency_rupee_rounded,
                        label: 'Visit fee',
                        value: FormattingUtils.formatConsultationFee(
                          nurse.effectiveHomeVisitFee!,
                        ),
                        strikeValue: nurse.originalHomeVisitFee != null
                            ? FormattingUtils.formatConsultationFee(
                                nurse.originalHomeVisitFee!,
                              )
                            : null,
                      ),
                    ),
                  if (nurse.effectiveHomeVisitFee != null &&
                      nurse.yearsOfExperience != null)
                    const _ProfileStatDivider(),
                  if (nurse.yearsOfExperience != null)
                    Expanded(
                      child: _ProfileStatColumn(
                        icon: Icons.work_outline_rounded,
                        label: 'Experience',
                        value: '${nurse.yearsOfExperience}+ yrs',
                      ),
                    ),
                  if (nurse.yearsOfExperience != null)
                    const _ProfileStatDivider(),
                  Expanded(
                    child: _ProfileStatColumn(
                      icon: Icons.schedule_rounded,
                      label: 'Service',
                      value: nurse.availableForHomeVisit != false
                          ? 'Home nursing'
                          : 'Unavailable',
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (skills.isNotEmpty) ...[
            const SizedBox(height: 12),
            _ProfileDetailRow(
              icon: Icons.medical_services_outlined,
              label: 'Services & skills',
              value: skills.join(' · '),
            ),
          ],
          if (languages.isNotEmpty) ...[
            const SizedBox(height: 8),
            _ProfileDetailRow(
              icon: Icons.translate_rounded,
              label: 'Languages',
              value: languages.join(', '),
            ),
          ],
          if (locationLine.isNotEmpty) ...[
            const SizedBox(height: 8),
            _ProfileDetailRow(
              icon: Icons.location_on_outlined,
              label: 'Location',
              value: locationLine,
            ),
          ],
        ],
      ),
    );
  }

  Widget _profilePlaceholder() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            kNurseCardAccentLight,
            kNurseCardAccent.withValues(alpha: 0.18),
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.health_and_safety_rounded,
          size: 34,
          color: kNurseCardAccent,
        ),
      ),
    );
  }
}

class _ProfileChip extends StatelessWidget {
  const _ProfileChip({
    required this.icon,
    required this.label,
    required this.iconColor,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: iconColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return chip;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: chip,
      ),
    );
  }
}

class _ProfileStatColumn extends StatelessWidget {
  const _ProfileStatColumn({
    required this.icon,
    required this.label,
    required this.value,
    this.strikeValue,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? strikeValue;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        if (strikeValue != null) ...[
          Text(
            strikeValue!,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
              decoration: TextDecoration.lineThrough,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
        ],
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.labelSmall.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ProfileStatDivider extends StatelessWidget {
  const _ProfileStatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: AppColors.divider,
    );
  }
}

class _ProfileDetailRow extends StatelessWidget {
  const _ProfileDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.35,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
