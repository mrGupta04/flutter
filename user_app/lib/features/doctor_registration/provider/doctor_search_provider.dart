import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/consultation_type.dart';
import '../../../data/models/doctor_model.dart';
import 'doctor_registration_repository_provider.dart';
import 'verified_doctors_provider.dart';

/// Parameters for searching verified doctors.
class DoctorSearchParams {
  const DoctorSearchParams({
    this.query,
    this.city,
    this.specialization,
    this.minYearsExperience,
    required this.consultationType,
  });

  final String? query;
  final String? city;
  final String? specialization;
  final int? minYearsExperience;
  final ConsultationType consultationType;

  bool get hasTextFilters =>
      (query != null && query!.trim().isNotEmpty) ||
      (city != null && city!.trim().isNotEmpty) ||
      (specialization != null && specialization!.trim().isNotEmpty) ||
      minYearsExperience != null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DoctorSearchParams &&
        other.query == query &&
        other.city == city &&
        other.specialization == specialization &&
        other.minYearsExperience == minYearsExperience &&
        other.consultationType == consultationType;
  }

  @override
  int get hashCode => Object.hash(
        query,
        city,
        specialization,
        minYearsExperience,
        consultationType,
      );
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

bool doctorMatchesKeyword(DoctorModel doctor, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;

  final haystacks = <String>[
    doctor.fullName,
    doctor.firstName ?? '',
    doctor.lastName ?? '',
    doctor.clinicName ?? '',
    doctor.qualification ?? '',
    ...?doctor.specializations,
  ];

  return haystacks.any((value) => value.toLowerCase().contains(q));
}

int _doctorKeywordRank(DoctorModel doctor, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return 0;

  final fullName = doctor.fullName.toLowerCase();
  final first = (doctor.firstName ?? '').toLowerCase();
  final last = (doctor.lastName ?? '').toLowerCase();
  if (fullName.startsWith(q) || first.startsWith(q) || last.startsWith(q)) {
    return 0;
  }
  if (fullName.contains(q) || first.contains(q) || last.contains(q)) {
    return 1;
  }
  if ((doctor.clinicName ?? '').toLowerCase().contains(q)) return 2;
  return 3;
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
      var doctors = filterDoctorsByConsultation(
        response.data!
            .where((doctor) => doctor.isPublicProfileDisplayable)
            .toList(growable: false),
        params.consultationType,
      );
      final keyword = _trimOrNull(params.query);
      if (keyword != null) {
        doctors = doctors
            .where((doctor) => doctorMatchesKeyword(doctor, keyword))
            .toList()
          ..sort(
            (a, b) => _doctorKeywordRank(a, keyword)
                .compareTo(_doctorKeywordRank(b, keyword)),
          );
      }
      final minYears = params.minYearsExperience;
      if (minYears != null) {
        doctors = doctors
            .where(
              (doctor) =>
                  doctor.yearsOfExperience != null &&
                  doctor.yearsOfExperience! >= minYears,
            )
            .toList();
      }
      return doctors;
    }

    throw Exception(response.error ?? 'Search failed');
  },
);
