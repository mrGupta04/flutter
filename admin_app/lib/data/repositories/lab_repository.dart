import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../models/api_response_model.dart';
import '../models/lab_model.dart';
import '../services/dio_service.dart';

class LabSearchParams {
  const LabSearchParams({
    this.query,
    this.city,
    this.testId,
    this.homeCollection,
    this.latitude,
    this.longitude,
  });

  final String? query;
  final String? city;
  final String? testId;
  final bool? homeCollection;
  final double? latitude;
  final double? longitude;
}

class LabRepository {
  final DioService _dioService;

  LabRepository({DioService? dioService}) : _dioService = dioService ?? DioService();

  Future<ApiResponse<List<LabModel>>> searchVerified(LabSearchParams params) async {
    try {
      final response = await _dioService.get(
        AppConstants.endpointVerifiedLabs,
        queryParameters: {
          if (params.query != null && params.query!.isNotEmpty) 'q': params.query,
          if (params.city != null && params.city!.isNotEmpty) 'city': params.city,
          if (params.testId != null && params.testId!.isNotEmpty)
            'testId': params.testId,
          if (params.homeCollection == true) 'homeCollection': 'true',
          if (params.latitude != null) 'latitude': params.latitude.toString(),
          if (params.longitude != null) 'longitude': params.longitude.toString(),
        },
      );

      final body = response.data as Map<String, dynamic>;
      final list = (body['data'] as List?)
              ?.map((e) => LabModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];

      return ApiResponse(
        success: body['success'] as bool? ?? false,
        message: body['message'] as String?,
        data: list,
        statusCode: body['statusCode'] as int? ?? 200,
      );
    } on DioException catch (e) {
      return _handleError(e);
    } catch (_) {
      return ApiResponse(success: false, error: 'An unexpected error occurred', statusCode: 500);
    }
  }

  ApiResponse<T> _handleError<T>(DioException error) {
    String message = AppConstants.errorSomethingWentWrong;
    int statusCode = 500;
    if (error.type == DioExceptionType.badResponse) {
      statusCode = error.response?.statusCode ?? 500;
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        message = (data['error'] ?? data['message'] ?? message) as String;
      }
    }
    return ApiResponse<T>(success: false, error: message, statusCode: statusCode);
  }
}
