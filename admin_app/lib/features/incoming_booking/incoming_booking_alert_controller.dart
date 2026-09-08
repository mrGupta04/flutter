import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/models/provider_type.dart';
import '../../core/services/socket_service.dart';
import '../../data/models/doctor_booking_model.dart';
import '../../data/repositories/ambulance_registration_repository.dart';
import '../auth/provider/provider_auth_provider.dart';
import '../doctor_dashboard/provider/dashboard_provider.dart';
import '../nurse_dashboard/provider/nurse_dashboard_provider.dart';
import 'incoming_booking_request.dart';
import 'incoming_booking_ringer.dart';

const _completedPrefsKey = 'incoming_booking_alert_completed_v1';

class IncomingBookingAlertState {
  const IncomingBookingAlertState({
    this.current,
    this.isActing = false,
    this.actionError,
    this.remainingSeconds = 0,
  });

  final IncomingBookingRequest? current;
  final bool isActing;
  final String? actionError;
  final int remainingSeconds;

  bool get isVisible => current != null;

  IncomingBookingAlertState copyWith({
    IncomingBookingRequest? current,
    bool clearCurrent = false,
    bool? isActing,
    String? actionError,
    bool clearError = false,
    int? remainingSeconds,
  }) {
    return IncomingBookingAlertState(
      current: clearCurrent ? null : (current ?? this.current),
      isActing: isActing ?? this.isActing,
      actionError: clearError ? null : (actionError ?? this.actionError),
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
    );
  }
}

class IncomingBookingAlertNotifier
    extends StateNotifier<IncomingBookingAlertState> {
  IncomingBookingAlertNotifier(this._ref)
      : super(const IncomingBookingAlertState()) {
    _bind();
  }

  final Ref _ref;
  final Set<String> _completedIds = {};
  final List<IncomingBookingRequest> _queue = [];
  bool _prefsLoaded = false;
  bool _disposed = false;
  Timer? _tick;

  void _bind() {
    SocketService.instance.on('app_notification', _onSocketPayload);
    SocketService.instance.on('booking-notification', _onSocketPayload);
    SocketService.instance.on('booking-status-update', _onStatusPayload);
    SocketService.instance.on('booking_status_update', _onStatusPayload);
    SocketService.instance.on('ambulance_request_created', _onSocketPayload);
    SocketService.instance.on('ambulance_event', _onSocketPayload);
    SocketService.instance.on('ambulance_assigned', _onStatusPayload);
    SocketService.instance.on('ambulance_request_cancelled', _onStatusPayload);
  }

  void _onSocketPayload(dynamic data) {
    final map = _asMap(data);
    if (map.isEmpty) return;
    final event = map['event']?.toString();
    if (event != null && event.isNotEmpty) {
      map['type'] = map['type'] ?? event;
    }
    if (map['offer'] is Map) {
      final offer = Map<String, dynamic>.from(map['offer'] as Map);
      map.addAll(offer);
    }
    unawaited(handleNotification(map));
  }

  void _onStatusPayload(dynamic data) {
    final map = _asMap(data);
    final bookingId = map['bookingId']?.toString() ?? '';
    if (bookingId.isEmpty) return;
    final status = map['status']?.toString() ?? '';
    if (!IncomingBookingRequest.isPendingStatus(status)) {
      unawaited(_dismissIfCurrent(bookingId, persist: true));
    }
  }

  Future<void> handleNotification(Map<String, dynamic> payload) async {
    await _ensurePrefs();
    if (_disposed) return;
    final nested = payload['data'] is Map
        ? Map<String, dynamic>.from(payload['data'] as Map)
        : const <String, dynamic>{};
    final type = payload['type']?.toString();
    if (IncomingBookingRequest.isExpiryType(type, nested) ||
        IncomingBookingRequest.isExpiryType(type, payload)) {
      final bookingId =
          nested['bookingId']?.toString() ?? payload['bookingId']?.toString();
      if (bookingId != null && bookingId.isNotEmpty) {
        await _dismissIfCurrent(bookingId, persist: true);
      }
      return;
    }
    if (!IncomingBookingRequest.isIncomingType(type, nested) &&
        !IncomingBookingRequest.isIncomingType(type, payload)) {
      return;
    }
    final role = _currentRole();
    if (role == null) return;
    final request = IncomingBookingRequest.fromPayload(
      payload,
      fallbackRole: role,
    );
    if (request.bookingId.isEmpty) return;
    await present(request);
  }

  Future<void> present(IncomingBookingRequest request) async {
    await _ensurePrefs();
    if (_disposed || request.bookingId.isEmpty) return;
    if (_completedIds.contains(request.bookingId)) return;
    if (state.current?.bookingId == request.bookingId) return;
    if (_queue.any((item) => item.bookingId == request.bookingId)) return;

    if (request.approvalExpiresAt != null &&
        request.approvalExpiresAt!.isBefore(DateTime.now())) {
      await _markCompleted(request.bookingId);
      return;
    }
    if (request.remainingSeconds <= 0 && request.alertExpiresAt != null) {
      await _markCompleted(request.bookingId);
      return;
    }

    if (state.current != null) {
      _queue.add(request);
      return;
    }
    await _show(request);
  }

  Future<void> syncPendingBookings(
    List<DoctorBookingModel> bookings, {
    required String providerRole,
    bool listIsFresh = false,
  }) async {
    await _ensurePrefs();
    if (_disposed) return;

    final pending = bookings
        .where((b) => b.isAwaitingDoctorApproval && b.id.isNotEmpty)
        .toList()
      ..sort((a, b) {
        final aTime = a.createdAt ?? a.slotStart ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? b.slotStart ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

    final pendingIds = pending.map((b) => b.id).toSet();
    if (listIsFresh &&
        state.current != null &&
        !pendingIds.contains(state.current!.bookingId)) {
      await _dismissIfCurrent(state.current!.bookingId, persist: true);
    }

    for (final booking in pending) {
      if (_completedIds.contains(booking.id)) continue;
      final created = booking.createdAt;
      if (created != null &&
          DateTime.now().difference(created) > const Duration(minutes: 3)) {
        continue;
      }
      await present(
        IncomingBookingRequest.fromBooking(
          booking,
          providerRole: providerRole,
        ),
      );
    }
  }

  Future<void> accept() async {
    final current = state.current;
    if (current == null || state.isActing) return;
    state = state.copyWith(isActing: true, clearError: true);
    final ok = await _callAccept(current);
    if (_disposed) return;
    if (ok) {
      await _completeCurrent(persist: true);
      await _reloadBookings();
      return;
    }
    await _reloadBookings();
    if (_disposed) return;
    if (state.current?.bookingId == current.bookingId) {
      state = state.copyWith(
        isActing: false,
        actionError: 'Could not accept. The request may have expired.',
      );
    }
  }

  Future<void> reject() async {
    final current = state.current;
    if (current == null || state.isActing) return;
    state = state.copyWith(isActing: true, clearError: true);
    final ok = await _callReject(current);
    if (_disposed) return;
    if (ok) {
      await _completeCurrent(persist: true);
      await _reloadBookings();
      return;
    }
    await _reloadBookings();
    if (_disposed) return;
    if (state.current?.bookingId == current.bookingId) {
      state = state.copyWith(
        isActing: false,
        actionError: 'Could not reject. Please try again.',
      );
    }
  }

  Future<void> clearSession() async {
    _queue.clear();
    _tick?.cancel();
    await IncomingBookingRinger.instance.stop();
    if (!_disposed) {
      state = const IncomingBookingAlertState();
    }
  }

  Future<void> _show(IncomingBookingRequest request) async {
    state = IncomingBookingAlertState(
      current: request,
      remainingSeconds: request.remainingSeconds,
    );
    await IncomingBookingRinger.instance.start();
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      unawaited(_onTick());
    });
  }

  Future<void> _onTick() async {
    final current = state.current;
    if (current == null) return;
    final left = current.remainingSeconds;
    if (left <= 0) {
      await _expireCurrent();
      return;
    }
    if (!_disposed) {
      state = state.copyWith(remainingSeconds: left);
    }
  }

  Future<void> _expireCurrent() async {
    final current = state.current;
    if (current == null) return;
    await IncomingBookingRinger.instance.stop();
    if (!_disposed) {
      state = state.copyWith(
        current: current.copyWith(status: 'expired'),
        remainingSeconds: 0,
        isActing: false,
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    await _completeCurrent(persist: true);
  }

  Future<void> _completeCurrent({required bool persist}) async {
    final id = state.current?.bookingId;
    _tick?.cancel();
    await IncomingBookingRinger.instance.stop();
    if (id != null && persist) {
      await _markCompleted(id);
    }
    if (_disposed) return;
    state = const IncomingBookingAlertState();
    await _showNext();
  }

  Future<void> _dismissIfCurrent(String bookingId, {required bool persist}) async {
    if (state.current?.bookingId != bookingId) {
      _queue.removeWhere((item) => item.bookingId == bookingId);
      if (persist) await _markCompleted(bookingId);
      return;
    }
    await _completeCurrent(persist: persist);
  }

  Future<void> _showNext() async {
    while (_queue.isNotEmpty) {
      final next = _queue.removeAt(0);
      if (_completedIds.contains(next.bookingId)) continue;
      await _show(next);
      return;
    }
  }

  Future<bool> _callAccept(IncomingBookingRequest request) async {
    try {
      if (request.providerRole == 'ambulance') {
        final response = await AmbulanceRegistrationRepository()
            .acceptRequest(request.bookingId);
        return response.success;
      }
      if (request.providerRole == 'nurse') {
        return _ref
            .read(nurseDashboardProvider.notifier)
            .approveHomeVisitRequest(request.bookingId);
      }
      return _ref
          .read(doctorDashboardProvider.notifier)
          .approveHomeVisitRequest(request.bookingId);
    } catch (_) {
      return false;
    }
  }

  Future<bool> _callReject(IncomingBookingRequest request) async {
    try {
      if (request.providerRole == 'ambulance') {
        final response = await AmbulanceRegistrationRepository()
            .rejectRequest(request.bookingId, reason: 'unavailable');
        return response.success;
      }
      if (request.providerRole == 'nurse') {
        return _ref
            .read(nurseDashboardProvider.notifier)
            .rejectHomeVisitRequest(request.bookingId);
      }
      return _ref
          .read(doctorDashboardProvider.notifier)
          .rejectHomeVisitRequest(request.bookingId);
    } catch (_) {
      return false;
    }
  }

  Future<void> _reloadBookings() async {
    try {
      final role = _currentRole();
      if (role == 'nurse') {
        await _ref.read(nurseDashboardProvider.notifier).loadBookings();
      } else if (role == 'doctor') {
        await _ref.read(doctorDashboardProvider.notifier).loadBookings();
      }
    } catch (_) {}
  }

  String? _currentRole() {
    final type = _ref.read(providerAuthProvider).providerType;
    if (type == ProviderType.nurse) return 'nurse';
    if (type == ProviderType.doctor) return 'doctor';
    if (type == ProviderType.ambulance) return 'ambulance';
    return null;
  }

  Future<void> _ensurePrefs() async {
    if (_prefsLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList(_completedPrefsKey) ?? const [];
      _completedIds
        ..clear()
        ..addAll(stored);
    } catch (_) {}
    _prefsLoaded = true;
  }

  Future<void> _markCompleted(String bookingId) async {
    if (bookingId.isEmpty) return;
    _completedIds.add(bookingId);
    _queue.removeWhere((item) => item.bookingId == bookingId);
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = _completedIds.toList();
      if (ids.length > 120) {
        ids.removeRange(0, ids.length - 120);
        _completedIds
          ..clear()
          ..addAll(ids);
      }
      await prefs.setStringList(_completedPrefsKey, ids);
    } catch (_) {}
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    return const {};
  }

  @override
  void dispose() {
    _disposed = true;
    _tick?.cancel();
    IncomingBookingRinger.instance.stop();
    SocketService.instance.off('app_notification', _onSocketPayload);
    SocketService.instance.off('booking-notification', _onSocketPayload);
    SocketService.instance.off('booking-status-update', _onStatusPayload);
    SocketService.instance.off('booking_status_update', _onStatusPayload);
    SocketService.instance.off('ambulance_request_created', _onSocketPayload);
    SocketService.instance.off('ambulance_event', _onSocketPayload);
    SocketService.instance.off('ambulance_assigned', _onStatusPayload);
    SocketService.instance.off('ambulance_request_cancelled', _onStatusPayload);
    super.dispose();
  }
}

final incomingBookingAlertProvider = StateNotifierProvider<
    IncomingBookingAlertNotifier, IncomingBookingAlertState>((ref) {
  return IncomingBookingAlertNotifier(ref);
});
