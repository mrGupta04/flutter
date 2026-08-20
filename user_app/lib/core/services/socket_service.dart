import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../config/api_config.dart';
import 'token_storage.dart';

typedef SocketEventHandler = void Function(dynamic data);

/// Authenticated Socket.IO client with auto-reconnect and room restore.
class SocketService {
  SocketService._();

  static final SocketService instance = SocketService._();

  io.Socket? _socket;
  String? _joinedBookingId;
  final _handlers = <String, List<SocketEventHandler>>{};
  final _connection = StreamController<bool>.broadcast();

  Stream<bool> get connectionChanges => _connection.stream;
  bool get isConnected => _socket?.connected == true;
  String? get joinedBookingId => _joinedBookingId;

  Future<void> connectIfAuthenticated() async {
    try {
      await connect();
    } catch (_) {
      // Stay offline until the user signs in.
    }
  }

  Future<void> connect() async {
    if (_socket?.connected == true) return;
    final token = await TokenStorage.instance.getPatientToken();
    if (token == null || token.isEmpty) {
      throw StateError('Sign in required for live tracking');
    }

    if (_socket != null) {
      _socket!.io.options?['auth'] = {'token': token};
      _socket!.connect();
      return;
    }

    final socket = io.io(
      ApiConfig.socketUrl,
      io.OptionBuilder()
          .setTransports(['polling', 'websocket'])
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
      if (!_connection.isClosed) _connection.add(true);
      final bookingId = _joinedBookingId;
      if (bookingId != null && bookingId.isNotEmpty) {
        socket.emit('join_booking_room', {'bookingId': bookingId});
        socket.emit('join-booking-room', {'bookingId': bookingId});
      }
    });
    socket.onDisconnect((_) {
      if (!_connection.isClosed) _connection.add(false);
    });
    socket.onConnectError((_) {
      if (!_connection.isClosed) _connection.add(false);
    });
    socket.onReconnect((_) {
      if (!_connection.isClosed) _connection.add(true);
      final bookingId = _joinedBookingId;
      if (bookingId != null && bookingId.isNotEmpty) {
        socket.emit('join_booking_room', {'bookingId': bookingId});
        socket.emit('join-booking-room', {'bookingId': bookingId});
      }
    });

    for (final event in [
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
      'nurse-started-trip',
      'nurse-arrived',
    ]) {
      socket.on(event, (data) => _dispatch(event, data));
    }

    _socket = socket;
    socket.connect();
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
  }
}
