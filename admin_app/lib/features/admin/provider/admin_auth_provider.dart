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
  final bool canReassign;
  final List<String> permissions;

  const AdminAuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.email,
    this.role,
    this.name,
    this.error,
    this.canReassign = false,
    this.permissions = const [],
  });

  bool get isAdmin => role == 'admin' || role == 'super_admin';
  bool get isApprover => role == 'approver';

  bool canApproveCategory(String category) {
    if (isAdmin) return true;
    return permissions.contains(category);
  }

  AdminAuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    String? email,
    String? role,
    String? name,
    String? error,
    bool? canReassign,
    List<String>? permissions,
  }) {
    return AdminAuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      email: email ?? this.email,
      role: role ?? this.role,
      name: name ?? this.name,
      error: error,
      canReassign: canReassign ?? this.canReassign,
      permissions: permissions ?? this.permissions,
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
    final canReassign = await TokenStorage.instance.getAdminCanReassign();
    final permissions = await TokenStorage.instance.getAdminPermissions();
    if (token != null && token.isNotEmpty) {
      state = state.copyWith(
        isAuthenticated: true,
        email: email,
        role: role ?? 'admin',
        name: name,
        canReassign: canReassign,
        permissions: permissions,
      );
    }
  }

  Future<bool> login({
    required String email,
    required String password,
    bool asApprover = false,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final response = await _repository.login(
      email: email,
      password: password,
      asApprover: asApprover,
    );

    if (response.success &&
        response.data != null &&
        response.data!.token.isNotEmpty) {
      await TokenStorage.instance.saveAdminToken(response.data!.token);
      await TokenStorage.instance.saveAdminEmail(response.data!.email);
      await TokenStorage.instance.saveAdminRole(response.data!.role);
      if (response.data!.name != null) {
        await TokenStorage.instance.saveAdminName(response.data!.name!);
      }
      await TokenStorage.instance.saveAdminCanReassign(
        response.data!.canReassign,
      );
      await TokenStorage.instance.saveAdminPermissions(
        response.data!.permissions,
      );
      if (response.data!.refreshToken != null &&
          response.data!.sessionId != null) {
        await TokenStorage.instance.saveAdminRefreshSession(
          refreshToken: response.data!.refreshToken!,
          sessionId: response.data!.sessionId!,
        );
      }
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        email: response.data!.email,
        role: response.data!.role,
        name: response.data!.name,
        canReassign: response.data!.canReassign,
        permissions: response.data!.permissions,
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
    if (state.isApprover) {
      await _repository.logoutApprover();
    }
    await TokenStorage.instance.clearAdminSession();
    state = const AdminAuthState();
  }
}

final adminAuthProvider =
    StateNotifierProvider<AdminAuthNotifier, AdminAuthState>((ref) {
      return AdminAuthNotifier(ref.watch(adminAuthRepositoryProvider));
    });
