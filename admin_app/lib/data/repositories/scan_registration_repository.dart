import 'dart:typed_data';

import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/token_storage.dart';
import '../models/api_response_model.dart';
import '../models/scan_center_model.dart';
import '../services/dio_service.dart';

class ScanRegistrationRepository {
  final DioService _dioService;

  ScanRegistrationRepository({DioService? dioService})
      : _dioService = dioService ?? DioService();

  Future<ApiResponse<String>> uploadProfilePicture({
    required String scanCenterId,
    required Uint8List bytes,
    String? filename,
    String? mobileNumber,
  }) async {
    try {
      final response = await _dioService.uploadFile(
        AppConstants.endpointScanUploadProfile,
        bytes: bytes,
        filename: filename ?? 'logo.jpg',
        fieldName: 'file',
        additionalFields: {
          'scanCenterId': scanCenterId,
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
    } catch (_) {
      return ApiResponse(
        success: false,
        error: 'An unexpected error occurred',
        statusCode: 500,
      );
    }
  }

  Future<ApiResponse<ScanCenterDocument>> uploadDocument({
    required String scanCenterId,
    required Uint8List bytes,
    required String type,
    required String label,
    String? filename,
    String? mobileNumber,
  }) async {
    try {
      final response = await _dioService.uploadFile(
        AppConstants.endpointScanUploadDocument,
        bytes: bytes,
        filename: filename ?? 'document.pdf',
        fieldName: 'file',
        additionalFields: {
          'scanCenterId': scanCenterId,
          'type': type,
          'label': label,
          if (mobileNumber != null) 'mobileNumber': mobileNumber,
        },
      );

      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>?;

      return ApiResponse(
        success: body['success'] as bool? ?? false,
        message: body['message'] as String?,
        data: data != null ? ScanCenterDocument.fromJson(data) : null,
        statusCode: body['statusCode'] as int? ?? 200,
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

  Future<ApiResponse<String>> uploadCenterImage({
    required String scanCenterId,
    required Uint8List bytes,
    String? filename,
    String? mobileNumber,
  }) async {
    try {
      final response = await _dioService.uploadFile(
        AppConstants.endpointScanUploadImage,
        bytes: bytes,
        filename: filename ?? 'center.jpg',
        fieldName: 'file',
        additionalFields: {
          'scanCenterId': scanCenterId,
          if (mobileNumber != null) 'mobileNumber': mobileNumber,
        },
      );

      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>?;
      final url = data?['url'] as String?;

      return ApiResponse(
        success: body['success'] as bool? ?? false,
        message: body['message'] as String?,
        data: url,
        statusCode: body['statusCode'] as int? ?? 200,
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

  Future<ApiResponse<ScanCenterModel>> register(
    ScanCenterModel center, {
    String? password,
  }) async {
    try {
      final payload = center.toJson();
      if (password != null && password.isNotEmpty) {
        payload['password'] = password;
      }
      final response = await _dioService.post(
        AppConstants.endpointRegisterScanCenter,
        data: payload,
      );

      final body = response.data as Map<String, dynamic>;
      final token = body['token'] as String?;
      final data = body['data'] as Map<String, dynamic>?;
      final entityId = data?['id'] as String?;
      if (token != null && token.isNotEmpty && entityId != null) {
        await TokenStorage.instance.saveProviderSession(
          providerType: 'scan-center',
          token: token,
          entityId: entityId,
        );
      }

      return ApiResponse.fromJson(
        body,
        (json) => ScanCenterModel.fromJson(json as Map<String, dynamic>),
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

  Future<ApiResponse<ScanCenterModel>> getProfile({String? scanCenterId}) async {
    try {
      final id = scanCenterId ?? await TokenStorage.instance.getScanCenterId();
      final response = await _dioService.get(
        AppConstants.endpointGetScanCenterProfile,
        queryParameters: {if (id != null) 'scanCenterId': id},
      );

      return ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ScanCenterModel.fromJson(json as Map<String, dynamic>),
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

  Future<ApiResponse<ScanCenterModel>> updateProfile(ScanCenterModel center) async {
    try {
      final response = await _dioService.put(
        AppConstants.endpointUpdateScanCenterProfile,
        data: center.toJson(),
      );

      return ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ScanCenterModel.fromJson(json as Map<String, dynamic>),
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

    return ApiResponse<T>(success: false, error: message, statusCode: statusCode);
  }
}
