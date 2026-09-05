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
  if (type == 'ambulance_emergency' ||
      type == 'ambulance_assigned' ||
      type == 'ambulance_update' ||
      role == 'ambulance') {
    router.push('${AppConstants.routeAmbulanceOperations}?tab=0');
    return;
  }
  if (type == 'emergency_blood' ||
      type == 'blood_request' ||
      type == 'blood_inventory' ||
      type == 'blood_donor' ||
      role == 'blood-bank' ||
      role == 'bloodbank') {
    final tab = type == 'emergency_blood'
        ? 2
        : type == 'blood_donor'
            ? 3
            : type == 'blood_inventory'
                ? 0
                : 1;
    router.push('${AppConstants.routeBloodBankOperations}?tab=$tab');
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
