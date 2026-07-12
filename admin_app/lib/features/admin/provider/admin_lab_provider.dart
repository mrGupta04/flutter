import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/lab_model.dart';
import '../../../data/repositories/admin_repository.dart';
import 'admin_provider.dart';

class AdminLabsListState {
  const AdminLabsListState({
    this.labs = const [],
    this.isLoading = false,
    this.error,
    this.selectedStatus,
  });

  final List<LabModel> labs;
  final bool isLoading;
  final String? error;
  final String? selectedStatus;

  AdminLabsListState copyWith({
    List<LabModel>? labs,
    bool? isLoading,
    String? error,
    String? selectedStatus,
  }) {
    return AdminLabsListState(
      labs: labs ?? this.labs,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedStatus: selectedStatus ?? this.selectedStatus,
    );
  }
}

class AdminLabsListNotifier extends StateNotifier<AdminLabsListState> {
  AdminLabsListNotifier(this.repository) : super(const AdminLabsListState());

  final AdminRepository repository;

  Future<void> fetchLabs({int page = 1, String? status}) async {
    state = state.copyWith(isLoading: true, error: null);
    final response = await repository.getLabsForVerification(page: page, status: status);
    if (response.success && response.data != null) {
      state = state.copyWith(labs: response.data!, isLoading: false, selectedStatus: status);
    } else {
      state = state.copyWith(
        isLoading: false,
        error: response.error ?? 'Failed to fetch labs',
      );
    }
  }

  void filterByStatus(String? status) => fetchLabs(status: status);
}

final adminLabsListProvider =
    StateNotifierProvider<AdminLabsListNotifier, AdminLabsListState>((ref) {
  return AdminLabsListNotifier(ref.watch(adminRepositoryProvider));
});

class LabDetailsState {
  const LabDetailsState({
    this.lab,
    this.isLoading = false,
    this.error,
    this.isApproving = false,
    this.isRejecting = false,
    this.isSuspending = false,
    this.isRequestingDocs = false,
  });

  final LabModel? lab;
  final bool isLoading;
  final String? error;
  final bool isApproving;
  final bool isRejecting;
  final bool isSuspending;
  final bool isRequestingDocs;

  LabDetailsState copyWith({
    LabModel? lab,
    bool? isLoading,
    String? error,
    bool? isApproving,
    bool? isRejecting,
    bool? isSuspending,
    bool? isRequestingDocs,
  }) {
    return LabDetailsState(
      lab: lab ?? this.lab,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isApproving: isApproving ?? this.isApproving,
      isRejecting: isRejecting ?? this.isRejecting,
      isSuspending: isSuspending ?? this.isSuspending,
      isRequestingDocs: isRequestingDocs ?? this.isRequestingDocs,
    );
  }
}

class LabDetailsNotifier extends StateNotifier<LabDetailsState> {
  LabDetailsNotifier(this.repository) : super(const LabDetailsState());

  final AdminRepository repository;

  Future<void> fetchLabDetails(String labId) async {
    state = state.copyWith(isLoading: true, error: null);
    final response = await repository.getLabDetails(labId: labId);
    if (response.success && response.data != null) {
      state = state.copyWith(lab: response.data, isLoading: false);
    } else {
      state = state.copyWith(
        isLoading: false,
        error: response.error ?? 'Failed to fetch lab',
      );
    }
  }

  Future<bool> approveLab({required String labId, String? notes}) async {
    state = state.copyWith(isApproving: true, error: null);
    final response = await repository.approveLab(labId: labId, approvalNotes: notes);
    if (response.success && response.data != null) {
      state = state.copyWith(lab: response.data, isApproving: false);
      return true;
    }
    state = state.copyWith(
      isApproving: false,
      error: response.error ?? 'Failed to approve lab',
    );
    return false;
  }

  Future<bool> rejectLab({required String labId, required String reason}) async {
    state = state.copyWith(isRejecting: true, error: null);
    final response = await repository.rejectLab(labId: labId, rejectionReason: reason);
    if (response.success && response.data != null) {
      state = state.copyWith(lab: response.data, isRejecting: false);
      return true;
    }
    state = state.copyWith(
      isRejecting: false,
      error: response.error ?? 'Failed to reject lab',
    );
    return false;
  }

  Future<bool> suspendLab({required String labId, String? reason}) async {
    state = state.copyWith(isSuspending: true, error: null);
    final response = await repository.suspendLab(labId: labId, reason: reason);
    if (response.success && response.data != null) {
      state = state.copyWith(lab: response.data, isSuspending: false);
      return true;
    }
    state = state.copyWith(
      isSuspending: false,
      error: response.error ?? 'Failed to suspend lab',
    );
    return false;
  }

  Future<bool> requestDocuments({required String labId, required String note}) async {
    state = state.copyWith(isRequestingDocs: true, error: null);
    final response = await repository.requestLabDocuments(labId: labId, note: note);
    if (response.success && response.data != null) {
      state = state.copyWith(lab: response.data, isRequestingDocs: false);
      return true;
    }
    state = state.copyWith(
      isRequestingDocs: false,
      error: response.error ?? 'Failed to request documents',
    );
    return false;
  }

  Future<bool> verifyDocument({
    required String labId,
    required String documentId,
  }) async {
    final response = await repository.verifyLabDocument(
      labId: labId,
      documentId: documentId,
    );
    if (response.success && response.data != null) {
      state = state.copyWith(lab: response.data, error: null);
      return true;
    }
    state = state.copyWith(error: response.error ?? 'Failed to verify document');
    return false;
  }

  Future<bool> rejectDocument({
    required String labId,
    required String documentId,
    required String reason,
  }) async {
    final response = await repository.rejectLabDocument(
      labId: labId,
      documentId: documentId,
      rejectionReason: reason,
    );
    if (response.success && response.data != null) {
      state = state.copyWith(lab: response.data, error: null);
      return true;
    }
    state = state.copyWith(error: response.error ?? 'Failed to reject document');
    return false;
  }
}

final labDetailsProvider =
    StateNotifierProvider.family<LabDetailsNotifier, LabDetailsState, String>(
  (ref, labId) {
    final notifier = LabDetailsNotifier(ref.watch(adminRepositoryProvider));
    notifier.fetchLabDetails(labId);
    return notifier;
  },
);
