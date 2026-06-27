import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/nurse_model.dart';
import '../../../data/repositories/nurse_registration_repository.dart';

class NurseSearchParams {
  const NurseSearchParams({
    this.query,
    this.city,
    this.specialization,
  });

  final String? query;
  final String? city;
  final String? specialization;

  bool get hasTextFilters =>
      (query != null && query!.trim().isNotEmpty) ||
      (city != null && city!.trim().isNotEmpty) ||
      (specialization != null && specialization!.trim().isNotEmpty);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NurseSearchParams &&
        other.query == query &&
        other.city == city &&
        other.specialization == specialization;
  }

  @override
  int get hashCode => Object.hash(query, city, specialization);
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
      return response.data!;
    }

    throw Exception(response.error ?? 'Search failed');
  },
);
