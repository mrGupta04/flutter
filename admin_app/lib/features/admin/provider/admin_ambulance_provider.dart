import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/ambulance_model.dart';
import '../../../data/models/doctor_document_model.dart';
import '../../../data/repositories/admin_repository.dart';
import 'admin_provider.dart';

class AdminAmbulancesListState {
  final List<AmbulanceModel> ambulances;
  final bool isLoading;
  final String? error;
  final String? selectedStatus;

  AdminAmbulancesListState({
    this.ambulances = const [],
    this.isLoading = false,
    this.error,
    this.selectedStatus,
  });

  AdminAmbulancesListState copyWith({
    List<AmbulanceModel>? ambulances,
    bool? isLoading,
    String? error,
    String? selectedStatus,
  }) {
    return AdminAmbulancesListState(
      ambulances: ambulances ?? this.ambulances,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedStatus: selectedStatus ?? this.selectedStatus,
    );
  }
}

class AdminAmbulancesListNotifier
    extends StateNotifier<AdminAmbulancesListState> {
  final AdminRepository repository;

  AdminAmbulancesListNotifier(this.repository)
      : super(AdminAmbulancesListState());

  Future<void> fetchAmbulances({int page = 1, String? status}) async {
    state = state.copyWith(isLoading: true, error: null);
    final response = await repository.getAmbulancesForVerification(
      page: page,
      status: status,
    );
    if (response.success && response.data != null) {
      state = state.copyWith(
        ambulances: response.data!,
        isLoading: false,
        selectedStatus: status,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: response.error ?? 'Failed to fetch ambulances',
      );
    }
  }

  void filterByStatus(String? status) => fetchAmbulances(status: status);
}

final adminAmbulancesListProvider = StateNotifierProvider<
    AdminAmbulancesListNotifier, AdminAmbulancesListState>((ref) {
  return AdminAmbulancesListNotifier(ref.watch(adminRepositoryProvider));
});

class AmbulanceDetailsState {
  final AmbulanceModel? ambulance;
  final List<DoctorDocumentModel> documents;
  final bool isLoading;
  final String? error;
  final bool isApproving;
  final bool isRejecting;

  AmbulanceDetailsState({
    this.ambulance,
    this.documents = const [],
    this.isLoading = false,
    this.error,
    this.isApproving = false,
    this.isRejecting = false,
  });

  AmbulanceDetailsState copyWith({
    AmbulanceModel? ambulance,
    List<DoctorDocumentModel>? documents,
    bool? isLoading,
    String? error,
    bool? isApproving,
    bool? isRejecting,
  }) {
    return AmbulanceDetailsState(
      ambulance: ambulance ?? this.ambulance,
      documents: documents ?? this.documents,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isApproving: isApproving ?? this.isApproving,
      isRejecting: isRejecting ?? this.isRejecting,
    );
  }
}

class AmbulanceDetailsNotifier extends StateNotifier<AmbulanceDetailsState> {
  final AdminRepository repository;

  AmbulanceDetailsNotifier(this.repository) : super(AmbulanceDetailsState());

  Future<void> fetchAmbulanceDetails(String ambulanceId) async {
    state = state.copyWith(isLoading: true, error: null);
    final response =
        await repository.getAmbulanceDetails(ambulanceId: ambulanceId);
    final documentsResponse =
        await repository.getAmbulanceDocuments(ambulanceId: ambulanceId);
    if (response.success && response.data != null) {
      state = state.copyWith(
        ambulance: response.data,
        documents: documentsResponse.data ?? [],
        isLoading: false,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: response.error ?? 'Failed to fetch ambulance',
      );
    }
  }

  Future<bool> verifyDocument({
    required String ambulanceId,
    required String documentId,
  }) async {
    final response = await repository.verifyAmbulanceDocument(
      ambulanceId: ambulanceId,
      documentId: documentId,
    );
    if (response.success) {
      await fetchAmbulanceDetails(ambulanceId);
      return true;
    }
    state = state.copyWith(error: response.error ?? 'Failed to verify document');
    return false;
  }

  Future<bool> rejectDocument({
    required String ambulanceId,
    required String documentId,
    required String reason,
  }) async {
    final response = await repository.rejectAmbulanceDocument(
      ambulanceId: ambulanceId,
      documentId: documentId,
      rejectionReason: reason,
    );
    if (response.success) {
      await fetchAmbulanceDetails(ambulanceId);
      return true;
    }
    state = state.copyWith(error: response.error ?? 'Failed to reject document');
    return false;
  }

  Future<bool> approveAmbulance({
    required String ambulanceId,
    String? notes,
  }) async {
    state = state.copyWith(isApproving: true, error: null);
    final response = await repository.approveAmbulance(
      ambulanceId: ambulanceId,
      approvalNotes: notes,
    );
    if (response.success && response.data != null) {
      state = state.copyWith(ambulance: response.data, isApproving: false);
      return true;
    }
    state = state.copyWith(
      isApproving: false,
      error: response.error ?? 'Failed to approve ambulance',
    );
    return false;
  }

  Future<bool> rejectAmbulance({
    required String ambulanceId,
    required String reason,
  }) async {
    state = state.copyWith(isRejecting: true, error: null);
    final response = await repository.rejectAmbulance(
      ambulanceId: ambulanceId,
      rejectionReason: reason,
    );
    if (response.success && response.data != null) {
      state = state.copyWith(ambulance: response.data, isRejecting: false);
      return true;
    }
    state = state.copyWith(
      isRejecting: false,
      error: response.error ?? 'Failed to reject ambulance',
    );
    return false;
  }
}

final ambulanceDetailsProvider = StateNotifierProvider.family<
    AmbulanceDetailsNotifier, AmbulanceDetailsState, String>((ref, ambulanceId) {
  final notifier = AmbulanceDetailsNotifier(ref.watch(adminRepositoryProvider));
  notifier.fetchAmbulanceDetails(ambulanceId);
  return notifier;
});
