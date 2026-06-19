import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/blood_bank_model.dart';
import '../../../data/repositories/admin_repository.dart';
import 'admin_provider.dart';

class AdminBloodBanksListState {
  final List<BloodBankModel> bloodBanks;
  final bool isLoading;
  final String? error;
  final String? selectedStatus;

  AdminBloodBanksListState({
    this.bloodBanks = const [],
    this.isLoading = false,
    this.error,
    this.selectedStatus,
  });

  AdminBloodBanksListState copyWith({
    List<BloodBankModel>? bloodBanks,
    bool? isLoading,
    String? error,
    String? selectedStatus,
  }) {
    return AdminBloodBanksListState(
      bloodBanks: bloodBanks ?? this.bloodBanks,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedStatus: selectedStatus ?? this.selectedStatus,
    );
  }
}

class AdminBloodBanksListNotifier
    extends StateNotifier<AdminBloodBanksListState> {
  final AdminRepository repository;

  AdminBloodBanksListNotifier(this.repository)
      : super(AdminBloodBanksListState());

  Future<void> fetchBloodBanks({int page = 1, String? status}) async {
    state = state.copyWith(isLoading: true, error: null);
    final response = await repository.getBloodBanksForVerification(
      page: page,
      status: status,
    );
    if (response.success && response.data != null) {
      state = state.copyWith(
        bloodBanks: response.data!,
        isLoading: false,
        selectedStatus: status,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: response.error ?? 'Failed to fetch blood banks',
      );
    }
  }

  void filterByStatus(String? status) => fetchBloodBanks(status: status);
}

final adminBloodBanksListProvider = StateNotifierProvider<
    AdminBloodBanksListNotifier, AdminBloodBanksListState>((ref) {
  return AdminBloodBanksListNotifier(ref.watch(adminRepositoryProvider));
});

class BloodBankDetailsState {
  final BloodBankModel? bloodBank;
  final bool isLoading;
  final String? error;
  final bool isApproving;
  final bool isRejecting;

  BloodBankDetailsState({
    this.bloodBank,
    this.isLoading = false,
    this.error,
    this.isApproving = false,
    this.isRejecting = false,
  });

  BloodBankDetailsState copyWith({
    BloodBankModel? bloodBank,
    bool? isLoading,
    String? error,
    bool? isApproving,
    bool? isRejecting,
  }) {
    return BloodBankDetailsState(
      bloodBank: bloodBank ?? this.bloodBank,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isApproving: isApproving ?? this.isApproving,
      isRejecting: isRejecting ?? this.isRejecting,
    );
  }
}

class BloodBankDetailsNotifier extends StateNotifier<BloodBankDetailsState> {
  final AdminRepository repository;

  BloodBankDetailsNotifier(this.repository) : super(BloodBankDetailsState());

  Future<void> fetchBloodBankDetails(String bloodBankId) async {
    state = state.copyWith(isLoading: true, error: null);
    final response =
        await repository.getBloodBankDetails(bloodBankId: bloodBankId);
    if (response.success && response.data != null) {
      state = state.copyWith(bloodBank: response.data, isLoading: false);
    } else {
      state = state.copyWith(
        isLoading: false,
        error: response.error ?? 'Failed to fetch blood bank',
      );
    }
  }

  Future<bool> approveBloodBank({
    required String bloodBankId,
    String? notes,
  }) async {
    state = state.copyWith(isApproving: true, error: null);
    final response = await repository.approveBloodBank(
      bloodBankId: bloodBankId,
      approvalNotes: notes,
    );
    if (response.success && response.data != null) {
      state = state.copyWith(bloodBank: response.data, isApproving: false);
      return true;
    }
    state = state.copyWith(
      isApproving: false,
      error: response.error ?? 'Failed to approve blood bank',
    );
    return false;
  }

  Future<bool> rejectBloodBank({
    required String bloodBankId,
    required String reason,
  }) async {
    state = state.copyWith(isRejecting: true, error: null);
    final response = await repository.rejectBloodBank(
      bloodBankId: bloodBankId,
      rejectionReason: reason,
    );
    if (response.success && response.data != null) {
      state = state.copyWith(bloodBank: response.data, isRejecting: false);
      return true;
    }
    state = state.copyWith(
      isRejecting: false,
      error: response.error ?? 'Failed to reject blood bank',
    );
    return false;
  }
}

final bloodBankDetailsProvider = StateNotifierProvider.family<
    BloodBankDetailsNotifier, BloodBankDetailsState, String>((ref, bloodBankId) {
  final notifier = BloodBankDetailsNotifier(ref.watch(adminRepositoryProvider));
  notifier.fetchBloodBankDetails(bloodBankId);
  return notifier;
});
