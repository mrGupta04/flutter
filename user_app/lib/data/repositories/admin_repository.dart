import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../models/models.dart';
import '../models/nurse_model.dart';
import '../services/dio_service.dart';

/// Admin repository — talks to REST API with admin JWT.
class AdminRepository {
  final DioService _dioService;

  AdminRepository({DioService? dioService})
      : _dioService = dioService ?? DioService();

  Future<ApiResponse<List<DoctorModel>>> getDoctorsForVerification({
    int page = 1,
    int pageSize = 20,
    String? status,
  }) async {
    try {
      final response = await _dioService.get(
        AppConstants.endpointAdminDoctors,
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          if (status != null && status.isNotEmpty) 'status': status,
        },
      );

      final body = response.data as Map<String, dynamic>;
      final list = (body['data'] as List? ?? [])
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

  Future<ApiResponse<DoctorModel>> getDoctorDetails({
    required String doctorId,
  }) async {
    try {
      final response = await _dioService.get(
        AppConstants.endpointAdminDoctor(doctorId),
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

  Future<ApiResponse<DoctorModel>> approveDoctor({
    required String doctorId,
    String? approvalNotes,
  }) async {
    try {
      final response = await _dioService.post(
        AppConstants.endpointAdminApprove(doctorId),
        data: {
          if (approvalNotes != null) 'approvalNotes': approvalNotes,
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

  Future<ApiResponse<DoctorModel>> rejectDoctor({
    required String doctorId,
    required String rejectionReason,
  }) async {
    try {
      final response = await _dioService.post(
        AppConstants.endpointAdminReject(doctorId),
        data: {'rejectionReason': rejectionReason},
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

  Future<ApiResponse<List<DoctorDocumentModel>>> getDoctorDocuments({
    required String doctorId,
  }) async {
    try {
      final response = await _dioService.get(
        AppConstants.endpointAdminDoctorDocuments(doctorId),
      );

      final body = response.data as Map<String, dynamic>;
      final list = (body['data'] as List? ?? [])
          .map((e) => DoctorDocumentModel.fromJson(e as Map<String, dynamic>))
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

  // ——— Nurse admin ———

  Future<ApiResponse<List<NurseModel>>> getNursesForVerification({
    int page = 1,
    int pageSize = 20,
    String? status,
  }) async {
    try {
      final response = await _dioService.get(
        AppConstants.endpointAdminNurses,
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          if (status != null && status.isNotEmpty) 'status': status,
        },
      );

      final body = response.data as Map<String, dynamic>;
      final list = (body['data'] as List? ?? [])
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

  Future<ApiResponse<NurseModel>> getNurseDetails({
    required String nurseId,
  }) async {
    try {
      final response = await _dioService.get(
        AppConstants.endpointAdminNurse(nurseId),
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

  Future<ApiResponse<NurseModel>> approveNurse({
    required String nurseId,
    String? approvalNotes,
  }) async {
    try {
      final response = await _dioService.post(
        AppConstants.endpointAdminNurseApprove(nurseId),
        data: {
          if (approvalNotes != null) 'approvalNotes': approvalNotes,
        },
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

  Future<ApiResponse<NurseModel>> rejectNurse({
    required String nurseId,
    required String rejectionReason,
  }) async {
    try {
      final response = await _dioService.post(
        AppConstants.endpointAdminNurseReject(nurseId),
        data: {'rejectionReason': rejectionReason},
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
