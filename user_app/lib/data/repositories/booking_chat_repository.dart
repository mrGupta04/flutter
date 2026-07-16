import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../services/dio_service.dart';

class ChatMessage {
  final String id;
  final String bookingId;
  final String senderType;
  final String senderId;
  final String body;
  final DateTime? createdAt;

  const ChatMessage({
    required this.id,
    required this.bookingId,
    required this.senderType,
    required this.senderId,
    required this.body,
    this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      bookingId: json['bookingId']?.toString() ?? '',
      senderType: json['senderType']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}

class BookingChatRepository {
  BookingChatRepository({DioService? dioService})
      : _dio = dioService ?? DioService();

  final DioService _dio;

  Future<List<ChatMessage>> list(String bookingId) async {
    try {
      final response =
          await _dio.get(AppConstants.endpointPatientBookingChat(bookingId));
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as List<dynamic>? ?? [];
      return data
          .whereType<Map>()
          .map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      throw _messageFromDio(e);
    }
  }

  Future<ChatMessage> send(String bookingId, String message) async {
    try {
      final response = await _dio.post(
        AppConstants.endpointPatientBookingChat(bookingId),
        data: {'body': message},
      );
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      return ChatMessage.fromJson(data);
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
