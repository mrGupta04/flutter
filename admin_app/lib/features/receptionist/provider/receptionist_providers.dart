import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/token_storage.dart';
import '../../../data/models/receptionist_model.dart';
import '../../../data/repositories/receptionist_repository.dart';

final receptionistRepositoryProvider = Provider<ReceptionistRepository>(
  (ref) => ReceptionistRepository(),
);

class ReceptionistAuthState {
  const ReceptionistAuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.profile,
    this.error,
  });

  final bool isLoading;
  final bool isAuthenticated;
  final ReceptionistModel? profile;
  final String? error;

  ReceptionistAuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    ReceptionistModel? profile,
    String? error,
  }) {
    return ReceptionistAuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      profile: profile ?? this.profile,
      error: error,
    );
  }
}

class ReceptionistAuthNotifier extends StateNotifier<ReceptionistAuthState> {
  ReceptionistAuthNotifier(this._repository) : super(const ReceptionistAuthState()) {
    _restore();
  }

  final ReceptionistRepository _repository;

  Future<void> _restore() async {
    final type = await TokenStorage.instance.getProviderType();
    final token = await TokenStorage.instance.getToken();
    if (type != 'receptionist' || token == null || token.isEmpty) return;
    state = state.copyWith(isAuthenticated: true, isLoading: true);
    final res = await _repository.me();
    if (res.success && res.data != null) {
      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        profile: res.data,
      );
    } else {
      await logout();
    }
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, error: null);
    final res = await _repository.login(email: email, password: password);
    if (res.success && res.data != null) {
      state = ReceptionistAuthState(
        isAuthenticated: true,
        profile: res.data,
      );
      return true;
    }
    state = ReceptionistAuthState(
      error: res.error ?? 'Invalid email or password',
    );
    return false;
  }

  Future<void> logout() async {
    await TokenStorage.instance.clearProviderSession();
    state = const ReceptionistAuthState();
  }
}

final receptionistAuthProvider =
    StateNotifierProvider<ReceptionistAuthNotifier, ReceptionistAuthState>(
  (ref) => ReceptionistAuthNotifier(ref.read(receptionistRepositoryProvider)),
);

class ReceptionistDashboardState {
  const ReceptionistDashboardState({
    this.filter = 'today',
    this.visits = const [],
    this.isLoading = false,
    this.error,
  });

  final String filter;
  final List<ClinicVisitModel> visits;
  final bool isLoading;
  final String? error;

  ReceptionistDashboardState copyWith({
    String? filter,
    List<ClinicVisitModel>? visits,
    bool? isLoading,
    String? error,
  }) {
    return ReceptionistDashboardState(
      filter: filter ?? this.filter,
      visits: visits ?? this.visits,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ReceptionistDashboardNotifier
    extends StateNotifier<ReceptionistDashboardState> {
  ReceptionistDashboardNotifier(this._repository)
      : super(const ReceptionistDashboardState()) {
    load();
  }

  final ReceptionistRepository _repository;

  Future<void> load({String? filter}) async {
    final nextFilter = filter ?? state.filter;
    state = state.copyWith(isLoading: true, error: null, filter: nextFilter);
    final res = await _repository.listBookings(filter: nextFilter);
    if (res.success && res.data != null) {
      state = state.copyWith(isLoading: false, visits: res.data, error: null);
    } else {
      state = state.copyWith(
        isLoading: false,
        error: res.error ?? 'Could not load clinic visits',
      );
    }
  }

  Future<String?> verify({required String bookingId, required String otp}) async {
    final res = await _repository.verifyPatient(bookingId: bookingId, otp: otp);
    if (res.success) {
      await load();
      return null;
    }
    return res.error ?? 'Verification failed';
  }

  Future<String?> regenerateOtp(String bookingId) async {
    final res = await _repository.regenerateOtp(bookingId);
    if (res.success) return null;
    return res.error ?? 'Could not generate a new code';
  }
}

final receptionistDashboardProvider = StateNotifierProvider<
    ReceptionistDashboardNotifier, ReceptionistDashboardState>(
  (ref) => ReceptionistDashboardNotifier(ref.read(receptionistRepositoryProvider)),
);

class DoctorReceptionistsState {
  const DoctorReceptionistsState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  final List<ReceptionistModel> items;
  final bool isLoading;
  final String? error;

  DoctorReceptionistsState copyWith({
    List<ReceptionistModel>? items,
    bool? isLoading,
    String? error,
  }) {
    return DoctorReceptionistsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class DoctorReceptionistsNotifier extends StateNotifier<DoctorReceptionistsState> {
  DoctorReceptionistsNotifier(this._repository)
      : super(const DoctorReceptionistsState()) {
    load();
  }

  final ReceptionistRepository _repository;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    final res = await _repository.listForDoctor();
    if (res.success && res.data != null) {
      state = state.copyWith(isLoading: false, items: res.data);
    } else {
      state = state.copyWith(
        isLoading: false,
        error: res.error ?? 'Could not load receptionists',
      );
    }
  }

  Future<String?> create({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final res = await _repository.create(
      name: name,
      email: email,
      password: password,
      phone: phone,
    );
    if (res.success) {
      await load();
      return null;
    }
    return res.error ?? 'Could not create receptionist';
  }

  Future<String?> update(ReceptionistModel item) async {
    final res = await _repository.update(
      id: item.id,
      name: item.name,
      email: item.email,
      phone: item.phone,
    );
    if (res.success) {
      await load();
      return null;
    }
    return res.error ?? 'Could not update receptionist';
  }

  Future<String?> setStatus(String id, String status) async {
    final res = await _repository.setStatus(id: id, status: status);
    if (res.success) {
      await load();
      return null;
    }
    return res.error ?? 'Could not update status';
  }

  Future<String?> resetPassword(String id, String password) async {
    final res = await _repository.resetPassword(id: id, password: password);
    return res.success ? null : (res.error ?? 'Could not reset password');
  }

  Future<String?> delete(String id) async {
    final res = await _repository.delete(id);
    if (res.success) {
      await load();
      return null;
    }
    return res.error ?? 'Could not delete receptionist';
  }
}

final doctorReceptionistsProvider =
    StateNotifierProvider<DoctorReceptionistsNotifier, DoctorReceptionistsState>(
  (ref) => DoctorReceptionistsNotifier(ref.read(receptionistRepositoryProvider)),
);
