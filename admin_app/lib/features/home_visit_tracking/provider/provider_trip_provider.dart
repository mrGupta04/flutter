import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/socket_service.dart';
import '../../../core/services/tracking_location_service.dart';
import '../data/home_visit_tracking_repository.dart';
import '../data/tracking_models.dart';

class ProviderTripState {
  const ProviderTripState({
    this.snapshot,
    this.loading = true,
    this.starting = false,
    this.error,
    this.socketConnected = false,
    this.gpsActive = false,
  });

  final TrackingSnapshot? snapshot;
  final bool loading;
  final bool starting;
  final String? error;
  final bool socketConnected;
  final bool gpsActive;

  ProviderTripState copyWith({
    TrackingSnapshot? snapshot,
    bool? loading,
    bool? starting,
    String? error,
    bool clearError = false,
    bool? socketConnected,
    bool? gpsActive,
  }) {
    return ProviderTripState(
      snapshot: snapshot ?? this.snapshot,
      loading: loading ?? this.loading,
      starting: starting ?? this.starting,
      error: clearError ? null : (error ?? this.error),
      socketConnected: socketConnected ?? this.socketConnected,
      gpsActive: gpsActive ?? this.gpsActive,
    );
  }
}

class ProviderTripArgs {
  const ProviderTripArgs({
    required this.bookingId,
    required this.role,
  });

  final String bookingId;
  final String role;
}

class ProviderTripNotifier extends StateNotifier<ProviderTripState> {
  ProviderTripNotifier(this._args)
      : super(const ProviderTripState()) {
    _init();
  }

  final ProviderTripArgs _args;
  final _repository = HomeVisitTrackingRepository();
  final _socket = SocketService.instance;
  final _location = TrackingLocationService.instance;
  StreamSubscription<bool>? _connSub;
  DateTime? _lastRestFallback;

  String get bookingId => _args.bookingId;
  String get role => _args.role;

  Future<void> _init() async {
    _connSub = _socket.connectionChanges.listen((connected) {
      if (!mounted) return;
      state = state.copyWith(socketConnected: connected);
    });
    _socket.on('tracking_status', _onStatus);
    _socket.on('tracking_started', _onStarted);
    _socket.on('tracking_stopped', _onStopped);
    _socket.on('tracking_error', _onError);
    try {
      await _socket.connect();
      _socket.joinBookingRoom(bookingId);
      await refresh();
      if (state.snapshot?.isOnTheWay == true) {
        await _resumeGps();
      }
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    try {
      final snapshot = await _repository.fetchSnapshot(
        role: role,
        bookingId: bookingId,
      );
      if (!mounted) return;
      state = state.copyWith(
        snapshot: snapshot,
        loading: false,
        clearError: true,
        socketConnected: _socket.isConnected,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> startTrip() async {
    if (state.starting || _location.isTracking) return;
    state = state.copyWith(starting: true, clearError: true);
    try {
      final snapshot = await _repository.startTrip(
        role: role,
        bookingId: bookingId,
      );
      _socket.startTracking(bookingId);
      if (!mounted) return;
      state = state.copyWith(snapshot: snapshot, starting: false);
      await _resumeGps();
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(starting: false, error: e.toString());
    }
  }

  Future<void> markArrived() async {
    await _stop(progress: 'arrived');
  }

  Future<void> stopTrip() async {
    await _stop();
  }

  Future<void> _stop({String? progress}) async {
    await _location.stop();
    _socket.stopTracking(bookingId, progress: progress);
    try {
      final snapshot = await _repository.stopTrip(
        role: role,
        bookingId: bookingId,
        progress: progress,
      );
      if (!mounted) return;
      state = state.copyWith(snapshot: snapshot, gpsActive: false);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(gpsActive: false, error: e.toString());
    }
  }

  Future<void> _resumeGps() async {
    await _location.start(
      bookingId: bookingId,
      onLocation: _onGps,
      onError: (message) {
        if (!mounted) return;
        state = state.copyWith(error: message);
      },
    );
    if (!mounted) return;
    state = state.copyWith(gpsActive: _location.isTracking);
  }

  void _onGps(TrackingPoint point) {
    final current = state.snapshot;
    if (current != null && mounted) {
      state = state.copyWith(
        snapshot: TrackingSnapshot(
          bookingId: current.bookingId,
          trackingStatus: current.trackingStatus,
          visitProgress: current.visitProgress,
          bookingStatus: current.bookingStatus,
          providerType: current.providerType,
          providerId: current.providerId,
          providerName: current.providerName,
          providerMobile: current.providerMobile,
          patientName: current.patientName,
          patientAddress: current.patientAddress,
          patientCity: current.patientCity,
          patientLatitude: current.patientLatitude,
          patientLongitude: current.patientLongitude,
          currentLatitude: point.latitude,
          currentLongitude: point.longitude,
          heading: point.heading,
          speed: point.speed,
          lastUpdatedAt: DateTime.fromMillisecondsSinceEpoch(point.timestamp),
          distanceText: current.distanceText,
          etaMinutes: current.etaMinutes,
          durationText: current.durationText,
          polyline: current.polyline,
          isTracking: true,
          routeWarning: current.routeWarning,
        ),
      );
    }
    final payload = {
      'bookingId': bookingId,
      'latitude': point.latitude,
      'longitude': point.longitude,
      if (point.heading != null) 'heading': point.heading,
      if (point.speed != null) 'speed': point.speed,
      'timestamp': point.timestamp,
    };
    if (_socket.isConnected) {
      _socket.sendLocation(payload);
    } else {
      final now = DateTime.now();
      if (_lastRestFallback == null ||
          now.difference(_lastRestFallback!) > const Duration(seconds: 8)) {
        _lastRestFallback = now;
        unawaited(
          _repository.sendLocationFallback(
            role: role,
            bookingId: bookingId,
            latitude: point.latitude,
            longitude: point.longitude,
            heading: point.heading,
            speed: point.speed,
            timestamp: point.timestamp,
          ),
        );
      }
    }
  }

  void _onStatus(dynamic data) {
    if (data is Map && data['snapshot'] is Map) {
      final snapshot = TrackingSnapshot.fromJson(
        Map<String, dynamic>.from(data['snapshot'] as Map),
      );
      if (!mounted) return;
      state = state.copyWith(snapshot: snapshot);
    }
  }

  void _onStarted(dynamic data) {
    refresh();
  }

  void _onStopped(dynamic data) {
    unawaited(_location.stop());
    if (!mounted) return;
    state = state.copyWith(gpsActive: false);
    refresh();
  }

  void _onError(dynamic data) {
    if (!mounted) return;
    final message = data is Map
        ? data['message']?.toString()
        : data?.toString();
    if (message != null && message.isNotEmpty) {
      state = state.copyWith(error: message);
    }
  }

  @override
  void dispose() {
    _connSub?.cancel();
    _socket.off('tracking_status', _onStatus);
    _socket.off('tracking_started', _onStarted);
    _socket.off('tracking_stopped', _onStopped);
    _socket.off('tracking_error', _onError);
    _socket.leaveBookingRoom();
    unawaited(_location.stop());
    super.dispose();
  }
}

final providerTripProvider = StateNotifierProvider.autoDispose
    .family<ProviderTripNotifier, ProviderTripState, ProviderTripArgs>(
  (ref, args) => ProviderTripNotifier(args),
);
