import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/doctor_document_model.dart';
import '../../../data/models/nurse_model.dart';
import '../../../data/repositories/admin_repository.dart';
import 'admin_provider.dart';

class AdminNursesListState {
  final List<NurseModel> nurses;
  final bool isLoading;
  final String? error;
  final String? selectedStatus;

  AdminNursesListState({
    this.nurses = const [],
    this.isLoading = false,
    this.error,
    this.selectedStatus,
  });

  AdminNursesListState copyWith({
    List<NurseModel>? nurses,
    bool? isLoading,
    String? error,
    String? selectedStatus,
  }) {
    return AdminNursesListState(
      nurses: nurses ?? this.nurses,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedStatus: selectedStatus ?? this.selectedStatus,
    );
  }
}

class AdminNursesListNotifier extends StateNotifier<AdminNursesListState> {
  final AdminRepository repository;

  AdminNursesListNotifier(this.repository) : super(AdminNursesListState());

  Future<void> fetchNurses({int page = 1, String? status}) async {
    state = state.copyWith(isLoading: true, error: null);
    final response = await repository.getNursesForVerification(
      page: page,
      status: status,
    );
    if (response.success && response.data != null) {
      state = state.copyWith(
        nurses: response.data!,
        isLoading: false,
        selectedStatus: status,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: response.error ?? 'Failed to fetch nurses',
      );
    }
  }

  void filterByStatus(String? status) => fetchNurses(status: status);
}

final adminNursesListProvider =
    StateNotifierProvider<AdminNursesListNotifier, AdminNursesListState>((ref) {
  return AdminNursesListNotifier(ref.watch(adminRepositoryProvider));
});

class NurseDetailsState {
  final NurseModel? nurse;
  final List<DoctorDocumentModel> documents;
  final bool isLoading;
  final String? error;
  final bool isApproving;
  final bool isRejecting;

  NurseDetailsState({
    this.nurse,
    this.documents = const [],
    this.isLoading = false,
    this.error,
    this.isApproving = false,
    this.isRejecting = false,
  });

  NurseDetailsState copyWith({
    NurseModel? nurse,
    List<DoctorDocumentModel>? documents,
    bool? isLoading,
    String? error,
    bool? isApproving,
    bool? isRejecting,
  }) {
    return NurseDetailsState(
      nurse: nurse ?? this.nurse,
      documents: documents ?? this.documents,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isApproving: isApproving ?? this.isApproving,
      isRejecting: isRejecting ?? this.isRejecting,
    );
  }
}

class NurseDetailsNotifier extends StateNotifier<NurseDetailsState> {
  final AdminRepository repository;

  NurseDetailsNotifier(this.repository) : super(NurseDetailsState());

  Future<void> fetchNurseDetails(String nurseId, {bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true, error: null);
    }
    final response = await repository.getNurseDetails(nurseId: nurseId);
    final documentsResponse =
        await repository.getNurseDocuments(nurseId: nurseId);
    if (response.success && response.data != null) {
      state = state.copyWith(
        nurse: response.data,
        documents: documentsResponse.data ?? [],
        isLoading: false,
        error: null,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: response.error ?? 'Failed to fetch nurse',
      );
    }
  }

  Future<bool> verifyDocument({
    required String nurseId,
    required String documentId,
  }) async {
    final response = await repository.verifyNurseDocument(
      nurseId: nurseId,
      documentId: documentId,
    );
    if (response.success) {
      if (response.data != null) {
        final docs = state.documents
            .map((d) => d.id == documentId ? response.data! : d)
            .toList();
        state = state.copyWith(documents: docs, error: null);
      }
      await fetchNurseDetails(nurseId, silent: true);
      return true;
    }
    state = state.copyWith(error: response.error ?? 'Failed to verify document');
    return false;
  }

  Future<bool> rejectDocument({
    required String nurseId,
    required String documentId,
    required String reason,
  }) async {
    final response = await repository.rejectNurseDocument(
      nurseId: nurseId,
      documentId: documentId,
      rejectionReason: reason,
    );
    if (response.success) {
      if (response.data != null) {
        final docs = state.documents
            .map((d) => d.id == documentId ? response.data! : d)
            .toList();
        state = state.copyWith(documents: docs, error: null);
      }
      await fetchNurseDetails(nurseId, silent: true);
      return true;
    }
    state = state.copyWith(error: response.error ?? 'Failed to reject document');
    return false;
  }

  Future<bool> approveNurse({required String nurseId, String? notes}) async {
    state = state.copyWith(isApproving: true, error: null);
    final response = await repository.approveNurse(
      nurseId: nurseId,
      approvalNotes: notes,
    );
    if (response.success && response.data != null) {
      state = state.copyWith(nurse: response.data, isApproving: false);
      return true;
    }
    state = state.copyWith(
      isApproving: false,
      error: response.error ?? 'Failed to approve nurse',
    );
    return false;
  }

  Future<bool> rejectNurse({
    required String nurseId,
    required String reason,
  }) async {
    state = state.copyWith(isRejecting: true, error: null);
    final response = await repository.rejectNurse(
      nurseId: nurseId,
      rejectionReason: reason,
    );
    if (response.success && response.data != null) {
      state = state.copyWith(nurse: response.data, isRejecting: false);
      return true;
    }
    state = state.copyWith(
      isRejecting: false,
      error: response.error ?? 'Failed to reject nurse',
    );
    return false;
  }
}

final nurseDetailsProvider =
    StateNotifierProvider.family<NurseDetailsNotifier, NurseDetailsState, String>(
  (ref, nurseId) {
    final notifier = NurseDetailsNotifier(ref.watch(adminRepositoryProvider));
    notifier.fetchNurseDetails(nurseId);
    return notifier;
  },
);
