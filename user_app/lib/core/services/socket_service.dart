import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../config/api_config.dart';
import 'token_storage.dart';

typedef SocketEventHandler = void Function(dynamic data);

const _kTrackingEvents = [
  'doctor_location_update',
  'tracking_started',
  'tracking_stopped',
  'tracking_status',
  'tracking_error',
  'provider_offline',
  'app_notification',
  'booking-notification',
  'booking-status-update',
  'booking_status_update',
  'nurse-location-update',
  'nurse_location_update',
  'nurse-started-trip',
  'nurse-arrived',
  'ambulance_event',
  'ambulance_location_updated',
  'ambulance_request_created',
  'ambulance_assigned',
  'ambulance_driver_accepted',
  'ambulance_driver_en_route',
  'ambulance_arrived',
  'patient_picked_up',
  'ambulance_trip_started',
  'ambulance_destination_reached',
  'ambulance_trip_completed',
  'ambulance_request_cancelled',
];

/// Authenticated Socket.IO client with auto-reconnect and room restore.
class SocketService {
  SocketService._();

  static final SocketService instance = SocketService._();

  io.Socket? _socket;
  String? _joinedBookingId;
  final _handlers = <String, List<SocketEventHandler>>{};
  final _connection = StreamController<bool>.broadcast();
  bool _connected = false;

  Stream<bool> get connectionChanges async* {
    yield _connected;
    yield* _connection.stream;
  }

  bool get isConnected => _socket?.connected == true || _connected;
  String? get joinedBookingId => _joinedBookingId;

  void _emitConnected(bool connected) {
    if (_connected == connected) return;
    _connected = connected;
    if (!_connection.isClosed) _connection.add(connected);
  }

  Future<void> connectIfAuthenticated() async {
    try {
      await connect();
    } catch (_) {
      // Stay offline until the user signs in.
    }
  }

  Future<void> connect() async {
    if (_socket?.connected == true) {
      _emitConnected(true);
      return;
    }
    final token = await TokenStorage.instance.getPatientToken();
    if (token == null || token.isEmpty) {
      throw StateError('Sign in required for live tracking');
    }

    if (_socket != null) {
      _socket!.io.options?['auth'] = {'token': token};
      _socket!.io.options?['query'] = {'token': token};
      final waiting = _waitForConnection();
      _socket!.connect();
      await waiting;
      return;
    }

    final socket = io.io(
      ApiConfig.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setPath('/socket.io')
          .disableAutoConnect()
          .enableReconnection()
          .enableForceNew()
          .setReconnectionAttempts(50)
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(8000)
          .setAuth({'token': token})
          .setQuery({'token': token})
          .build(),
    );

    socket.onConnect((_) {
      _emitConnected(true);
      final bookingId = _joinedBookingId;
      if (bookingId != null && bookingId.isNotEmpty) {
        socket.emit('join_booking_room', {'bookingId': bookingId});
        socket.emit('join-booking-room', {'bookingId': bookingId});
      }
    });
    socket.onDisconnect((_) => _emitConnected(false));
    socket.onConnectError((_) => _emitConnected(false));
    socket.onReconnect((_) {
      _emitConnected(true);
      final bookingId = _joinedBookingId;
      if (bookingId != null && bookingId.isNotEmpty) {
        socket.emit('join_booking_room', {'bookingId': bookingId});
        socket.emit('join-booking-room', {'bookingId': bookingId});
      }
    });

    for (final event in _kTrackingEvents) {
      socket.on(event, (data) => _dispatch(event, data));
    }

    _socket = socket;
    final waiting = _waitForConnection();
    socket.connect();
    await waiting;
  }

  Future<void> _waitForConnection() async {
    if (_socket?.connected == true) {
      _emitConnected(true);
      return;
    }
    final done = Completer<void>();
    final sub = _connection.stream.listen((connected) {
      if (connected && !done.isCompleted) done.complete();
    });
    if (_socket?.connected == true) {
      _emitConnected(true);
      if (!done.isCompleted) done.complete();
    }
    final timer = Timer(const Duration(seconds: 8), () {
      if (!done.isCompleted) done.complete();
    });
    try {
      await done.future;
    } finally {
      timer.cancel();
      await sub.cancel();
    }
  }

  void on(String event, SocketEventHandler handler) {
    _handlers.putIfAbsent(event, () => []).add(handler);
  }

  void off(String event, SocketEventHandler handler) {
    _handlers[event]?.remove(handler);
  }

  void _dispatch(String event, dynamic data) {
    final list = List<SocketEventHandler>.from(_handlers[event] ?? const []);
    for (final handler in list) {
      handler(data);
    }
  }

  void joinBookingRoom(String bookingId) {
    _joinedBookingId = bookingId;
    _socket?.emit('join_booking_room', {'bookingId': bookingId});
    _socket?.emit('join-booking-room', {'bookingId': bookingId});
  }

  void leaveBookingRoom() {
    final bookingId = _joinedBookingId;
    if (bookingId != null && bookingId.isNotEmpty) {
      _socket?.emit('leave_booking_room', {'bookingId': bookingId});
      _socket?.emit('leave-booking-room', {'bookingId': bookingId});
    }
    _joinedBookingId = null;
  }

  Future<void> dispose() async {
    leaveBookingRoom();
    _socket?.dispose();
    _socket = null;
    _emitConnected(false);
  }
}
