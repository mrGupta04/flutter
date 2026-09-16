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

  Future<ApiResponse<List<ReceptionistModel>>> listForDoctor() {
    return listForOwner(ReceptionistOwnerType.doctor);
  }

  Future<ApiResponse<List<ReceptionistModel>>> listForOwner(
    ReceptionistOwnerType ownerType,
  ) async {
    try {
      final response = await _dio.get(_base(ownerType));
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
    ReceptionistOwnerType ownerType = ReceptionistOwnerType.doctor,
  }) async {
    try {
      final response = await _dio.post(
        _base(ownerType),
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
    ReceptionistOwnerType ownerType = ReceptionistOwnerType.doctor,
  }) async {
    try {
      final response = await _dio.patch(
        _item(ownerType, id),
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
    ReceptionistOwnerType ownerType = ReceptionistOwnerType.doctor,
  }) async {
    try {
      final response = await _dio.patch(
        _status(ownerType, id),
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
    ReceptionistOwnerType ownerType = ReceptionistOwnerType.doctor,
  }) async {
    try {
      final response = await _dio.post(
        _password(ownerType, id),
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

  Future<ApiResponse<void>> delete(
    String id, {
    ReceptionistOwnerType ownerType = ReceptionistOwnerType.doctor,
  }) async {
    try {
      final response = await _dio.delete(_item(ownerType, id));
      final body = response.data as Map<String, dynamic>;
      return ApiResponse(
        success: body['success'] as bool? ?? true,
        message: body['message'] as String?,
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  String _base(ReceptionistOwnerType ownerType) {
    switch (ownerType) {
      case ReceptionistOwnerType.doctor:
        return AppConstants.endpointDoctorReceptionists;
      case ReceptionistOwnerType.lab:
        return AppConstants.endpointLabReceptionists;
      case ReceptionistOwnerType.scan:
        return AppConstants.endpointScanReceptionists;
      case ReceptionistOwnerType.bloodBank:
        return AppConstants.endpointBloodBankReceptionists;
    }
  }

  String _item(ReceptionistOwnerType ownerType, String id) {
    switch (ownerType) {
      case ReceptionistOwnerType.doctor:
        return AppConstants.endpointDoctorReceptionist(id);
      case ReceptionistOwnerType.lab:
        return AppConstants.endpointLabReceptionist(id);
      case ReceptionistOwnerType.scan:
        return AppConstants.endpointScanReceptionist(id);
      case ReceptionistOwnerType.bloodBank:
        return AppConstants.endpointBloodBankReceptionist(id);
    }
  }

  String _status(ReceptionistOwnerType ownerType, String id) {
    switch (ownerType) {
      case ReceptionistOwnerType.doctor:
        return AppConstants.endpointDoctorReceptionistStatus(id);
      case ReceptionistOwnerType.lab:
        return AppConstants.endpointLabReceptionistStatus(id);
      case ReceptionistOwnerType.scan:
        return AppConstants.endpointScanReceptionistStatus(id);
      case ReceptionistOwnerType.bloodBank:
        return AppConstants.endpointBloodBankReceptionistStatus(id);
    }
  }

  String _password(ReceptionistOwnerType ownerType, String id) {
    switch (ownerType) {
      case ReceptionistOwnerType.doctor:
        return AppConstants.endpointDoctorReceptionistPassword(id);
      case ReceptionistOwnerType.lab:
        return AppConstants.endpointLabReceptionistPassword(id);
      case ReceptionistOwnerType.scan:
        return AppConstants.endpointScanReceptionistPassword(id);
      case ReceptionistOwnerType.bloodBank:
        return AppConstants.endpointBloodBankReceptionistPassword(id);
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
