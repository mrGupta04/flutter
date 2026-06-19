import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/doctor_model.dart';
import 'doctor_registration_repository_provider.dart';

/// Polls `/doctor/live-status` so cards update without reloading the full list.
final doctorLiveStatusProvider =
    FutureProvider.family<Map<String, bool>, String>((ref, idsKey) async {
  final ids = idsKey
      .split(',')
      .map((id) => id.trim())
      .where((id) => id.isNotEmpty)
      .toList(growable: false);

  if (ids.isEmpty) return const {};

  final timer = Timer.periodic(const Duration(seconds: 15), (_) {
    ref.invalidateSelf();
  });
  ref.onDispose(timer.cancel);

  final repository = ref.watch(doctorRegistrationRepositoryProvider);
  final response = await repository.getDoctorsLiveStatus(ids);

  if (response.success && response.data != null) {
    return response.data!;
  }

  return const {};
});

String doctorIdsCacheKey(Iterable<DoctorModel> doctors) {
  return doctors
      .map((doctor) => doctor.id)
      .whereType<String>()
      .where((id) => id.isNotEmpty)
      .join(',');
}

DoctorModel applyLiveStatus(DoctorModel doctor, Map<String, bool> liveMap) {
  final id = doctor.id;
  if (id == null || !liveMap.containsKey(id)) return doctor;
  return doctor.copyWith(isLiveNow: liveMap[id]!);
}
