import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/consultation_type.dart';
import '../../../data/models/doctor_model.dart';
import 'doctor_registration_repository_provider.dart';

/// Fetches verified doctors for the public home screen.
final verifiedDoctorsProvider = FutureProvider<List<DoctorModel>>((ref) async {
  return ref.watch(
    verifiedDoctorsByConsultationProvider(null).future,
  );
});

/// Verified doctors optionally filtered by consultation type.
final verifiedDoctorsByConsultationProvider =
    FutureProvider.family<List<DoctorModel>, ConsultationType?>(
  (ref, consultationType) async {
    final repository = ref.watch(doctorRegistrationRepositoryProvider);
    final response = await repository.getVerifiedDoctors(
      pageSize: 50,
      consultationType: consultationType,
    );

    if (response.success && response.data != null) {
      return filterDoctorsByConsultation(
        response.data!,
        consultationType,
      );
    }

    throw Exception(response.error ?? 'Failed to load verified doctors');
  },
);

/// Client-side filter when showing all doctors with faded buttons.
List<DoctorModel> filterDoctorsByConsultation(
  List<DoctorModel> doctors,
  ConsultationType? type,
) {
  if (type == null) return doctors;
  return doctors
      .where((d) => d.offersConsultationType(type))
      .toList(growable: false);
}
