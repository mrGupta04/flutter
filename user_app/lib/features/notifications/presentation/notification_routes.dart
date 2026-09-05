import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/repositories/notifications_repository.dart';

void openPatientNotification(
  GoRouter router, {
  required String type,
  Map<String, dynamic> data = const {},
}) {
  final bookingId = data['bookingId']?.toString() ?? '';
  switch (type) {
    case 'chat_message':
      if (bookingId.isEmpty) return;
      router.push(
        '${AppConstants.routeBookingChat}?bookingId=$bookingId&title=${Uri.encodeComponent('Chat')}',
      );
      return;
    case 'en_route':
    case 'arrived':
      if (bookingId.isNotEmpty) {
        router.push(
          '${AppConstants.routeHomeVisitTrack}?bookingId=$bookingId',
        );
      } else {
        router.push(AppConstants.routeUserDashboard);
      }
      return;
    case 'payment_due':
    case 'booking_approved':
      if (bookingId.isNotEmpty) {
        router.push(
          '${AppConstants.routeNursePayment}?bookingId=$bookingId',
        );
        return;
      }
      router.push(AppConstants.routeUserDashboard);
      return;
    case 'booking_confirmed':
    case 'payment_expired':
    case 'payment_failed':
    case 'home_visit_request':
    case 'visit_reminder':
    case 'visit_completed':
      router.push(AppConstants.routeUserDashboard);
      return;
    case 'prescription_ready':
    case 'visit_note_ready':
    case 'nursing_report_ready':
      router.push(
        bookingId.isNotEmpty
            ? AppConstants.routeNursingReports
            : AppConstants.routeUserDashboard,
      );
      return;
    case 'visit_completion_otp':
    case 'visit_started':
      if (bookingId.isNotEmpty) {
        router.push(
          '${AppConstants.routeBookingTimeline}?bookingId=$bookingId',
        );
      } else {
        router.push(AppConstants.routeUserDashboard);
      }
      return;
    case 'blood_request':
    case 'emergency_blood':
    case 'blood_donor':
      final orderId = data['orderId']?.toString() ?? '';
      final requestId = data['requestId']?.toString() ?? '';
      final donorRequest = data['donorRequestId']?.toString() ?? '';
      if (type == 'blood_donor' || donorRequest.isNotEmpty) {
        router.push(AppConstants.routeBloodDonorRequests);
        return;
      }
      if (orderId.isNotEmpty) {
        router.push('${AppConstants.routeBloodRequestDetail}/$orderId');
        return;
      }
      if (requestId.isNotEmpty) {
        router.push(AppConstants.routeMyBloodRequests);
        return;
      }
      router.push(AppConstants.routeMyBloodRequests);
      return;
    case 'ambulance_emergency':
    case 'ambulance_assigned':
    case 'ambulance_update':
      if (bookingId.isNotEmpty) {
        router.push(
          '${AppConstants.routeAmbulanceTrack}?bookingId=$bookingId',
        );
      } else {
        router.push(AppConstants.routeAmbulanceHub);
      }
      return;
    default:
      if (bookingId.isNotEmpty) {
        router.push(AppConstants.routeUserDashboard);
      } else {
        router.push(AppConstants.routeNotifications);
      }
  }
}

void openPatientNotificationFromPayload(
  GoRouter router,
  Map<String, dynamic> payload,
) {
  openPatientNotification(
    router,
    type: payload['type']?.toString() ?? '',
    data: payload,
  );
}

void openPatientNotificationModel(GoRouter router, AppNotification n) {
  openPatientNotification(router, type: n.type, data: n.data);
}
