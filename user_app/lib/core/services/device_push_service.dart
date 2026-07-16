import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../constants/app_constants.dart';
import '../../data/services/dio_service.dart';

/// Background FCM handler — must be a top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
}

/// Registers device tokens with the backend and shows foreground notifications.
///
/// Uses real FCM when Firebase is configured (`google-services.json` +
/// `PUSH` init succeeds). Otherwise registers a stable `dev:` token so the
/// inbox + backend push pipeline still works in local/dev builds.
class DevicePushService {
  DevicePushService._();
  static final DevicePushService instance = DevicePushService._();

  final _local = FlutterLocalNotificationsPlugin();
  final _dio = DioService();
  bool _initialized = false;
  bool _firebaseReady = false;
  String? _tokenEndpoint;

  Future<void> init({required String deviceTokenEndpoint}) async {
    _tokenEndpoint = deviceTokenEndpoint;
    if (_initialized) {
      await registerTokenWithBackend();
      return;
    }
    _initialized = true;

    await _initLocalNotifications();
    _firebaseReady = await _tryInitFirebase();

    if (_firebaseReady) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      FirebaseMessaging.onMessage.listen(_showForegroundMessage);
      FirebaseMessaging.instance.onTokenRefresh.listen((token) {
        _persistAndRegister(token);
      });
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
        '[Push] Firebase not configured — using dev device token. ($e)',
      );
      return false;
    }
  }

  Future<void> _initLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    const channel = AndroidNotificationChannel(
      'medconnect_alerts',
      'Care alerts',
      description: 'Booking and visit notifications',
      importance: Importance.high,
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _showForegroundMessage(RemoteMessage message) async {
    final title = message.notification?.title ?? message.data['title'] ?? 'Update';
    final body = message.notification?.body ?? message.data['body'] ?? '';
    await _local.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'medconnect_alerts',
          'Care alerts',
          channelDescription: 'Booking and visit notifications',
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: body.isNotEmpty
              ? BigTextStyleInformation(body)
              : null,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  Future<void> registerTokenWithBackend() async {
    final endpoint = _tokenEndpoint;
    if (endpoint == null || endpoint.isEmpty) return;

    String? token;
    if (_firebaseReady) {
      try {
        token = await FirebaseMessaging.instance.getToken();
      } catch (e) {
        debugPrint('[Push] getToken failed: $e');
      }
    }
    token ??= await _ensureDevToken();
    await _persistAndRegister(token);
  }

  Future<String> _ensureDevToken() async {
    final prefs = await SharedPreferences.getInstance();
    const key = 'dev_push_device_token';
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
      debugPrint('[Push] Registered device token (${token.length} chars)');
    } catch (e) {
      debugPrint('[Push] Failed to register token: $e');
    }
  }
}

/// Convenience endpoints used by each app.
class PushEndpoints {
  static const patient = AppConstants.endpointPatientDeviceToken;
}
