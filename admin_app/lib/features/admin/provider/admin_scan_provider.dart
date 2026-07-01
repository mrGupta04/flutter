import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/scan_center_model.dart';
import '../../../data/repositories/admin_repository.dart';
import 'admin_provider.dart';

class AdminScanCentersListState {
  const AdminScanCentersListState({
    this.centers = const [],
    this.isLoading = false,
    this.error,
    this.selectedStatus,
  });

  final List<ScanCenterModel> centers;
  final bool isLoading;
  final String? error;
  final String? selectedStatus;

  AdminScanCentersListState copyWith({
    List<ScanCenterModel>? centers,
    bool? isLoading,
    String? error,
    String? selectedStatus,
  }) {
    return AdminScanCentersListState(
      centers: centers ?? this.centers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedStatus: selectedStatus ?? this.selectedStatus,
    );
  }
}

class AdminScanCentersListNotifier extends StateNotifier<AdminScanCentersListState> {
  AdminScanCentersListNotifier(this.repository)
      : super(const AdminScanCentersListState());

  final AdminRepository repository;

  Future<void> fetchScanCenters({int page = 1, String? status}) async {
    state = state.copyWith(isLoading: true, error: null);
    final response =
        await repository.getScanCentersForVerification(page: page, status: status);
    if (response.success && response.data != null) {
      state = state.copyWith(
        centers: response.data!,
        isLoading: false,
        selectedStatus: status,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: response.error ?? 'Failed to fetch scan centers',
      );
    }
  }

  void filterByStatus(String? status) => fetchScanCenters(status: status);
}

final adminScanCentersListProvider =
    StateNotifierProvider<AdminScanCentersListNotifier, AdminScanCentersListState>(
  (ref) {
    return AdminScanCentersListNotifier(ref.watch(adminRepositoryProvider));
  },
);

class ScanCenterDetailsState {
  const ScanCenterDetailsState({
    this.center,
    this.isLoading = false,
    this.error,
    this.isApproving = false,
    this.isRejecting = false,
    this.isSuspending = false,
    this.isRequestingDocs = false,
  });

  final ScanCenterModel? center;
  final bool isLoading;
  final String? error;
  final bool isApproving;
  final bool isRejecting;
  final bool isSuspending;
  final bool isRequestingDocs;

  ScanCenterDetailsState copyWith({
    ScanCenterModel? center,
    bool? isLoading,
    String? error,
    bool? isApproving,
    bool? isRejecting,
    bool? isSuspending,
    bool? isRequestingDocs,
  }) {
    return ScanCenterDetailsState(
      center: center ?? this.center,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isApproving: isApproving ?? this.isApproving,
      isRejecting: isRejecting ?? this.isRejecting,
      isSuspending: isSuspending ?? this.isSuspending,
      isRequestingDocs: isRequestingDocs ?? this.isRequestingDocs,
    );
  }
}

class ScanCenterDetailsNotifier extends StateNotifier<ScanCenterDetailsState> {
  ScanCenterDetailsNotifier(this.repository) : super(const ScanCenterDetailsState());

  final AdminRepository repository;

  Future<void> fetchScanCenterDetails(String scanCenterId) async {
    state = state.copyWith(isLoading: true, error: null);
    final response =
        await repository.getScanCenterDetails(scanCenterId: scanCenterId);
    if (response.success && response.data != null) {
      state = state.copyWith(center: response.data, isLoading: false);
    } else {
      state = state.copyWith(
        isLoading: false,
        error: response.error ?? 'Failed to fetch scan center',
      );
    }
  }

  Future<bool> approveScanCenter({
    required String scanCenterId,
    String? notes,
  }) async {
    state = state.copyWith(isApproving: true, error: null);
    final response = await repository.approveScanCenter(
      scanCenterId: scanCenterId,
      approvalNotes: notes,
    );
    if (response.success && response.data != null) {
      state = state.copyWith(center: response.data, isApproving: false);
      return true;
    }
    state = state.copyWith(
      isApproving: false,
      error: response.error ?? 'Failed to approve scan center',
    );
    return false;
  }

  Future<bool> rejectScanCenter({
    required String scanCenterId,
    required String reason,
  }) async {
    state = state.copyWith(isRejecting: true, error: null);
    final response = await repository.rejectScanCenter(
      scanCenterId: scanCenterId,
      rejectionReason: reason,
    );
    if (response.success && response.data != null) {
      state = state.copyWith(center: response.data, isRejecting: false);
      return true;
    }
    state = state.copyWith(
      isRejecting: false,
      error: response.error ?? 'Failed to reject scan center',
    );
    return false;
  }

  Future<bool> suspendScanCenter({
    required String scanCenterId,
    String? reason,
  }) async {
    state = state.copyWith(isSuspending: true, error: null);
    final response = await repository.suspendScanCenter(
      scanCenterId: scanCenterId,
      reason: reason,
    );
    if (response.success && response.data != null) {
      state = state.copyWith(center: response.data, isSuspending: false);
      return true;
    }
    state = state.copyWith(
      isSuspending: false,
      error: response.error ?? 'Failed to suspend scan center',
    );
    return false;
  }

  Future<bool> requestDocuments({
    required String scanCenterId,
    required String note,
  }) async {
    state = state.copyWith(isRequestingDocs: true, error: null);
    final response = await repository.requestScanCenterDocuments(
      scanCenterId: scanCenterId,
      note: note,
    );
    if (response.success && response.data != null) {
      state = state.copyWith(center: response.data, isRequestingDocs: false);
      return true;
    }
    state = state.copyWith(
      isRequestingDocs: false,
      error: response.error ?? 'Failed to request documents',
    );
    return false;
  }
}

final scanCenterDetailsProvider = StateNotifierProvider.family<
    ScanCenterDetailsNotifier, ScanCenterDetailsState, String>(
  (ref, scanCenterId) {
    final notifier = ScanCenterDetailsNotifier(ref.watch(adminRepositoryProvider));
    notifier.fetchScanCenterDetails(scanCenterId);
    return notifier;
  },
);
