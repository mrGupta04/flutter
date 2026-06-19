import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/token_storage.dart';
import '../../../data/repositories/admin_auth_repository.dart';

final adminAuthRepositoryProvider = Provider((ref) => AdminAuthRepository());

class AdminAuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final String? email;
  final String? role;
  final String? name;
  final String? error;

  const AdminAuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.email,
    this.role,
    this.name,
    this.error,
  });

  bool get isAdmin => role == 'admin';

  AdminAuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    String? email,
    String? role,
    String? name,
    String? error,
  }) {
    return AdminAuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      email: email ?? this.email,
      role: role ?? this.role,
      name: name ?? this.name,
      error: error,
    );
  }
}

class AdminAuthNotifier extends StateNotifier<AdminAuthState> {
  final AdminAuthRepository _repository;

  AdminAuthNotifier(this._repository) : super(const AdminAuthState()) {
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final token = await TokenStorage.instance.getAdminToken();
    final email = await TokenStorage.instance.getAdminEmail();
    final role = await TokenStorage.instance.getAdminRole();
    final name = await TokenStorage.instance.getAdminName();
    if (token != null && token.isNotEmpty) {
      state = state.copyWith(
        isAuthenticated: true,
        email: email,
        role: role ?? 'admin',
        name: name,
      );
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final response = await _repository.login(email: email, password: password);

    if (response.success &&
        response.data != null &&
        response.data!.token.isNotEmpty) {
      await TokenStorage.instance.saveAdminToken(response.data!.token);
      await TokenStorage.instance.saveAdminEmail(response.data!.email);
      await TokenStorage.instance.saveAdminRole(response.data!.role);
      if (response.data!.name != null) {
        await TokenStorage.instance.saveAdminName(response.data!.name!);
      }
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        email: response.data!.email,
        role: response.data!.role,
        name: response.data!.name,
        error: null,
      );
      return true;
    }

    state = state.copyWith(
      isLoading: false,
      error: response.error ?? 'Login failed',
    );
    return false;
  }

  Future<void> logout() async {
    await TokenStorage.instance.clearAdminSession();
    state = const AdminAuthState();
  }
}

final adminAuthProvider =
    StateNotifierProvider<AdminAuthNotifier, AdminAuthState>((ref) {
  return AdminAuthNotifier(ref.watch(adminAuthRepositoryProvider));
});
