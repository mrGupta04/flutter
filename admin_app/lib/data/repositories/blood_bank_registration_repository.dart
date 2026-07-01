import 'dart:typed_data';

import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/token_storage.dart';
import '../models/api_response_model.dart';
import '../models/blood_bank_model.dart';
import '../services/dio_service.dart';

class BloodBankRegistrationRepository {
  final DioService _dioService;

  BloodBankRegistrationRepository({DioService? dioService})
      : _dioService = dioService ?? DioService();

  Future<ApiResponse<String>> uploadProfilePicture({
    required String bloodBankId,
    required Uint8List bytes,
    String? filename,
    String? mobileNumber,
  }) async {
    try {
      final response = await _dioService.uploadFile(
        AppConstants.endpointBloodBankUploadProfile,
        bytes: bytes,
        filename: filename ?? 'profile.jpg',
        fieldName: 'file',
        additionalFields: {
          'bloodBankId': bloodBankId,
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

  Future<ApiResponse<BloodBankModel>> register(
    BloodBankModel bloodBank, {
    String? password,
  }) async {
    try {
      final payload = bloodBank.toJson();
      if (password != null && password.isNotEmpty) {
        payload['password'] = password;
      }
      final response = await _dioService.post(
        AppConstants.endpointRegisterBloodBank,
        data: payload,
      );

      final body = response.data as Map<String, dynamic>;
      final token = body['token'] as String?;
      final data = body['data'] as Map<String, dynamic>?;
      final entityId = data?['id'] as String?;
      if (token != null && token.isNotEmpty && entityId != null) {
        await TokenStorage.instance.saveProviderSession(
          providerType: 'blood-bank',
          token: token,
          entityId: entityId,
        );
      }

      return ApiResponse.fromJson(
        body,
        (json) => BloodBankModel.fromJson(json as Map<String, dynamic>),
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

  Future<ApiResponse<BloodBankModel>> updateProfile(BloodBankModel bloodBank) async {
    try {
      final response = await _dioService.put(
        AppConstants.endpointUpdateBloodBankProfile,
        data: bloodBank.toJson(),
      );
      return ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => BloodBankModel.fromJson(json as Map<String, dynamic>),
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

  Future<ApiResponse<BloodBankModel>> getProfile({String? bloodBankId}) async {
    try {
      final id = bloodBankId ?? await TokenStorage.instance.getBloodBankId();
      final response = await _dioService.get(
        AppConstants.endpointGetBloodBankProfile,
        queryParameters: {if (id != null) 'bloodBankId': id},
      );

      return ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => BloodBankModel.fromJson(json as Map<String, dynamic>),
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

  Future<ApiResponse<Map<String, dynamic>>> getDashboard({String? bloodBankId}) async {
    try {
      final id = bloodBankId ?? await TokenStorage.instance.getBloodBankId();
      final response = await _dioService.get(
        AppConstants.endpointBloodBankDashboard,
        queryParameters: {if (id != null) 'bloodBankId': id},
      );
      final body = response.data as Map<String, dynamic>;
      return ApiResponse(
        success: body['success'] as bool? ?? true,
        data: body['data'] as Map<String, dynamic>? ?? {},
        statusCode: body['statusCode'] as int? ?? 200,
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> getBookings({String? status}) async {
    try {
      final id = await TokenStorage.instance.getBloodBankId();
      final response = await _dioService.get(
        AppConstants.endpointBloodBankBookings,
        queryParameters: {
          if (id != null) 'bloodBankId': id,
          if (status != null) 'status': status,
        },
      );
      final body = response.data as Map<String, dynamic>;
      final list = (body['data'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      return ApiResponse(success: true, data: list);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> getEmergencyRequests() async {
    try {
      final id = await TokenStorage.instance.getBloodBankId();
      final response = await _dioService.get(
        AppConstants.endpointBloodBankEmergency,
        queryParameters: {if (id != null) 'bloodBankId': id},
      );
      final body = response.data as Map<String, dynamic>;
      final list = (body['data'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      return ApiResponse(success: true, data: list);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<void>> updateOrderStatus(String orderId, String status) async {
    try {
      await _dioService.post(
        '${AppConstants.endpointBloodBankBookings}/$orderId/status',
        data: {'status': status},
      );
      return ApiResponse(success: true);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<void>> acceptEmergencyRequest(String requestId) async {
    try {
      final id = await TokenStorage.instance.getBloodBankId();
      await _dioService.post(
        '${AppConstants.endpointBloodBankEmergency}/$requestId/accept',
        data: {if (id != null) 'bloodBankId': id},
      );
      return ApiResponse(success: true);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<String>> uploadLogo({
    required String bloodBankId,
    required Uint8List bytes,
    String? filename,
  }) async {
    try {
      final response = await _dioService.uploadFile(
        AppConstants.endpointBloodBankUploadLogo,
        bytes: bytes,
        filename: filename ?? 'logo.jpg',
        fieldName: 'file',
        additionalFields: {'bloodBankId': bloodBankId},
      );
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>?;
      return ApiResponse(
        success: body['success'] as bool? ?? false,
        data: data?['logoUrl'] as String?,
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<BloodBankDocument>> uploadDocument({
    required String bloodBankId,
    required Uint8List bytes,
    required String type,
    required String label,
    String? filename,
    String? mobileNumber,
  }) async {
    try {
      final response = await _dioService.uploadFile(
        AppConstants.endpointBloodBankUploadDocument,
        bytes: bytes,
        filename: filename ?? 'document.pdf',
        fieldName: 'file',
        additionalFields: {
          'bloodBankId': bloodBankId,
          'type': type,
          'label': label,
          if (mobileNumber != null) 'mobileNumber': mobileNumber,
        },
      );
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>?;
      final docs = (data?['documents'] as List?) ?? [];
      final last = docs.isNotEmpty ? docs.last as Map<String, dynamic> : null;
      return ApiResponse(
        success: body['success'] as bool? ?? false,
        data: last != null ? BloodBankDocument.fromJson(last) : null,
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<String>> uploadGalleryImage({
    required String bloodBankId,
    required Uint8List bytes,
    String? filename,
  }) async {
    try {
      final response = await _dioService.uploadFile(
        AppConstants.endpointBloodBankUploadGallery,
        bytes: bytes,
        filename: filename ?? 'gallery.jpg',
        fieldName: 'file',
        additionalFields: {'bloodBankId': bloodBankId},
      );
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>?;
      final images = (data?['galleryImages'] as List?) ?? [];
      final url = images.isNotEmpty ? images.last.toString() : null;
      return ApiResponse(success: body['success'] as bool? ?? false, data: url);
    } on DioException catch (e) {
      return _handleError(e);
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
