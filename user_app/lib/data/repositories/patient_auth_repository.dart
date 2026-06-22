import 'dart:typed_data';

import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/phone_countries.dart';
import '../../core/services/token_storage.dart';
import '../models/api_response_model.dart';
import '../models/patient_user_model.dart';
import '../services/dio_service.dart';

class PatientAuthRepository {
  PatientAuthRepository({DioService? dioService})
      : _dio = dioService ?? DioService();

  final DioService _dio;

  Future<ApiResponse<PatientUserModel>> register({
    required String firstName,
    String? lastName,
    required String email,
    required String mobileNumber,
    String countryCode = PhoneCountries.defaultDialCode,
    required String password,
    required int age,
    required String gender,
    required String aadhaarNumber,
    required Uint8List profilePictureBytes,
    required String profilePictureFileName,
    required Uint8List aadhaarCardBytes,
    required String aadhaarCardFileName,
  }) async {
    try {
      final formData = FormData();
      formData.fields.addAll([
        MapEntry('firstName', firstName),
        if (lastName != null && lastName.isNotEmpty)
          MapEntry('lastName', lastName),
        MapEntry('email', email),
        MapEntry('mobileNumber', mobileNumber),
        MapEntry('countryCode', countryCode),
        MapEntry('password', password),
        MapEntry('age', age.toString()),
        MapEntry('gender', gender),
        MapEntry('aadhaarNumber', aadhaarNumber),
      ]);
      formData.files.addAll([
        MapEntry(
          'profilePicture',
          MultipartFile.fromBytes(
            profilePictureBytes,
            filename: profilePictureFileName,
          ),
        ),
        MapEntry(
          'aadhaarCard',
          MultipartFile.fromBytes(
            aadhaarCardBytes,
            filename: aadhaarCardFileName,
          ),
        ),
      ]);

      final response = await _dio.postFormData(
        AppConstants.endpointPatientRegister,
        data: formData,
      );
      return _parseAuthResponse(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<PatientUserModel>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        AppConstants.endpointPatientLogin,
        data: {'email': email, 'password': password},
      );
      return _parseAuthResponse(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<PatientUserModel>> fetchProfile() async {
    try {
      final response = await _dio.get(AppConstants.endpointPatientProfile);
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      final user = PatientUserModel.fromJson(data);
      await _persistUserSession(user);
      return ApiResponse(
        success: body['success'] as bool? ?? true,
        message: body['message'] as String?,
        statusCode: body['statusCode'] as int? ?? 200,
        data: user,
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<void> logout() async {
    await TokenStorage.instance.clearPatientSession();
  }

  Future<ApiResponse<PatientUserModel>> _parseAuthResponse(
    Map<String, dynamic> body,
  ) async {
    final data = body['data'] as Map<String, dynamic>? ?? {};
    final user = PatientUserModel.fromJson(data);
    final token = body['token'] as String?;

    if (token != null && token.isNotEmpty) {
      await _persistUserSession(user, token: token);
    }

    return ApiResponse(
      success: body['success'] as bool? ?? false,
      message: body['message'] as String?,
      statusCode: body['statusCode'] as int? ?? 200,
      data: user,
      error: body['success'] == false
          ? (body['error'] as String? ?? body['message'] as String?)
          : null,
    );
  }

  Future<void> _persistUserSession(
    PatientUserModel user, {
    String? token,
  }) async {
    if (token != null) {
      await TokenStorage.instance.savePatientSession(
        token: token,
        patientId: user.id,
        email: user.email,
        displayName: user.fullName,
        mobileNumber: user.mobileNumber,
        profilePicture: user.profilePicture,
        gender: user.gender,
        age: user.age,
      );
    } else {
      final existing = await TokenStorage.instance.getPatientToken();
      if (existing != null) {
        await TokenStorage.instance.savePatientSession(
          token: existing,
          patientId: user.id,
          email: user.email,
          displayName: user.fullName,
          mobileNumber: user.mobileNumber,
          profilePicture: user.profilePicture,
          gender: user.gender,
          age: user.age,
        );
      }
    }
  }

  ApiResponse<T> _handleError<T>(DioException error) {
    String message = AppConstants.errorSomethingWentWrong;
    int statusCode = 500;
    if (error.type == DioExceptionType.badResponse) {
      statusCode = error.response?.statusCode ?? 500;
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        message = (data['error'] ?? data['message'] ?? message) as String;
      }
    } else if (error.type == DioExceptionType.connectionError) {
      message = AppConstants.errorNetworkException;
    }
    return ApiResponse(success: false, error: message, statusCode: statusCode);
  }
}
