import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/lab_model.dart';
import '../../../data/repositories/lab_repository.dart';

export '../../../data/repositories/lab_repository.dart' show LabSearchParams;

final labRepositoryProvider = Provider((ref) => LabRepository());

final labSearchProvider =
    FutureProvider.family<List<LabModel>, LabSearchParams>((ref, params) async {
  final repo = ref.watch(labRepositoryProvider);
  final response = await repo.searchVerified(params);
  if (response.success && response.data != null) {
    return response.data!;
  }
  throw Exception(response.error ?? 'Could not load labs');
});
