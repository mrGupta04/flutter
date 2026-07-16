import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../services/dio_service.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic> data;
  final DateTime? createdAt;
  final DateTime? readAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.data = const {},
    this.createdAt,
    this.readAt,
  });

  bool get isUnread => readAt == null;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      type: json['type']?.toString() ?? 'general',
      data: json['data'] is Map
          ? Map<String, dynamic>.from(json['data'] as Map)
          : const {},
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      readAt: json['readAt'] != null
          ? DateTime.tryParse(json['readAt'].toString())
          : null,
    );
  }
}

class NotificationsRepository {
  NotificationsRepository({DioService? dioService})
      : _dio = dioService ?? DioService();

  final DioService _dio;

  Future<({List<AppNotification> notifications, int unreadCount})> list({
    bool unreadOnly = false,
  }) async {
    try {
      final response = await _dio.get(
        AppConstants.endpointPatientNotifications,
        queryParameters: {
          if (unreadOnly) 'unreadOnly': 'true',
        },
      );
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      final list = (data['notifications'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((e) => AppNotification.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      final unread = (data['unreadCount'] as num?)?.toInt() ?? 0;
      return (notifications: list, unreadCount: unread);
    } on DioException catch (e) {
      throw _messageFromDio(e);
    }
  }

  Future<void> markRead(String id) async {
    try {
      await _dio.post(
        AppConstants.endpointPatientNotificationRead(id),
        data: const {},
      );
    } on DioException catch (e) {
      throw _messageFromDio(e);
    }
  }

  Future<void> markAllRead() async {
    try {
      await _dio.post(
        AppConstants.endpointPatientNotificationsReadAll,
        data: const {},
      );
    } on DioException catch (e) {
      throw _messageFromDio(e);
    }
  }

  String _messageFromDio(DioException error) {
    if (error.type == DioExceptionType.badResponse) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        return (data['error'] ?? data['message'] ?? 'Request failed') as String;
      }
    }
    if (error.type == DioExceptionType.connectionError) {
      return AppConstants.errorNetworkException;
    }
    return AppConstants.errorSomethingWentWrong;
  }
}
