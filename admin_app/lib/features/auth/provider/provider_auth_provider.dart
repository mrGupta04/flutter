import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/provider_type.dart';
import '../../../core/services/doctor_presence_service.dart';
import '../../../core/services/nurse_presence_service.dart';
import '../../../core/services/token_storage.dart';
import '../../../data/repositories/provider_auth_repository.dart';

class ProviderAuthState {
  ProviderAuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.providerType,
    this.entityId,
    this.profilePicture,
    this.displayName,
    this.isLoadingProfile = false,
    this.error,
  });

  final bool isLoading;
  final bool isAuthenticated;
  final ProviderType? providerType;
  final String? entityId;
  final String? profilePicture;
  final String? displayName;
  final bool isLoadingProfile;
  final String? error;

  ProviderAuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    ProviderType? providerType,
    String? entityId,
    String? profilePicture,
    String? displayName,
    bool? isLoadingProfile,
    String? error,
  }) {
    return ProviderAuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      providerType: providerType ?? this.providerType,
      entityId: entityId ?? this.entityId,
      profilePicture: profilePicture ?? this.profilePicture,
      displayName: displayName ?? this.displayName,
      isLoadingProfile: isLoadingProfile ?? this.isLoadingProfile,
      error: error,
    );
  }
}

class ProviderAuthNotifier extends StateNotifier<ProviderAuthState> {
  ProviderAuthNotifier(this._repository) : super(ProviderAuthState()) {
    _restoreSession();
  }

  final ProviderAuthRepository _repository;

  ProviderType? _typeFromStorage(String? typeKey) {
    if (typeKey == null) return null;
    return ProviderType.fromRouteParam(typeKey) ??
        (typeKey == 'bloodbank' ? ProviderType.bloodBank : null);
  }

  void _applyProfileFromMap(ProviderType type, Map<String, dynamic> profile) {
    state = state.copyWith(
      profilePicture: ProviderAuthRepository.profilePictureFrom(profile),
      displayName: ProviderAuthRepository.displayNameFrom(type, profile),
    );
  }

  Future<void> refreshSession() async {
    await _restoreSession();
    if (state.isAuthenticated && state.providerType != null) {
      await refreshProfile();
    }
  }

  Future<void> _restoreSession() async {
    final token = await TokenStorage.instance.getToken();
    if (token == null || token.isEmpty) {
      state = ProviderAuthState();
      return;
    }

    final typeKey = await TokenStorage.instance.getProviderType();
    final type = _typeFromStorage(typeKey);
    if (type == null) return;

    var entityId = switch (type) {
      ProviderType.doctor => await TokenStorage.instance.getDoctorId(),
      ProviderType.nurse => await TokenStorage.instance.getNurseId(),
      ProviderType.ambulance => await TokenStorage.instance.getAmbulanceId(),
      ProviderType.bloodBank => await TokenStorage.instance.getBloodBankId(),
      ProviderType.lab => await TokenStorage.instance.getLabId(),
      ProviderType.scanCenter => await TokenStorage.instance.getScanCenterId(),
    };

    state = ProviderAuthState(
      isAuthenticated: true,
      providerType: type,
      entityId: entityId,
    );

    await refreshProfile();

    if (type == ProviderType.doctor) {
      final profile = await _repository.fetchProfile(type);
      final id = profile.data?['id'] as String?;
      if (id != null && id.isNotEmpty) {
        await TokenStorage.instance.saveDoctorId(id);
        entityId = id;
        state = state.copyWith(entityId: id);
      }
      await DoctorPresenceService.instance.goOnline();
    } else if (type == ProviderType.nurse) {
      final profile = await _repository.fetchProfile(type);
      final id = profile.data?['id'] as String?;
      if (id != null && id.isNotEmpty) {
        await TokenStorage.instance.saveNurseId(id);
        entityId = id;
        state = state.copyWith(entityId: id);
      }
      await NursePresenceService.instance.goOnline();
    }
  }

  Future<void> refreshProfile() async {
    final type = state.providerType;
    if (!state.isAuthenticated || type == null) return;

    state = state.copyWith(isLoadingProfile: true);
    final response = await _repository.fetchProfile(type);
    if (response.success && response.data != null) {
      _applyProfileFromMap(type, response.data!);
    }
    state = state.copyWith(isLoadingProfile: false);
  }

  Future<bool> login({
    required ProviderType type,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final response = await _repository.login(
      type: type,
      email: email,
      password: password,
    );

    if (response.success && response.data != null) {
      final profile = response.data!.profile;
      var entityId = response.data!.entityId;
      final token = response.data!.token;

      if (token.isNotEmpty) {
        await TokenStorage.instance.saveProviderSession(
          providerType: type == ProviderType.bloodBank
              ? 'blood-bank'
              : type.routeParam,
          token: token,
          entityId: entityId.isNotEmpty ? entityId : null,
        );
        if (entityId.isEmpty) {
          entityId = profile['id'] as String? ?? '';
          if (entityId.isNotEmpty && type == ProviderType.doctor) {
            await TokenStorage.instance.saveDoctorId(entityId);
          } else if (entityId.isNotEmpty && type == ProviderType.nurse) {
            await TokenStorage.instance.saveNurseId(entityId);
          }
        }
      }

      state = ProviderAuthState(
        isLoading: false,
        isAuthenticated: true,
        providerType: type,
        entityId: entityId.isNotEmpty ? entityId : null,
        profilePicture: ProviderAuthRepository.profilePictureFrom(profile),
        displayName: ProviderAuthRepository.displayNameFrom(type, profile),
      );
      if (type == ProviderType.doctor) {
        await DoctorPresenceService.instance.goOnline();
      } else if (type == ProviderType.nurse) {
        await NursePresenceService.instance.goOnline();
      }
      return true;
    }

    state = state.copyWith(
      isLoading: false,
      error: response.error ?? 'Login failed',
    );
    return false;
  }

  Future<void> logout() async {
    if (state.providerType == ProviderType.doctor) {
      await DoctorPresenceService.instance.goOffline(immediate: true);
    } else if (state.providerType == ProviderType.nurse) {
      await NursePresenceService.instance.goOffline(immediate: true);
    }
    await TokenStorage.instance.clearProviderSession();
    state = ProviderAuthState();
  }

  Future<bool> isLoggedInAs(ProviderType type) async {
    final token = await TokenStorage.instance.getToken();
    if (token == null || token.isEmpty) return false;
    final stored = await TokenStorage.instance.getProviderType();
    if (stored == null) return false;
    if (type == ProviderType.bloodBank) {
      return stored == 'blood-bank' || stored == 'bloodbank';
    }
    return stored == type.routeParam;
  }
}

final providerAuthRepositoryProvider = Provider((ref) => ProviderAuthRepository());

final providerAuthProvider =
    StateNotifierProvider<ProviderAuthNotifier, ProviderAuthState>((ref) {
  return ProviderAuthNotifier(ref.watch(providerAuthRepositoryProvider));
});
