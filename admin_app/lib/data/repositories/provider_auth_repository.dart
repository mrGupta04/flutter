import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/provider_type.dart';
import '../../core/services/token_storage.dart';
import '../models/api_response_model.dart';
import '../services/dio_service.dart';

class ProviderLoginResult {
  final String token;
  final String entityId;
  final Map<String, dynamic> profile;

  const ProviderLoginResult({
    required this.token,
    required this.entityId,
    required this.profile,
  });
}

class ProviderAuthRepository {
  final DioService _dioService;

  ProviderAuthRepository({DioService? dioService})
      : _dioService = dioService ?? DioService();

  String _loginEndpoint(ProviderType type) {
    switch (type) {
      case ProviderType.doctor:
        return AppConstants.endpointDoctorLogin;
      case ProviderType.nurse:
        return AppConstants.endpointNurseLogin;
      case ProviderType.ambulance:
        return AppConstants.endpointAmbulanceLogin;
      case ProviderType.bloodBank:
        return AppConstants.endpointBloodBankLogin;
      case ProviderType.lab:
        return AppConstants.endpointLabLogin;
    }
  }

  String _entityIdFromProfile(ProviderType type, Map<String, dynamic> profile) {
    final id = profile['id'] as String? ??
        profile['_id']?.toString() ??
        profile['doctorId'] as String? ??
        profile['nurseId'] as String? ??
        profile['ambulanceId'] as String? ??
        profile['bloodBankId'] as String? ??
        profile['labId'] as String?;
    return id ?? '';
  }

  String _providerTypeKey(ProviderType type) {
    switch (type) {
      case ProviderType.doctor:
        return 'doctor';
      case ProviderType.nurse:
        return 'nurse';
      case ProviderType.ambulance:
        return 'ambulance';
      case ProviderType.bloodBank:
        return 'blood-bank';
      case ProviderType.lab:
        return 'lab';
    }
  }

  Future<ApiResponse<ProviderLoginResult>> login({
    required ProviderType type,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dioService.post(
        _loginEndpoint(type),
        data: {'email': email.trim(), 'password': password},
      );

      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      final token = body['token'] as String? ?? '';
      final entityId = _entityIdFromProfile(type, data);

      if (token.isNotEmpty && entityId.isNotEmpty) {
        await TokenStorage.instance.saveProviderSession(
          providerType: _providerTypeKey(type),
          token: token,
          entityId: entityId,
        );
      }

      return ApiResponse(
        success: body['success'] as bool? ?? true,
        statusCode: body['statusCode'] as int? ?? 200,
        message: body['message'] as String?,
        data: ProviderLoginResult(
          token: token,
          entityId: entityId,
          profile: data,
        ),
      );
    } on DioException catch (e) {
      return _handleError(e);
    } catch (_) {
      return ApiResponse(
        success: false,
        error: AppConstants.errorSomethingWentWrong,
        statusCode: 500,
      );
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> fetchProfile(ProviderType type) async {
    try {
      late final String endpoint;
      late final Map<String, String> query;

      switch (type) {
        case ProviderType.doctor:
          endpoint = AppConstants.endpointGetProfile;
          final doctorId = await TokenStorage.instance.getDoctorId();
          query = {if (doctorId != null) 'doctorId': doctorId};
          break;
        case ProviderType.nurse:
          endpoint = AppConstants.endpointGetNurseProfile;
          final nurseId = await TokenStorage.instance.getNurseId();
          query = {if (nurseId != null) 'nurseId': nurseId};
          break;
        case ProviderType.ambulance:
          endpoint = AppConstants.endpointGetAmbulanceProfile;
          final ambulanceId = await TokenStorage.instance.getAmbulanceId();
          query = {if (ambulanceId != null) 'ambulanceId': ambulanceId};
          break;
        case ProviderType.bloodBank:
          endpoint = AppConstants.endpointGetBloodBankProfile;
          final bloodBankId = await TokenStorage.instance.getBloodBankId();
          query = {if (bloodBankId != null) 'bloodBankId': bloodBankId};
          break;
      }

      final response = await _dioService.get(endpoint, queryParameters: query);
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      return ApiResponse(
        success: body['success'] as bool? ?? true,
        statusCode: body['statusCode'] as int? ?? 200,
        data: data,
      );
    } on DioException catch (e) {
      return _handleError(e);
    } catch (_) {
      return ApiResponse(
        success: false,
        error: AppConstants.errorSomethingWentWrong,
        statusCode: 500,
      );
    }
  }

  static String? profilePictureFrom(Map<String, dynamic> profile) {
    final url = profile['profilePicture'] as String?;
    if (url != null && url.isNotEmpty) return url;
    return null;
  }

  static String displayNameFrom(ProviderType type, Map<String, dynamic> profile) {
    switch (type) {
      case ProviderType.doctor:
        final first = profile['firstName'] as String? ?? '';
        final last = profile['lastName'] as String? ?? '';
        final name = '$first $last'.trim();
        return name.isEmpty ? 'Doctor' : name;
      case ProviderType.nurse:
        final first = profile['firstName'] as String? ?? '';
        final last = profile['lastName'] as String? ?? '';
        final name = '$first $last'.trim();
        return name.isEmpty ? 'Nurse' : name;
      case ProviderType.ambulance:
        return (profile['serviceName'] as String?)?.trim().isNotEmpty == true
            ? profile['serviceName'] as String
            : (profile['ownerName'] as String?) ?? 'Ambulance';
      case ProviderType.bloodBank:
        return (profile['institutionName'] as String?) ?? 'Blood Bank';
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
