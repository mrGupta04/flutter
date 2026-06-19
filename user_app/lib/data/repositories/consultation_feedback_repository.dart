import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../services/dio_service.dart';

class ConsultationFeedbackRepository {
  ConsultationFeedbackRepository({DioService? dioService})
      : _dio = dioService ?? DioService();

  final DioService _dio;

  Future<void> submitFeedback({
    required String bookingId,
    required int rating,
    String? comment,
  }) async {
    try {
      await _dio.post(
        AppConstants.endpointConsultationFeedback(bookingId),
        data: {
          'rating': rating,
          if (comment != null && comment.trim().isNotEmpty)
            'comment': comment.trim(),
        },
      );
    } on DioException catch (e) {
      throw _messageFromDio(e);
    }
  }

  Future<void> dismissFeedback(String bookingId) async {
    try {
      await _dio.post(
        AppConstants.endpointConsultationFeedbackDismiss(bookingId),
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
