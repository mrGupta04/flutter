import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/lab_model.dart';
import '../../../data/repositories/lab_registration_repository.dart';

final labDashboardRepositoryProvider = Provider(
  (ref) => LabRegistrationRepository(),
);

class LabDashboardState {
  const LabDashboardState({
    this.lab,
    this.isLoading = false,
    this.error,
  });

  final LabModel? lab;
  final bool isLoading;
  final String? error;

  int get todaysBookings => 0;

  int get upcomingBookings => 0;

  int get homeCollections => 0;

  int get pendingReports => 0;

  int get revenueInr => 0;

  int get testsCount {
    final tests = lab?.offeredTests ?? const [];
    return tests.where((t) => t.enabled).length;
  }

  int get packagesCount => 0;

  LabDashboardState copyWith({
    LabModel? lab,
    bool? isLoading,
    String? error,
  }) {
    return LabDashboardState(
      lab: lab ?? this.lab,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class LabDashboardNotifier extends StateNotifier<LabDashboardState> {
  LabDashboardNotifier(this.repository) : super(const LabDashboardState());

  final LabRegistrationRepository repository;

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, error: null);
    final response = await repository.getProfile();
    if (response.success && response.data != null) {
      state = state.copyWith(lab: response.data, isLoading: false);
    } else {
      state = state.copyWith(
        isLoading: false,
        error: response.error ?? 'Failed to load lab profile',
      );
    }
  }

  Future<void> refreshAll() => loadProfile();
}

final labDashboardProvider =
    StateNotifierProvider<LabDashboardNotifier, LabDashboardState>((ref) {
  return LabDashboardNotifier(ref.watch(labDashboardRepositoryProvider));
});
