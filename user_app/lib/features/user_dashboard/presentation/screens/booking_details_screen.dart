import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/friendly_error.dart';
import '../../../../core/utils/media_url_utils.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/models/patient_booking_model.dart';
import '../../../../data/services/lab_scan_payment_flow.dart';
import '../../../../shared/widgets/appointment_code_display.dart';
import '../../../../shared/widgets/full_screen_image_viewer.dart';
import '../../../../shared/widgets/user_adaptive_scaffold.dart';
import '../../../../shared/widgets/user_app_footer.dart';
import '../../../feedback/presentation/utils/feedback_prompt_helper.dart';
import '../../../feedback/presentation/widgets/post_session_feedback_sheet.dart';
import '../../../nurse_home_visit/nurse_home_visit_navigation.dart';
import '../../../online_consult/provider/online_consult_provider.dart';
import '../../../video_consult/presentation/widgets/join_video_consult_button.dart';
import '../../data/booking_status_config.dart';
import '../../provider/patient_dashboard_provider.dart';
import '../utils/nursing_report_view_utils.dart';
import '../utils/prescription_view_utils.dart';
import '../widgets/booking_empty_state.dart';
import '../widgets/booking_status_badge.dart';
import '../widgets/cancel_booking_sheet.dart';
import '../widgets/reschedule_booking_sheet.dart';
import '../widgets/visit_completion_otp_banner.dart';

final labScanPaymentFlowProvider = Provider.autoDispose((ref) {
  final flow = LabScanPaymentFlow();
  ref.onDispose(flow.dispose);
  return flow;
});

class BookingDetailsScreen extends ConsumerStatefulWidget {
  const BookingDetailsScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  ConsumerState<BookingDetailsScreen> createState() =>
      _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends ConsumerState<BookingDetailsScreen> {
  PatientBookingModel? _remote;
  bool _loadingRemote = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(patientDashboardProvider.notifier).loadBookings();
      final local =
          ref.read(patientDashboardProvider.notifier).bookingById(widget.bookingId);
      if (local == null) {
        setState(() => _loadingRemote = true);
        final fetched = await ref
            .read(patientDashboardProvider.notifier)
            .loadBookingById(widget.bookingId);
        if (mounted) {
          setState(() {
            _remote = fetched;
            _loadingRemote = false;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bookingId = widget.bookingId;
    final dash = ref.watch(patientDashboardProvider);
    PatientBookingModel? booking;
    for (final item in [...dash.bookings, ...dash.historyBookings]) {
      if (item.id == bookingId) {
        booking = item;
        break;
      }
    }
    booking ??= _remote;

    if ((dash.isLoadingBookings || _loadingRemote) && booking == null) {
      return UserAdaptiveScaffold(
        currentTab: UserNavTab.profile,
        appBar: AppBar(title: const Text('Booking details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (booking == null) {
      return UserAdaptiveScaffold(
        currentTab: UserNavTab.profile,
        appBar: AppBar(title: const Text('Booking details')),
        body: BookingListError(
          message: dash.error != null
              ? friendlyErrorMessage(dash.error!)
              : 'This booking could not be found.',
          onRetry: () =>
              ref.read(patientDashboardProvider.notifier).loadBookings(),
        ),
      );
    }

    final item = booking;
    final status = BookingStatusView.of(item);
    final dateFmt = DateFormat('d MMM yyyy');
    final timeFmt = DateFormat('h:mm a');
    final imageUrl = MediaUrlUtils.resolve(item.doctorProfilePicture);
    final current = item.isActiveOrUpcoming;

    return UserAdaptiveScaffold(
      currentTab: UserNavTab.profile,
      appBar: AppBar(title: Text(item.typeLabel)),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(patientDashboardProvider.notifier).loadBookings(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            if (item.serviceType == 'ambulance' && item.isLiveNow)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: AppDecorations.borderRadiusLg,
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'Active ambulance — track live location below.',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: AppDecorations.borderRadiusLg,
                border: Border.all(color: AppColors.grey200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      TappableProfilePhoto(
                        imageUrl: imageUrl,
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.primaryLight,
                          backgroundImage:
                              imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                          child: imageUrl.isEmpty
                              ? const Icon(Icons.person_rounded, color: AppColors.primary)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.doctorName,
                              style: AppTextStyles.titleMedium.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              item.typeLabel,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      BookingStatusBadge(status: status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Booking ID: ${item.id}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.grey500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _Section(
              title: 'Appointment details',
              children: [
                _Row('Date', dateFmt.format(item.slotStart.toLocal())),
                _Row('Time', timeFmt.format(item.slotStart.toLocal())),
                _Row('Service', item.typeLabel),
                _Row('Provider', item.doctorName),
                if (item.clinicName != null && item.clinicName!.isNotEmpty)
                  _Row('Location', item.clinicName!),
                if (item.patientAddress != null && item.patientAddress!.isNotEmpty)
                  _Row('Address', item.patientAddress!),
                if (item.visitReason != null && item.visitReason!.isNotEmpty)
                  _Row('Notes', item.visitReason!),
              ],
            ),
            const SizedBox(height: 12),
            _Section(
              title: 'Payment',
              children: [
                _Row(
                  'Status',
                  item.paymentStatus == 'paid' || item.paymentStatus == 'success'
                      ? 'Paid'
                      : item.paymentStatus == 'refunded'
                          ? 'Refunded'
                          : item.paymentStatus == 'failed'
                              ? 'Payment failed'
                              : item.needsHomeVisitPayment || item.needsLabOrScanPayment
                                  ? 'Payment pending'
                                  : (item.paymentStatus ?? '—'),
                ),
                if ((item.amountPaid ?? item.consultationFee) != null)
                  _Row(
                    'Amount',
                    '₹${item.amountPaid ?? item.consultationFee}',
                  ),
                if (item.paymentMethod != null && item.paymentMethod!.isNotEmpty)
                  _Row('Method', item.paymentMethod!),
                if (item.paymentReference != null &&
                    item.paymentReference!.isNotEmpty)
                  _Row('Reference', item.paymentReference!),
                if (item.paidAt != null)
                  _Row('Paid on', DateFormat('d MMM yyyy, h:mm a').format(item.paidAt!.toLocal())),
              ],
            ),
            if (item.timeline.isNotEmpty) ...[
              const SizedBox(height: 12),
              _Section(
                title: 'Timeline',
                children: [
                  for (final step in item.timeline)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            step.done
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked,
                            size: 18,
                            color: step.done ? AppColors.success : AppColors.grey400,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              step.label,
                              style: AppTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (item.needsHomeVisitPayment)
                  FilledButton(
                    onPressed: () async {
                      if (item.isNurseVisit) {
                        context.push(nursePaymentRoute(item.id));
                        return;
                      }
                      try {
                        await ref.read(bookingPaymentFlowProvider).payForExistingBooking(
                              bookingId: item.id,
                            );
                        if (context.mounted) {
                          SnackBarHelper.showSuccess(context, 'Payment successful.');
                        }
                        await ref.read(patientDashboardProvider.notifier).loadBookings();
                      } catch (e) {
                        if (context.mounted) {
                          SnackBarHelper.showError(context, friendlyErrorMessage(e));
                        }
                      }
                    },
                    child: const Text('Pay now'),
                  ),
                if (item.needsLabOrScanPayment && current)
                  FilledButton(
                    onPressed: () async {
                      try {
                        final flow = ref.read(labScanPaymentFlowProvider);
                        if (item.serviceType == 'scan') {
                          await flow.payScanBooking(
                            bookingId: item.id,
                            businessName: item.doctorName,
                          );
                        } else {
                          await flow.payLabBooking(
                            bookingId: item.id,
                            businessName: item.doctorName,
                          );
                        }
                        if (context.mounted) {
                          SnackBarHelper.showSuccess(context, 'Payment successful.');
                        }
                        await ref.read(patientDashboardProvider.notifier).loadBookings();
                      } catch (e) {
                        if (context.mounted) {
                          SnackBarHelper.showError(context, friendlyErrorMessage(e));
                        }
                      }
                    },
                    child: const Text('Pay now'),
                  ),
                if (item.isClinicVisit &&
                    item.isConfirmed &&
                    (item.appointmentCode != null &&
                        item.appointmentCode!.isNotEmpty))
                  AppointmentCodeDisplay(
                    code: item.appointmentCode!,
                    verified: item.isAppointmentVerified,
                    bookingId: item.id,
                  ),
                if (item.isOnlineConsult && current)
                  JoinVideoConsultButton(
                    bookingId: item.id,
                    canJoinVideo: item.canJoinVideo,
                    peerName: item.doctorName,
                    doctorId: item.doctorId,
                    doctorProfilePicture: item.doctorProfilePicture,
                    consultationType: item.consultationType,
                    sessionLabel: item.label,
                    videoStartsInMinutes: item.videoStartsInMinutes,
                  ),
                if (item.isNurseVisit && item.isConfirmed && !item.isTerminal)
                  VisitCompletionOtpBanner(bookingId: item.id),
                if (item.nursingReportPdfUrl != null)
                  OutlinedButton.icon(
                    onPressed: () => openNursingReportPdf(
                      context,
                      bookingId: item.id,
                      pdfUrl: item.nursingReportPdfUrl,
                      repository: ref.read(patientDashboardRepositoryProvider),
                    ),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Nursing report'),
                  ),
                if (!current && item.hasPrescription)
                  OutlinedButton.icon(
                    onPressed: () => openPatientPrescriptionPdf(
                      context,
                      bookingId: item.id,
                      prescriptionPdfUrl: item.prescriptionPdfUrl,
                      repository: ref.read(patientDashboardRepositoryProvider),
                    ),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('View prescription'),
                  ),
                if (item.canViewReceipt)
                  OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        final url = await ref
                            .read(patientDashboardRepositoryProvider)
                            .fetchReceiptPdfUrl(item.id);
                        if (!context.mounted) return;
                        if (url == null || url.isEmpty) {
                          SnackBarHelper.showError(
                            context,
                            'Receipt is not available yet.',
                          );
                          return;
                        }
                        await openPatientPrescriptionPdf(
                          context,
                          bookingId: item.id,
                          prescriptionPdfUrl: url,
                        );
                      } catch (e) {
                        if (context.mounted) {
                          SnackBarHelper.showError(
                            context,
                            friendlyErrorMessage(e),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: const Text('View receipt'),
                  ),
                if (!current && item.canRequestFeedback)
                  OutlinedButton.icon(
                    onPressed: () => showFeedbackAfterSession(
                      context,
                      PostSessionFeedbackInfo(
                        bookingId: item.id,
                        doctorId: item.doctorId,
                        doctorName: item.doctorName,
                        doctorProfilePicture: item.doctorProfilePicture,
                        consultationType: item.consultationType,
                        sessionLabel: item.label,
                      ),
                    ),
                    icon: const Icon(Icons.star_outline_rounded),
                    label: const Text('Rate provider'),
                  ),
                if (item.canTrackHomeVisitLive)
                  FilledButton.icon(
                    onPressed: () => context.push(
                      '${AppConstants.routeHomeVisitTrack}?bookingId=${Uri.encodeComponent(item.id)}',
                    ),
                    icon: const Icon(Icons.near_me_rounded),
                    label: const Text('Track visit'),
                  ),
                if (item.canTrackAmbulanceLive)
                  FilledButton.icon(
                    onPressed: () => context.push(
                      '${AppConstants.routeAmbulanceTrack}?bookingId=${Uri.encodeComponent(item.id)}',
                    ),
                    icon: const Icon(Icons.emergency_rounded),
                    label: const Text('Track ambulance'),
                  ),
                if (item.canChat)
                  OutlinedButton.icon(
                    onPressed: () => context.push(
                      '${AppConstants.routeBookingChat}?bookingId=${Uri.encodeComponent(item.id)}&title=${Uri.encodeComponent(item.doctorName)}',
                    ),
                    icon: const Icon(Icons.chat_outlined),
                    label: const Text('Chat'),
                  ),
                OutlinedButton.icon(
                  onPressed: () => context.push(
                    '${AppConstants.routeBookingTimeline}?bookingId=${Uri.encodeComponent(item.id)}',
                  ),
                  icon: const Icon(Icons.timeline_rounded),
                  label: const Text('Full timeline'),
                ),
                if (item.canCancel && current)
                  OutlinedButton.icon(
                    onPressed: () async {
                      final ok = await showCancelBookingSheet(
                        context,
                        bookingId: item.id,
                      );
                      if (ok) {
                        await ref.read(patientDashboardProvider.notifier).loadBookings();
                        if (context.mounted) {
                          SnackBarHelper.showSuccess(context, 'Booking cancelled');
                        }
                      }
                    },
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Cancel'),
                  ),
                if (item.canCancel &&
                    current &&
                    (item.serviceType == 'doctor' || item.serviceType == 'nurse'))
                  OutlinedButton.icon(
                    onPressed: () async {
                      final ok = await showRescheduleBookingSheet(
                        context,
                        booking: item,
                      );
                      if (ok) {
                        await ref.read(patientDashboardProvider.notifier).loadBookings();
                        if (context.mounted) {
                          SnackBarHelper.showSuccess(context, 'Visit rescheduled');
                        }
                      }
                    },
                    icon: const Icon(Icons.event_repeat),
                    label: const Text('Reschedule'),
                  ),
                if (!current &&
                    (item.serviceType == 'doctor' || item.serviceType == 'nurse'))
                  OutlinedButton.icon(
                    onPressed: () {
                      if (item.isNurseVisit) {
                        context.push(
                          '${AppConstants.routeNurseHomeVisitBooking}?nurseId=${Uri.encodeComponent(item.providerId)}',
                        );
                      } else {
                        context.push(
                          '${AppConstants.routeDoctorProfile}?id=${item.providerId}',
                        );
                      }
                    },
                    icon: const Icon(Icons.replay),
                    label: const Text('Book again'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppDecorations.borderRadiusLg,
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

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
            width: 88,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
