import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/user_auth_guard.dart';
import '../../data/models/consultation_type.dart';
import '../../data/models/doctor_model.dart';
import '../doctor_registration/presentation/screens/doctor_profile_screen.dart';

String consultationBookingPath(String doctorId, ConsultationType type) {
  final encodedId = Uri.encodeComponent(doctorId);
  switch (type) {
    case ConsultationType.onlineConsult:
      return '${AppConstants.routeOnlineConsultBooking}?doctorId=$encodedId';
    case ConsultationType.visitSite:
      return '${AppConstants.routeHospitalVisitBooking}?doctorId=$encodedId';
    case ConsultationType.bookHome:
      return '${AppConstants.routeHomeVisitBooking}?doctorId=$encodedId';
  }
}

bool _isOnConsultationBooking(
  BuildContext context,
  String doctorId,
  ConsultationType type,
) {
  final state = GoRouterState.of(context);
  if (state.uri.queryParameters['doctorId'] != doctorId) return false;

  return switch (type) {
    ConsultationType.onlineConsult =>
      state.uri.path == AppConstants.routeOnlineConsultBooking,
    ConsultationType.visitSite =>
      state.uri.path == AppConstants.routeHospitalVisitBooking,
    ConsultationType.bookHome =>
      state.uri.path == AppConstants.routeHomeVisitBooking,
  };
}

String _unavailableMessage(ConsultationType type) {
  return switch (type) {
    ConsultationType.onlineConsult =>
      'This doctor does not offer online consultation.',
    ConsultationType.visitSite =>
      'This doctor does not offer hospital visits.',
    ConsultationType.bookHome => 'This doctor does not offer home visits.',
  };
}

/// Opens the dedicated booking screen for [type].
Future<void> openConsultationBooking(
  BuildContext context,
  DoctorModel doctor,
  ConsultationType type, {
  bool replace = false,
}) async {
  if (doctor.id == null || doctor.id!.isEmpty) return;

  if (!await ensureUserLoggedIn(context)) return;
  if (!context.mounted) return;

  if (!doctor.offersConsultationType(type)) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_unavailableMessage(type))),
    );
    return;
  }

  if (_isOnConsultationBooking(context, doctor.id!, type)) return;

  final path = consultationBookingPath(doctor.id!, type);
  if (replace) {
    context.replace(path);
  } else {
    context.push(path);
  }
}

/// Switches between booking screens without stacking routes.
Future<void> switchConsultationBooking(
  BuildContext context,
  DoctorModel doctor,
  ConsultationType type,
) {
  return openConsultationBooking(context, doctor, type, replace: true);
}

/// Opens online consult booking when the doctor offers it.
Future<void> openOnlineConsultBooking(
  BuildContext context,
  DoctorModel doctor,
) {
  return openConsultationBooking(
    context,
    doctor,
    ConsultationType.onlineConsult,
  );
}

/// Opens hospital / clinic visit booking when the doctor offers visit site.
Future<void> openHospitalVisitBooking(
  BuildContext context,
  DoctorModel doctor,
) {
  return openConsultationBooking(
    context,
    doctor,
    ConsultationType.visitSite,
  );
}

/// Opens home visit booking when the doctor offers home consultations.
Future<void> openHomeVisitBooking(
  BuildContext context,
  DoctorModel doctor,
) {
  return openConsultationBooking(
    context,
    doctor,
    ConsultationType.bookHome,
  );
}

/// Card tap: open doctor profile (photos, details, then book).
Future<void> onDoctorCardTap(BuildContext context, DoctorModel doctor) async {
  openDoctorProfile(context, doctor);
}
