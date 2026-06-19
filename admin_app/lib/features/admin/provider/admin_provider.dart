import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/repositories.dart';
import '../presentation/utils/admin_documents_helper.dart';

/// Provider for AdminRepository
final adminRepositoryProvider = Provider((ref) {
  return AdminRepository();
});

/// State for admin doctors list
class AdminDoctorsListState {
  final List<DoctorModel> doctors;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int totalPages;
  final String? selectedStatus;

  AdminDoctorsListState({
    this.doctors = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.totalPages = 1,
    this.selectedStatus,
  });

  AdminDoctorsListState copyWith({
    List<DoctorModel>? doctors,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? totalPages,
    String? selectedStatus,
  }) {
    return AdminDoctorsListState(
      doctors: doctors ?? this.doctors,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      selectedStatus: selectedStatus ?? this.selectedStatus,
    );
  }
}

/// Notifier for admin doctors list
class AdminDoctorsListNotifier extends StateNotifier<AdminDoctorsListState> {
  final AdminRepository repository;

  AdminDoctorsListNotifier(this.repository) : super(AdminDoctorsListState());

  /// Fetch doctors for verification
  Future<void> fetchDoctors({
    int page = 1,
    String? status,
  }) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
    );

    try {
      final response = await repository.getDoctorsForVerification(
        page: page,
        status: status,
      );

      if (response.success && response.data != null) {
        state = state.copyWith(
          doctors: response.data!,
          isLoading: false,
          error: null,
          currentPage: page,
          selectedStatus: status,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.error ?? 'Failed to fetch doctors',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An error occurred',
      );
    }
  }

  /// Filter doctors by status
  void filterByStatus(String? status) {
    fetchDoctors(status: status);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for admin doctors list
final adminDoctorsListProvider =
    StateNotifierProvider<AdminDoctorsListNotifier, AdminDoctorsListState>((ref) {
  final repository = ref.watch(adminRepositoryProvider);
  return AdminDoctorsListNotifier(repository);
});

/// State for doctor details
class DoctorDetailsState {
  final DoctorModel? doctor;
  final List<DoctorDocumentModel> documents;
  final bool isLoading;
  final String? error;
  final bool isApproving;
  final bool isRejecting;

  DoctorDetailsState({
    this.doctor,
    this.documents = const [],
    this.isLoading = false,
    this.error,
    this.isApproving = false,
    this.isRejecting = false,
  });

  DoctorDetailsState copyWith({
    DoctorModel? doctor,
    List<DoctorDocumentModel>? documents,
    bool? isLoading,
    String? error,
    bool? isApproving,
    bool? isRejecting,
  }) {
    return DoctorDetailsState(
      doctor: doctor ?? this.doctor,
      documents: documents ?? this.documents,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isApproving: isApproving ?? this.isApproving,
      isRejecting: isRejecting ?? this.isRejecting,
    );
  }
}

/// Notifier for doctor details
class DoctorDetailsNotifier extends StateNotifier<DoctorDetailsState> {
  final AdminRepository repository;

  DoctorDetailsNotifier(this.repository) : super(DoctorDetailsState());

  /// Fetch doctor details
  Future<void> fetchDoctorDetails(String doctorId) async {
    if (doctorId.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        error: 'Invalid doctor id',
      );
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final doctorResponse = await repository.getDoctorDetails(doctorId: doctorId);
      final documentsResponse = await repository.getDoctorDocuments(doctorId: doctorId);

      if (doctorResponse.success && doctorResponse.data != null) {
        final doctor = doctorResponse.data!;
        final mergedDocuments = mergeAdminDocuments(
          doctor,
          documentsResponse.data ?? [],
        );
        state = state.copyWith(
          doctor: doctor,
          documents: mergedDocuments,
          isLoading: false,
          error: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: doctorResponse.error ?? 'Failed to fetch doctor details',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An error occurred',
      );
    }
  }

  /// Admin approval — publish doctor on user app
  Future<bool> approveDoctor({
    required String doctorId,
    String? notes,
  }) async {
    state = state.copyWith(isApproving: true, error: null);

    try {
      final response = await repository.approveDoctor(
        doctorId: doctorId,
        approvalNotes: notes,
      );

      if (response.success && response.data != null) {
        state = state.copyWith(
          doctor: response.data,
          isApproving: false,
          error: null,
        );
        await fetchDoctorDetails(doctorId);
        return true;
      } else {
        state = state.copyWith(
          isApproving: false,
          error: response.error ?? 'Failed to approve doctor',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isApproving: false,
        error: 'An error occurred',
      );
      return false;
    }
  }

  /// Reject doctor
  Future<bool> rejectDoctor({
    required String doctorId,
    required String reason,
  }) async {
    state = state.copyWith(isRejecting: true, error: null);

    try {
      final response = await repository.rejectDoctor(
        doctorId: doctorId,
        rejectionReason: reason,
      );

      if (response.success && response.data != null) {
        state = state.copyWith(
          doctor: response.data,
          isRejecting: false,
          error: null,
        );
        return true;
      } else {
        state = state.copyWith(
          isRejecting: false,
          error: response.error ?? 'Failed to reject doctor',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isRejecting: false,
        error: 'An error occurred',
      );
      return false;
    }
  }

  Future<bool> verifyDocument({
    required String doctorId,
    required String documentId,
    DocumentType? documentType,
  }) async {
    var resolvedId = documentId.trim();
    if (resolvedId.isEmpty) {
      resolvedId = await _resolveDocumentId(
        doctorId: doctorId,
        documentType: documentType,
      );
    }
    if (resolvedId.isEmpty) {
      state = state.copyWith(
        error: 'Document record not found. Pull to refresh and try again.',
      );
      return false;
    }

    final response = await repository.verifyDoctorDocument(
      doctorId: doctorId,
      documentId: resolvedId,
    );
    if (response.success) {
      await fetchDoctorDetails(doctorId);
      return true;
    }
    state = state.copyWith(error: response.error ?? 'Failed to verify document');
    return false;
  }

  Future<String> _resolveDocumentId({
    required String doctorId,
    DocumentType? documentType,
  }) async {
    if (documentType == null) return '';

    final existing = state.documents
        .where(
          (doc) =>
              doc.documentType == documentType &&
              doc.id != null &&
              doc.id!.isNotEmpty,
        )
        .map((doc) => doc.id!)
        .firstOrNull;
    if (existing != null) return existing;

    var doctor = state.doctor;
    if (doctor == null) {
      final doctorResponse =
          await repository.getDoctorDetails(doctorId: doctorId);
      if (!doctorResponse.success || doctorResponse.data == null) {
        return '';
      }
      doctor = doctorResponse.data;
      state = state.copyWith(doctor: doctor);
    }

    final documentsResponse =
        await repository.getDoctorDocuments(doctorId: doctorId);
    if (!documentsResponse.success) {
      return '';
    }

    final merged = mergeAdminDocuments(
      doctor!,
      documentsResponse.data ?? [],
    );
    state = state.copyWith(documents: merged);

    return merged
            .where(
              (doc) =>
                  doc.documentType == documentType &&
                  doc.id != null &&
                  doc.id!.isNotEmpty,
            )
            .map((doc) => doc.id!)
            .firstOrNull ??
        '';
  }

  Future<bool> rejectDocument({
    required String doctorId,
    required String documentId,
    required String reason,
    DocumentType? documentType,
  }) async {
    var resolvedId = documentId.trim();
    if (resolvedId.isEmpty) {
      resolvedId = await _resolveDocumentId(
        doctorId: doctorId,
        documentType: documentType,
      );
    }
    if (resolvedId.isEmpty) {
      state = state.copyWith(
        error: 'Document record not found. Pull to refresh and try again.',
      );
      return false;
    }

    final response = await repository.rejectDoctorDocument(
      doctorId: doctorId,
      documentId: resolvedId,
      rejectionReason: reason,
    );
    if (response.success) {
      await fetchDoctorDetails(doctorId);
      return true;
    }
    state = state.copyWith(error: response.error ?? 'Failed to reject document');
    return false;
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for doctor details (family-based with parameter)
final doctorDetailsProvider =
    StateNotifierProvider.family<DoctorDetailsNotifier, DoctorDetailsState, String>(
  (ref, doctorId) {
    final repository = ref.watch(adminRepositoryProvider);
    final notifier = DoctorDetailsNotifier(repository);
    // Automatically fetch details when created
    notifier.fetchDoctorDetails(doctorId);
    return notifier;
  },
);
