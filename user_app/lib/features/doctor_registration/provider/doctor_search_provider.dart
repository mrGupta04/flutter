import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/consultation_type.dart';
import '../../../data/models/doctor_model.dart';
import 'doctor_registration_repository_provider.dart';

/// Parameters for searching verified doctors.
class DoctorSearchParams {
  const DoctorSearchParams({
    this.query,
    this.city,
    this.specialization,
    required this.consultationType,
  });

  final String? query;
  final String? city;
  final String? specialization;
  final ConsultationType consultationType;

  bool get hasTextFilters =>
      (query != null && query!.trim().isNotEmpty) ||
      (city != null && city!.trim().isNotEmpty) ||
      (specialization != null && specialization!.trim().isNotEmpty);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DoctorSearchParams &&
        other.query == query &&
        other.city == city &&
        other.specialization == specialization &&
        other.consultationType == consultationType;
  }

  @override
  int get hashCode => Object.hash(query, city, specialization, consultationType);
}

/// Maps category labels on home to API specialization search terms.
const categorySpecializationMap = <String, String>{
  'Cardiology': 'Cardiology',
  'Mental': 'Psychiatry',
  'Pediatric': 'Pediatric',
  'Eye Care': 'Ophthalmology',
};

String? _trimOrNull(String? value) {
  if (value == null) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

final doctorSearchProvider =
    FutureProvider.autoDispose.family<List<DoctorModel>, DoctorSearchParams>(
  (ref, params) async {
    final repository = ref.watch(doctorRegistrationRepositoryProvider);
    final response = await repository.getVerifiedDoctors(
      pageSize: 50,
      query: _trimOrNull(params.query),
      city: _trimOrNull(params.city),
      specialization: _trimOrNull(params.specialization),
      consultationType: params.consultationType,
    );

    if (response.success && response.data != null) {
      return response.data!;
    }

    throw Exception(response.error ?? 'Search failed');
  },
);
