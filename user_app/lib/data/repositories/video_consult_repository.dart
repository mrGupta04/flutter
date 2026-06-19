import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../models/video_session_model.dart';
import '../services/dio_service.dart';

class VideoConsultRepository {
  VideoConsultRepository({DioService? dioService})
      : _dio = dioService ?? DioService();

  final DioService _dio;

  Future<VideoSessionModel> fetchSession(String bookingId) async {
    try {
      final response = await _dio.get(
        AppConstants.endpointConsultationVideoSession(bookingId),
      );
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      return VideoSessionModel.fromJson(data);
    } on DioException catch (e) {
      throw _messageFromDio(e);
    }
  }

  Future<void> markJoined(String bookingId) async {
    try {
      await _dio.post(
        AppConstants.endpointConsultationVideoJoin(bookingId),
        data: const {},
      );
    } on DioException catch (e) {
      throw _messageFromDio(e);
    }
  }

  Future<void> markEnded(String bookingId) async {
    try {
      await _dio.post(
        AppConstants.endpointConsultationVideoEnd(bookingId),
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
        return (data['error'] ?? data['message'] ?? 'Request failed')
            as String;
      }
    }
    if (error.type == DioExceptionType.connectionError) {
      return AppConstants.errorNetworkException;
    }
    return AppConstants.errorSomethingWentWrong;
  }
}
