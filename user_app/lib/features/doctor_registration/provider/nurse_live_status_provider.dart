import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/nurse_model.dart';
import '../../../data/repositories/nurse_registration_repository.dart';

final _nurseRegistrationRepositoryProvider =
    Provider((ref) => NurseRegistrationRepository());

/// Polls `/nurse/live-status` so cards update without reloading the full list.
final nurseLiveStatusProvider =
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

  final repository = ref.watch(_nurseRegistrationRepositoryProvider);
  final response = await repository.getNursesLiveStatus(ids);

  if (response.success && response.data != null) {
    return response.data!;
  }

  return const {};
});

String nurseIdsCacheKey(Iterable<NurseModel> nurses) {
  return nurses
      .map((nurse) => nurse.id)
      .whereType<String>()
      .where((id) => id.isNotEmpty)
      .join(',');
}

NurseModel applyNurseLiveStatus(NurseModel nurse, Map<String, bool> liveMap) {
  final id = nurse.id;
  if (id == null || !liveMap.containsKey(id)) return nurse;
  return nurse.copyWith(isLiveNow: liveMap[id]!);
}
