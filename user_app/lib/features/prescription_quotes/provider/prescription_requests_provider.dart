import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/prescription_request_model.dart';
import '../data/prescription_request_repository.dart';

final prescriptionRequestRepositoryProvider = Provider(
  (ref) => PrescriptionRequestRepository(),
);

class PrescriptionRequestsState {
  const PrescriptionRequestsState({
    this.requests = const [],
    this.isLoading = false,
    this.error,
  });

  final List<PrescriptionRequestModel> requests;
  final bool isLoading;
  final String? error;

  PrescriptionRequestsState copyWith({
    List<PrescriptionRequestModel>? requests,
    bool? isLoading,
    String? error,
  }) {
    return PrescriptionRequestsState(
      requests: requests ?? this.requests,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class PrescriptionRequestsNotifier
    extends StateNotifier<PrescriptionRequestsState> {
  PrescriptionRequestsNotifier(this._repo)
      : super(const PrescriptionRequestsState());

  final PrescriptionRequestRepository _repo;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    final res = await _repo.listMyRequests();
    if (res.success && res.data != null) {
      state = state.copyWith(requests: res.data, isLoading: false);
    } else {
      state = state.copyWith(
        isLoading: false,
        error: res.error ?? 'Failed to load requests',
      );
    }
  }
}

final prescriptionRequestsProvider = StateNotifierProvider<
    PrescriptionRequestsNotifier, PrescriptionRequestsState>(
  (ref) => PrescriptionRequestsNotifier(
    ref.watch(prescriptionRequestRepositoryProvider),
  ),
);

final prescriptionRequestDetailProvider = FutureProvider.autoDispose
    .family<PrescriptionRequestModel?, String>((ref, id) async {
  final res =
      await ref.watch(prescriptionRequestRepositoryProvider).getById(id);
  if (!res.success) {
    throw Exception(res.error ?? 'Failed to load request');
  }
  return res.data;
});