import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/token_storage.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../data/models/patient_booking_model.dart';
import '../../../data/repositories/patient_dashboard_repository.dart';
import '../../user_auth/provider/patient_auth_provider.dart';

final patientDashboardRepositoryProvider = Provider(
  (ref) => PatientDashboardRepository(),
);

class PatientDashboardState {
  const PatientDashboardState({
    this.bookings = const [],
    this.historyBookings = const [],
    this.stats = const PatientBookingStats(total: 0, upcoming: 0, past: 0),
    this.historyPagination = const BookingListPagination(),
    this.isLoadingBookings = false,
    this.isLoadingHistory = false,
    this.isLoadingMoreHistory = false,
    this.isSavingProfile = false,
    this.error,
    this.historyError,
  });

  final List<PatientBookingModel> bookings;
  final List<PatientBookingModel> historyBookings;
  final PatientBookingStats stats;
  final BookingListPagination historyPagination;
  final bool isLoadingBookings;
  final bool isLoadingHistory;
  final bool isLoadingMoreHistory;
  final bool isSavingProfile;
  final String? error;
  final String? historyError;

  List<PatientBookingModel> get upcomingBookings {
    final list = bookings.where((b) => b.isActiveOrUpcoming).toList();
    list.sort((a, b) {
      final payA = a.needsHomeVisitPayment ? 0 : 1;
      final payB = b.needsHomeVisitPayment ? 0 : 1;
      if (payA != payB) return payA - payB;
      final liveA = a.isLiveNow ? 0 : 1;
      final liveB = b.isLiveNow ? 0 : 1;
      if (liveA != liveB) return liveA - liveB;
      return a.slotStart.compareTo(b.slotStart);
    });
    return list;
  }

  List<PatientBookingModel> get activeBookings =>
      upcomingBookings.where((b) => b.isLiveNow).toList();

  List<PatientBookingModel> get pendingBookings =>
      upcomingBookings.where((b) => b.isPendingRequest).toList();

  List<PatientBookingModel> get upcomingConfirmedBookings =>
      upcomingBookings
          .where((b) => !b.isLiveNow && !b.isPendingRequest)
          .toList();

  List<PatientBookingModel> get pastBookings => historyBookings;

  PatientBookingModel? get nextUpcoming {
    final list = upcomingConfirmedBookings;
    if (list.isEmpty) return upcomingBookings.isEmpty ? null : upcomingBookings.first;
    return list.first;
  }

  PatientBookingModel? get emergencyActive {
    for (final booking in activeBookings) {
      if (booking.serviceType == 'ambulance') return booking;
    }
    return activeBookings.isEmpty ? null : activeBookings.first;
  }

  List<PatientBookingModel> filterByCategory(
    List<PatientBookingModel> list,
    PatientBookingCategory category,
  ) =>
      list.where((b) => category.matches(b)).toList();

  PatientDashboardState copyWith({
    List<PatientBookingModel>? bookings,
    List<PatientBookingModel>? historyBookings,
    PatientBookingStats? stats,
    BookingListPagination? historyPagination,
    bool? isLoadingBookings,
    bool? isLoadingHistory,
    bool? isLoadingMoreHistory,
    bool? isSavingProfile,
    String? error,
    String? historyError,
    bool clearError = false,
    bool clearHistoryError = false,
  }) {
    return PatientDashboardState(
      bookings: bookings ?? this.bookings,
      historyBookings: historyBookings ?? this.historyBookings,
      stats: stats ?? this.stats,
      historyPagination: historyPagination ?? this.historyPagination,
      isLoadingBookings: isLoadingBookings ?? this.isLoadingBookings,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      isLoadingMoreHistory: isLoadingMoreHistory ?? this.isLoadingMoreHistory,
      isSavingProfile: isSavingProfile ?? this.isSavingProfile,
      error: clearError ? null : (error ?? this.error),
      historyError: clearHistoryError ? null : (historyError ?? this.historyError),
    );
  }
}

class PatientDashboardNotifier extends StateNotifier<PatientDashboardState> {
  PatientDashboardNotifier(this._repo, this._ref)
      : super(const PatientDashboardState());

  final PatientDashboardRepository _repo;
  final Ref _ref;

  Future<void> loadBookings() async {
    final auth = _ref.read(patientAuthProvider);
    if (!auth.isInitialized) {
      await _ref.read(patientAuthProvider.notifier).initialize();
    }

    final hasSession = _ref.read(patientAuthProvider).isLoggedIn ||
        await TokenStorage.instance.isPatientLoggedIn();
    if (!hasSession) {
      state = state.copyWith(
        bookings: const [],
        stats: const PatientBookingStats(total: 0, upcoming: 0, past: 0),
        isLoadingBookings: false,
        error: 'Please sign in to view your bookings.',
      );
      return;
    }

    state = state.copyWith(isLoadingBookings: true, clearError: true);
    try {
      final res = await _repo.fetchBookings(scope: 'current', limit: 50);
      state = state.copyWith(
        bookings: res.bookings,
        stats: res.stats,
        isLoadingBookings: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingBookings: false,
        error: friendlyErrorMessage(e),
      );
    }
  }

  Future<void> loadHistory({
    bool refresh = true,
    String status = 'all',
    String? q,
    PatientBookingCategory? service,
  }) async {
    final page = refresh ? 1 : state.historyPagination.page + 1;
    if (!refresh && (!state.historyPagination.hasMore || state.isLoadingMoreHistory)) {
      return;
    }
    state = state.copyWith(
      isLoadingHistory: refresh,
      isLoadingMoreHistory: !refresh,
      clearHistoryError: true,
    );
    try {
      final res = await _repo.fetchBookings(
        scope: 'history',
        page: page,
        limit: 20,
        status: status,
        q: q,
        service: service,
      );
      state = state.copyWith(
        historyBookings: refresh
            ? res.bookings
            : [...state.historyBookings, ...res.bookings],
        stats: res.stats,
        historyPagination: res.pagination,
        isLoadingHistory: false,
        isLoadingMoreHistory: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingHistory: false,
        isLoadingMoreHistory: false,
        historyError: friendlyErrorMessage(e),
      );
    }
  }

  PatientBookingModel? bookingById(String id) {
    for (final item in state.bookings) {
      if (item.id == id) return item;
    }
    for (final item in state.historyBookings) {
      if (item.id == id) return item;
    }
    return null;
  }

  Future<PatientBookingModel?> loadBookingById(String id) async {
    final existing = bookingById(id);
    if (existing != null) return existing;
    return _repo.fetchBookingById(id);
  }

  Future<bool> refreshAll() async {
    await _ref.read(patientAuthProvider.notifier).initialize();
    await loadBookings();
    return state.error == null;
  }

  Future<bool> updateProfile({
    required String firstName,
    String? lastName,
    required String email,
    required String mobileNumber,
    required int age,
    required String gender,
    String? aadhaarNumber,
    String? password,
    Uint8List? profilePictureBytes,
    String? profilePictureFileName,
    Uint8List? aadhaarCardBytes,
    String? aadhaarCardFileName,
    String? dateOfBirth,
    String? bloodGroup,
    String? addressLine,
    String? city,
    String? addressState,
    String? pincode,
    bool removeProfilePicture = false,
  }) async {
    state = state.copyWith(isSavingProfile: true, clearError: true);
    try {
      final user = await _repo.updateProfile(
        firstName: firstName,
        lastName: lastName,
        email: email,
        mobileNumber: mobileNumber,
        age: age,
        gender: gender,
        aadhaarNumber: aadhaarNumber,
        password: password,
        profilePictureBytes: profilePictureBytes,
        profilePictureFileName: profilePictureFileName,
        aadhaarCardBytes: aadhaarCardBytes,
        aadhaarCardFileName: aadhaarCardFileName,
        dateOfBirth: dateOfBirth,
        bloodGroup: bloodGroup,
        addressLine: addressLine,
        city: city,
        addressState: addressState,
        pincode: pincode,
        removeProfilePicture: removeProfilePicture,
      );

      final token = await TokenStorage.instance.getPatientToken();
      if (token != null) {
        await TokenStorage.instance.savePatientSession(
          token: token,
          patientId: user.id,
          email: user.email,
          displayName: user.fullName,
          mobileNumber: user.mobileNumber,
          profilePicture: user.profilePicture,
          gender: user.gender,
          age: user.age,
        );
      }

      _ref.read(patientAuthProvider.notifier).setUser(user);
      state = state.copyWith(isSavingProfile: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSavingProfile: false,
        error: friendlyErrorMessage(e),
      );
      return false;
    }
  }
}

final patientDashboardProvider =
    StateNotifierProvider<PatientDashboardNotifier, PatientDashboardState>(
  (ref) {
    return PatientDashboardNotifier(
      ref.watch(patientDashboardRepositoryProvider),
      ref,
    );
  },
);
