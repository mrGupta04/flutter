import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/socket_service.dart';
import '../data/home_visit_tracking_repository.dart';
import '../data/tracking_models.dart';

class PatientTrackingState {
  const PatientTrackingState({
    this.snapshot,
    this.loading = true,
    this.error,
    this.socketConnected = false,
    this.providerOffline = false,
  });

  final TrackingSnapshot? snapshot;
  final bool loading;
  final String? error;
  final bool socketConnected;
  final bool providerOffline;

  PatientTrackingState copyWith({
    TrackingSnapshot? snapshot,
    bool? loading,
    String? error,
    bool clearError = false,
    bool? socketConnected,
    bool? providerOffline,
  }) {
    return PatientTrackingState(
      snapshot: snapshot ?? this.snapshot,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      socketConnected: socketConnected ?? this.socketConnected,
      providerOffline: providerOffline ?? this.providerOffline,
    );
  }
}

class PatientTrackingNotifier extends StateNotifier<PatientTrackingState> {
  PatientTrackingNotifier(this.bookingId) : super(const PatientTrackingState()) {
    _init();
  }

  final String bookingId;
  final _repository = HomeVisitTrackingRepository();
  final _socket = SocketService.instance;
  StreamSubscription<bool>? _connSub;
  Timer? _pollTimer;
  Timer? _routeTimer;
  DateTime? _lastRouteAt;

  Future<void> _init() async {
    _connSub = _socket.connectionChanges.listen((connected) {
      if (!mounted) return;
      state = state.copyWith(socketConnected: connected);
      if (connected) {
        _socket.joinBookingRoom(bookingId);
        _pollTimer?.cancel();
      } else {
        _startPollFallback();
      }
    });
    _socket.on('doctor_location_update', _onLocation);
    _socket.on('tracking_status', _onStatus);
    _socket.on('tracking_started', _onStarted);
    _socket.on('tracking_stopped', _onStopped);
    _socket.on('tracking_error', _onError);
    _socket.on('provider_offline', _onOffline);
    await refresh(includeRoute: true);
    _startPollFallback();
    try {
      await _socket.connect();
      _socket.joinBookingRoom(bookingId);
    } catch (_) {
      // Keep polling if the live socket cannot connect.
    }
  }

  void _startPollFallback() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      unawaited(refresh(includeRoute: false));
    });
  }

  Future<void> refresh({bool includeRoute = true}) async {
    try {
      final snapshot = await _repository.fetchSnapshot(
        bookingId,
        includeRoute: includeRoute,
      );
      if (!mounted) return;
      state = state.copyWith(
        snapshot: snapshot,
        loading: false,
        clearError: true,
        socketConnected: _socket.isConnected,
        providerOffline: false,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void _onLocation(dynamic data) {
    if (data is! Map) return;
    final update = ProviderLocationUpdate.fromJson(
      Map<String, dynamic>.from(data),
    );
    if (update.bookingId != bookingId) return;
    final current = state.snapshot;
    if (current == null) {
      refresh(includeRoute: true);
      return;
    }
    if (!mounted) return;
    state = state.copyWith(
      snapshot: current.copyWith(
        currentLatitude: update.latitude,
        currentLongitude: update.longitude,
        heading: update.heading,
        speed: update.speed,
        lastUpdatedAt: DateTime.fromMillisecondsSinceEpoch(update.timestamp),
        isTracking: true,
        trackingStatus: 'on_the_way',
      ),
      providerOffline: false,
    );
    _maybeRefreshRoute();
  }

  void _maybeRefreshRoute() {
    final now = DateTime.now();
    if (_lastRouteAt != null &&
        now.difference(_lastRouteAt!) < const Duration(seconds: 45)) {
      return;
    }
    _lastRouteAt = now;
    _routeTimer?.cancel();
    _routeTimer = Timer(const Duration(milliseconds: 400), () async {
      try {
        final route = await _repository.fetchRoute(bookingId);
        final current = state.snapshot;
        if (!mounted || current == null) return;
        state = state.copyWith(
          snapshot: current.copyWith(
            distanceText: route.distanceText,
            etaMinutes: route.etaMinutes,
            durationText: route.durationText,
            polyline: route.polyline,
          ),
        );
      } catch (_) {
        // Keep last route; GPS marker still moves.
      }
    });
  }

  void _onStatus(dynamic data) {
    if (data is Map && data['snapshot'] is Map) {
      if (!mounted) return;
      state = state.copyWith(
        snapshot: TrackingSnapshot.fromJson(
          Map<String, dynamic>.from(data['snapshot'] as Map),
        ),
      );
      return;
    }
    refresh(includeRoute: true);
  }

  void _onStarted(dynamic _) => refresh(includeRoute: true);

  void _onStopped(dynamic _) => refresh(includeRoute: false);

  void _onError(dynamic data) {
    if (!mounted) return;
    final message = data is Map ? data['message']?.toString() : data?.toString();
    if (message != null && message.isNotEmpty) {
      state = state.copyWith(error: message);
    }
  }

  void _onOffline(dynamic _) {
    if (!mounted) return;
    state = state.copyWith(providerOffline: true);
  }

  @override
  void dispose() {
    _connSub?.cancel();
    _pollTimer?.cancel();
    _routeTimer?.cancel();
    _socket.off('doctor_location_update', _onLocation);
    _socket.off('tracking_status', _onStatus);
    _socket.off('tracking_started', _onStarted);
    _socket.off('tracking_stopped', _onStopped);
    _socket.off('tracking_error', _onError);
    _socket.off('provider_offline', _onOffline);
    _socket.leaveBookingRoom();
    super.dispose();
  }
}

final patientTrackingProvider = StateNotifierProvider.autoDispose
    .family<PatientTrackingNotifier, PatientTrackingState, String>(
  (ref, bookingId) => PatientTrackingNotifier(bookingId),
);
