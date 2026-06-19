import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/token_storage.dart';

/// Auth state backed by secure token storage abstraction.
class AuthState {
  const AuthState({this.token, this.isLoading = false});

  final String? token;
  final bool isLoading;

  bool get isAuthenticated => token != null && token!.isNotEmpty;

  AuthState copyWith({String? token, bool? isLoading}) {
    return AuthState(
      token: token ?? this.token,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _loadToken();
  }

  Future<void> _loadToken() async {
    state = state.copyWith(isLoading: true);
    final token = await TokenStorage.instance.getToken();
    state = AuthState(token: token, isLoading: false);
  }

  Future<void> saveToken(String token) async {
    await TokenStorage.instance.saveToken(token);
    state = AuthState(token: token);
  }

  Future<void> logout() async {
    await TokenStorage.instance.clearToken();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
