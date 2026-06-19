import 'package:dio/dio.dart';

import '../../core/constants/app_constants.dart';
import '../models/api_response_model.dart';
import '../models/doctor_feedback_model.dart';
import '../services/dio_service.dart';

class DoctorFeedbackRepository {
  DoctorFeedbackRepository({DioService? dioService})
      : _dioService = dioService ?? DioService();

  final DioService _dioService;

  Future<ApiResponse<DoctorFeedbackSummary>> getDoctorFeedback({
    required String doctorId,
    int limit = 20,
  }) async {
    try {
      final response = await _dioService.get(
        AppConstants.endpointDoctorFeedback,
        queryParameters: {
          'doctorId': doctorId,
          'limit': limit,
        },
      );

      final body = response.data as Map<String, dynamic>;
      final raw = body['data'];
      final map = raw is Map<String, dynamic> ? raw : <String, dynamic>{};

      return ApiResponse(
        success: body['success'] as bool? ?? true,
        statusCode: body['statusCode'] as int? ?? 200,
        data: DoctorFeedbackSummary.fromJson(map),
      );
    } on DioException catch (e) {
      return _handleError(e);
    } catch (_) {
      return ApiResponse(
        success: false,
        error: 'An unexpected error occurred',
        statusCode: 500,
      );
    }
  }

  ApiResponse<T> _handleError<T>(DioException error) {
    String message = 'An error occurred';
    int statusCode = 500;

    if (error.type == DioExceptionType.connectionError) {
      message = AppConstants.errorNetworkException;
    } else if (error.type == DioExceptionType.badResponse) {
      statusCode = error.response?.statusCode ?? 500;
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        message = (data['error'] ?? data['message'] ?? 'Server error') as String;
      }
    }

    return ApiResponse<T>(
      success: false,
      error: message,
      statusCode: statusCode,
    );
  }
}
