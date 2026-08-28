import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../constants/app_constants.dart';
import '../../data/services/dio_service.dart';

const kProviderAlertChannelId = 'medconnect_alerts';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (_) {}
}

typedef NotificationTapCallback = void Function(Map<String, dynamic> payload);

class DevicePushService with WidgetsBindingObserver {
  DevicePushService._();
  static final DevicePushService instance = DevicePushService._();

  final _local = FlutterLocalNotificationsPlugin();
  final _dio = DioService();
  bool _bootstrapped = false;
  bool _firebaseReady = false;
  bool _observerAttached = false;
  AppLifecycleState _lifecycle = AppLifecycleState.resumed;
  String? _tokenEndpoint;
  NotificationTapCallback? _onNotificationTap;
  NotificationTapCallback? onIncomingBooking;
  Map<String, dynamic>? _pendingTap;
  final _shownIds = <String>{};
  int _tokenRetries = 0;

  set onNotificationTap(NotificationTapCallback? handler) {
    _onNotificationTap = handler;
    final pending = _pendingTap;
    if (handler != null && pending != null) {
      _pendingTap = null;
      WidgetsBinding.instance.addPostFrameCallback((_) => handler(pending));
    }
  }

  bool get firebaseReady => _firebaseReady;
  bool get isAppForeground =>
      _lifecycle == AppLifecycleState.resumed ||
      _lifecycle == AppLifecycleState.inactive;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycle = state;
  }

  Future<void> bootstrap() async {
    if (_bootstrapped) return;
    _bootstrapped = true;
    if (!_observerAttached) {
      WidgetsBinding.instance.addObserver(this);
      _observerAttached = true;
    }
    await _initLocalNotifications();
    _firebaseReady = await _tryInitFirebase();
    if (_firebaseReady) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: false,
        badge: true,
        sound: false,
      );
      try {
        await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          announcement: true,
        );
      } catch (_) {}
      FirebaseMessaging.onMessage.listen(_showForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleRemoteTap);
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        _handleRemoteTap(initial);
      }
      FirebaseMessaging.instance.onTokenRefresh.listen(_persistAndRegister);
    }
  }

  Future<void> promptOsPermission() async {
    if (_firebaseReady) {
      try {
        await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          announcement: true,
        );
      } catch (_) {}
    }
    await _requestOsPermission();
  }

  Future<void> init({required String deviceTokenEndpoint}) async {
    _tokenEndpoint = deviceTokenEndpoint;
    if (!_bootstrapped) {
      await bootstrap();
    }
    await registerTokenWithBackend();
  }

  Future<bool> _tryInitFirebase() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      return true;
    } catch (e) {
      debugPrint(
        '[Push] Firebase not configured — using socket banners + dev token. ($e)',
      );
      return false;
    }
  }

  Future<void> _initLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _local.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (response) {
        final payload = _decodePayload(response.payload);
        if (payload.isEmpty) return;
        final handler = _onNotificationTap;
        if (handler != null) {
          handler(payload);
        } else {
          _pendingTap = payload;
        }
      },
    );
    const channel = AndroidNotificationChannel(
      kProviderAlertChannelId,
      'Provider alerts',
      description: 'Booking requests and patient messages',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _requestOsPermission() async {
    try {
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (_) {}
    try {
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        await Permission.notification.request();
      }
    } catch (_) {}
  }

  Map<String, dynamic> _decodePayload(String? raw) {
    if (raw == null || raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return const {};
  }

  Map<String, dynamic> _payloadFromRemote(RemoteMessage message) {
    final data = Map<String, dynamic>.from(message.data);
    data['title'] ??= message.notification?.title;
    data['body'] ??= message.notification?.body;
    data['id'] ??= data['notificationId'] ?? message.messageId;
    return data;
  }

  void _handleRemoteTap(RemoteMessage message) {
    final payload = _payloadFromRemote(message);
    final handler = _onNotificationTap;
    if (handler != null) {
      handler(payload);
    } else {
      _pendingTap = payload;
    }
  }

  bool _isIncomingBooking(String type, Map<String, dynamic> extra) {
    final action = extra['action']?.toString().toLowerCase() ?? '';
    final value = type.toLowerCase();
    return value == 'home_visit_request' ||
        action == 'home_visit_request' ||
        action == 'incoming_booking_request';
  }

  Future<void> _showForegroundMessage(RemoteMessage message) async {
    final data = _payloadFromRemote(message);
    final type = data['type']?.toString() ?? '';
    if (_isIncomingBooking(type, data) && isAppForeground) {
      onIncomingBooking?.call(data);
      return;
    }
    await showLocalAlert(
      id: data['notificationId']?.toString() ??
          data['id']?.toString() ??
          message.messageId ??
          '${message.hashCode}',
      title: data['title']?.toString() ?? 'Update',
      body: data['body']?.toString() ?? '',
      type: data['type']?.toString() ?? '',
      extra: data,
    );
  }

  Future<void> showRealtimeAlert({
    required String title,
    String body = '',
    String id = '',
    String type = '',
    Map<String, dynamic> extra = const {},
  }) {
    if (_isIncomingBooking(type, extra) && isAppForeground) {
      onIncomingBooking?.call({
        'id': id,
        'type': type,
        'title': title,
        'body': body,
        ...extra,
      });
      return Future.value();
    }
    if (_firebaseReady && !isAppForeground) {
      return Future.value();
    }
    return showLocalAlert(
      title: title,
      body: body,
      id: id,
      type: type,
      extra: extra,
    );
  }

  Future<void> showLocalAlert({
    required String title,
    String body = '',
    String id = '',
    String type = '',
    Map<String, dynamic> extra = const {},
  }) async {
    if (id.isNotEmpty && !_shownIds.add(id)) return;
    if (_shownIds.length > 80) {
      _shownIds.remove(_shownIds.first);
    }
    final payload = jsonEncode({
      'id': id,
      'type': type,
      'title': title,
      'body': body,
      ...extra,
    });
    await _local.show(
      id.hashCode == 0 ? title.hashCode : id.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          kProviderAlertChannelId,
          'Provider alerts',
          channelDescription: 'Booking requests and patient messages',
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          enableVibration: true,
          category: AndroidNotificationCategory.message,
          visibility: NotificationVisibility.public,
          ticker: title,
          styleInformation:
              body.isNotEmpty ? BigTextStyleInformation(body) : null,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  Future<void> registerTokenWithBackend() async {
    final endpoint = _tokenEndpoint;
    if (endpoint == null || endpoint.isEmpty) return;

    String? token;
    if (_firebaseReady) {
      try {
        await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        token = await FirebaseMessaging.instance.getToken();
      } catch (e) {
        debugPrint('[Push] getToken failed: $e');
      }
      if (token == null || token.isEmpty || token.startsWith('dev_')) {
        if (_tokenRetries >= 5) {
          debugPrint('[Push] Gave up waiting for a real FCM token');
          return;
        }
        _tokenRetries += 1;
        debugPrint(
          '[Push] Real FCM token not ready yet — retrying (not using a dev token)',
        );
        Future<void>.delayed(const Duration(seconds: 4), () {
          if (_tokenEndpoint == endpoint) {
            registerTokenWithBackend();
          }
        });
        return;
      }
      _tokenRetries = 0;
    } else {
      token = await _ensureDevToken();
    }
    await _persistAndRegister(token);
  }

  Future<String> _ensureDevToken() async {
    final prefs = await SharedPreferences.getInstance();
    const key = 'dev_push_device_token_provider';
    var token = prefs.getString(key);
    if (token == null || token.isEmpty) {
      token = 'dev_${const Uuid().v4()}';
      await prefs.setString(key, token);
    }
    return token;
  }

  Future<void> _persistAndRegister(String token) async {
    final endpoint = _tokenEndpoint;
    if (endpoint == null || endpoint.isEmpty || token.isEmpty) return;
    try {
      await _dio.post(endpoint, data: {'token': token});
      debugPrint('[Push] Registered provider device token');
    } catch (e) {
      debugPrint('[Push] Failed to register token: $e');
    }
  }

  static String endpointForRole(String role) {
    return role == 'nurse'
        ? AppConstants.endpointNurseDeviceToken
        : AppConstants.endpointDoctorDeviceToken;
  }
}
