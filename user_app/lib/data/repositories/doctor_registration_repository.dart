import 'dart:typed_data';

import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/token_storage.dart';
import '../../core/utils/doctor_presence_utils.dart';
import '../../data/models/models.dart';
import '../../data/services/dio_service.dart';

/// Doctor registration repository
class DoctorRegistrationRepository {
  final DioService _dioService;

  DoctorRegistrationRepository({DioService? dioService})
      : _dioService = dioService ?? DioService();

  /// Register doctor
  Future<ApiResponse<DoctorModel>> registerDoctor({
    required DoctorModel doctor,
  }) async {
    try {
      final response = await _dioService.post(
        AppConstants.endpointRegisterDoctor,
        data: doctor.toJson(),
      );

      final body = response.data as Map<String, dynamic>;
      final result = ApiResponse.fromJson(
        body,
        (json) => DoctorModel.fromJson(json as Map<String, dynamic>),
      );

      final token = body['token'] as String?;
      if (token != null && token.isNotEmpty) {
        await TokenStorage.instance.saveToken(token);
      }
      if (result.data?.id != null) {
        await TokenStorage.instance.saveDoctorId(result.data!.id!);
      }

      return result;
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

  /// Aadhaar provider config (mock vs real UIDAI via Surepass).
  Future<ApiResponse<Map<String, dynamic>>> getAadhaarConfig() async {
    try {
      final response = await _dioService.get(AppConstants.endpointAadhaarConfig);
      final body = response.data as Map<String, dynamic>;
      return ApiResponse(
        success: body['success'] as bool? ?? true,
        statusCode: body['statusCode'] as int? ?? 200,
        data: body['data'] as Map<String, dynamic>? ?? {},
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

  /// Send Aadhaar verification OTP to linked mobile.
  Future<ApiResponse<Map<String, dynamic>>> sendAadhaarOtp({
    required String doctorId,
    required String aadhaarNumber,
    required String mobileNumber,
  }) async {
    try {
      final response = await _dioService.post(
        AppConstants.endpointAadhaarSendOtp,
        data: {
          'doctorId': doctorId,
          'aadhaarNumber': aadhaarNumber,
          'mobileNumber': mobileNumber,
        },
      );

      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};

      return ApiResponse(
        success: body['success'] as bool? ?? true,
        message: body['message'] as String?,
        statusCode: body['statusCode'] as int? ?? 200,
        data: data,
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

  /// Verify Aadhaar OTP.
  Future<ApiResponse<DoctorModel>> verifyAadhaarOtp({
    required String doctorId,
    required String aadhaarNumber,
    required String otp,
  }) async {
    try {
      final response = await _dioService.post(
        AppConstants.endpointAadhaarVerifyOtp,
        data: {
          'doctorId': doctorId,
          'aadhaarNumber': aadhaarNumber,
          'otp': otp,
        },
      );

      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      final doctorJson = data['doctor'] as Map<String, dynamic>?;

      return ApiResponse(
        success: body['success'] as bool? ?? true,
        message: body['message'] as String?,
        statusCode: body['statusCode'] as int? ?? 200,
        data: doctorJson != null
            ? DoctorModel.fromJson(doctorJson)
            : null,
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

  /// Upload profile picture before registration submit
  Future<ApiResponse<String>> uploadProfilePicture({
    required String doctorId,
    String? filePath,
    Uint8List? bytes,
    String? filename,
    String? mobileNumber,
  }) async {
    try {
      final response = await _dioService.uploadFile(
        AppConstants.endpointUploadProfile,
        filePath: filePath,
        bytes: bytes,
        filename: filename ?? 'profile.jpg',
        fieldName: 'file',
        additionalFields: {
          'doctorId': doctorId,
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

  /// Upload document
  Future<ApiResponse<DoctorDocumentModel>> uploadDocument({
    required String doctorId,
    String? filePath,
    Uint8List? bytes,
    String? filename,
    required DocumentType documentType,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      final response = await _dioService.uploadFile(
        AppConstants.endpointUploadDocument,
        filePath: filePath,
        bytes: bytes,
        filename: filename,
        fieldName: 'file',
        additionalFields: {
          'doctorId': doctorId,
          'documentType': _documentTypeToString(documentType),
        },
        onSendProgress: onSendProgress,
      );

      return ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => DoctorDocumentModel.fromJson(json as Map<String, dynamic>),
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

  /// Public list of verified doctors (no auth).
  Future<ApiResponse<List<DoctorModel>>> getVerifiedDoctors({
    int page = 1,
    int pageSize = 20,
    String? query,
    String? city,
    String? specialization,
    ConsultationType? consultationType,
  }) async {
    try {
      final response = await _dioService.get(
        AppConstants.endpointVerifiedDoctors,
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
          if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
          if (specialization != null && specialization.trim().isNotEmpty)
            'specialization': specialization.trim(),
          if (consultationType != null)
            'consultationType': consultationType.apiValue,
        },
      );

      final body = response.data as Map<String, dynamic>;
      final raw = body['data'];
      final list = (_extractDoctorList(raw))
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

  /// Lightweight live-status poll for doctor cards (presence only).
  Future<ApiResponse<Map<String, bool>>> getDoctorsLiveStatus(
    List<String> doctorIds,
  ) async {
    final ids = doctorIds.where((id) => id.trim().isNotEmpty).toList();
    if (ids.isEmpty) {
      return ApiResponse(success: true, statusCode: 200, data: const {});
    }

    try {
      final response = await _dioService.get(
        AppConstants.endpointDoctorLiveStatus,
        queryParameters: {'ids': ids.join(',')},
      );

      final body = response.data as Map<String, dynamic>;
      final rows = body['data'];
      final map = <String, bool>{};

      if (rows is List) {
        for (final row in rows) {
          if (row is! Map<String, dynamic>) continue;
          final id = row['id'] as String?;
          if (id == null || id.isEmpty) continue;
          final lastActiveAt = _parseLiveStatusTime(row['lastActiveAt']);
          final isLive = row['isLiveNow'] == true ||
              isDoctorLiveNow(lastActiveAt: lastActiveAt);
          map[id] = isLive;
        }
      }

      return ApiResponse(
        success: body['success'] as bool? ?? true,
        statusCode: body['statusCode'] as int? ?? 200,
        data: map,
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

  DateTime? _parseLiveStatusTime(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// Get doctor profile
  Future<ApiResponse<DoctorModel>> getDoctorProfile({
    String? doctorId,
  }) async {
    try {
      final id = doctorId ?? await TokenStorage.instance.getDoctorId();
      if (id == null || id.isEmpty) {
        return ApiResponse(
          success: false,
          error: 'Doctor ID not found',
          statusCode: 400,
        );
      }

      final response = await _dioService.get(
        AppConstants.endpointGetProfile,
        queryParameters: {
          'doctorId': id,
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

  /// Update doctor profile
  Future<ApiResponse<DoctorModel>> updateDoctorProfile({
    required DoctorModel doctor,
  }) async {
    try {
      final response = await _dioService.put(
        AppConstants.endpointUpdateProfile,
        data: doctor.toJson(),
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

  String _documentTypeToString(DocumentType type) {
    switch (type) {
      case DocumentType.medicalLicense:
        return 'medical_license';
      case DocumentType.governmentId:
        return 'government_id';
      case DocumentType.degreeCertificate:
        return 'degree_certificate';
      case DocumentType.clinicProof:
        return 'clinic_proof';
      case DocumentType.cancelledCheque:
        return 'cancelled_cheque';
    }
  }

  /// Handle Dio errors
  ApiResponse<T> _handleError<T>(DioException error) {
    String message = 'An error occurred';
    int statusCode = 500;

    if (error.type == DioExceptionType.connectionTimeout) {
      message = 'Connection timeout. Please try again.';
      statusCode = 408;
    } else if (error.type == DioExceptionType.receiveTimeout) {
      message = 'Request timeout. Please try again.';
      statusCode = 408;
    } else if (error.type == DioExceptionType.connectionError) {
      message = AppConstants.errorNetworkException;
    } else if (error.type == DioExceptionType.badResponse) {
      statusCode = error.response?.statusCode ?? 500;
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        message = (data['error'] ?? data['message'] ?? 'Server error') as String;
      }
    } else if (error.type == DioExceptionType.unknown) {
      message = AppConstants.errorNetworkException;
    }

    return ApiResponse<T>(
      success: false,
      error: message,
      statusCode: statusCode,
    );
  }
}

List<dynamic> _extractDoctorList(dynamic raw) {
  if (raw is List) return raw;
  if (raw is Map<String, dynamic>) {
    final nested = raw['data'];
    if (nested is List) return nested;
  }
  return const [];
}
