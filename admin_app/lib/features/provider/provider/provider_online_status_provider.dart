import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/provider_presence.dart';
import '../../../core/services/token_storage.dart';

class ProviderOnlineStatusState {
  const ProviderOnlineStatusState({
    this.isOnline = false,
    this.isReady = false,
    this.isSaving = false,
  });

  final bool isOnline;
  final bool isReady;
  final bool isSaving;

  ProviderOnlineStatusState copyWith({
    bool? isOnline,
    bool? isReady,
    bool? isSaving,
  }) {
    return ProviderOnlineStatusState(
      isOnline: isOnline ?? this.isOnline,
      isReady: isReady ?? this.isReady,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

class ProviderOnlineStatusNotifier
    extends StateNotifier<ProviderOnlineStatusState> {
  ProviderOnlineStatusNotifier() : super(const ProviderOnlineStatusState()) {
    restore();
  }

  int _generation = 0;

  Future<void> restore() async {
    final generation = ++_generation;
    final enabled = await TokenStorage.instance.getProviderOnlineEnabled();
    if (!mounted || generation != _generation) return;
    state = state.copyWith(isOnline: enabled, isReady: true);
    await syncProviderPresence(online: enabled);
  }

  Future<void> setOnline(bool enabled) async {
    if (state.isSaving || state.isOnline == enabled) return;
    final generation = ++_generation;
    state = state.copyWith(isOnline: enabled, isSaving: true);
    await TokenStorage.instance.setProviderOnlineEnabled(enabled);
    await syncProviderPresence(online: enabled);
    if (!mounted || generation != _generation) return;
    state = state.copyWith(isSaving: false);
  }

  Future<void> reset() async {
    _generation++;
    state = const ProviderOnlineStatusState(isReady: true);
    await TokenStorage.instance.setProviderOnlineEnabled(false);
    await syncProviderPresence(online: false);
  }
}

final providerOnlineStatusProvider = StateNotifierProvider<
    ProviderOnlineStatusNotifier, ProviderOnlineStatusState>(
  (ref) => ProviderOnlineStatusNotifier(),
);
