import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/blood_bank_model.dart';
import '../../../data/repositories/blood_bank_repository.dart';

final verifiedBloodBanksProvider =
    FutureProvider.autoDispose<List<BloodBankModel>>((ref) async {
  final repository = BloodBankRepository();
  final response = await repository.getVerifiedBloodBanks();
  if (response.success && response.data != null) {
    return response.data!;
  }
  throw Exception(response.error ?? 'Failed to load blood banks');
});
