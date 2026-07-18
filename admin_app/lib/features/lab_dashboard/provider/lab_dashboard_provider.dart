import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/token_storage.dart';
import '../../../data/models/api_response_model.dart';
import '../../../data/models/lab_model.dart';
import '../../../data/repositories/lab_registration_repository.dart';
import '../../../data/services/dio_service.dart';

final labDashboardRepositoryProvider = Provider(
  (ref) => LabRegistrationRepository(),
);

class LabBookingItem {
  const LabBookingItem({
    required this.id,
    required this.patientName,
    required this.label,
    required this.status,
    required this.paymentStatus,
    required this.amount,
    this.collectionType,
  });

  final String id;
  final String patientName;
  final String label;
  final String status;
  final String paymentStatus;
  final int amount;
  final String? collectionType;

  factory LabBookingItem.fromJson(Map<String, dynamic> json) {
    final items = json['items'] as List? ?? [];
    final names = items
        .map((e) => (e as Map)['testName']?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .join(', ');
    return LabBookingItem(
      id: json['id']?.toString() ?? '',
      patientName: json['patientName']?.toString() ?? 'Patient',
      label: names.isNotEmpty
          ? names
          : (json['timeSlot']?.toString() ?? 'Lab booking'),
      status: json['status']?.toString() ?? 'requested',
      paymentStatus: json['paymentStatus']?.toString() ?? 'pending',
      amount: (json['totalAmount'] as num?)?.toInt() ?? 0,
      collectionType: json['collectionType']?.toString(),
    );
  }
}

class LabDashboardState {
  const LabDashboardState({
    this.lab,
    this.bookings = const [],
    this.isLoading = false,
    this.error,
  });

  final LabModel? lab;
  final List<LabBookingItem> bookings;
  final bool isLoading;
  final String? error;

  int get todaysBookings => bookings
      .where((b) => b.status != 'cancelled' && b.status != 'rejected')
      .length;

  int get upcomingBookings => bookings
      .where((b) =>
          !['completed', 'cancelled', 'rejected', 'report_ready'].contains(b.status))
      .length;

  int get homeCollections =>
      bookings.where((b) => b.collectionType == 'home_collection').length;

  int get pendingReports => bookings
      .where((b) =>
          ['confirmed', 'sample_collected', 'processing'].contains(b.status))
      .length;

  int get revenueInr => bookings
      .where((b) => b.paymentStatus == 'paid')
      .fold(0, (sum, b) => sum + b.amount);

  int get testsCount {
    final tests = lab?.offeredTests ?? const [];
    return tests.where((t) => t.enabled).length;
  }

  int get packagesCount => 0;

  LabDashboardState copyWith({
    LabModel? lab,
    List<LabBookingItem>? bookings,
    bool? isLoading,
    String? error,
  }) {
    return LabDashboardState(
      lab: lab ?? this.lab,
      bookings: bookings ?? this.bookings,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class LabDashboardNotifier extends StateNotifier<LabDashboardState> {
  LabDashboardNotifier(this.repository) : super(const LabDashboardState());

  final LabRegistrationRepository repository;
  final _dio = DioService();

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, error: null);
    final response = await repository.getProfile();
    if (response.success && response.data != null) {
      state = state.copyWith(lab: response.data, isLoading: false);
      await loadBookings();
    } else {
      state = state.copyWith(
        isLoading: false,
        error: response.error ?? 'Failed to load lab profile',
      );
    }
  }

  Future<void> loadBookings() async {
    final labId = state.lab?.id ?? await TokenStorage.instance.getLabId();
    if (labId == null) return;
    try {
      final response = await _dio.get(
        AppConstants.endpointLabBookings,
        queryParameters: {'labId': labId},
      );
      final body = response.data as Map<String, dynamic>;
      final list = extractApiList(body['data']);
      final bookings = list
          .map((e) => LabBookingItem.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(bookings: bookings);
    } catch (_) {
      state = state.copyWith(bookings: const []);
    }
  }

  Future<bool> updateBookingStatus({
    required String bookingId,
    required String status,
  }) async {
    final labId = state.lab?.id ?? await TokenStorage.instance.getLabId();
    if (labId == null) return false;
    try {
      await _dio.post(
        '${AppConstants.endpointLabBookings}/$bookingId/status',
        data: {'labId': labId, 'status': status},
      );
      await loadBookings();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> refreshAll() async {
    await loadProfile();
  }
}

final labDashboardProvider =
    StateNotifierProvider<LabDashboardNotifier, LabDashboardState>((ref) {
  return LabDashboardNotifier(ref.watch(labDashboardRepositoryProvider));
});
