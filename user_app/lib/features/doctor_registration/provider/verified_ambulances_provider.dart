import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/ambulance_model.dart';
import '../../../data/repositories/ambulance_repository.dart';

final verifiedAmbulancesProvider =
    FutureProvider.autoDispose<List<AmbulanceModel>>((ref) async {
  final repository = AmbulanceRepository();
  final response = await repository.getVerifiedAmbulances();
  if (response.success && response.data != null) {
    return response.data!;
  }
  throw Exception(response.error ?? 'Failed to load ambulances');
});
