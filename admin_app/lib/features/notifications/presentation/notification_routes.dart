import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';

void openProviderNotification(
  GoRouter router, {
  required String role,
  required String type,
  Map<String, dynamic> data = const {},
}) {
  final bookingId = data['bookingId']?.toString() ?? '';
  if (type == 'chat_message' && bookingId.isNotEmpty) {
    router.push(
      '${AppConstants.routeProviderBookingChat}?role=$role&bookingId=$bookingId&title=${Uri.encodeComponent('Chat')}',
    );
    return;
  }
  if (bookingId.isNotEmpty) {
    final dashboard = role == 'nurse'
        ? AppConstants.routeNurseDashboard
        : AppConstants.routeDoctorDashboard;
    router.push(dashboard);
    return;
  }
  router.push('${AppConstants.routeProviderNotifications}?role=$role');
}

void openProviderNotificationFromPayload(
  GoRouter router,
  String role,
  Map<String, dynamic> payload,
) {
  openProviderNotification(
    router,
    role: role,
    type: payload['type']?.toString() ?? '',
    data: payload,
  );
}
