import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../models/api_response_model.dart';
import '../models/blood_bank_model.dart';
import '../services/dio_service.dart';

class BloodBankRepository {
  final DioService _dioService;

  BloodBankRepository({DioService? dioService})
      : _dioService = dioService ?? DioService();

  Future<ApiResponse<List<BloodBankModel>>> getVerifiedBloodBanks({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? city,
    bool? available24x7,
    String? bloodGroup,
    bool? hasApheresis,
  }) async {
    try {
      final response = await _dioService.get(
        AppConstants.endpointVerifiedBloodBanks,
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          if (search != null && search.isNotEmpty) 'q': search,
          if (city != null && city.isNotEmpty) 'city': city,
          if (available24x7 == true) 'available24x7': 'true',
          if (bloodGroup != null && bloodGroup.isNotEmpty) 'bloodGroup': bloodGroup,
          if (hasApheresis == true) 'hasApheresis': 'true',
        },
      );

      final body = response.data as Map<String, dynamic>;
      final list = (body['data'] as List? ?? [])
          .map((e) => BloodBankModel.fromJson(e as Map<String, dynamic>))
          .toList();

      return ApiResponse(
        success: body['success'] as bool? ?? true,
        statusCode: body['statusCode'] as int? ?? 200,
        data: list,
      );
    } on DioException catch (e) {
      return _handleError(e);
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'An unexpected error occurred',
        statusCode: 500,
      );
    }
  }

  ApiResponse<T> _handleError<T>(DioException error) {
    String message = AppConstants.errorSomethingWentWrong;
    int statusCode = 500;
    if (error.type == DioExceptionType.connectionError) {
      message = AppConstants.errorNetworkException;
    } else if (error.type == DioExceptionType.badResponse) {
      statusCode = error.response?.statusCode ?? 500;
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        message = (data['error'] ?? data['message'] ?? message) as String;
      }
    }
    return ApiResponse<T>(success: false, error: message, statusCode: statusCode);
  }
}
