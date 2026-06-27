import 'dart:typed_data';

import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/token_storage.dart';
import '../models/api_response_model.dart';
import '../models/doctor_document_model.dart';
import '../models/doctor_availability_model.dart';
import '../models/doctor_booking_model.dart';
import '../../core/constants/doctor_availability_constants.dart';
import '../models/nurse_model.dart';
import '../services/dio_service.dart';

class NurseRegistrationRepository {
  final DioService _dioService;

  NurseRegistrationRepository({DioService? dioService})
      : _dioService = dioService ?? DioService();

  Future<ApiResponse<DoctorDocumentModel>> uploadDocument({
    required String nurseId,
    required String documentType,
    required Uint8List bytes,
    String? filename,
    String? mobileNumber,
  }) async {
    try {
      final response = await _dioService.uploadFile(
        AppConstants.endpointNurseUploadDocument,
        bytes: bytes,
        filename: filename ?? 'document.jpg',
        fieldName: 'file',
        additionalFields: {
          'nurseId': nurseId,
          'documentType': documentType,
          if (mobileNumber != null) 'mobileNumber': mobileNumber,
        },
      );

      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};

      return ApiResponse(
        success: body['success'] as bool? ?? false,
        message: body['message'] as String?,
        statusCode: body['statusCode'] as int? ?? 200,
        data: DoctorDocumentModel.fromJson(data),
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

  Future<ApiResponse<DoctorAvailabilityModel>> saveAvailability({
    required String nurseId,
    required Set<String> selectedSlotKeys,
    DateTime? weekStartDate,
  }) async {
    try {
      final response = await _dioService.put(
        AppConstants.endpointNurseAvailability,
        data: {
          'nurseId': nurseId,
          'weekStartDate': weekStartDate?.toIso8601String(),
          'slots': DoctorAvailabilityConstants.buildSlotPayload(selectedSlotKeys),
        },
      );

      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      if (data['nurseId'] != null && data['doctorId'] == null) {
        data['doctorId'] = data['nurseId'];
      }

      return ApiResponse(
        success: body['success'] as bool? ?? false,
        message: body['message'] as String?,
        statusCode: body['statusCode'] as int? ?? 200,
        data: DoctorAvailabilityModel.fromJson(data),
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

  Future<ApiResponse<DoctorAvailabilityModel>> getAvailability({
    String? nurseId,
  }) async {
    try {
      final id = nurseId ?? await TokenStorage.instance.getNurseId();
      if (id == null || id.isEmpty) {
        return ApiResponse(
          success: false,
          error: 'Nurse ID not found',
          statusCode: 400,
        );
      }
      final response = await _dioService.get(
        AppConstants.endpointNurseAvailability,
        queryParameters: {'nurseId': id},
      );
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      if (data['nurseId'] != null && data['doctorId'] == null) {
        data['doctorId'] = data['nurseId'];
      }
      return ApiResponse(
        success: body['success'] as bool? ?? true,
        statusCode: body['statusCode'] as int? ?? 200,
        data: DoctorAvailabilityModel.fromJson(data),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<List<DoctorBookingModel>>> getBookings({
    String? nurseId,
  }) async {
    try {
      final id = nurseId ?? await TokenStorage.instance.getNurseId();
      if (id == null || id.isEmpty) {
        return ApiResponse(
          success: false,
          error: 'Nurse ID not found',
          statusCode: 400,
        );
      }
      final response = await _dioService.get(
        AppConstants.endpointNurseBookings,
        queryParameters: {'nurseId': id},
      );
      final body = response.data as Map<String, dynamic>;
      final list = (body['data'] as List? ?? [])
          .map((e) => DoctorBookingModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return ApiResponse(
        success: body['success'] as bool? ?? true,
        statusCode: body['statusCode'] as int? ?? 200,
        data: list,
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<void>> approveHomeVisitRequest({
    required String bookingId,
    String? nurseId,
  }) async {
    try {
      final id = nurseId ?? await TokenStorage.instance.getNurseId();
      final response = await _dioService.post(
        AppConstants.endpointNurseApproveHomeVisit(bookingId),
        data: {if (id != null) 'nurseId': id},
      );
      final body = response.data as Map<String, dynamic>;
      return ApiResponse(
        success: body['success'] as bool? ?? false,
        message: body['message'] as String?,
        statusCode: body['statusCode'] as int? ?? 200,
        error: body['error'] as String?,
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<void>> rejectHomeVisitRequest({
    required String bookingId,
    String? nurseId,
  }) async {
    try {
      final id = nurseId ?? await TokenStorage.instance.getNurseId();
      final response = await _dioService.post(
        AppConstants.endpointNurseRejectHomeVisit(bookingId),
        data: {if (id != null) 'nurseId': id},
      );
      final body = response.data as Map<String, dynamic>;
      return ApiResponse(
        success: body['success'] as bool? ?? false,
        message: body['message'] as String?,
        statusCode: body['statusCode'] as int? ?? 200,
        error: body['error'] as String?,
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<List<DoctorDocumentModel>>> getDocuments({
    required String nurseId,
  }) async {
    try {
      final response = await _dioService.get(
        AppConstants.endpointNurseDocuments,
        queryParameters: {'nurseId': nurseId},
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

  Future<ApiResponse<String>> uploadProfilePicture({
    required String nurseId,
    required Uint8List bytes,
    String? filename,
    String? mobileNumber,
  }) async {
    try {
      final response = await _dioService.uploadFile(
        AppConstants.endpointNurseUploadProfile,
        bytes: bytes,
        filename: filename ?? 'profile.jpg',
        fieldName: 'file',
        additionalFields: {
          'nurseId': nurseId,
          if (mobileNumber != null) 'mobileNumber': mobileNumber,
        },
      );

      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>?;
      final url = data?['profilePicture'] as String?;

      return ApiResponse(
        success: body['success'] as bool? ?? false,
        message: body['message'] as String?,
        data: url,
        statusCode: body['statusCode'] as int? ?? 200,
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

  Future<ApiResponse<NurseModel>> register(
    NurseModel nurse, {
    String? password,
  }) async {
    try {
      final payload = nurse.toJson();
      if (password != null && password.isNotEmpty) {
        payload['password'] = password;
      }
      final response = await _dioService.post(
        AppConstants.endpointRegisterNurse,
        data: payload,
      );

      final body = response.data as Map<String, dynamic>;
      final token = body['token'] as String?;
      final nurseData = body['data'] as Map<String, dynamic>? ??
          body['nurse'] as Map<String, dynamic>?;
      final nurseId = nurseData?['id'] as String?;
      if (token != null && token.isNotEmpty && nurseId != null) {
        await TokenStorage.instance.saveProviderSession(
          providerType: 'nurse',
          token: token,
          entityId: nurseId,
        );
      }

      return ApiResponse.fromJson(
        body,
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

  Future<ApiResponse<NurseModel>> updateProfile(NurseModel nurse) async {
    try {
      final response = await _dioService.put(
        AppConstants.endpointUpdateNurseProfile,
        data: nurse.toJson(),
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

  Future<ApiResponse<NurseModel>> getProfile({String? nurseId}) async {
    try {
      final id = nurseId ?? await TokenStorage.instance.getNurseId();
      if (id == null || id.isEmpty) {
        return ApiResponse(
          success: false,
          error: 'Nurse ID not found',
          statusCode: 400,
        );
      }
      final response = await _dioService.get(
        AppConstants.endpointGetNurseProfile,
        queryParameters: {'nurseId': id},
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
  }) async {
    try {
      final response = await _dioService.get(
        AppConstants.endpointVerifiedNurses,
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          if (search != null && search.isNotEmpty) 'q': search,
          if (city != null && city.isNotEmpty) 'city': city,
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
