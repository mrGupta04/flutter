import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/user_auth_guard.dart';
import '../../data/models/nurse_model.dart';

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
