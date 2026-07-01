import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/scan_center_model.dart';
import '../../../data/repositories/scan_repository.dart';

export '../../../data/repositories/scan_repository.dart' show ScanSearchParams;

final scanRepositoryProvider = Provider((ref) => ScanRepository());

final scanSearchProvider =
    FutureProvider.family<List<ScanCenterModel>, ScanSearchParams>(
  (ref, params) async {
    final repo = ref.watch(scanRepositoryProvider);
    final response = await repo.searchVerified(params);
    if (response.success && response.data != null) {
      return response.data!;
    }
    throw Exception(response.error ?? 'Could not load scan centers');
  },
);

final scanCenterDetailProvider =
    FutureProvider.family<ScanCenterModel, String>((ref, id) async {
  final repo = ref.watch(scanRepositoryProvider);
  final response = await repo.getById(id);
  if (response.success && response.data != null) {
    return response.data!;
  }
  throw Exception(response.error ?? 'Could not load scan center');
});
