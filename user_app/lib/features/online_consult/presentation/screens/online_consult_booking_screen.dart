import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_text_styles.dart';
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
import '../../../../shared/widgets/prescription_included_banner.dart';
import '../../../../shared/widgets/previous_reports_picker.dart';
import '../../../hospital_visit/provider/hospital_visit_provider.dart';
import '../../../upcoming_meeting/provider/upcoming_meeting_timer_provider.dart';
import '../../../user_auth/provider/patient_auth_provider.dart';
import '../../online_consult_navigation.dart';
import '../../provider/online_consult_provider.dart';

class OnlineConsultBookingScreen extends ConsumerStatefulWidget {
  const OnlineConsultBookingScreen({super.key, required this.doctorId});

  final String doctorId;

  @override
  ConsumerState<OnlineConsultBookingScreen> createState() =>
      _OnlineConsultBookingScreenState();
}

class _OnlineConsultBookingScreenState
    extends ConsumerState<OnlineConsultBookingScreen> {
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _notesController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  ConsultationType _selectedType = ConsultationType.onlineConsult;
  String? _selectedDateKey;

  bool get _isHospitalVisit => _selectedType == ConsultationType.visitSite;

  BookableSlotsQuery get _slotsQuery => BookableSlotsQuery(
        doctorId: widget.doctorId,
        consultationType: _selectedType.apiValue,
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
    _notesController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _onConsultationTypeSelected(ConsultationType type, DoctorModel doctor) {
    if (type == ConsultationType.bookHome) {
      openHomeVisitBooking(context, doctor);
      return;
    }
    if (!_isHospitalVisit && type == ConsultationType.visitSite && !doctor.offersVisitSite) {
      return;
    }
    if (_isHospitalVisit && type == ConsultationType.onlineConsult && !doctor.offersOnlineConsult) {
      return;
    }
    if (type == _selectedType) return;

    ref.read(onlineConsultBookingProvider(widget.doctorId).notifier).selectSlot(null);
    ref.read(hospitalVisitBookingProvider(widget.doctorId).notifier).selectSlot(null);
    setState(() {
      _selectedType = type;
      _selectedDateKey = null;
    });
    ref.invalidate(bookableSlotsProvider(_slotsQuery));
  }

  Future<void> _submitHospitalVisit(DoctorModel doctor) async {
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
      final err =
          ref.read(hospitalVisitBookingProvider(widget.doctorId)).error;
      SnackBarHelper.showError(context, err ?? 'Booking failed');
    }
  }

  Future<void> _submit(DoctorModel doctor) async {
    if (!await ensureUserLoggedIn(context)) return;
    if (!_formKey.currentState!.validate()) return;

    final ok = await ref
        .read(onlineConsultBookingProvider(widget.doctorId).notifier)
        .submit(
          doctorId: widget.doctorId,
          patientName: _nameController.text.trim(),
          patientMobile: _mobileController.text.trim(),
          patientEmail: _emailController.text.trim(),
          patientNotes: _notesController.text.trim(),
        );

    if (!mounted) return;
    if (ok) {
      final booking =
          ref.read(onlineConsultBookingProvider(widget.doctorId)).booking;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Payment successful'),
          content: Text(
            booking != null
                ? 'Your online consult with ${booking.doctorName ?? doctor.fullName} is confirmed for:\n\n${booking.label}\n\nAmount paid: ₹${booking.consultationFee ?? 0}'
                : 'Your appointment is confirmed.',
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
      final err =
          ref.read(onlineConsultBookingProvider(widget.doctorId)).error;
      SnackBarHelper.showError(context, err ?? 'Booking failed');
    }
  }

  String _payButtonLabel(BookableSlot? slot, int? fee) {
    if (fee != null && fee > 0) {
      return 'Pay ₹$fee & book';
    }
    return 'Pay & book';
  }

  @override
  Widget build(BuildContext context) {
    final doctorAsync = ref.watch(doctorForBookingProvider(widget.doctorId));
    final slotsAsync = ref.watch(bookableSlotsProvider(_slotsQuery));
    final onlineBookingState =
        ref.watch(onlineConsultBookingProvider(widget.doctorId));
    final hospitalBookingState =
        ref.watch(hospitalVisitBookingProvider(widget.doctorId));
    final selectedSlot = _isHospitalVisit
        ? hospitalBookingState.selectedSlot
        : onlineBookingState.selectedSlot;
    final isReservingSlot = _isHospitalVisit
        ? hospitalBookingState.isReservingSlot
        : onlineBookingState.isReservingSlot;
    final isSubmitting = _isHospitalVisit
        ? hospitalBookingState.isSubmitting
        : onlineBookingState.isSubmitting;

    ref.listen(bookableSlotsProvider(_slotsQuery), (previous, next) {
      final selected = _isHospitalVisit
          ? ref.read(hospitalVisitBookingProvider(widget.doctorId)).selectedSlot
          : ref.read(onlineConsultBookingProvider(widget.doctorId)).selectedSlot;
      if (selected == null) return;
      final holdId = _isHospitalVisit
          ? ref.read(hospitalVisitBookingProvider(widget.doctorId)).slotHoldId
          : ref.read(onlineConsultBookingProvider(widget.doctorId)).slotHoldId;
      if (holdId != null && holdId.isNotEmpty) return;
      next.whenData((slotsData) {
        final stillAvailable = slotsData.slots.any(
          (slot) => slot.slotKey == selected.slotKey,
        );
        if (!stillAvailable && mounted) {
          if (_isHospitalVisit) {
            ref
                .read(hospitalVisitBookingProvider(widget.doctorId).notifier)
                .selectSlot(null);
          } else {
            ref
                .read(onlineConsultBookingProvider(widget.doctorId).notifier)
                .selectSlot(null);
          }
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
        title: Text(
          _isHospitalVisit ? 'Book hospital visit' : 'Book online consult',
        ),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _DoctorHeader(
                      doctor: doctor,
                      consultationType: _selectedType,
                      slotsData: slotsAsync.asData?.value,
                    ),
                    const SizedBox(height: 12),
                    DoctorConsultationFeesBanner(
                      doctor: doctor,
                      highlightedType: _selectedType,
                      onTypeSelected: (type) =>
                          _onConsultationTypeSelected(type, doctor),
                    ),
                    const SizedBox(height: 12),
                    ConsultationBookingPriceSummary(
                      doctor: doctor,
                      consultationType: _selectedType,
                      slotsConsultationFee:
                          slotsAsync.valueOrNull?.consultationFee,
                    ),
                    if (!_isHospitalVisit) ...[
                      const SizedBox(height: 12),
                      const PrescriptionIncludedBanner(compact: true),
                    ],
                    const SizedBox(height: 20),
                    slotsAsync.when(
                      skipLoadingOnReload: true,
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, _) => AppErrorWidget(
                        message: e.toString().replaceFirst('Exception: ', ''),
                        onRetry: () => ref.invalidate(
                          bookableSlotsProvider(_slotsQuery),
                        ),
                      ),
                      data: (slotsData) => BookableSlotsSection(
                        slotsData: slotsData,
                        selectedSlot: selectedSlot,
                        selectedDateKey: _selectedDateKey,
                        isSlotSelectionBusy: isReservingSlot,
                        onDateSelected: (dateKey) {
                          setState(() => _selectedDateKey = dateKey);
                          if (selectedSlot?.dateKey != dateKey) {
                            if (_isHospitalVisit) {
                              ref
                                  .read(
                                    hospitalVisitBookingProvider(widget.doctorId)
                                        .notifier,
                                  )
                                  .selectSlot(null);
                            } else {
                              ref
                                  .read(
                                    onlineConsultBookingProvider(widget.doctorId)
                                        .notifier,
                                  )
                                  .selectSlot(null);
                            }
                          }
                        },
                        onSlotSelected: (slot) async {
                          if (_isHospitalVisit) {
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
                          } else {
                            await ref
                                .read(
                                  onlineConsultBookingProvider(widget.doctorId)
                                      .notifier,
                                )
                                .selectSlot(slot);
                            if (!mounted) return;
                            final err = ref
                                .read(onlineConsultBookingProvider(widget.doctorId))
                                .error;
                            if (err != null && mounted) {
                              SnackBarHelper.showError(context, err);
                            }
                          }
                        },
                        emptyMessage: _isHospitalVisit
                            ? 'This doctor has not set clinic visit hours yet, '
                                'or all slots are booked. Try online consult or another doctor.'
                            : 'This doctor has no online consult slots open right now. '
                                'Try hospital visit or another doctor.',
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Your details',
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (_isHospitalVisit) ...[
                      const SizedBox(height: 4),
                      Text(
                        'We need your contact and address for the visit record',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          CustomTextField(
                            controller: _nameController,
                            label: 'Full name',
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
                            label: _isHospitalVisit ? 'Email' : 'Email (optional)',
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: _isHospitalVisit
                                ? (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Email is required';
                                    }
                                    return ValidationUtils.validateEmail(v);
                                  }
                                : null,
                          ),
                          if (_isHospitalVisit) ...[
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
                          ] else ...[
                            const SizedBox(height: 12),
                            CustomTextField(
                              controller: _notesController,
                              label: 'Symptoms / notes (optional)',
                              prefixIcon: Icons.notes_rounded,
                              maxLines: 3,
                              minLines: 2,
                            ),
                            const SizedBox(height: 20),
                            PreviousReportsPicker(
                              reports: onlineBookingState.pendingReports,
                              enabled: !onlineBookingState.isSubmitting,
                              onChanged: (reports) => ref
                                  .read(
                                    onlineConsultBookingProvider(widget.doctorId)
                                        .notifier,
                                  )
                                  .setPendingReports(reports),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              ),
            ),
            BottomCtaBar(
              child: CustomButton(
                label: selectedSlot != null
                    ? (_isHospitalVisit
                        ? (() {
                            final fee = resolvePayableConsultationFee(
                              doctor: doctor,
                              type: ConsultationType.visitSite,
                              slotsConsultationFee:
                                  slotsAsync.valueOrNull?.consultationFee,
                            );
                            return fee != null && fee > 0
                                ? 'Pay ₹$fee & book visit'
                                : 'Pay & book visit';
                          })()
                        : _payButtonLabel(
                            selectedSlot,
                            resolvePayableConsultationFee(
                              doctor: doctor,
                              type: ConsultationType.onlineConsult,
                              slotsConsultationFee:
                                  slotsAsync.valueOrNull?.consultationFee,
                            ),
                          ))
                    : (_isHospitalVisit
                        ? 'Select appointment time'
                        : 'Select a time slot'),
                icon: Icons.payments_rounded,
                isEnabled: selectedSlot != null && !isReservingSlot,
                isLoading: isSubmitting || isReservingSlot,
                onPressed: () => _isHospitalVisit
                    ? _submitHospitalVisit(doctor)
                    : _submit(doctor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoctorHeader extends StatelessWidget {
  const _DoctorHeader({
    required this.doctor,
    required this.consultationType,
    this.slotsData,
  });

  final DoctorModel doctor;
  final ConsultationType consultationType;
  final BookableSlotsResponse? slotsData;

  @override
  Widget build(BuildContext context) {
    final imageUrl = MediaUrlUtils.resolve(doctor.profilePicture);
    final name = doctor.fullName.isNotEmpty
        ? (doctor.fullName.startsWith('Dr.')
            ? doctor.fullName
            : 'Dr. ${doctor.fullName}')
        : 'Doctor';
    final isHospital = consultationType == ConsultationType.visitSite;
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
                radius: 32,
                backgroundImage:
                    imageUrl.isNotEmpty ? CachedNetworkImageProvider(imageUrl) : null,
                child: imageUrl.isEmpty
                    ? const Icon(Icons.person_rounded, color: AppColors.primary)
                    : null,
              ),
              const SizedBox(width: 14),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isHospital ? AppColors.accentLight : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isHospital
                          ? Icons.local_hospital_rounded
                          : Icons.videocam_rounded,
                      size: 16,
                      color: isHospital ? AppColors.accent : AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isHospital ? 'Visit' : 'Online',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isHospital ? AppColors.accent : AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isHospital) ...[
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
        ],
      ),
    );
  }
}
