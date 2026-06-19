import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/user_auth_guard.dart';
import '../../data/models/consultation_type.dart';
import '../../data/models/doctor_model.dart';
import '../doctor_registration/presentation/screens/doctor_profile_screen.dart';

/// Opens online consult booking when the doctor offers it.
Future<void> openOnlineConsultBooking(
  BuildContext context,
  DoctorModel doctor,
) async {
  if (doctor.id == null || doctor.id!.isEmpty) return;

  if (!await ensureUserLoggedIn(context)) return;

  if (!context.mounted) return;

  if (!doctor.offersConsultationType(ConsultationType.onlineConsult)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This doctor does not offer online consultation.'),
      ),
    );
    return;
  }

  context.push(
    '${AppConstants.routeOnlineConsultBooking}?doctorId=${Uri.encodeComponent(doctor.id!)}',
  );
}

/// Opens hospital / clinic visit booking when the doctor offers visit site.
Future<void> openHospitalVisitBooking(
  BuildContext context,
  DoctorModel doctor,
) async {
  if (doctor.id == null || doctor.id!.isEmpty) return;

  if (!await ensureUserLoggedIn(context)) return;

  if (!context.mounted) return;

  if (!doctor.offersConsultationType(ConsultationType.visitSite)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This doctor does not offer hospital visits.'),
      ),
    );
    return;
  }

  context.push(
    '${AppConstants.routeHospitalVisitBooking}?doctorId=${Uri.encodeComponent(doctor.id!)}',
  );
}

/// Card tap: open doctor profile (photos, details, then book).
Future<void> onDoctorCardTap(BuildContext context, DoctorModel doctor) async {
  openDoctorProfile(context, doctor);
}
