import 'package:flutter/widgets.dart';

import '../models/provider_type.dart';
import 'doctor_presence_service.dart';
import 'token_storage.dart';

/// Marks doctor offline when the app is closed; keeps presence while in foreground.
class DoctorPresenceLifecycleObserver extends WidgetsBindingObserver {
  DoctorPresenceLifecycleObserver._();

  static final DoctorPresenceLifecycleObserver instance =
      DoctorPresenceLifecycleObserver._();

  bool _registered = false;

  void register() {
    if (_registered) return;
    WidgetsBinding.instance.addObserver(this);
    _registered = true;
    _ensureOnlineIfDoctor();
  }

  void unregister() {
    if (!_registered) return;
    WidgetsBinding.instance.removeObserver(this);
    _registered = false;
  }

  Future<bool> _isLoggedInDoctor() async {
    final token = await TokenStorage.instance.getToken();
    if (token == null || token.isEmpty) return false;
    final type = await TokenStorage.instance.getProviderType();
    return type == ProviderType.doctor.routeParam;
  }

  Future<void> _ensureOnlineIfDoctor() async {
    if (await _isLoggedInDoctor()) {
      await DoctorPresenceService.instance.goOnline();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.detached:
        DoctorPresenceService.instance.goOffline(immediate: true);
        break;
      case AppLifecycleState.resumed:
        _ensureOnlineIfDoctor();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
    }
  }
}
