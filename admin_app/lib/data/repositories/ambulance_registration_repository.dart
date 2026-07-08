import 'dart:typed_data';

import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/token_storage.dart';
import '../models/api_response_model.dart';
import '../models/ambulance_model.dart';
import '../models/doctor_document_model.dart';
import '../services/dio_service.dart';

class AmbulanceRegistrationRepository {
  final DioService _dioService;

  AmbulanceRegistrationRepository({DioService? dioService})
      : _dioService = dioService ?? DioService();

  Future<ApiResponse<List<DoctorDocumentModel>>> getDocuments({
    required String ambulanceId,
  }) async {
    try {
      final response = await _dioService.get(
        AppConstants.endpointAmbulanceDocuments,
        queryParameters: {'ambulanceId': ambulanceId},
      );
      final body = response.data as Map<String, dynamic>;
      final list = extractApiList(body['data'])
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
    required String ambulanceId,
    required Uint8List bytes,
    String? filename,
    String? mobileNumber,
  }) async {
    try {
      final response = await _dioService.uploadFile(
        AppConstants.endpointAmbulanceUploadProfile,
        bytes: bytes,
        filename: filename ?? 'profile.jpg',
        fieldName: 'file',
        additionalFields: {
          'ambulanceId': ambulanceId,
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

  Future<ApiResponse<String>> uploadDocument({
    required String ambulanceId,
    required String documentType,
    required Uint8List bytes,
    required String filename,
    String? vehicleId,
    String? driverId,
    String? mobileNumber,
  }) async {
    try {
      final response = await _dioService.uploadFile(
        AppConstants.endpointAmbulanceUploadDocument,
        bytes: bytes,
        filename: filename,
        fieldName: 'file',
        additionalFields: {
          'ambulanceId': ambulanceId,
          'documentType': documentType,
          if (vehicleId != null) 'vehicleId': vehicleId,
          if (driverId != null) 'driverId': driverId,
          if (mobileNumber != null) 'mobileNumber': mobileNumber,
        },
      );

      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>?;
      final url = data?['fileUrl'] as String?;

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

  Future<ApiResponse<AmbulanceModel>> register(
    AmbulanceModel ambulance, {
    String? password,
  }) async {
    try {
      final payload = ambulance.toJson();
      if (password != null && password.isNotEmpty) {
        payload['password'] = password;
      }
      final response = await _dioService.post(
        AppConstants.endpointRegisterAmbulance,
        data: payload,
      );

      final body = response.data as Map<String, dynamic>;
      final token = body['token'] as String?;
      final data = body['data'] as Map<String, dynamic>?;
      final entityId = data?['id'] as String?;
      if (token != null && token.isNotEmpty && entityId != null) {
        await TokenStorage.instance.saveProviderSession(
          providerType: 'ambulance',
          token: token,
          entityId: entityId,
        );
      }

      return ApiResponse.fromJson(
        body,
        (json) => AmbulanceModel.fromJson(json as Map<String, dynamic>),
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

  Future<ApiResponse<AmbulanceModel>> updateProfile(AmbulanceModel ambulance) async {
    try {
      final response = await _dioService.put(
        AppConstants.endpointUpdateAmbulanceProfile,
        data: ambulance.toJson(),
      );
      return ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => AmbulanceModel.fromJson(json as Map<String, dynamic>),
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

  Future<ApiResponse<AmbulanceModel>> getProfile({String? ambulanceId}) async {
    try {
      final id = ambulanceId ?? await TokenStorage.instance.getAmbulanceId();
      final response = await _dioService.get(
        AppConstants.endpointGetAmbulanceProfile,
        queryParameters: {if (id != null) 'ambulanceId': id},
      );

      return ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => AmbulanceModel.fromJson(json as Map<String, dynamic>),
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
