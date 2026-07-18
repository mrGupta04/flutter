import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/doctor_availability_constants.dart';
import '../../../../core/services/doctor_presence_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validation_utils.dart';
import '../../../../core/widgets/custom_widgets.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/utils/media_url_utils.dart';
import '../../../../data/models/consultation_type.dart';
import '../../../../data/models/doctor_booking_model.dart';
import '../../../../data/models/previous_report_model.dart';
import '../../../../data/models/doctor_document_model.dart';
import '../../../../data/models/doctor_model.dart';
import '../../../../data/services/dio_service.dart';
import '../../../../features/doctor_registration/provider/registration_provider.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../../../shared/widgets/healthcare_ui.dart';
import '../../../../shared/widgets/provider_document_status_section.dart';
import '../../../../shared/widgets/patient_location_map_card.dart';
import '../../../../shared/widgets/shimmer_widgets.dart';
import '../../../doctor_registration/presentation/widgets/weekly_availability_picker.dart';
import '../../../video_consult/presentation/widgets/join_video_consult_button.dart';
import '../../../video_consult/presentation/widgets/prescription_sheet.dart';
import '../../provider/dashboard_provider.dart';

class DoctorDashboardScreen extends ConsumerStatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  ConsumerState<DoctorDashboardScreen> createState() =>
      _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends ConsumerState<DoctorDashboardScreen> {
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(doctorDashboardProvider.notifier).loadProfile();
      DoctorPresenceService.instance.goOnline();
      _loadUnreadNotifications();
    });
  }

  Future<void> _loadUnreadNotifications() async {
    try {
      final response =
          await DioService().get(AppConstants.endpointDoctorNotifications);
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      if (!mounted) return;
      setState(() {
        _unreadNotifications = (data['unreadCount'] as num?)?.toInt() ?? 0;
      });
    } catch (_) {}
  }

  Future<void> _openNotifications() async {
    await context.push('${AppConstants.routeProviderNotifications}?role=doctor');
    if (mounted) _loadUnreadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = ref.watch(doctorDashboardProvider);
    final completion = ref.watch(profileCompletionProvider);
    final registered = ref.watch(doctorRegistrationProvider).doctor;
    final doctor = dashboard.doctor ??
        (dashboard.isLoading ? registered : null) ??
        registered;
    final isVerified =
        doctor?.verificationStatus == VerificationStatus.verified;
    final showPendingBanner =
        doctor != null && !isVerified && !dashboard.isLoading;
    final hasRejectedDocuments = ref.watch(doctorDocumentsProvider).maybeWhen(
          data: (docs) =>
              docs.any((d) => d.status == DocumentStatus.rejected),
          orElse: () => false,
        );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My practice'),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: _unreadNotifications > 0,
              label: Text('$_unreadNotifications'),
              child: const Icon(Icons.notifications_outlined),
            ),
            tooltip: 'Notifications',
            onPressed: _openNotifications,
          ),
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            tooltip: 'Earnings',
            onPressed: () => context.push(
              '${AppConstants.routeProviderEarnings}?role=doctor',
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh updates',
            onPressed: dashboard.isLoading
                ? null
                : () => ref.read(doctorDashboardProvider.notifier).refreshAll(),
          ),
        ],
      ),
      body: dashboard.isLoading && dashboard.doctor == null
          ? const SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  ShimmerProfileHeader(),
                  SizedBox(height: 24),
                  ShimmerStatCard(),
                ],
              ),
            )
          : dashboard.error != null && dashboard.doctor == null
              ? AppErrorWidget(
                  message: dashboard.error!,
                  onRetry: () =>
                      ref.read(doctorDashboardProvider.notifier).loadProfile(),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showPendingBanner)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Material(
                          color: AppColors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: () => context.push(
                              AppConstants.routeApplicationSubmitted,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.hourglass_top_rounded,
                                    color: AppColors.warning,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Verification pending — you can still update your profile and availability. Tap for status.',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textPrimary,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: AppColors.textSecondary,
                                    size: 22,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => ref
                            .read(doctorDashboardProvider.notifier)
                            .refreshAll(),
                        child: _DashboardContent(
                          doctor: doctor,
                          completion: completion,
                          isUpdating: dashboard.isUpdating,
                          needsAvailabilityUpdate:
                              dashboard.needsAvailabilityUpdate,
                          availabilityMessage:
                              dashboard.availabilityReminder?.message ??
                                  dashboard.availability?.reminderMessage,
                          onlineSlotCount:
                              dashboard.availability?.selectedSlotKeys.length ??
                                  0,
                          clinicSlotCount: dashboard.clinicAvailability
                                  ?.selectedSlotKeys.length ??
                              0,
                          offersOnlineConsult:
                              doctor?.offersOnlineConsult ?? false,
                          offersVisitSite: doctor?.offersVisitSite ?? false,
                          bookingStats: dashboard.bookingStats,
                          bookings: dashboard.bookings,
                          upcomingOnlineBookings:
                              dashboard.upcomingOnlineBookings,
                          upcomingClinicBookings:
                              dashboard.upcomingClinicBookings,
                          upcomingHomeBookings: dashboard.upcomingHomeBookings,
                          pendingHomeVisitRequests:
                              dashboard.pendingHomeVisitRequests,
                          pastBookings: dashboard.pastBookings,
                          isLoadingBookings: dashboard.isLoadingBookings,
                          bookingsError: dashboard.bookingsError,
                          onRetryBookings: () => ref
                              .read(doctorDashboardProvider.notifier)
                              .loadBookings(),
                          onRefreshBookings: () => ref
                              .read(doctorDashboardProvider.notifier)
                              .loadBookings(),
                          onVerifyClinicVisit: _showVerifyAppointmentDialog,
                          onApproveHomeVisit: _approveHomeVisit,
                          onRejectHomeVisit: _rejectHomeVisit,
                          onUpload: _uploadDocument,
                          onReuploadDocuments: _showRejectedDocumentsSheet,
                          hasRejectedDocuments: hasRejectedDocuments,
                          onEditProfile: () =>
                              _showEditProfileSheet(doctor),
                          onUpdateAvailability: () =>
                              _showAvailabilitySheet(dashboard),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Future<void> _approveHomeVisit(String bookingId) async {
    final ok = await ref
        .read(doctorDashboardProvider.notifier)
        .approveHomeVisitRequest(bookingId);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Home visit approved. Patient will be asked to pay to confirm.',
          ),
        ),
      );
    } else {
      final err = ref.read(doctorDashboardProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err ?? 'Could not approve request')),
      );
    }
  }

  Future<void> _rejectHomeVisit(String bookingId) async {
    final ok = await ref
        .read(doctorDashboardProvider.notifier)
        .rejectHomeVisitRequest(bookingId);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Home visit request declined.')),
      );
    } else {
      final err = ref.read(doctorDashboardProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err ?? 'Could not decline request')),
      );
    }
  }

  Future<void> _showVerifyAppointmentDialog() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final verified = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verify clinic visit'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Ask the patient for their 4-digit appointment code and enter it below.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 8,
                ),
                decoration: const InputDecoration(
                  labelText: 'Appointment code',
                  hintText: '0000',
                  counterText: '',
                ),
                validator: (value) {
                  final code = value?.trim() ?? '';
                  if (!RegExp(r'^\d{4}$').hasMatch(code)) {
                    return 'Enter a 4-digit code';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() != true) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );

    if (verified != true || !mounted) return;

    final ok = await ref
        .read(doctorDashboardProvider.notifier)
        .verifyClinicAppointment(controller.text.trim());
    controller.dispose();

    if (!mounted) return;
    SnackBarHelper.showSuccess(
      context,
      ok
          ? 'Appointment verified successfully'
          : ref.read(doctorDashboardProvider).error ?? 'Verification failed',
    );
  }

  Future<void> _uploadDocument(DocumentType type) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: AppConstants.allowedDocumentFormats,
    );
    if (result == null || result.files.single.path == null) return;

    final success = await ref.read(doctorDashboardProvider.notifier).uploadDocument(
          filePath: result.files.single.path!,
          documentType: type,
        );

    if (!mounted) return;

    if (success) {
      ref.invalidate(doctorDocumentsProvider);
      SnackBarHelper.showSuccess(context, AppConstants.successDocumentUploaded);
    } else {
      final error = ref.read(doctorDashboardProvider).error ?? 'Upload failed';
      SnackBarHelper.showError(context, error);
    }
  }

  Future<void> _showRejectedDocumentsSheet() async {
    final docs = await ref.read(doctorDocumentsProvider.future);
    final rejected = docs
        .where(
          (d) =>
              d.status == DocumentStatus.rejected && d.documentType != null,
        )
        .toList();

    if (!mounted) return;

    if (rejected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No rejected documents right now')),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Re-upload documents',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose a rejected document to upload a corrected file.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              ...rejected.map(
                (doc) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.divider),
                    ),
                    leading: const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                    ),
                    title: Text(doc.documentTypeDisplay),
                    subtitle: doc.rejectionReason?.trim().isNotEmpty == true
                        ? Text(
                            doc.rejectionReason!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          )
                        : null,
                    trailing: const Icon(Icons.upload_file_rounded),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await _uploadDocument(doc.documentType!);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAvailabilitySheet(DoctorDashboardState dashboard) {
    final doctor = dashboard.doctor;
    final showOnline = doctor?.offersOnlineConsult ?? true;
    final showClinic = doctor?.offersVisitSite ?? false;
    final showHome = doctor?.offersBookHome ?? false;
    final onlineSelected = Set<String>.from(
      dashboard.availability?.selectedSlotKeys ?? const {},
    );
    final clinicSelected = Set<String>.from(
      dashboard.clinicAvailability?.selectedSlotKeys ?? const {},
    );
    final homeSelected = Set<String>.from(
      dashboard.homeAvailability?.selectedSlotKeys ?? const {},
    );
    var activeType = showOnline
        ? 'online_consult'
        : (showClinic ? 'visit_site' : 'book_home');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          Set<String> activeSelected() {
            switch (activeType) {
              case 'visit_site':
                return clinicSelected;
              case 'book_home':
                return homeSelected;
              case 'online_consult':
              default:
                return onlineSelected;
            }
          }

          Set<String> blockedForActive() {
            return {
              ...onlineSelected,
              ...clinicSelected,
              ...homeSelected,
            }..removeAll(activeSelected());
          }

          Color activeColor() {
            switch (activeType) {
              case 'visit_site':
                return AppColors.accent;
              case 'book_home':
                return AppColors.secondary;
              case 'online_consult':
              default:
                return AppColors.primary;
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Update weekly availability',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Set separate schedules for online, clinic, and home visits.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if ([showOnline, showClinic, showHome].where((v) => v).length >
                      1) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (showOnline)
                          ChoiceChip(
                            label: const Text('Online'),
                            selected: activeType == 'online_consult',
                            onSelected: (_) => setModalState(
                              () => activeType = 'online_consult',
                            ),
                          ),
                        if (showClinic)
                          ChoiceChip(
                            label: const Text('Clinic'),
                            selected: activeType == 'visit_site',
                            onSelected: (_) => setModalState(
                              () => activeType = 'visit_site',
                            ),
                          ),
                        if (showHome)
                          ChoiceChip(
                            label: const Text('Home'),
                            selected: activeType == 'book_home',
                            onSelected: (_) => setModalState(
                              () => activeType = 'book_home',
                            ),
                          ),
                      ],
                    ),
                  ],
                  if (dashboard.availabilityReminder?.suggestedWeekStart !=
                          null ||
                      dashboard.availability?.weekStartDate != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _availabilityWeekLabel(dashboard),
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  WeeklyAvailabilityPicker(
                    selectedSlots: activeSelected(),
                    blockedSlots: blockedForActive(),
                    selectedColor: activeColor(),
                    onToggle: (day, hour, isSelected) {
                      setModalState(() {
                        final key =
                            DoctorAvailabilityConstants.slotKey(day, hour);
                        if (isSelected) {
                          onlineSelected.remove(key);
                          clinicSelected.remove(key);
                          homeSelected.remove(key);
                          switch (activeType) {
                            case 'visit_site':
                              clinicSelected.add(key);
                            case 'book_home':
                              homeSelected.add(key);
                            case 'online_consult':
                            default:
                              onlineSelected.add(key);
                          }
                        } else {
                          switch (activeType) {
                            case 'visit_site':
                              clinicSelected.remove(key);
                            case 'book_home':
                              homeSelected.remove(key);
                            case 'online_consult':
                            default:
                              onlineSelected.remove(key);
                          }
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    label: switch (activeType) {
                      'visit_site' => 'Save clinic visit slots',
                      'book_home' => 'Save home visit slots',
                      _ => 'Save online consult slots',
                    },
                    isLoading:
                        ref.read(doctorDashboardProvider).isSavingAvailability,
                    isEnabled: activeSelected().isNotEmpty,
                    onPressed: () async {
                      final ok = await ref
                          .read(doctorDashboardProvider.notifier)
                          .saveAvailability(
                            activeSelected(),
                            consultationType: activeType,
                          );
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        SnackBarHelper.showSuccess(
                          context,
                          ok
                              ? 'Availability saved — patients can book these slots now'
                              : ref.read(doctorDashboardProvider).error ??
                                  'Failed to save availability',
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showEditProfileSheet(DoctorModel? doctor) {
    if (doctor == null) return;
    final parentContext = context;

    final onlineFeeController = TextEditingController(
      text: doctor.onlineConsultFee?.toString() ??
          (doctor.offersOnlineConsult
              ? doctor.consultationFee?.toString() ?? ''
              : ''),
    );
    final visitFeeController = TextEditingController(
      text: doctor.visitSiteFee?.toString() ??
          (doctor.offersVisitSite
              ? doctor.consultationFee?.toString() ?? ''
              : ''),
    );
    final homeFeeController = TextEditingController(
      text: doctor.homeVisitFee?.toString() ??
          (doctor.offersBookHome
              ? doctor.consultationFee?.toString() ?? ''
              : ''),
    );
    final bioController = TextEditingController(text: doctor.bio ?? '');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 8,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit profile',
                style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Update fees for each consultation type you offer.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (doctor.offersOnlineConsult) ...[
                const SizedBox(height: 20),
                CustomTextField(
                  controller: onlineFeeController,
                  label: 'Online consult fee (₹)',
                  prefixIcon: Icons.videocam_outlined,
                  keyboardType: TextInputType.number,
                ),
              ],
              if (doctor.offersVisitSite) ...[
                const SizedBox(height: 16),
                CustomTextField(
                  controller: visitFeeController,
                  label: 'Hospital visit fee (₹)',
                  prefixIcon: Icons.local_hospital_outlined,
                  keyboardType: TextInputType.number,
                ),
              ],
              if (doctor.offersBookHome) ...[
                const SizedBox(height: 16),
                CustomTextField(
                  controller: homeFeeController,
                  label: 'Home visit fee (₹)',
                  prefixIcon: Icons.home_outlined,
                  keyboardType: TextInputType.number,
                ),
              ],
              if (!doctor.hasAnyConsultationOption) ...[
                const SizedBox(height: 20),
                CustomTextField(
                  controller: onlineFeeController,
                  label: 'Consultation fee (₹)',
                  prefixIcon: Icons.currency_rupee_rounded,
                  keyboardType: TextInputType.number,
                ),
              ],
              const SizedBox(height: 16),
              CustomTextField(
                controller: bioController,
                label: 'About you',
                maxLines: 4,
                minLines: 3,
              ),
              const SizedBox(height: 24),
              CustomButton(
                label: 'Save',
                isLoading: ref.read(doctorDashboardProvider).isUpdating,
                onPressed: () async {
                  final onlineFee = int.tryParse(onlineFeeController.text.trim());
                  final visitFee = int.tryParse(visitFeeController.text.trim());
                  final homeFee = int.tryParse(homeFeeController.text.trim());
                  final fees = <int>[
                    if (doctor.offersOnlineConsult && onlineFee != null)
                      onlineFee,
                    if (doctor.offersVisitSite && visitFee != null) visitFee,
                    if (doctor.offersBookHome && homeFee != null) homeFee,
                  ];
                  final updated = doctor.copyWith(
                    onlineConsultFee:
                        doctor.offersOnlineConsult ? onlineFee : doctor.onlineConsultFee,
                    visitSiteFee:
                        doctor.offersVisitSite ? visitFee : doctor.visitSiteFee,
                    homeVisitFee:
                        doctor.offersBookHome ? homeFee : doctor.homeVisitFee,
                    consultationFee: fees.isNotEmpty
                        ? fees.reduce((a, b) => a < b ? a : b)
                        : onlineFee ?? doctor.consultationFee,
                    bio: bioController.text,
                  );
                  final success = await ref
                      .read(doctorDashboardProvider.notifier)
                      .updateProfile(updated);
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  if (!parentContext.mounted) return;
                  if (success) {
                    SnackBarHelper.showSuccess(
                      parentContext,
                      'Profile updated',
                    );
                  } else {
                    SnackBarHelper.showError(
                      parentContext,
                      ref.read(doctorDashboardProvider).error ??
                          'Could not update profile',
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

bool _doctorHasServiceFees(DoctorModel doctor) {
  if (doctor.offersOnlineConsult &&
      (doctor.effectiveFeeForConsultationType(ConsultationType.onlineConsult) ??
              0) >
          0) {
    return true;
  }
  if (doctor.offersVisitSite &&
      (doctor.effectiveFeeForConsultationType(ConsultationType.visitSite) ??
              0) >
          0) {
    return true;
  }
  if (doctor.offersBookHome &&
      (doctor.effectiveFeeForConsultationType(ConsultationType.bookHome) ?? 0) >
          0) {
    return true;
  }
  return doctor.consultationFee != null && doctor.consultationFee! > 0;
}

String? _doctorFeesSummary(DoctorModel doctor) {
  final parts = <String>[];
  if (doctor.offersOnlineConsult) {
    final fee =
        doctor.effectiveFeeForConsultationType(ConsultationType.onlineConsult);
    if (fee != null && fee > 0) {
      parts.add('Online ${FormattingUtils.formatConsultationFee(fee)}');
    }
  }
  if (doctor.offersVisitSite) {
    final fee =
        doctor.effectiveFeeForConsultationType(ConsultationType.visitSite);
    if (fee != null && fee > 0) {
      parts.add('Clinic ${FormattingUtils.formatConsultationFee(fee)}');
    }
  }
  if (doctor.offersBookHome) {
    final fee =
        doctor.effectiveFeeForConsultationType(ConsultationType.bookHome);
    if (fee != null && fee > 0) {
      parts.add('Home ${FormattingUtils.formatConsultationFee(fee)}');
    }
  }
  if (parts.isEmpty) return null;
  return parts.join(' · ');
}

String _availabilityWeekLabel(DoctorDashboardState dashboard) {
  final start = dashboard.availabilityReminder?.suggestedWeekStart ??
      dashboard.availability?.weekStartDate ??
      dashboard.clinicAvailability?.weekStartDate;
  final end = dashboard.availabilityReminder?.suggestedWeekEnd ??
      dashboard.availability?.weekEndDate ??
      dashboard.clinicAvailability?.weekEndDate;
  if (start == null) return 'Current week';
  final startLocal = start.toLocal();
  final endLocal = end?.toLocal();
  final startStr = FormattingUtils.formatDate(startLocal);
  if (endLocal == null) return 'Week of $startStr';
  return 'Week: $startStr – ${FormattingUtils.formatDate(endLocal)}';
}

String _availabilitySummary({
  required int onlineSlotCount,
  required int clinicSlotCount,
  required bool offersOnlineConsult,
  required bool offersVisitSite,
}) {
  final parts = <String>[];
  if (offersOnlineConsult) {
    parts.add(
      onlineSlotCount == 0
          ? 'no online slots'
          : '$onlineSlotCount online slot(s)',
    );
  }
  if (offersVisitSite) {
    parts.add(
      clinicSlotCount == 0
          ? 'no clinic slots'
          : '$clinicSlotCount clinic slot(s)',
    );
  }
  if (parts.isEmpty) {
    return 'No bookable consultation types enabled';
  }
  return parts.join(' · ');
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.doctor,
    required this.completion,
    required this.isUpdating,
    required this.needsAvailabilityUpdate,
    this.availabilityMessage,
    this.onlineSlotCount = 0,
    this.clinicSlotCount = 0,
    this.offersOnlineConsult = false,
    this.offersVisitSite = false,
    this.bookingStats = const DoctorBookingStats(),
    this.bookings = const [],
    this.upcomingOnlineBookings = const [],
    this.upcomingClinicBookings = const [],
    this.upcomingHomeBookings = const [],
    this.pendingHomeVisitRequests = const [],
    this.pastBookings = const [],
    this.isLoadingBookings = false,
    this.bookingsError,
    this.onRetryBookings,
    this.onRefreshBookings,
    this.onVerifyClinicVisit,
    this.onApproveHomeVisit,
    this.onRejectHomeVisit,
    required this.onUpload,
    required this.onReuploadDocuments,
    this.hasRejectedDocuments = false,
    required this.onEditProfile,
    required this.onUpdateAvailability,
  });

  final DoctorModel? doctor;
  final int completion;
  final bool isUpdating;
  final bool needsAvailabilityUpdate;
  final String? availabilityMessage;
  final int onlineSlotCount;
  final int clinicSlotCount;
  final bool offersOnlineConsult;
  final bool offersVisitSite;
  final DoctorBookingStats bookingStats;
  final List<DoctorBookingModel> bookings;
  final List<DoctorBookingModel> upcomingOnlineBookings;
  final List<DoctorBookingModel> upcomingClinicBookings;
  final List<DoctorBookingModel> upcomingHomeBookings;
  final List<DoctorBookingModel> pendingHomeVisitRequests;
  final List<DoctorBookingModel> pastBookings;
  final bool isLoadingBookings;
  final String? bookingsError;
  final VoidCallback? onRetryBookings;
  final Future<void> Function()? onRefreshBookings;
  final VoidCallback? onVerifyClinicVisit;
  final Future<void> Function(String bookingId)? onApproveHomeVisit;
  final Future<void> Function(String bookingId)? onRejectHomeVisit;
  final Future<void> Function(DocumentType) onUpload;
  final VoidCallback onReuploadDocuments;
  final bool hasRejectedDocuments;
  final VoidCallback onEditProfile;
  final VoidCallback onUpdateAvailability;

  @override
  Widget build(BuildContext context) {
    if (doctor == null) {
      return const EmptyStateWidget(
        icon: Icons.person_outline_rounded,
        title: 'No profile yet',
        message: 'Complete registration to access your dashboard.',
      );
    }

    final isVerified =
        doctor!.verificationStatus == VerificationStatus.verified;
    final statusLabel = isVerified ? 'Verified doctor' : 'Under review';

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: AppColors.gradientHero),
              borderRadius: AppDecorations.borderRadiusXl,
              boxShadow: AppDecorations.softShadow(opacity: 0.1),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: AppDecorations.borderRadiusXl,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.14),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.white.withValues(alpha: 0.65),
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: doctor!.profilePicture != null &&
                                doctor!.profilePicture!.startsWith('http')
                            ? Image.network(
                                doctor!.profilePicture!,
                                width: 67,
                                height: 67,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const ColoredBox(
                                  color: AppColors.white,
                                  child: Icon(
                                    Icons.person_rounded,
                                    color: AppColors.primary,
                                    size: 32,
                                  ),
                                ),
                              )
                            : const ColoredBox(
                                color: AppColors.white,
                                child: Icon(
                                  Icons.person_rounded,
                                  color: AppColors.primary,
                                  size: 32,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            doctor!.fullName,
                            style: AppTextStyles.titleLarge.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            doctor!.specializations?.join(', ') ??
                                'General Medicine',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.white.withValues(alpha: 0.95),
                              height: 1.3,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          VerificationBadge(
                            status: statusLabel,
                            backgroundColor: AppColors.white,
                            textColor: AppColors.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _BookingStatsRow(stats: bookingStats),
          const SizedBox(height: 16),
          _ConsultationServicesOverview(doctor: doctor!),
          const SizedBox(height: 16),
          _PracticeUpdatesSection(
            doctor: doctor!,
            needsAvailabilityUpdate: needsAvailabilityUpdate,
            availabilityMessage: availabilityMessage,
            upcomingBookings: [
              ...upcomingOnlineBookings,
              ...upcomingClinicBookings,
              ...upcomingHomeBookings,
            ],
            onUpdateAvailability: onUpdateAvailability,
          ),
          if (!isVerified) ...[
            const SizedBox(height: 20),
            ProviderDocumentStatusSection(
              onReuploadDocument: onUpload,
              isUploading: isUpdating,
            ),
          ],
          const SizedBox(height: 16),
          _AppointmentsSection(
            bookings: bookings,
            upcomingOnlineBookings: upcomingOnlineBookings,
            upcomingClinicBookings: upcomingClinicBookings,
            upcomingHomeBookings: upcomingHomeBookings,
            pendingHomeVisitRequests: pendingHomeVisitRequests,
            pastBookings: pastBookings,
            isLoading: isLoadingBookings,
            error: bookingsError,
            onRetry: onRetryBookings,
            isVerified: isVerified,
            offersOnlineConsult: offersOnlineConsult,
            offersVisitSite: offersVisitSite,
            offersBookHome: doctor!.offersBookHome,
            onVerifyClinicVisit: onVerifyClinicVisit,
            onApproveHomeVisit: onApproveHomeVisit,
            onRejectHomeVisit: onRejectHomeVisit,
            onVideoEnded: onRefreshBookings,
          ),
          if (needsAvailabilityUpdate) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: onUpdateAvailability,
              child: OfferPromoCard(
                title: 'Update your availability',
                subtitle: availabilityMessage ??
                    'Your weekly schedule has ended. Set time slots for the next week so patients can book you.',
                badge: 'ACTION',
                icon: Icons.calendar_month_rounded,
              ),
            ),
          ],
          const SizedBox(height: 16),
          ServiceBenefitCard(
            icon: Icons.schedule_rounded,
            title: 'Weekly availability',
            subtitle: _availabilitySummary(
              onlineSlotCount: onlineSlotCount,
              clinicSlotCount: clinicSlotCount,
              offersOnlineConsult: offersOnlineConsult,
              offersVisitSite: offersVisitSite,
            ),
            color: AppColors.primary,
            onTap: onUpdateAvailability,
          ),
          const SizedBox(height: 16),
          _ProfessionalProfileSection(doctor: doctor!),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: AppDecorations.borderRadiusLg,
              border: Border.all(color: AppColors.border),
              boxShadow: AppDecorations.softShadow(opacity: 0.04),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Profile strength',
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '$completion%',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.offer,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: AppDecorations.borderRadiusPill,
                  child: LinearProgressIndicator(
                    value: completion / 100,
                    minHeight: 8,
                    backgroundColor: AppColors.grey100,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const MarketplaceSectionTitle(title: 'Manage practice'),
          ServiceBenefitCard(
            icon: Icons.edit_calendar_rounded,
            title: 'Edit profile & fees',
            subtitle: 'Update bio, consultation charges',
            color: AppColors.primary,
            onTap: onEditProfile,
          ),
          if (hasRejectedDocuments) ...[
            const SizedBox(height: 10),
            ServiceBenefitCard(
              icon: Icons.upload_file_rounded,
              title: 'Re-upload documents',
              subtitle: 'Fix rejected documents for admin review',
              color: AppColors.primary,
              onTap: onReuploadDocuments,
            ),
          ],
          const SizedBox(height: 10),
          ServiceBenefitCard(
            icon: Icons.settings_rounded,
            title: 'Consultation settings',
            subtitle: _doctorFeesSummary(doctor!) ?? 'Set your fees',
            color: AppColors.offer,
            onTap: onEditProfile,
          ),
          const SizedBox(height: 16),
          _PracticeInsightsSection(doctor: doctor!),
          const SizedBox(height: 16),
          _TodayChecklistSection(
            isVerified: isVerified,
            hasFee: _doctorHasServiceFees(doctor!),
            hasBio: (doctor!.bio?.trim().isNotEmpty ?? false),
            onEditProfile: onEditProfile,
            onUploadDegree: () => onUpload(DocumentType.degreeCertificate),
          ),
          if (!isVerified) ...[
            const SizedBox(height: 16),
            const OfferPromoCard(
              title: 'Verification in progress',
              subtitle: 'Our team reviews within 24–48 hours',
              badge: 'PENDING',
              icon: Icons.hourglass_empty_rounded,
            ),
          ],
          if (isUpdating) ...[
            const SizedBox(height: 20),
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ],
        ],
      ),
    );
  }
}

class _PracticeInsightsSection extends StatelessWidget {
  const _PracticeInsightsSection({required this.doctor});

  final DoctorModel doctor;

  @override
  Widget build(BuildContext context) {
    final languagesCount = doctor.languagesSpoken?.length ?? 0;
    final specializationsCount = doctor.specializations?.length ?? 0;
    final experience = doctor.yearsOfExperience ?? 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppDecorations.borderRadiusLg,
        border: Border.all(color: AppColors.border),
        boxShadow: AppDecorations.softShadow(opacity: 0.04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Practice insights',
            style: AppTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _InsightTile(
                    icon: Icons.work_history_outlined,
                    label: 'Experience',
                    value: '$experience yrs',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _InsightTile(
                    icon: Icons.translate_rounded,
                    label: 'Languages',
                    value: '$languagesCount',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _InsightTile(
                    icon: Icons.local_hospital_outlined,
                    label: 'Specialties',
                    value: '$specializationsCount',
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

class _InsightTile extends StatelessWidget {
  const _InsightTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.grey100),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelLarge.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayChecklistSection extends StatelessWidget {
  const _TodayChecklistSection({
    required this.isVerified,
    required this.hasFee,
    required this.hasBio,
    required this.onEditProfile,
    required this.onUploadDegree,
  });

  final bool isVerified;
  final bool hasFee;
  final bool hasBio;
  final VoidCallback onEditProfile;
  final VoidCallback onUploadDegree;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppDecorations.borderRadiusLg,
        border: Border.all(color: AppColors.border),
        boxShadow: AppDecorations.softShadow(opacity: 0.04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today checklist',
            style: AppTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          _ChecklistTile(
            title: 'Verification status',
            subtitle: isVerified ? 'Completed' : 'Pending review',
            done: isVerified,
            onTap: null,
          ),
          _ChecklistTile(
            title: 'Consultation fee setup',
            subtitle: hasFee ? 'Completed' : 'Add your consultation fee',
            done: hasFee,
            onTap: hasFee ? null : onEditProfile,
          ),
          _ChecklistTile(
            title: 'Professional bio',
            subtitle: hasBio ? 'Completed' : 'Add a short profile summary',
            done: hasBio,
            onTap: hasBio ? null : onEditProfile,
          ),
          _ChecklistTile(
            title: 'Degree document',
            subtitle: 'Upload latest qualification proof',
            done: false,
            onTap: onUploadDegree,
          ),
        ],
      ),
    );
  }
}

class _ChecklistTile extends StatelessWidget {
  const _ChecklistTile({
    required this.title,
    required this.subtitle,
    required this.done,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool done;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(
                done ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                color: done ? AppColors.success : AppColors.textTertiary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.grey400,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Languages, years of experience, and bio from registration.
class _ProfessionalProfileSection extends StatelessWidget {
  const _ProfessionalProfileSection({required this.doctor});

  final DoctorModel doctor;

  @override
  Widget build(BuildContext context) {
    final experienceText = doctor.yearsOfExperience != null
        ? FormattingUtils.formatExperience(doctor.yearsOfExperience!)
        : null;
    final languages = doctor.languagesSpoken ?? [];
    final bio = doctor.bio?.trim();
    final hasBio = bio != null && bio.isNotEmpty;
    final qualification = doctor.qualification?.trim();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppDecorations.borderRadiusLg,
        border: Border.all(color: AppColors.border),
        boxShadow: AppDecorations.softShadow(opacity: 0.04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Professional profile',
            style: AppTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          if (experienceText != null)
            _ProfileInfoRow(
              icon: Icons.work_history_outlined,
              label: 'Experience',
              value: experienceText,
            ),
          if (qualification != null && qualification.isNotEmpty) ...[
            const SizedBox(height: 10),
            _ProfileInfoRow(
              icon: Icons.school_outlined,
              label: 'Qualification',
              value: qualification,
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'Languages',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (languages.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: languages
                  .map(
                    (lang) => Chip(
                      label: Text(lang),
                      labelStyle: AppTextStyles.labelSmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      backgroundColor: AppColors.primaryLight,
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            )
          else
            Text(
              'No languages added yet',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          if (hasBio) ...[
            const SizedBox(height: 14),
            Text(
              'About / professional experience',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              bio,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
                height: 1.45,
              ),
            ),
          ] else if (experienceText == null && languages.isEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Complete registration to add experience and languages.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({
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
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConsultationServicesOverview extends StatelessWidget {
  const _ConsultationServicesOverview({required this.doctor});

  final DoctorModel doctor;

  @override
  Widget build(BuildContext context) {
    final serviceFees = <({String label, IconData icon, int? fee})>[
      if (doctor.offersOnlineConsult)
        (
          label: 'Online consult',
          icon: Icons.videocam_rounded,
          fee: doctor.effectiveFeeForConsultationType(
            ConsultationType.onlineConsult,
          ),
        ),
      if (doctor.offersVisitSite)
        (
          label: 'Clinic visit',
          icon: Icons.local_hospital_rounded,
          fee: doctor.effectiveFeeForConsultationType(
            ConsultationType.visitSite,
          ),
        ),
      if (doctor.offersBookHome)
        (
          label: 'Home visit',
          icon: Icons.home_rounded,
          fee: doctor.effectiveFeeForConsultationType(
            ConsultationType.bookHome,
          ),
        ),
    ];
    final clinicLine = [
      doctor.clinicName,
      doctor.city,
    ].where((p) => p != null && p.trim().isNotEmpty).join(' · ');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppDecorations.borderRadiusLg,
        border: Border.all(color: AppColors.border),
        boxShadow: AppDecorations.softShadow(opacity: 0.04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Practice overview',
            style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (serviceFees.isNotEmpty)
            Column(
              children: [
                for (var i = 0; i < serviceFees.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  _ServiceFeeRow(
                    icon: serviceFees[i].icon,
                    label: serviceFees[i].label,
                    fee: serviceFees[i].fee,
                  ),
                ],
              ],
            )
          else
            Text(
              'No consultation types enabled',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          if (clinicLine.isNotEmpty) ...[
            const SizedBox(height: 12),
            _OverviewRow(
              icon: Icons.local_hospital_outlined,
              label: 'Clinic',
              value: clinicLine,
            ),
          ],
          if (doctor.mobileNumber != null && doctor.mobileNumber!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _OverviewRow(
              icon: Icons.phone_outlined,
              label: 'Contact',
              value: FormattingUtils.formatPhoneNumber(doctor.mobileNumber!),
            ),
          ],
        ],
      ),
    );
  }
}

class _ServiceFeeRow extends StatelessWidget {
  const _ServiceFeeRow({
    required this.icon,
    required this.label,
    required this.fee,
  });

  final IconData icon;
  final String label;
  final int? fee;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            fee != null && fee! > 0
                ? FormattingUtils.formatConsultationFee(fee!)
                : 'Set fee',
            style: AppTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.w800,
              color: fee != null && fee! > 0
                  ? AppColors.primaryDark
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewRow extends StatelessWidget {
  const _OverviewRow({
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
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              Text(
                value,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BookingStatsRow extends StatelessWidget {
  const _BookingStatsRow({required this.stats});

  final DoctorBookingStats stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _BookingStatTile(
                icon: Icons.videocam_rounded,
                label: 'Online',
                value: '${stats.upcomingOnline}',
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _BookingStatTile(
                icon: Icons.local_hospital_rounded,
                label: 'Clinic',
                value: '${stats.upcomingClinic}',
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _BookingStatTile(
                icon: Icons.home_rounded,
                label: 'Home',
                value: '${stats.upcomingHome}',
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _BookingStatTile(
                icon: Icons.today_rounded,
                label: 'Today',
                value: '${stats.today}',
                color: AppColors.offer,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _BookingStatTile(
                icon: Icons.event_available_rounded,
                label: 'Upcoming',
                value: '${stats.upcoming}',
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _BookingStatTile(
                icon: Icons.history_rounded,
                label: 'Past',
                value: '${stats.past}',
                color: AppColors.grey600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BookingStatTile extends StatelessWidget {
  const _BookingStatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppDecorations.borderRadiusLg,
        border: Border.all(color: AppColors.border),
        boxShadow: AppDecorations.softShadow(opacity: 0.04),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PracticeUpdatesSection extends StatelessWidget {
  const _PracticeUpdatesSection({
    required this.doctor,
    required this.needsAvailabilityUpdate,
    this.availabilityMessage,
    required this.upcomingBookings,
    required this.onUpdateAvailability,
  });

  final DoctorModel doctor;
  final bool needsAvailabilityUpdate;
  final String? availabilityMessage;
  final List<DoctorBookingModel> upcomingBookings;
  final VoidCallback onUpdateAvailability;

  @override
  Widget build(BuildContext context) {
    final isVerified =
        doctor.verificationStatus == VerificationStatus.verified;
    final updates = <_PracticeUpdateItem>[];

    if (!isVerified) {
      updates.add(
        _PracticeUpdateItem(
          icon: Icons.verified_user_outlined,
          title: 'Verification in progress',
          subtitle:
              'Your profile is under admin review. You can still update availability.',
          color: AppColors.warning,
        ),
      );
    }

    if (needsAvailabilityUpdate) {
      updates.add(
        _PracticeUpdateItem(
          icon: Icons.calendar_month_rounded,
          title: 'Availability needs update',
          subtitle: availabilityMessage ??
              'Set your weekly slots so patients can book you.',
          color: AppColors.primary,
          onTap: onUpdateAvailability,
        ),
      );
    }

    final recent = upcomingBookings.take(3).toList();
    for (final booking in recent) {
      updates.add(
        _PracticeUpdateItem(
          icon: booking.isClinicVisit
              ? Icons.local_hospital_rounded
              : Icons.videocam_rounded,
          title: booking.title,
          subtitle: booking.subtitle,
          color: booking.isClinicVisit ? AppColors.accent : AppColors.primary,
        ),
      );
    }

    if (updates.isEmpty) {
      updates.add(
        const _PracticeUpdateItem(
          icon: Icons.check_circle_outline_rounded,
          title: 'All caught up',
          subtitle: 'No pending actions. New patient bookings will appear here.',
          color: AppColors.success,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MarketplaceSectionTitle(title: 'Updates'),
        const SizedBox(height: 8),
        ...updates.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: item,
          ),
        ),
      ],
    );
  }
}

class _PracticeUpdateItem extends StatelessWidget {
  const _PracticeUpdateItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: AppDecorations.borderRadiusLg,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppDecorations.borderRadiusLg,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: AppDecorations.borderRadiusLg,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textTertiary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppointmentsSection extends StatelessWidget {
  const _AppointmentsSection({
    required this.bookings,
    required this.upcomingOnlineBookings,
    required this.upcomingClinicBookings,
    required this.upcomingHomeBookings,
    this.pendingHomeVisitRequests = const [],
    required this.pastBookings,
    required this.isLoading,
    this.error,
    this.onRetry,
    required this.isVerified,
    required this.offersOnlineConsult,
    required this.offersVisitSite,
    required this.offersBookHome,
    this.onVerifyClinicVisit,
    this.onVideoEnded,
    this.onApproveHomeVisit,
    this.onRejectHomeVisit,
  });

  final List<DoctorBookingModel> bookings;
  final List<DoctorBookingModel> upcomingOnlineBookings;
  final List<DoctorBookingModel> upcomingClinicBookings;
  final List<DoctorBookingModel> upcomingHomeBookings;
  final List<DoctorBookingModel> pendingHomeVisitRequests;
  final List<DoctorBookingModel> pastBookings;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;
  final bool isVerified;
  final bool offersOnlineConsult;
  final bool offersVisitSite;
  final bool offersBookHome;
  final VoidCallback? onVerifyClinicVisit;
  final Future<void> Function()? onVideoEnded;
  final Future<void> Function(String bookingId)? onApproveHomeVisit;
  final Future<void> Function(String bookingId)? onRejectHomeVisit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MarketplaceSectionTitle(title: 'Patient bookings'),
        if (offersVisitSite && onVerifyClinicVisit != null) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onVerifyClinicVisit,
            icon: const Icon(Icons.pin_rounded, size: 20),
            label: const Text('Verify clinic visit code'),
          ),
        ],
        const SizedBox(height: 8),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (error != null)
          AppErrorWidget(
            message: error!,
            onRetry: onRetry,
          )
        else if (bookings.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: AppDecorations.borderRadiusLg,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.event_busy_outlined,
                  size: 40,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(height: 8),
                Text(
                  'No bookings yet',
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isVerified
                      ? 'Online consults, clinic visits, and home visits booked by patients will appear here.'
                      : 'Bookings appear after your profile is verified and patients book you on the app.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          )
        else ...[
          if (offersBookHome && pendingHomeVisitRequests.isNotEmpty) ...[
            _PendingHomeVisitRequestsSection(
              bookings: pendingHomeVisitRequests,
              onApprove: onApproveHomeVisit,
              onReject: onRejectHomeVisit,
            ),
            const SizedBox(height: 12),
          ],
          if (offersOnlineConsult) ...[
            _BookingTypeSection(
              title: 'Upcoming online consults',
              icon: Icons.videocam_rounded,
              color: AppColors.primary,
              bookings: upcomingOnlineBookings,
              emptyMessage: 'No upcoming online consultations.',
              onVideoEnded: onVideoEnded,
            ),
            const SizedBox(height: 12),
          ],
          if (offersVisitSite) ...[
            _BookingTypeSection(
              title: 'Upcoming clinic visits',
              icon: Icons.local_hospital_rounded,
              color: AppColors.accent,
              bookings: upcomingClinicBookings,
              emptyMessage: 'No upcoming clinic appointments.',
              onVerify: onVerifyClinicVisit,
            ),
            const SizedBox(height: 12),
          ],
          if (offersBookHome) ...[
            _BookingTypeSection(
              title: 'Upcoming home visits',
              icon: Icons.home_rounded,
              color: AppColors.secondary,
              bookings: upcomingHomeBookings,
              emptyMessage: 'No upcoming home visits.',
            ),
            const SizedBox(height: 12),
          ],
          _BookingTypeSection(
            title: 'Past appointments',
            icon: Icons.history_rounded,
            color: AppColors.grey600,
            bookings: pastBookings,
            emptyMessage: 'No past appointments yet.',
            isPast: true,
          ),
        ],
      ],
    );
  }
}

class _PendingHomeVisitRequestsSection extends StatelessWidget {
  const _PendingHomeVisitRequestsSection({
    required this.bookings,
    this.onApprove,
    this.onReject,
  });

  final List<DoctorBookingModel> bookings;
  final Future<void> Function(String bookingId)? onApprove;
  final Future<void> Function(String bookingId)? onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppDecorations.borderRadiusLg,
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.notifications_active_rounded,
                  size: 20, color: AppColors.secondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'New home visit requests',
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${bookings.length}',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...bookings.map(
            (booking) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PendingHomeVisitRequestCard(
                booking: booking,
                onApprove: onApprove,
                onReject: onReject,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingHomeVisitRequestCard extends StatelessWidget {
  const _PendingHomeVisitRequestCard({
    required this.booking,
    this.onApprove,
    this.onReject,
  });

  final DoctorBookingModel booking;
  final Future<void> Function(String bookingId)? onApprove;
  final Future<void> Function(String bookingId)? onReject;

  @override
  Widget build(BuildContext context) {
    final slot = booking.slotStart;
    final slotText = slot != null
        ? '${FormattingUtils.formatDateWithDay(slot)} · ${FormattingUtils.formatTime(slot)}'
        : booking.subtitle;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight.withValues(alpha: 0.2),
        borderRadius: AppDecorations.borderRadiusMd,
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            booking.patientName ?? 'Patient',
            style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            slotText,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (booking.patientLocationLine != null) ...[
            const SizedBox(height: 6),
            Text(
              booking.patientLocationLine!,
              style: AppTextStyles.bodySmall,
            ),
          ],
          if (booking.distanceKm != null) ...[
            const SizedBox(height: 6),
            Text(
              'Distance: ${booking.distanceKm} km',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (booking.isHomeVisit &&
              booking.patientLatitude != null &&
              booking.patientLongitude != null) ...[
            const SizedBox(height: 10),
            PatientLocationMapCard(
              latitude: booking.patientLatitude!,
              longitude: booking.patientLongitude!,
              addressLine: booking.patientLocationLine,
              title: 'Patient location',
              mapHeight: 170,
            ),
          ],
          if (booking.visitReason != null &&
              booking.visitReason!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Reason: ${booking.visitReason!.trim()}',
              style: AppTextStyles.bodySmall,
            ),
          ],
          if (booking.consultationFee != null) ...[
            const SizedBox(height: 6),
            Text(
              'Fee if approved: ${FormattingUtils.formatConsultationFee(booking.consultationFee!)}',
              style: AppTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject == null
                      ? null
                      : () => onReject!(booking.id),
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: onApprove == null
                      ? null
                      : () => onApprove!(booking.id),
                  child: const Text('Approve & request payment'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BookingTypeSection extends StatelessWidget {
  const _BookingTypeSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.bookings,
    required this.emptyMessage,
    this.isPast = false,
    this.onVerify,
    this.onVideoEnded,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<DoctorBookingModel> bookings;
  final String emptyMessage;
  final bool isPast;
  final VoidCallback? onVerify;
  final Future<void> Function()? onVideoEnded;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppDecorations.borderRadiusLg,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${bookings.length}',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (bookings.isEmpty)
            Text(
              emptyMessage,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          else
            ...bookings.map(
              (booking) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _BookingCard(
                  booking: booking,
                  isPast: isPast,
                  onVerify: onVerify,
                  onVideoEnded: onVideoEnded,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    this.isPast = false,
    this.onVerify,
    this.onVideoEnded,
  });

  final DoctorBookingModel booking;
  final bool isPast;
  final VoidCallback? onVerify;
  final Future<void> Function()? onVideoEnded;

  Color get _color {
    if (booking.isClinicVisit) return AppColors.accent;
    if (booking.isHomeVisit) return AppColors.secondary;
    return AppColors.primary;
  }

  IconData get _icon {
    if (booking.isClinicVisit) return Icons.local_hospital_rounded;
    if (booking.isHomeVisit) return Icons.home_rounded;
    return Icons.videocam_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    final slot = booking.slotStart;
    final slotText = slot != null
        ? '${FormattingUtils.formatDateWithDay(slot)} · ${FormattingUtils.formatTime(slot)}'
        : booking.subtitle;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isPast ? AppColors.grey50 : AppColors.white,
        borderRadius: AppDecorations.borderRadiusLg,
        border: Border.all(
          color: isPast ? AppColors.grey200 : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isPast ? 0.08 : 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            booking.patientName ?? booking.title,
                            style: AppTextStyles.labelLarge.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        _StatusPill(
                          label: booking.displayTypeLabel,
                          color: color,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      slotText,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (booking.patientMobile != null &&
              booking.patientMobile!.isNotEmpty)
            _BookingDetailRow(
              icon: Icons.phone_outlined,
              text: FormattingUtils.formatPhoneNumber(booking.patientMobile!),
            ),
          if (booking.patientEmail != null &&
              booking.patientEmail!.trim().isNotEmpty)
            _BookingDetailRow(
              icon: Icons.email_outlined,
              text: booking.patientEmail!.trim(),
            ),
          if (booking.patientLocationLine != null &&
              (booking.isClinicVisit || booking.isHomeVisit))
            _BookingDetailRow(
              icon: Icons.location_on_outlined,
              text: booking.patientLocationLine!,
            ),
          if (booking.distanceKm != null && booking.isHomeVisit)
            _BookingDetailRow(
              icon: Icons.social_distance_rounded,
              text: '${booking.distanceKm} km from you',
            ),
          if (booking.isHomeVisit &&
              booking.patientLatitude != null &&
              booking.patientLongitude != null) ...[
            const SizedBox(height: 10),
            PatientLocationMapCard(
              latitude: booking.patientLatitude!,
              longitude: booking.patientLongitude!,
              addressLine: booking.patientLocationLine,
              title: 'Patient location',
              mapHeight: 150,
            ),
          ],
          if (booking.isHomeVisit && booking.status == 'confirmed') ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () async {
                    try {
                      await DioService().post(
                        AppConstants.endpointDoctorVisitProgress(booking.id),
                        data: {'progress': 'en_route'},
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Marked on the way')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$e')),
                        );
                      }
                    }
                  },
                  child: const Text('On the way'),
                ),
                OutlinedButton(
                  onPressed: () async {
                    try {
                      await DioService().post(
                        AppConstants.endpointDoctorVisitProgress(booking.id),
                        data: {'progress': 'arrived'},
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Marked arrived')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$e')),
                        );
                      }
                    }
                  },
                  child: const Text('Arrived'),
                ),
                OutlinedButton(
                  onPressed: () async {
                    try {
                      await DioService().post(
                        AppConstants.endpointDoctorVisitProgress(booking.id),
                        data: {'progress': 'completed'},
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Marked completed')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$e')),
                        );
                      }
                    }
                  },
                  child: const Text('Completed'),
                ),
              ],
            ),
          ],
          if (!isPast && booking.status == 'confirmed') ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.push(
                  '${AppConstants.routeProviderBookingChat}'
                  '?role=doctor&bookingId=${booking.id}'
                  '&title=${Uri.encodeComponent(booking.patientName ?? "Patient")}',
                ),
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                label: const Text('Chat with patient'),
              ),
            ),
          ],
          if (booking.visitReason != null &&
              booking.visitReason!.trim().isNotEmpty)
            _BookingDetailRow(
              icon: Icons.notes_rounded,
              text: booking.visitReason!.trim(),
            ),
          if (booking.patientNotes != null &&
              booking.patientNotes!.trim().isNotEmpty)
            _BookingDetailRow(
              icon: Icons.chat_bubble_outline_rounded,
              text: booking.patientNotes!.trim(),
            ),
          if (booking.previousReports.isNotEmpty) ...[
            const SizedBox(height: 8),
            _PreviousReportsSection(reports: booking.previousReports),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              _StatusPill(
                label: booking.displayStatusLabel,
                color: isPast ? AppColors.grey600 : AppColors.success,
              ),
              if (booking.isClinicVisit && booking.isAppointmentVerified) ...[
                const SizedBox(width: 8),
                _StatusPill(
                  label: 'VERIFIED',
                  color: AppColors.success,
                ),
              ],
              if (booking.consultationFee != null) ...[
                const SizedBox(width: 8),
                Text(
                  FormattingUtils.formatConsultationFee(booking.consultationFee!),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.offerDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const Spacer(),
              if (booking.createdAt != null)
                Text(
                  'Booked ${FormattingUtils.formatDate(booking.createdAt!)}',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
            ],
          ),
          if (booking.isClinicVisit &&
              !isPast &&
              !booking.isAppointmentVerified &&
              onVerify != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onVerify,
                icon: const Icon(Icons.verified_user_outlined, size: 18),
                label: const Text('Enter patient code to verify'),
              ),
            ),
          ],
          if (booking.isOnlineConsult && !isPast) ...[
            const SizedBox(height: 12),
            JoinVideoConsultButton(
              bookingId: booking.id,
              canJoinVideo: booking.canJoinVideo,
              peerName: booking.patientName ?? 'Patient',
              videoStartsInMinutes: booking.videoStartsInMinutes,
              onReturned: onVideoEnded,
            ),
          ],
          if (booking.isOnlineConsult) ...[
            const SizedBox(height: 12),
            if (booking.hasPrescription)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 18,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Prescription sent to patient',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final saved = await PrescriptionSheet.show(
                      context,
                      bookingId: booking.id,
                    );
                    if (saved == true) {
                      await onVideoEnded?.call();
                    }
                  },
                  icon: const Icon(Icons.medication_rounded, size: 18),
                  label: const Text('Write & send prescription'),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _BookingDetailRow extends StatelessWidget {
  const _BookingDetailRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppColors.textTertiary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviousReportsSection extends StatelessWidget {
  const _PreviousReportsSection({required this.reports});

  final List<PreviousReportModel> reports;

  Future<void> _openReport(PreviousReportModel report) async {
    final url = MediaUrlUtils.resolve(report.fileUrl);
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Previous reports (${reports.length})',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: reports.map((report) {
            return ActionChip(
              avatar: Icon(
                report.isPdf
                    ? Icons.picture_as_pdf_rounded
                    : Icons.image_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              label: Text(
                report.displayName,
                style: AppTextStyles.labelSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () => _openReport(report),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}
