import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/user_auth_guard.dart';
import '../../data/models/nurse_model.dart';

String nursePaymentRoute(String bookingId) =>
    '${AppConstants.routeNursePayment}?bookingId=${Uri.encodeComponent(bookingId)}';

String nurseMockPaymentRoute(String bookingId, {int amount = 0}) =>
    '${AppConstants.routeNurseMockPayment}?bookingId=${Uri.encodeComponent(bookingId)}'
    '&amount=$amount';

String nurseBookingStatusRoute(String bookingId) =>
    '${AppConstants.routeNurseBookingStatus}?bookingId=${Uri.encodeComponent(bookingId)}';

String nurseLiveTrackRoute(String bookingId) =>
    '${AppConstants.routeHomeVisitTrack}?bookingId=${Uri.encodeComponent(bookingId)}';

Future<void> openNurseHomeVisitBooking(
  BuildContext context,
  NurseModel nurse,
) async {
  if (nurse.id == null || nurse.id!.isEmpty) return;

  if (!await ensureUserLoggedIn(context)) return;
  if (!context.mounted) return;

  if (nurse.availableForHomeVisit == false) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This nurse is not available for home visits.'),
      ),
    );
    return;
  }

  context.push(
    '${AppConstants.routeNurseHomeVisitBooking}?nurseId=${Uri.encodeComponent(nurse.id!)}',
  );
}
