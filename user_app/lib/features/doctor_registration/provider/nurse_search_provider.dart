import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/nurse_model.dart';
import '../../../data/repositories/nurse_registration_repository.dart';

class NurseSearchParams {
  const NurseSearchParams({
    this.query,
    this.city,
    this.specialization,
    this.minYearsExperience,
  });

  final String? query;
  final String? city;
  final String? specialization;
  final int? minYearsExperience;

  bool get hasTextFilters =>
      (query != null && query!.trim().isNotEmpty) ||
      (city != null && city!.trim().isNotEmpty) ||
      (specialization != null && specialization!.trim().isNotEmpty) ||
      minYearsExperience != null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NurseSearchParams &&
        other.query == query &&
        other.city == city &&
        other.specialization == specialization &&
        other.minYearsExperience == minYearsExperience;
  }

  @override
  int get hashCode =>
      Object.hash(query, city, specialization, minYearsExperience);
}

String? _trimOrNull(String? value) {
  if (value == null) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

final nurseSearchProvider =
    FutureProvider.autoDispose.family<List<NurseModel>, NurseSearchParams>(
  (ref, params) async {
    final repository = NurseRegistrationRepository();
    final response = await repository.getVerifiedNurses(
      pageSize: 50,
      search: _trimOrNull(params.query),
      city: _trimOrNull(params.city),
      specialization: _trimOrNull(params.specialization),
    );

    if (response.success && response.data != null) {
      var nurses = response.data!;
      final minYears = params.minYearsExperience;
      if (minYears != null) {
        nurses = nurses
            .where(
              (nurse) =>
                  nurse.yearsOfExperience != null &&
                  nurse.yearsOfExperience! >= minYears,
            )
            .toList();
      }
      return nurses;
    }

    throw Exception(response.error ?? 'Search failed');
  },
);
