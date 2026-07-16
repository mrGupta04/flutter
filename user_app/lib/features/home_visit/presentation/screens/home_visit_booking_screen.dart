import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/media_url_utils.dart';
import '../../../../core/utils/validation_utils.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/models/consultation_type.dart';
import '../../../../data/models/doctor_model.dart';
import '../../../../shared/widgets/bookable_slots_section.dart';
import '../../../../shared/widgets/consultation_booking_price_summary.dart';
import '../../../../shared/widgets/doctor_consultation_fees_banner.dart';
import '../../../../shared/widgets/healthcare_ui.dart';
import '../../../../shared/widgets/prescription_included_banner.dart';
import '../../../../shared/widgets/previous_reports_picker.dart';
import '../../../online_consult/provider/online_consult_provider.dart';
import '../../../upcoming_meeting/provider/upcoming_meeting_timer_provider.dart';
import '../../../user_auth/provider/patient_auth_provider.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/utils/user_auth_guard.dart';
import '../../provider/home_visit_provider.dart';

class HomeVisitBookingScreen extends ConsumerStatefulWidget {
  const HomeVisitBookingScreen({super.key, required this.doctorId});

  final String doctorId;

  @override
  ConsumerState<HomeVisitBookingScreen> createState() =>
      _HomeVisitBookingScreenState();
}

class _HomeVisitBookingScreenState extends ConsumerState<HomeVisitBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _reasonController = TextEditingController();
  String? _selectedDateKey;
  double? _patientLatitude;
  double? _patientLongitude;
  bool _isFetchingLocation = false;

  BookableSlotsQuery get _slotsQuery => BookableSlotsQuery(
        doctorId: widget.doctorId,
        consultationType: 'book_home',
      );

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
      if (_nameController.text.isEmpty) {
        _nameController.text = user.fullName;
      }
      if (_emailController.text.isEmpty) {
        _emailController.text = user.email;
      }
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
    super.dispose();
  }

  Future<void> _useMyLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      final position = await LocationService.getCurrentPosition();
      if (!mounted) return;
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

  Future<void> _submit(DoctorModel doctor) async {
    if (!await ensureUserLoggedIn(context)) return;
    if (!_formKey.currentState!.validate()) return;

    final ok = await ref
        .read(homeVisitBookingProvider(widget.doctorId).notifier)
        .submit(
          doctorId: widget.doctorId,
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
        );

    if (!mounted) return;
    if (ok) {
      final booking =
          ref.read(homeVisitBookingProvider(widget.doctorId)).booking;
      final homeAddress = [
        booking?.patientAddress ?? _addressController.text.trim(),
        booking?.patientCity ?? _cityController.text.trim(),
        _stateController.text.trim(),
        booking?.patientPincode ?? _pincodeController.text.trim(),
      ].where((e) => e.isNotEmpty).join(', ');

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Request sent'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Your home visit request was sent to Dr. ${booking?.doctorName ?? doctor.fullName}.',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'The doctor will review your address and distance. '
                  'You will be notified when they approve — then you can pay to confirm.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
                if (booking?.distanceKm != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Approx. distance: ${booking!.distanceKm} km',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  'Time: ${booking?.label ?? ''}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryLight.withValues(alpha: 0.35),
                    borderRadius: AppDecorations.borderRadiusMd,
                    border: Border.all(
                      color: AppColors.secondary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.home_rounded,
                              size: 18, color: AppColors.secondary),
                          const SizedBox(width: 6),
                          Text(
                            'Visit address',
                            style: AppTextStyles.labelMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        homeAddress,
                        style: AppTextStyles.bodySmall.copyWith(
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Keep your phone reachable. The doctor may call before arriving. '
                  'Ensure someone is home at the scheduled time.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
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
      if (booking != null) {
        ref.invalidate(bookableSlotsProvider(_slotsQuery));
        ref
            .read(upcomingMeetingTimerProvider.notifier)
            .registerConsultationResult(booking);
      }
    } else {
      final err = ref.read(homeVisitBookingProvider(widget.doctorId)).error;
      SnackBarHelper.showError(context, err ?? 'Request failed');
    }
  }

  String _submitButtonLabel() {
    return 'Request home visit';
  }

  @override
  Widget build(BuildContext context) {
    final doctorAsync = ref.watch(doctorForBookingProvider(widget.doctorId));
    final slotsAsync = ref.watch(bookableSlotsProvider(_slotsQuery));
    final bookingState = ref.watch(homeVisitBookingProvider(widget.doctorId));

    ref.listen(bookableSlotsProvider(_slotsQuery), (previous, next) {
      final visitState = ref.read(homeVisitBookingProvider(widget.doctorId));
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
              .read(homeVisitBookingProvider(widget.doctorId).notifier)
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
      appBar: AppBar(
        title: const Text('Book home visit'),
      ),
      body: doctorAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(
          message: e.toString().replaceFirst('Exception: ', ''),
          onRetry: () => ref.invalidate(doctorForBookingProvider(widget.doctorId)),
        ),
        data: (doctor) => Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(bookableSlotsProvider(_slotsQuery));
                  await ref.read(bookableSlotsProvider(_slotsQuery).future);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _DoctorHomeVisitHeader(doctor: doctor),
                        const SizedBox(height: 12),
                        DoctorConsultationFeesBanner(
                          doctor: doctor,
                          highlightedType: ConsultationType.bookHome,
                        ),
                        const SizedBox(height: 12),
                        ConsultationBookingPriceSummary(
                          doctor: doctor,
                          consultationType: ConsultationType.bookHome,
                          slotsConsultationFee:
                              slotsAsync.valueOrNull?.consultationFee,
                        ),
                        const SizedBox(height: 12),
                        const PrescriptionIncludedBanner(compact: true),
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
                              bookableSlotsProvider(_slotsQuery),
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
                                      homeVisitBookingProvider(widget.doctorId)
                                          .notifier,
                                    )
                                    .selectSlot(null);
                              }
                            },
                            onSlotSelected: (slot) async {
                              await ref
                                  .read(
                                    homeVisitBookingProvider(widget.doctorId)
                                        .notifier,
                                  )
                                  .selectSlot(slot);
                              if (!mounted) return;
                              final err = ref
                                  .read(homeVisitBookingProvider(widget.doctorId))
                                  .error;
                              if (err != null && mounted) {
                                SnackBarHelper.showError(context, err);
                              }
                            },
                            emptyMessage:
                                'This doctor has not set home visit hours yet, '
                                'or all slots are booked. Try another doctor or time.',
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Your home address',
                          style: AppTextStyles.titleSmall.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'The doctor will visit you at this address',
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
                            _patientLatitude != null
                                ? 'Location captured'
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
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          validator: (v) =>
                              ValidationUtils.validatePhoneNumber(v ?? ''),
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          controller: _emailController,
                          label: 'Email',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Email is required';
                            }
                            return ValidationUtils.validateEmail(v);
                          },
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          controller: _addressController,
                          label: 'House / flat / street address',
                          prefixIcon: Icons.home_outlined,
                          maxLines: 2,
                          minLines: 2,
                          validator: (v) {
                            if (v == null || v.trim().length < 5) {
                              return 'Enter your complete home address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: CustomTextField(
                                controller: _cityController,
                                label: 'City',
                                prefixIcon: Icons.location_city_outlined,
                                validator: (v) {
                                  if (v == null || v.trim().length < 2) {
                                    return 'Required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CustomTextField(
                                controller: _pincodeController,
                                label: 'Pincode',
                                prefixIcon: Icons.pin_drop_outlined,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(6),
                                ],
                                validator: (v) {
                                  if (v == null || v.trim().length < 6) {
                                    return '6 digits';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          controller: _stateController,
                          label: 'State (optional)',
                          prefixIcon: Icons.map_outlined,
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          controller: _reasonController,
                          label: 'Reason for visit',
                          prefixIcon: Icons.medical_information_outlined,
                          maxLines: 3,
                          minLines: 2,
                          validator: (v) {
                            if (v == null || v.trim().length < 3) {
                              return 'Briefly describe why you need the visit';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        PreviousReportsPicker(
                          reports: bookingState.pendingReports,
                          enabled: !bookingState.isSubmitting,
                          onChanged: (reports) => ref
                              .read(
                                homeVisitBookingProvider(widget.doctorId)
                                    .notifier,
                              )
                              .setPendingReports(reports),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            BottomCtaBar(
              child: CustomButton(
                label: bookingState.selectedSlot != null
                    ? _submitButtonLabel()
                    : 'Select visit time',
                icon: Icons.send_rounded,
                isEnabled: bookingState.selectedSlot != null &&
                    !bookingState.isReservingSlot,
                isLoading:
                    bookingState.isSubmitting || bookingState.isReservingSlot,
                onPressed: () => _submit(doctor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoctorHomeVisitHeader extends StatelessWidget {
  const _DoctorHomeVisitHeader({required this.doctor});

  final DoctorModel doctor;

  @override
  Widget build(BuildContext context) {
    final imageUrl = MediaUrlUtils.resolve(doctor.profilePicture);
    final name = doctor.fullName.isNotEmpty
        ? (doctor.fullName.startsWith('Dr.')
            ? doctor.fullName
            : 'Dr. ${doctor.fullName}')
        : 'Doctor';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondary.withValues(alpha: 0.12),
            AppColors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppDecorations.borderRadiusLg,
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage:
                imageUrl.isNotEmpty ? CachedNetworkImageProvider(imageUrl) : null,
            child: imageUrl.isEmpty
                ? const Icon(Icons.person_rounded, color: AppColors.secondary)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (doctor.specializations?.isNotEmpty == true)
                  Text(
                    doctor.specializations!.first,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                if (doctor.yearsOfExperience != null)
                  Text(
                    '${doctor.yearsOfExperience}+ years experience',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.home_rounded, size: 16, color: AppColors.secondary),
                const SizedBox(width: 4),
                Text(
                  'Home visit',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
