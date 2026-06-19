import 'dart:async';

import '../../data/repositories/doctor_registration_repository.dart';

/// Keeps the doctor marked as "live" while the app is open and in the foreground.
/// If the doctor closes or backgrounds the app without logging out, heartbeats
/// stop and [goOffline] is called from [DoctorPresenceLifecycleObserver].
class DoctorPresenceService {
  DoctorPresenceService._();

  static final DoctorPresenceService instance = DoctorPresenceService._();

  static const Duration _heartbeatInterval = Duration(seconds: 15);
  static const Duration _offlineDebounce = Duration(seconds: 2);

  final DoctorRegistrationRepository _repository = DoctorRegistrationRepository();
  Timer? _heartbeatTimer;
  Timer? _offlineDebounceTimer;
  bool _active = false;

  bool get isActive => _active;

  Future<void> goOnline() async {
    _offlineDebounceTimer?.cancel();
    _offlineDebounceTimer = null;

    final wasActive = _active;
    _active = true;
    await _repository.sendPresenceHeartbeat();

    if (!wasActive) {
      _heartbeatTimer?.cancel();
      _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
        _repository.sendPresenceHeartbeat();
      });
    }
  }

  Future<void> goOffline({bool immediate = false}) async {
    _offlineDebounceTimer?.cancel();
    _offlineDebounceTimer = null;

    if (!_active) return;

    if (!immediate) {
      _offlineDebounceTimer = Timer(_offlineDebounce, () {
        unawaited(_doGoOffline());
      });
      return;
    }

    await _doGoOffline();
  }

  Future<void> _doGoOffline() async {
    if (!_active) return;
    _active = false;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    await _repository.setPresenceOffline();
  }
}
