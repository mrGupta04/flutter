import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/token_storage.dart';
import '../../../data/models/patient_booking_model.dart';
import '../../../data/repositories/patient_dashboard_repository.dart';
import '../../user_auth/provider/patient_auth_provider.dart';

final patientDashboardRepositoryProvider = Provider(
  (ref) => PatientDashboardRepository(),
);

class PatientDashboardState {
  const PatientDashboardState({
    this.bookings = const [],
    this.stats = const PatientBookingStats(total: 0, upcoming: 0, past: 0),
    this.isLoadingBookings = false,
    this.isSavingProfile = false,
    this.error,
  });

  final List<PatientBookingModel> bookings;
  final PatientBookingStats stats;
  final bool isLoadingBookings;
  final bool isSavingProfile;
  final String? error;

  List<PatientBookingModel> get upcomingBookings =>
      bookings.where((b) => b.isActiveOrUpcoming).toList();

  List<PatientBookingModel> get pastBookings =>
      bookings.where((b) => !b.isActiveOrUpcoming).toList();

  List<PatientBookingModel> filterByCategory(
    List<PatientBookingModel> list,
    PatientBookingCategory category,
  ) =>
      list.where((b) => category.matches(b)).toList();

  PatientDashboardState copyWith({
    List<PatientBookingModel>? bookings,
    PatientBookingStats? stats,
    bool? isLoadingBookings,
    bool? isSavingProfile,
    String? error,
    bool clearError = false,
  }) {
    return PatientDashboardState(
      bookings: bookings ?? this.bookings,
      stats: stats ?? this.stats,
      isLoadingBookings: isLoadingBookings ?? this.isLoadingBookings,
      isSavingProfile: isSavingProfile ?? this.isSavingProfile,
      error: clearError ? null : (error ?? this.error),
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
      final res = await _repo.fetchBookings();
      state = state.copyWith(
        bookings: res.bookings,
        stats: res.stats,
        isLoadingBookings: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingBookings: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
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
        error: e.toString(),
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
