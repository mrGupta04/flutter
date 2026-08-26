import 'package:flutter/widgets.dart';

import '../models/provider_type.dart';
import 'doctor_presence_service.dart';
import 'nurse_presence_service.dart';
import 'provider_presence.dart';
import 'token_storage.dart';

/// Marks provider offline when the app is closed; resumes only if Online is on.
class DoctorPresenceLifecycleObserver extends WidgetsBindingObserver {
  DoctorPresenceLifecycleObserver._();

  static final DoctorPresenceLifecycleObserver instance =
      DoctorPresenceLifecycleObserver._();

  bool _registered = false;

  void register() {
    if (_registered) return;
    WidgetsBinding.instance.addObserver(this);
    _registered = true;
    _syncIfProvider();
  }

  void unregister() {
    if (!_registered) return;
    WidgetsBinding.instance.removeObserver(this);
    _registered = false;
  }

  Future<ProviderType?> _loggedInProviderType() async {
    final token = await TokenStorage.instance.getToken();
    if (token == null || token.isEmpty) return null;
    final type = await TokenStorage.instance.getProviderType();
    return ProviderType.fromRouteParam(type ?? '') ??
        (type == 'bloodbank' ? ProviderType.bloodBank : null);
  }

  Future<void> _syncIfProvider() async {
    final type = await _loggedInProviderType();
    if (type != ProviderType.doctor && type != ProviderType.nurse) return;
    final enabled = await TokenStorage.instance.getProviderOnlineEnabled();
    await syncProviderPresence(online: enabled);
  }

  Future<void> _goOfflineIfProvider() async {
    final type = await _loggedInProviderType();
    if (type == ProviderType.doctor) {
      await DoctorPresenceService.instance.goOffline(immediate: true);
    } else if (type == ProviderType.nurse) {
      await NursePresenceService.instance.goOffline(immediate: true);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.detached:
        _goOfflineIfProvider();
        break;
      case AppLifecycleState.resumed:
        _syncIfProvider();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
    }
  }
}
