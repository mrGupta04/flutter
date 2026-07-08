import 'dart:typed_data';

import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/doctor_availability_constants.dart';
import '../../core/services/token_storage.dart';
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
      final doctorId = result.data?.id;
      if (token != null && token.isNotEmpty && doctorId != null) {
        await TokenStorage.instance.saveProviderSession(
          providerType: 'doctor',
          token: token,
          entityId: doctorId,
        );
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

  /// Send email verification OTP during registration.
  Future<ApiResponse<Map<String, dynamic>>> sendEmailVerificationOtp({
    required String doctorId,
    required String email,
  }) async {
    try {
      final response = await _dioService.post(
        AppConstants.endpointDoctorEmailSendOtp,
        data: {
          'doctorId': doctorId,
          'email': email.trim(),
        },
      );

      final body = response.data as Map<String, dynamic>;
      return ApiResponse(
        success: body['success'] as bool? ?? false,
        message: body['message'] as String?,
        statusCode: body['statusCode'] as int? ?? 200,
        data: body['data'] as Map<String, dynamic>?,
        error: body['error'] as String?,
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

  /// Verify email OTP during registration.
  Future<ApiResponse<Map<String, dynamic>>> verifyEmailVerificationOtp({
    required String doctorId,
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _dioService.post(
        AppConstants.endpointDoctorEmailVerifyOtp,
        data: {
          'doctorId': doctorId,
          'email': email.trim(),
          'otp': otp.trim(),
        },
      );

      final body = response.data as Map<String, dynamic>;
      return ApiResponse(
        success: body['success'] as bool? ?? false,
        message: body['message'] as String?,
        statusCode: body['statusCode'] as int? ?? 200,
        data: body['data'] as Map<String, dynamic>?,
        error: body['error'] as String?,
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

  /// Upload hospital/clinic photo (profile-style — no admin document verification).
  Future<ApiResponse<String>> uploadHospitalPhoto({
    required String doctorId,
    required int photoIndex,
    String? filePath,
    Uint8List? bytes,
    String? filename,
    String? mobileNumber,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    try {
      final response = await _dioService.uploadFile(
        AppConstants.endpointUploadHospitalPhoto,
        filePath: filePath,
        bytes: bytes,
        filename: filename ?? 'hospital_$photoIndex.jpg',
        fieldName: 'file',
        additionalFields: {
          'doctorId': doctorId,
          'photoIndex': photoIndex.toString(),
          if (mobileNumber != null) 'mobileNumber': mobileNumber,
        },
        onSendProgress: onSendProgress,
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
    } catch (e) {
      return ApiResponse(
        success: false,
        error: 'An unexpected error occurred',
        statusCode: 500,
      );
    }
  }

  Future<ApiResponse<List<DoctorDocumentModel>>> getDocuments({
    required String doctorId,
  }) async {
    try {
      final response = await _dioService.get(
        AppConstants.endpointDoctorDocuments,
        queryParameters: {'doctorId': doctorId},
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

  /// Upload document
  Future<ApiResponse<DoctorDocumentModel>> uploadDocument({
    required String doctorId,
    String? filePath,
    Uint8List? bytes,
    String? filename,
    required DocumentType documentType,
    String? mobileNumber,
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
          if (mobileNumber != null) 'mobileNumber': mobileNumber,
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
      final list = extractApiList(body['data'])
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

  /// Get doctor profile
  Future<ApiResponse<DoctorModel>> getDoctorProfile({
    String? doctorId,
  }) async {
    try {
      final id = doctorId ?? await TokenStorage.instance.getDoctorId();
      final queryParameters = <String, dynamic>{};
      if (id != null && id.isNotEmpty) {
        queryParameters['doctorId'] = id;
      }

      final response = await _dioService.get(
        AppConstants.endpointGetProfile,
        queryParameters:
            queryParameters.isEmpty ? null : queryParameters,
      );

      final body = response.data as Map<String, dynamic>;
      final raw = body['data'];
      if (raw is! Map<String, dynamic>) {
        return ApiResponse.fromJson(
          body,
          (json) => DoctorModel.fromJson(json as Map<String, dynamic>),
        );
      }
      final doctorJson = Map<String, dynamic>.from(raw);
      doctorJson.remove('availabilityReminder');
      return ApiResponse(
        success: body['success'] as bool? ?? false,
        message: body['message'] as String?,
        statusCode: body['statusCode'] as int?,
        data: DoctorModel.fromJson(doctorJson),
        error: body['error'] as String?,
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

  /// List confirmed patient bookings for the doctor dashboard.
  Future<ApiResponse<List<DoctorBookingModel>>> getBookings({
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
        AppConstants.endpointDoctorBookings,
        queryParameters: {'doctorId': id},
      );

      final body = response.data as Map<String, dynamic>;
      final list = extractApiList(body['data']);
      final bookings = list
          .map(
            (e) => DoctorBookingModel.fromJson(e as Map<String, dynamic>),
          )
          .toList();

      return ApiResponse(
        success: body['success'] as bool? ?? true,
        statusCode: body['statusCode'] as int? ?? 200,
        data: bookings,
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

  Future<ApiResponse<DoctorBookingModel>> approveHomeVisitRequest({
    required String bookingId,
    String? doctorId,
  }) async {
    try {
      final id = doctorId ?? await TokenStorage.instance.getDoctorId();
      final response = await _dioService.post(
        AppConstants.endpointDoctorApproveHomeVisit(bookingId),
        data: id != null ? {'doctorId': id} : <String, dynamic>{},
      );
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      return ApiResponse(
        success: body['success'] as bool? ?? true,
        statusCode: body['statusCode'] as int? ?? 200,
        message: body['message'] as String?,
        data: DoctorBookingModel.fromJson(data),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<DoctorBookingModel>> rejectHomeVisitRequest({
    required String bookingId,
    String? doctorId,
  }) async {
    try {
      final id = doctorId ?? await TokenStorage.instance.getDoctorId();
      final response = await _dioService.post(
        AppConstants.endpointDoctorRejectHomeVisit(bookingId),
        data: id != null ? {'doctorId': id} : <String, dynamic>{},
      );
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      return ApiResponse(
        success: body['success'] as bool? ?? true,
        statusCode: body['statusCode'] as int? ?? 200,
        message: body['message'] as String?,
        data: DoctorBookingModel.fromJson(data),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// Get weekly availability (Sunday–Saturday, hourly slots).
  Future<ApiResponse<DoctorAvailabilityModel>> getAvailability({
    String? doctorId,
    String consultationType = 'online_consult',
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
        AppConstants.endpointDoctorAvailability,
        queryParameters: {
          'doctorId': id,
          'type': consultationType,
        },
      );

      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};

      return ApiResponse(
        success: body['success'] as bool? ?? true,
        statusCode: body['statusCode'] as int? ?? 200,
        data: DoctorAvailabilityModel.fromJson(data),
        message: data['reminderMessage'] as String?,
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

  /// Save weekly availability.
  Future<ApiResponse<DoctorAvailabilityModel>> saveAvailability({
    required String doctorId,
    required Set<String> selectedSlotKeys,
    DateTime? weekStartDate,
    String consultationType = 'online_consult',
  }) async {
    try {
      final response = await _dioService.put(
        AppConstants.endpointDoctorAvailability,
        data: {
          'doctorId': doctorId,
          'consultationType': consultationType,
          'weekStartDate': weekStartDate?.toIso8601String(),
          'slots': DoctorAvailabilityConstants.buildSlotPayload(selectedSlotKeys),
        },
      );

      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};

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

  /// Verify a clinic visit using the patient's 4-digit appointment code.
  Future<ApiResponse<Map<String, dynamic>>> verifyClinicAppointment({
    required String appointmentCode,
  }) async {
    try {
      final response = await _dioService.post(
        AppConstants.endpointDoctorVerifyAppointment,
        data: {'appointmentCode': appointmentCode},
      );
      final body = response.data as Map<String, dynamic>;
      return ApiResponse(
        success: body['success'] as bool? ?? false,
        message: body['message'] as String?,
        statusCode: body['statusCode'] as int? ?? 200,
        data: body['data'] as Map<String, dynamic>?,
        error: body['error'] as String?,
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

  /// Mark doctor as live (heartbeat while logged in).
  Future<void> sendPresenceHeartbeat() async {
    try {
      await _dioService.post(
        AppConstants.endpointDoctorPresenceHeartbeat,
        data: const {},
      );
    } catch (_) {
      // Non-blocking; next heartbeat will retry.
    }
  }

  /// Clear live status on logout.
  Future<void> setPresenceOffline() async {
    try {
      await _dioService.post(
        AppConstants.endpointDoctorPresenceOffline,
        data: const {},
      );
    } catch (_) {
      // Best-effort on logout.
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
      case DocumentType.aadhaarCard:
        return 'aadhaar_card';
      case DocumentType.hospitalPhoto1:
        return 'hospital_photo_1';
      case DocumentType.hospitalPhoto2:
        return 'hospital_photo_2';
      case DocumentType.hospitalPhoto3:
        return 'hospital_photo_3';
      case DocumentType.hospitalPhoto4:
        return 'hospital_photo_4';
      case DocumentType.hospitalPhoto5:
        return 'hospital_photo_5';
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
