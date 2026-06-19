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
import '../../../../data/models/bookable_slot_model.dart';
import '../../../../data/models/consultation_type.dart';
import '../../../../data/models/doctor_model.dart';
import '../../../../shared/widgets/bookable_slots_section.dart';
import '../../../../shared/widgets/healthcare_ui.dart';
import '../../../../shared/widgets/previous_reports_picker.dart';
import '../../../user_auth/provider/patient_auth_provider.dart';
import '../../../../core/utils/user_auth_guard.dart';
import '../../provider/online_consult_provider.dart';
import '../../../upcoming_meeting/provider/upcoming_meeting_timer_provider.dart';

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
  final _formKey = GlobalKey<FormState>();
  String? _selectedDateKey;

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
    super.dispose();
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
    final slotsAsync = ref.watch(bookableSlotsProvider(widget.doctorId));
    final bookingState =
        ref.watch(onlineConsultBookingProvider(widget.doctorId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Book online consult'),
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
                  ref.invalidate(bookableSlotsProvider(widget.doctorId));
                  await ref.read(bookableSlotsProvider(widget.doctorId).future);
                },
                child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _DoctorHeader(doctor: doctor),
                    const SizedBox(height: 20),
                    Text(
                      'Choose a time slot',
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Based on the doctor\'s weekly availability (Sun–Sat, 8 AM–6 PM)',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    slotsAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, _) => AppErrorWidget(
                        message: e.toString().replaceFirst('Exception: ', ''),
                        onRetry: () => ref.invalidate(
                          bookableSlotsProvider(widget.doctorId),
                        ),
                      ),
                      data: (slotsData) => BookableSlotsSection(
                        slotsData: slotsData,
                        selectedSlot: bookingState.selectedSlot,
                        selectedDateKey: _selectedDateKey,
                        onDateSelected: (dateKey) {
                          setState(() => _selectedDateKey = dateKey);
                          if (bookingState.selectedSlot?.dateKey != dateKey) {
                            ref
                                .read(
                                  onlineConsultBookingProvider(widget.doctorId)
                                      .notifier,
                                )
                                .selectSlot(null);
                          }
                        },
                        onSlotSelected: (slot) => ref
                            .read(
                              onlineConsultBookingProvider(widget.doctorId)
                                  .notifier,
                            )
                            .selectSlot(slot),
                        emptyMessage:
                            'This doctor has no online consult slots open right now. '
                            'Try another time or doctor.',
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Your details',
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
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
                            label: 'Email (optional)',
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),
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
                            reports: bookingState.pendingReports,
                            enabled: !bookingState.isSubmitting,
                            onChanged: (reports) => ref
                                .read(
                                  onlineConsultBookingProvider(widget.doctorId)
                                      .notifier,
                                )
                                .setPendingReports(reports),
                          ),
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
                label: bookingState.selectedSlot != null
                    ? _payButtonLabel(
                        bookingState.selectedSlot,
                        slotsAsync.valueOrNull?.consultationFee ??
                            doctor.feeForConsultationType(
                              ConsultationType.onlineConsult,
                            ),
                      )
                    : 'Select a time slot',
                icon: Icons.payments_rounded,
                isEnabled: bookingState.selectedSlot != null,
                isLoading: bookingState.isSubmitting,
                onPressed: () => _submit(doctor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoctorHeader extends StatelessWidget {
  const _DoctorHeader({required this.doctor});

  final DoctorModel doctor;

  @override
  Widget build(BuildContext context) {
    final imageUrl = MediaUrlUtils.resolve(doctor.profilePicture);
    final name = doctor.fullName.isNotEmpty
        ? (doctor.fullName.startsWith('Dr.')
            ? doctor.fullName
            : 'Dr. ${doctor.fullName}')
        : 'Doctor';
    final fee = doctor.feeForConsultationType(ConsultationType.onlineConsult) !=
            null
        ? '₹${doctor.feeForConsultationType(ConsultationType.onlineConsult)} consult fee'
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppDecorations.borderRadiusLg,
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
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
                if (fee != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    fee,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.videocam_rounded,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  'Online',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.primary,
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
