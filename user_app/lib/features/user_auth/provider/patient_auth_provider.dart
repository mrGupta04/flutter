import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/token_storage.dart';
import '../../../data/models/patient_user_model.dart';
import '../../../data/repositories/patient_auth_repository.dart';

final patientAuthRepositoryProvider = Provider(
  (ref) => PatientAuthRepository(),
);

class PatientAuthState {
  const PatientAuthState({
    this.user,
    this.isLoading = false,
    this.isInitialized = false,
    this.error,
  });

  final PatientUserModel? user;
  final bool isLoading;
  final bool isInitialized;
  final String? error;

  bool get isLoggedIn => user != null;

  PatientAuthState copyWith({
    PatientUserModel? user,
    bool? isLoading,
    bool? isInitialized,
    String? error,
    bool clearUser = false,
  }) {
    return PatientAuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      error: error,
    );
  }
}

class PatientAuthNotifier extends StateNotifier<PatientAuthState> {
  PatientAuthNotifier(this._repo) : super(const PatientAuthState());

  final PatientAuthRepository _repo;

  Future<void> initialize() async {
    if (state.isInitialized) return;
    final loggedIn = await TokenStorage.instance.isPatientLoggedIn();
    if (!loggedIn) {
      state = state.copyWith(isInitialized: true, clearUser: true);
      return;
    }

    final profileRes = await _repo.fetchProfile();
    if (profileRes.success && profileRes.data != null) {
      state = PatientAuthState(
        isInitialized: true,
        user: profileRes.data,
      );
      return;
    }

    final id = await TokenStorage.instance.getPatientId();
    final name = await TokenStorage.instance.getPatientName();
    final email = await TokenStorage.instance.getPatientEmail();
    final mobile = await TokenStorage.instance.getPatientMobile();
    final profilePicture =
        await TokenStorage.instance.getPatientProfilePicture();
    final gender = await TokenStorage.instance.getPatientGender();
    final age = await TokenStorage.instance.getPatientAge();

    if (id != null) {
      final parts = (name ?? '').split(' ');
      state = PatientAuthState(
        isInitialized: true,
        user: PatientUserModel(
          id: id,
          firstName: parts.isNotEmpty ? parts.first : 'User',
          lastName: parts.length > 1 ? parts.sublist(1).join(' ') : null,
          email: email ?? '',
          mobileNumber: mobile ?? '',
          profilePicture: profilePicture,
          gender: gender,
          age: age,
        ),
      );
    } else {
      state = state.copyWith(isInitialized: true, clearUser: true);
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final res = await _repo.login(email: email, password: password);
    if (res.success && res.data != null) {
      state = PatientAuthState(
        isInitialized: true,
        user: res.data,
        isLoading: false,
      );
      return true;
    }
    state = state.copyWith(
      isLoading: false,
      error: res.error ?? 'Login failed',
    );
    return false;
  }

  Future<bool> register({
    required String firstName,
    String? lastName,
    required String email,
    required String mobileNumber,
    required String password,
    required int age,
    required String gender,
    required String aadhaarNumber,
    required List<int> profilePictureBytes,
    required String profilePictureFileName,
    required List<int> aadhaarCardBytes,
    required String aadhaarCardFileName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final res = await _repo.register(
      firstName: firstName,
      lastName: lastName,
      email: email,
      mobileNumber: mobileNumber,
      password: password,
      age: age,
      gender: gender,
      aadhaarNumber: aadhaarNumber,
      profilePictureBytes: Uint8List.fromList(profilePictureBytes),
      profilePictureFileName: profilePictureFileName,
      aadhaarCardBytes: Uint8List.fromList(aadhaarCardBytes),
      aadhaarCardFileName: aadhaarCardFileName,
    );
    if (res.success && res.data != null) {
      state = PatientAuthState(
        isInitialized: true,
        user: res.data,
        isLoading: false,
      );
      return true;
    }
    state = state.copyWith(
      isLoading: false,
      error: res.error ?? 'Registration failed',
    );
    return false;
  }

  void setUser(PatientUserModel user) {
    state = PatientAuthState(
      isInitialized: true,
      user: user,
    );
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const PatientAuthState(isInitialized: true);
  }
}

final patientAuthProvider =
    StateNotifierProvider<PatientAuthNotifier, PatientAuthState>((ref) {
  final notifier = PatientAuthNotifier(ref.watch(patientAuthRepositoryProvider));
  notifier.initialize();
  return notifier;
});
