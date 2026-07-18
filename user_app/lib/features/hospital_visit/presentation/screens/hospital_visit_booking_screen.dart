import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/doctor_location_utils.dart';
import '../../../../core/utils/media_url_utils.dart';
import '../../../../core/utils/user_auth_guard.dart';
import '../../../../core/utils/validation_utils.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/models/bookable_slot_model.dart';
import '../../../../data/models/consultation_type.dart';
import '../../../../data/models/doctor_model.dart';
import '../../../../shared/widgets/appointment_code_display.dart';
import '../../../../shared/widgets/bookable_slots_section.dart';
import '../../../../shared/widgets/consultation_booking_price_summary.dart';
import '../../../../shared/widgets/doctor_consultation_fees_banner.dart';
import '../../../../shared/widgets/doctor_hospital_map_card.dart';
import '../../../../shared/widgets/healthcare_ui.dart';
import '../../../online_consult/online_consult_navigation.dart';
import '../../../online_consult/provider/online_consult_provider.dart';
import '../../../upcoming_meeting/provider/upcoming_meeting_timer_provider.dart';
import '../../../user_auth/provider/patient_auth_provider.dart';
import '../../provider/hospital_visit_provider.dart';

class HospitalVisitBookingScreen extends ConsumerStatefulWidget {
  const HospitalVisitBookingScreen({super.key, required this.doctorId});

  final String doctorId;

  @override
  ConsumerState<HospitalVisitBookingScreen> createState() =>
      _HospitalVisitBookingScreenState();
}

class _HospitalVisitBookingScreenState
    extends ConsumerState<HospitalVisitBookingScreen> {
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

  static const _slotsQueryType = 'visit_site';

  BookableSlotsQuery get _slotsQuery => BookableSlotsQuery(
        doctorId: widget.doctorId,
        consultationType: _slotsQueryType,
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
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _submit(DoctorModel doctor) async {
    if (!await ensureUserLoggedIn(context)) return;
    if (!_formKey.currentState!.validate()) return;

    final ok = await ref
        .read(hospitalVisitBookingProvider(widget.doctorId).notifier)
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
          couponCode: _couponController.text.trim().isEmpty
              ? null
              : _couponController.text.trim(),
        );

    if (!mounted) return;
    if (ok) {
      final booking =
          ref.read(hospitalVisitBookingProvider(widget.doctorId)).booking;
      final hospital = booking?.clinicName ?? doctor.clinicName ?? 'the clinic';
      final address = booking?.clinicAddress ??
          [
            doctor.address,
            doctor.city,
            doctor.pincode,
          ].where((e) => e != null && e.trim().isNotEmpty).join(', ');

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Payment successful'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Your clinic visit with ${booking?.doctorName ?? doctor.fullName} is booked.',
                  style: AppTextStyles.bodyMedium,
                ),
                if (booking?.consultationFee != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Amount paid: ₹${booking!.consultationFee}',
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
                Text(
                  'Location: $hospital\n$address',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
                if (booking?.appointmentCode != null) ...[
                  const SizedBox(height: 16),
                  AppointmentCodeDisplay(code: booking!.appointmentCode!),
                ],
                const SizedBox(height: 12),
                Text(
                  'Arrive 10 minutes early with a valid ID. Share your appointment code when the doctor asks.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            if (doctorHasMapLocation(doctor))
              TextButton.icon(
                onPressed: () {
                  openDoctorDirectionsInGoogleMaps(context, doctor);
                },
                icon: const Icon(Icons.directions_rounded),
                label: const Text('Navigate'),
              ),
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
      final err =
          ref.read(hospitalVisitBookingProvider(widget.doctorId)).error;
      SnackBarHelper.showError(context, err ?? 'Booking failed');
    }
  }

  String _payButtonLabel(int? fee) {
    if (fee != null && fee > 0) {
      return 'Pay ₹$fee & book visit';
    }
    return 'Pay & book visit';
  }

  @override
  Widget build(BuildContext context) {
    final doctorAsync = ref.watch(doctorForBookingProvider(widget.doctorId));
    final slotsAsync = ref.watch(bookableSlotsProvider(_slotsQuery));
    final bookingState =
        ref.watch(hospitalVisitBookingProvider(widget.doctorId));

    ref.listen(bookableSlotsProvider(_slotsQuery), (previous, next) {
      final visitState =
          ref.read(hospitalVisitBookingProvider(widget.doctorId));
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
              .read(hospitalVisitBookingProvider(widget.doctorId).notifier)
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
        title: const Text('Book hospital visit'),
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
                      _DoctorClinicHeader(
                        doctor: doctor,
                        slotsData: slotsAsync.asData?.value,
                      ),
                      const SizedBox(height: 12),
                      DoctorConsultationFeesBanner(
                        doctor: doctor,
                        highlightedType: ConsultationType.visitSite,
                        onTypeSelected: (type) {
                          if (type == ConsultationType.onlineConsult) {
                            openOnlineConsultBooking(context, doctor);
                          } else if (type == ConsultationType.bookHome) {
                            openHomeVisitBooking(context, doctor);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      ConsultationBookingPriceSummary(
                        doctor: doctor,
                        consultationType: ConsultationType.visitSite,
                        slotsConsultationFee:
                            slotsAsync.valueOrNull?.consultationFee,
                      ),
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
                            if (bookingState.selectedSlot?.dateKey != dateKey) {
                              ref
                                  .read(
                                    hospitalVisitBookingProvider(
                                      widget.doctorId,
                                    ).notifier,
                                  )
                                  .selectSlot(null);
                            }
                          },
                          onSlotSelected: (slot) async {
                            await ref
                                .read(
                                  hospitalVisitBookingProvider(widget.doctorId)
                                      .notifier,
                                )
                                .selectSlot(slot);
                            if (!mounted) return;
                            final err = ref
                                .read(hospitalVisitBookingProvider(widget.doctorId))
                                .error;
                            if (err != null && mounted) {
                              SnackBarHelper.showError(context, err);
                            }
                          },
                          emptyMessage:
                              'This doctor has not set clinic visit hours yet, '
                              'or all slots are booked. Try online consult or another doctor.',
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Your details',
                        style: AppTextStyles.titleSmall.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'We need your contact and address for the visit record',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
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
                        label: 'Your address (street / area)',
                        prefixIcon: Icons.home_outlined,
                        maxLines: 2,
                        minLines: 2,
                        validator: (v) {
                          if (v == null || v.trim().length < 5) {
                            return 'Enter your full address';
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
                              validator: ValidationUtils.validatePincode,
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
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: _couponController,
                        label: 'Coupon code (optional)',
                        prefixIcon: Icons.local_offer_outlined,
                        hint: 'Try CARE10 or FIRST100',
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
                    ? _payButtonLabel(
                        resolvePayableConsultationFee(
                          doctor: doctor,
                          type: ConsultationType.visitSite,
                          slotsConsultationFee:
                              slotsAsync.valueOrNull?.consultationFee,
                        ),
                      )
                    : 'Select appointment time',
                icon: Icons.payments_rounded,
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

class _DoctorClinicHeader extends StatelessWidget {
  const _DoctorClinicHeader({
    required this.doctor,
    this.slotsData,
  });

  final DoctorModel doctor;
  final BookableSlotsResponse? slotsData;

  @override
  Widget build(BuildContext context) {
    final imageUrl = MediaUrlUtils.resolve(doctor.profilePicture);
    final name = doctor.fullName.isNotEmpty
        ? (doctor.fullName.startsWith('Dr.')
            ? doctor.fullName
            : 'Dr. ${doctor.fullName}')
        : 'Doctor';
    final clinicName =
        slotsData?.clinicName ?? doctor.clinicName ?? 'Clinic / Hospital';
    final clinicAddress = slotsData?.clinicAddress ??
        [
          doctor.address,
          doctor.city,
          doctor.state,
          doctor.pincode,
        ].where((e) => e != null && e.toString().trim().isNotEmpty).join(', ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppDecorations.borderRadiusLg,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: imageUrl.isNotEmpty
                    ? CachedNetworkImageProvider(imageUrl)
                    : null,
                child: imageUrl.isEmpty
                    ? const Icon(Icons.person_rounded, color: AppColors.primary)
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
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_hospital_rounded,
                        size: 16, color: AppColors.accent),
                    const SizedBox(width: 4),
                    Text(
                      'Visit',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: AppDecorations.borderRadiusMd,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_hospital_outlined,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        clinicName,
                        style: AppTextStyles.labelLarge.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                if (clinicAddress.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.place_outlined,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          clinicAddress,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          DoctorHospitalMapCard(
            doctor: doctor,
            clinicName: clinicName,
            clinicAddress: clinicAddress,
          ),
        ],
      ),
    );
  }
}
