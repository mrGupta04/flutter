import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/token_storage.dart';
import '../../../data/models/api_response_model.dart';
import '../../../data/models/scan_center_model.dart';
import '../../../data/repositories/scan_registration_repository.dart';
import '../../../data/services/dio_service.dart';

final scanDashboardRepositoryProvider = Provider(
  (ref) => ScanRegistrationRepository(),
);

class ScanBookingItem {
  const ScanBookingItem({
    required this.id,
    required this.patientName,
    required this.label,
    required this.status,
    required this.paymentStatus,
    required this.amount,
  });

  final String id;
  final String patientName;
  final String label;
  final String status;
  final String paymentStatus;
  final int amount;

  factory ScanBookingItem.fromJson(Map<String, dynamic> json) {
    return ScanBookingItem(
      id: json['id']?.toString() ?? '',
      patientName: json['patientName']?.toString() ?? 'Patient',
      label: json['scanName']?.toString() ??
          json['timeSlot']?.toString() ??
          'Scan booking',
      status: json['status']?.toString() ?? 'requested',
      paymentStatus: json['paymentStatus']?.toString() ?? 'pending',
      amount: (json['totalAmount'] as num?)?.toInt() ?? 0,
    );
  }
}

class ScanDashboardState {
  const ScanDashboardState({
    this.center,
    this.bookings = const [],
    this.isLoading = false,
    this.error,
  });

  final ScanCenterModel? center;
  final List<ScanBookingItem> bookings;
  final bool isLoading;
  final String? error;

  int get bookingsCount => bookings
      .where((b) => b.status != 'cancelled' && b.status != 'rejected')
      .length;

  int get openBookings => bookings
      .where((b) =>
          !['completed', 'cancelled', 'rejected', 'report_ready'].contains(b.status))
      .length;

  int get revenueInr => bookings
      .where((b) => b.paymentStatus == 'paid')
      .fold(0, (sum, b) => sum + b.amount);

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
    List<ScanBookingItem>? bookings,
    bool? isLoading,
    String? error,
  }) {
    return ScanDashboardState(
      center: center ?? this.center,
      bookings: bookings ?? this.bookings,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ScanDashboardNotifier extends StateNotifier<ScanDashboardState> {
  ScanDashboardNotifier(this.repository) : super(const ScanDashboardState());

  final ScanRegistrationRepository repository;
  final _dio = DioService();

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, error: null);
    final response = await repository.getProfile();
    if (response.success && response.data != null) {
      state = state.copyWith(center: response.data, isLoading: false);
      await loadBookings();
    } else {
      state = state.copyWith(
        isLoading: false,
        error: response.error ?? 'Failed to load profile',
      );
    }
  }

  Future<void> loadBookings() async {
    final scanCenterId =
        state.center?.id ?? await TokenStorage.instance.getScanCenterId();
    if (scanCenterId == null) return;
    try {
      final response = await _dio.get(
        AppConstants.endpointScanBookings,
        queryParameters: {'scanCenterId': scanCenterId},
      );
      final body = response.data as Map<String, dynamic>;
      final list = extractApiList(body['data']);
      final bookings = list
          .map((e) => ScanBookingItem.fromJson(e as Map<String, dynamic>))
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
    final scanCenterId =
        state.center?.id ?? await TokenStorage.instance.getScanCenterId();
    if (scanCenterId == null) return false;
    try {
      await _dio.post(
        '${AppConstants.endpointScanBookings}/$bookingId/status',
        data: {'scanCenterId': scanCenterId, 'status': status},
      );
      await loadBookings();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> refreshAll() => loadProfile();
}

final scanDashboardProvider =
    StateNotifierProvider<ScanDashboardNotifier, ScanDashboardState>((ref) {
  return ScanDashboardNotifier(ref.watch(scanDashboardRepositoryProvider));
});
