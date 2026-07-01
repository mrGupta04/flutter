import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/blood_bank_model.dart';
import '../../../data/repositories/blood_bank_registration_repository.dart';

final bloodBankDashboardRepositoryProvider = Provider(
  (ref) => BloodBankRegistrationRepository(),
);

class BloodBankDashboardState {
  const BloodBankDashboardState({
    this.bloodBank,
    this.stats,
    this.orders = const [],
    this.emergencyRequests = const [],
    this.isLoading = false,
    this.error,
  });

  final BloodBankModel? bloodBank;
  final Map<String, dynamic>? stats;
  final List<Map<String, dynamic>> orders;
  final List<Map<String, dynamic>> emergencyRequests;
  final bool isLoading;
  final String? error;

  int get totalOrders => (stats?['totalOrders'] as num?)?.toInt() ?? 0;
  int get pendingOrders => (stats?['pendingOrders'] as num?)?.toInt() ?? 0;
  int get completedOrders => (stats?['completedOrders'] as num?)?.toInt() ?? 0;
  int get emergencyCount => (stats?['emergencyRequests'] as num?)?.toInt() ?? 0;
  int get todayOrders => (stats?['todayOrders'] as num?)?.toInt() ?? 0;
  int get revenue => (stats?['revenue'] as num?)?.toInt() ?? 0;
  int get activeOffers => (stats?['activeOffers'] as num?)?.toInt() ?? 0;

  BloodBankDashboardState copyWith({
    BloodBankModel? bloodBank,
    Map<String, dynamic>? stats,
    List<Map<String, dynamic>>? orders,
    List<Map<String, dynamic>>? emergencyRequests,
    bool? isLoading,
    String? error,
  }) {
    return BloodBankDashboardState(
      bloodBank: bloodBank ?? this.bloodBank,
      stats: stats ?? this.stats,
      orders: orders ?? this.orders,
      emergencyRequests: emergencyRequests ?? this.emergencyRequests,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class BloodBankDashboardNotifier extends StateNotifier<BloodBankDashboardState> {
  BloodBankDashboardNotifier(this.repository) : super(const BloodBankDashboardState());

  final BloodBankRegistrationRepository repository;

  Future<void> refreshAll() async {
    state = state.copyWith(isLoading: true, error: null);
    final profile = await repository.getProfile();
    final dashboard = await repository.getDashboard();
    final bookings = await repository.getBookings();
    final emergencies = await repository.getEmergencyRequests();

    if (profile.success && profile.data != null) {
      state = state.copyWith(
        bloodBank: profile.data,
        stats: dashboard.data,
        orders: bookings.data ?? const [],
        emergencyRequests: emergencies.data ?? const [],
        isLoading: false,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: profile.error ?? 'Failed to load dashboard',
      );
    }
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await repository.updateOrderStatus(orderId, status);
    await refreshAll();
  }

  Future<void> acceptEmergency(String requestId) async {
    await repository.acceptEmergencyRequest(requestId);
    await refreshAll();
  }
}

final bloodBankDashboardProvider =
    StateNotifierProvider<BloodBankDashboardNotifier, BloodBankDashboardState>(
        (ref) {
  return BloodBankDashboardNotifier(ref.watch(bloodBankDashboardRepositoryProvider));
});
