import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/token_storage.dart';
import '../models/api_response_model.dart';
import '../models/receptionist_model.dart';
import '../services/dio_service.dart';

class ReceptionistRepository {
  ReceptionistRepository({DioService? dioService})
      : _dio = dioService ?? DioService();

  final DioService _dio;

  Future<ApiResponse<ReceptionistModel>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        AppConstants.endpointReceptionistLogin,
        data: {'email': email.trim(), 'password': password},
      );
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      final token = body['token'] as String? ?? '';
      final profile = ReceptionistModel.fromJson(data);
      if (token.isNotEmpty && profile.id.isNotEmpty) {
        await TokenStorage.instance.saveProviderSession(
          providerType: 'receptionist',
          token: token,
          entityId: profile.id,
        );
      }
      return ApiResponse(
        success: body['success'] as bool? ?? true,
        message: body['message'] as String?,
        statusCode: body['statusCode'] as int? ?? 200,
        data: profile,
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<ReceptionistModel>> me() async {
    try {
      final response = await _dio.get(AppConstants.endpointReceptionistMe);
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      return ApiResponse(
        success: body['success'] as bool? ?? true,
        data: ReceptionistModel.fromJson(data),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<List<ClinicVisitModel>>> listBookings({
    String filter = 'today',
  }) async {
    try {
      final response = await _dio.get(
        AppConstants.endpointReceptionistBookings,
        queryParameters: {'filter': filter},
      );
      final body = response.data as Map<String, dynamic>;
      final list = extractApiList(body['data']);
      return ApiResponse(
        success: body['success'] as bool? ?? true,
        data: list
            .whereType<Map>()
            .map((e) => ClinicVisitModel.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<ClinicVisitModel>> verifyPatient({
    required String bookingId,
    required String otp,
  }) async {
    try {
      final response = await _dio.post(
        AppConstants.endpointReceptionistVerify(bookingId),
        data: {'otp': otp.trim()},
      );
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      return ApiResponse(
        success: body['success'] as bool? ?? true,
        message: body['message'] as String?,
        data: ClinicVisitModel.fromJson(data),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<void>> regenerateOtp(String bookingId) async {
    try {
      final response = await _dio.post(
        AppConstants.endpointReceptionistRegenOtp(bookingId),
        data: const {},
      );
      final body = response.data as Map<String, dynamic>;
      return ApiResponse(
        success: body['success'] as bool? ?? true,
        message: body['message'] as String?,
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<List<ReceptionistModel>>> listForDoctor() async {
    try {
      final response = await _dio.get(AppConstants.endpointDoctorReceptionists);
      final body = response.data as Map<String, dynamic>;
      final list = extractApiList(body['data']);
      return ApiResponse(
        success: body['success'] as bool? ?? true,
        data: list
            .whereType<Map>()
            .map((e) => ReceptionistModel.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<ReceptionistModel>> create({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      final response = await _dio.post(
        AppConstants.endpointDoctorReceptionists,
        data: {
          'name': name.trim(),
          'email': email.trim(),
          'password': password,
          if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        },
      );
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      return ApiResponse(
        success: body['success'] as bool? ?? true,
        message: body['message'] as String?,
        data: ReceptionistModel.fromJson(data),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<ReceptionistModel>> update({
    required String id,
    String? name,
    String? email,
    String? phone,
  }) async {
    try {
      final response = await _dio.patch(
        AppConstants.endpointDoctorReceptionist(id),
        data: {
          if (name != null) 'name': name.trim(),
          if (email != null) 'email': email.trim(),
          if (phone != null) 'phone': phone.trim(),
        },
      );
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      return ApiResponse(
        success: body['success'] as bool? ?? true,
        message: body['message'] as String?,
        data: ReceptionistModel.fromJson(data),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<ReceptionistModel>> setStatus({
    required String id,
    required String status,
  }) async {
    try {
      final response = await _dio.patch(
        AppConstants.endpointDoctorReceptionistStatus(id),
        data: {'status': status},
      );
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      return ApiResponse(
        success: body['success'] as bool? ?? true,
        data: ReceptionistModel.fromJson(data),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<void>> resetPassword({
    required String id,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        AppConstants.endpointDoctorReceptionistPassword(id),
        data: {'password': password},
      );
      final body = response.data as Map<String, dynamic>;
      return ApiResponse(
        success: body['success'] as bool? ?? true,
        message: body['message'] as String?,
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<void>> delete(String id) async {
    try {
      final response = await _dio.delete(AppConstants.endpointDoctorReceptionist(id));
      final body = response.data as Map<String, dynamic>;
      return ApiResponse(
        success: body['success'] as bool? ?? true,
        message: body['message'] as String?,
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  ApiResponse<T> _handleError<T>(DioException error) {
    var message = 'An error occurred';
    var statusCode = 500;
    if (error.type == DioExceptionType.badResponse) {
      statusCode = error.response?.statusCode ?? 500;
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        message = (data['error'] ?? data['message'] ?? 'Server error') as String;
      }
    } else if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.unknown) {
      message = AppConstants.errorNetworkException;
    }
    return ApiResponse(success: false, error: message, statusCode: statusCode);
  }
}
