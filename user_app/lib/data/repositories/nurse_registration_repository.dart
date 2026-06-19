import 'dart:typed_data';

import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/token_storage.dart';
import '../models/api_response_model.dart';
import '../models/nurse_model.dart';
import '../services/dio_service.dart';

class NurseRegistrationRepository {
  final DioService _dioService;

  NurseRegistrationRepository({DioService? dioService})
      : _dioService = dioService ?? DioService();

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

  Future<ApiResponse<NurseModel>> register(NurseModel nurse) async {
    try {
      final response = await _dioService.post(
        AppConstants.endpointRegisterNurse,
        data: nurse.toJson(),
      );

      final body = response.data as Map<String, dynamic>;
      final token = body['token'] as String?;
      if (token != null && token.isNotEmpty) {
        await TokenStorage.instance.saveNurseToken(token);
      }

      final nurseData = body['data'] as Map<String, dynamic>? ??
          body['nurse'] as Map<String, dynamic>?;
      if (nurseData != null && nurseData['id'] != null) {
        await TokenStorage.instance.saveNurseId(nurseData['id'] as String);
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

  /// Public profile for patient app (by nurse id).
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
    String? specialization,
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
          if (homeVisit == true) 'homeVisit': 'true',
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
