import 'dart:typed_data';

import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/token_storage.dart';
import '../models/api_response_model.dart';
import '../models/lab_model.dart';
import '../services/dio_service.dart';

typedef LabRegistrationExtrasMap = Map<String, dynamic>;

class LabRegistrationRepository {
  final DioService _dioService;

  LabRegistrationRepository({DioService? dioService})
      : _dioService = dioService ?? DioService();

  Future<ApiResponse<String>> uploadProfilePicture({
    required String labId,
    required Uint8List bytes,
    String? filename,
    String? mobileNumber,
  }) async {
    try {
      final response = await _dioService.uploadFile(
        AppConstants.endpointLabUploadProfile,
        bytes: bytes,
        filename: filename ?? 'logo.jpg',
        fieldName: 'file',
        additionalFields: {
          'labId': labId,
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
      return ApiResponse(success: false, error: 'An unexpected error occurred', statusCode: 500);
    }
  }

  Future<ApiResponse<LabDocument>> uploadDocument({
    required String labId,
    required Uint8List bytes,
    required String type,
    required String label,
    String? filename,
    String? mobileNumber,
  }) async {
    try {
      final response = await _dioService.uploadFile(
        AppConstants.endpointLabUploadDocument,
        bytes: bytes,
        filename: filename ?? 'document.pdf',
        fieldName: 'file',
        additionalFields: {
          'labId': labId,
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
        data: data != null ? LabDocument.fromJson(data) : null,
        statusCode: body['statusCode'] as int? ?? 200,
      );
    } on DioException catch (e) {
      return _handleError(e);
    } catch (_) {
      return ApiResponse(success: false, error: 'An unexpected error occurred', statusCode: 500);
    }
  }

  Future<ApiResponse<String>> uploadLabImage({
    required String labId,
    required Uint8List bytes,
    String? filename,
    String? mobileNumber,
  }) async {
    try {
      final response = await _dioService.uploadFile(
        AppConstants.endpointLabUploadImage,
        bytes: bytes,
        filename: filename ?? 'lab.jpg',
        fieldName: 'file',
        additionalFields: {
          'labId': labId,
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
      return ApiResponse(success: false, error: 'An unexpected error occurred', statusCode: 500);
    }
  }

  Future<ApiResponse<LabModel>> register(
    LabModel lab, {
    String? password,
    LabRegistrationExtrasMap? extras,
    List<Map<String, dynamic>>? offeredTestsPayload,
  }) async {
    try {
      final payload = {
        ...lab.toJson(),
        ...?extras,
        if (offeredTestsPayload != null) 'offeredTests': offeredTestsPayload,
      };
      if (password != null && password.isNotEmpty) {
        payload['password'] = password;
      }
      final response = await _dioService.post(
        AppConstants.endpointRegisterLab,
        data: payload,
      );

      final body = response.data as Map<String, dynamic>;
      final token = body['token'] as String?;
      final data = body['data'] as Map<String, dynamic>?;
      final entityId = data?['id'] as String?;
      if (token != null && token.isNotEmpty && entityId != null) {
        await TokenStorage.instance.saveToken(token);
      }

      return ApiResponse.fromJson(
        body,
        (json) => LabModel.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return _handleError(e);
    } catch (_) {
      return ApiResponse(success: false, error: 'An unexpected error occurred', statusCode: 500);
    }
  }

  Future<ApiResponse<LabModel>> getProfile({String? labId}) async {
    try {
      final response = await _dioService.get(
        AppConstants.endpointGetLabProfile,
        queryParameters: {if (labId != null) 'labId': labId},
      );

      return ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => LabModel.fromJson(json as Map<String, dynamic>),
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
