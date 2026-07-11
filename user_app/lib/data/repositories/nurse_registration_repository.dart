import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/doctor_presence_utils.dart';
import '../models/api_response_model.dart';
import '../models/nurse_model.dart';
import '../services/dio_service.dart';

/// Patient-facing nurse listing and profile API (registration is admin app only).
class NurseRegistrationRepository {
  final DioService _dioService;

  NurseRegistrationRepository({DioService? dioService})
      : _dioService = dioService ?? DioService();

  Future<ApiResponse<NurseModel>> getPublicProfile({
    required String nurseId,
  }) async {
    try {
      final response = await _dioService.get(
        AppConstants.endpointGetNurseProfile,
        queryParameters: {'nurseId': nurseId},
      );

      return ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => NurseModel.fromJson(json as Map<String, dynamic>),
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

  Future<ApiResponse<List<NurseModel>>> getVerifiedNurses({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? city,
    String? specialization,
    String? gender,
    bool? homeVisit,
  }) async {
    try {
      final response = await _dioService.get(
        AppConstants.endpointVerifiedNurses,
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          if (search != null && search.isNotEmpty) 'q': search,
          if (city != null && city.isNotEmpty) 'city': city,
          if (specialization != null && specialization.isNotEmpty)
            'specialization': specialization,
          if (gender != null && gender.isNotEmpty) 'gender': gender,
          if (homeVisit == true) 'homeVisit': 'true',
        },
      );

      final body = response.data as Map<String, dynamic>;
      final list = extractApiList(body['data'])
          .map((e) => NurseModel.fromJson(e as Map<String, dynamic>))
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

  /// Lightweight live-status poll for nurse cards (admin app presence).
  Future<ApiResponse<Map<String, bool>>> getNursesLiveStatus(
    List<String> nurseIds,
  ) async {
    final ids = nurseIds.where((id) => id.trim().isNotEmpty).toList();
    if (ids.isEmpty) {
      return ApiResponse(success: true, statusCode: 200, data: const {});
    }

    try {
      final response = await _dioService.get(
        AppConstants.endpointNurseLiveStatus,
        queryParameters: {'ids': ids.join(',')},
      );

      final body = response.data as Map<String, dynamic>;
      final rows = body['data'];
      final map = <String, bool>{};

      if (rows is List) {
        for (final row in rows) {
          if (row is! Map<String, dynamic>) continue;
          final id = row['id'] as String?;
          if (id == null || id.isEmpty) continue;
          final lastActiveAt = _parseLiveStatusTime(row['lastActiveAt']);
          final isLive = row['isLiveNow'] == true ||
              isDoctorLiveNow(lastActiveAt: lastActiveAt);
          map[id] = isLive;
        }
      }

      return ApiResponse(
        success: body['success'] as bool? ?? true,
        statusCode: body['statusCode'] as int? ?? 200,
        data: map,
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

  DateTime? _parseLiveStatusTime(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  ApiResponse<T> _handleError<T>(DioException error) {
    String message = AppConstants.errorSomethingWentWrong;
    int statusCode = 500;

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      message = AppConstants.errorTimeoutException;
      statusCode = 408;
    } else if (error.type == DioExceptionType.connectionError) {
      message = AppConstants.errorNetworkException;
    } else if (error.type == DioExceptionType.badResponse) {
      statusCode = error.response?.statusCode ?? 500;
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        message = (data['error'] ?? data['message'] ?? message) as String;
      }
    }

    return ApiResponse<T>(
      success: false,
      error: message,
      statusCode: statusCode,
    );
  }
}
