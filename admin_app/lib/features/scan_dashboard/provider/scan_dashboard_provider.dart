import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/scan_center_model.dart';
import '../../../data/repositories/scan_registration_repository.dart';

final scanDashboardRepositoryProvider = Provider(
  (ref) => ScanRegistrationRepository(),
);

class ScanDashboardState {
  const ScanDashboardState({
    this.center,
    this.isLoading = false,
    this.error,
  });

  final ScanCenterModel? center;
  final bool isLoading;
  final String? error;

  int get bookingsCount => 0;

  int get revenueInr => 0;

  int get activeOffersCount {
    final offers = center?.offers ?? const [];
    return offers.where((o) => o.isActiveNow).length;
  }

  int get servicesCount {
    final scans = center?.offeredScans ?? const [];
    return scans.where((s) => s.enabled).length;
  }

  ScanDashboardState copyWith({
    ScanCenterModel? center,
    bool? isLoading,
    String? error,
  }) {
    return ScanDashboardState(
      center: center ?? this.center,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ScanDashboardNotifier extends StateNotifier<ScanDashboardState> {
  ScanDashboardNotifier(this.repository) : super(const ScanDashboardState());

  final ScanRegistrationRepository repository;

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, error: null);
    final response = await repository.getProfile();
    if (response.success && response.data != null) {
      state = state.copyWith(center: response.data, isLoading: false);
    } else {
      state = state.copyWith(
        isLoading: false,
        error: response.error ?? 'Failed to load profile',
      );
    }
  }

  Future<void> refreshAll() => loadProfile();
}

final scanDashboardProvider =
    StateNotifierProvider<ScanDashboardNotifier, ScanDashboardState>((ref) {
  return ScanDashboardNotifier(ref.watch(scanDashboardRepositoryProvider));
});
