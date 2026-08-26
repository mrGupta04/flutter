import 'dart:async';

import '../../data/repositories/doctor_registration_repository.dart';

/// Keeps the doctor marked as "live" only while the Online toggle is on.
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

    if (!immediate) {
      _offlineDebounceTimer = Timer(_offlineDebounce, () {
        unawaited(_doGoOffline());
      });
      return;
    }

    await _doGoOffline();
  }

  Future<void> _doGoOffline() async {
    _active = false;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    await _repository.setPresenceOffline();
  }
}
