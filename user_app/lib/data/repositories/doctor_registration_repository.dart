import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/token_storage.dart';
import '../../core/utils/doctor_presence_utils.dart';
import '../../data/models/models.dart';
import '../../data/services/dio_service.dart';

/// Doctor discovery repository for the patient marketplace.
class DoctorRegistrationRepository {
  final DioService _dioService;

  DoctorRegistrationRepository({DioService? dioService})
      : _dioService = dioService ?? DioService();

  /// Public list of verified doctors (no auth).
  Future<ApiResponse<List<DoctorModel>>> getVerifiedDoctors({
    int page = 1,
    int pageSize = 20,
    String? query,
    String? city,
    String? specialization,
    ConsultationType? consultationType,
  }) async {
    try {
      final response = await _dioService.get(
        AppConstants.endpointVerifiedDoctors,
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
          if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
          if (specialization != null && specialization.trim().isNotEmpty)
            'specialization': specialization.trim(),
          if (consultationType != null)
            'consultationType': consultationType.apiValue,
        },
      );

      final body = response.data as Map<String, dynamic>;
      final list = extractApiList(body['data'])
          .map((e) => DoctorModel.fromJson(e as Map<String, dynamic>))
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

  /// Lightweight live-status poll for doctor cards (presence only).
  Future<ApiResponse<Map<String, bool>>> getDoctorsLiveStatus(
    List<String> doctorIds,
  ) async {
    final ids = doctorIds.where((id) => id.trim().isNotEmpty).toList();
    if (ids.isEmpty) {
      return ApiResponse(success: true, statusCode: 200, data: const {});
    }

    try {
      final response = await _dioService.get(
        AppConstants.endpointDoctorLiveStatus,
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
    } catch (_) {
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

  /// Get doctor profile for patient booking flows.
  Future<ApiResponse<DoctorModel>> getDoctorProfile({
    String? doctorId,
  }) async {
    try {
      final id = doctorId ?? await TokenStorage.instance.getDoctorId();
      if (id == null || id.isEmpty) {
        return ApiResponse(
          success: false,
          error: 'Doctor ID not found',
          statusCode: 400,
        );
      }

      final response = await _dioService.get(
        AppConstants.endpointGetProfile,
        queryParameters: {
          'doctorId': id,
        },
      );

      return ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => DoctorModel.fromJson(json as Map<String, dynamic>),
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
    String message = 'An error occurred';
    int statusCode = 500;

    if (error.type == DioExceptionType.connectionTimeout) {
      message = 'Connection timeout. Please try again.';
      statusCode = 408;
    } else if (error.type == DioExceptionType.receiveTimeout) {
      message = 'Request timeout. Please try again.';
      statusCode = 408;
    } else if (error.type == DioExceptionType.connectionError) {
      message = AppConstants.errorNetworkException;
    } else if (error.type == DioExceptionType.badResponse) {
      statusCode = error.response?.statusCode ?? 500;
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        message = (data['error'] ?? data['message'] ?? 'Server error') as String;
      }
    } else if (error.type == DioExceptionType.unknown) {
      message = AppConstants.errorNetworkException;
    }

    return ApiResponse<T>(
      success: false,
      error: message,
      statusCode: statusCode,
    );
  }
}
