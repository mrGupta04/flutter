import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../models/models.dart';
import '../models/nurse_model.dart';
import '../models/ambulance_model.dart';
import '../models/blood_bank_model.dart';
import '../services/dio_service.dart';

/// Admin repository — talks to REST API with admin JWT.
class AdminRepository {
  final DioService _dioService;

  AdminRepository({DioService? dioService})
      : _dioService = dioService ?? DioService();

  Future<ApiResponse<List<DoctorModel>>> getDoctorsForVerification({
    int page = 1,
    int pageSize = 20,
    String? status,
  }) async {
    try {
      final response = await _dioService.get(
        AppConstants.endpointAdminDoctors,
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          if (status != null && status.isNotEmpty) 'status': status,
        },
      );

      final body = response.data as Map<String, dynamic>;
      final list = (body['data'] as List? ?? [])
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

  Future<ApiResponse<DoctorModel>> getDoctorDetails({
    required String doctorId,
  }) async {
    try {
      final response = await _dioService.get(
        AppConstants.endpointAdminDoctor(doctorId),
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

  Future<ApiResponse<DoctorModel>> approveDoctor({
    required String doctorId,
    String? approvalNotes,
  }) async {
    try {
      final response = await _dioService.post(
        AppConstants.endpointAdminApprove(doctorId),
        data: {
          if (approvalNotes != null) 'approvalNotes': approvalNotes,
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

  Future<ApiResponse<DoctorModel>> rejectDoctor({
    required String doctorId,
    required String rejectionReason,
  }) async {
    try {
      final response = await _dioService.post(
        AppConstants.endpointAdminReject(doctorId),
        data: {'rejectionReason': rejectionReason},
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

  Future<ApiResponse<DoctorDocumentModel>> verifyDoctorDocument({
    required String doctorId,
    required String documentId,
  }) async {
    try {
      final response = await _dioService.post(
        AppConstants.endpointAdminDoctorDocumentVerify(doctorId, documentId),
        data: const {},
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

  Future<ApiResponse<DoctorDocumentModel>> rejectDoctorDocument({
    required String doctorId,
    required String documentId,
    required String rejectionReason,
  }) async {
    try {
      final response = await _dioService.post(
        AppConstants.endpointAdminDoctorDocumentReject(doctorId, documentId),
        data: {'rejectionReason': rejectionReason},
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

  Future<ApiResponse<List<DoctorDocumentModel>>> getDoctorDocuments({
    required String doctorId,
  }) async {
    try {
      final response = await _dioService.get(
        AppConstants.endpointAdminDoctorDocuments(doctorId),
      );

      final body = response.data as Map<String, dynamic>;
      final list = (body['data'] as List? ?? [])
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

  // ——— Nurse admin ———

  Future<ApiResponse<List<NurseModel>>> getNursesForVerification({
    int page = 1,
    int pageSize = 20,
    String? status,
  }) async {
    try {
      final response = await _dioService.get(
        AppConstants.endpointAdminNurses,
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          if (status != null && status.isNotEmpty) 'status': status,
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

  Future<ApiResponse<List<DoctorDocumentModel>>> getNurseDocuments({
    required String nurseId,
  }) async {
    try {
      final response = await _dioService.get(
        AppConstants.endpointAdminNurseDocuments(nurseId),
      );
      final body = response.data as Map<String, dynamic>;
      final list = (body['data'] as List? ?? [])
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

  Future<ApiResponse<DoctorDocumentModel>> verifyNurseDocument({
    required String nurseId,
    required String documentId,
  }) async {
    try {
      final response = await _dioService.post(
        AppConstants.endpointAdminNurseDocumentVerify(nurseId, documentId),
        data: const {},
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

  Future<ApiResponse<DoctorDocumentModel>> rejectNurseDocument({
    required String nurseId,
    required String documentId,
    required String rejectionReason,
  }) async {
    try {
      final response = await _dioService.post(
        AppConstants.endpointAdminNurseDocumentReject(nurseId, documentId),
        data: {'rejectionReason': rejectionReason},
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

  Future<ApiResponse<NurseModel>> getNurseDetails({
    required String nurseId,
  }) async {
    try {
      final response = await _dioService.get(
        AppConstants.endpointAdminNurse(nurseId),
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

  Future<ApiResponse<NurseModel>> approveNurse({
    required String nurseId,
    String? approvalNotes,
  }) async {
    try {
      final response = await _dioService.post(
        AppConstants.endpointAdminNurseApprove(nurseId),
        data: {
          if (approvalNotes != null) 'approvalNotes': approvalNotes,
        },
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

  Future<ApiResponse<NurseModel>> rejectNurse({
    required String nurseId,
    required String rejectionReason,
  }) async {
    try {
      final response = await _dioService.post(
        AppConstants.endpointAdminNurseReject(nurseId),
        data: {'rejectionReason': rejectionReason},
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

  // ——— Ambulance admin ———

  Future<ApiResponse<List<AmbulanceModel>>> getAmbulancesForVerification({
    int page = 1,
    int pageSize = 20,
    String? status,
  }) async {
    try {
      final response = await _dioService.get(
        AppConstants.endpointAdminAmbulances,
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          if (status != null && status.isNotEmpty) 'status': status,
        },
      );

      final body = response.data as Map<String, dynamic>;
      final list = (body['data'] as List? ?? [])
          .map((e) => AmbulanceModel.fromJson(e as Map<String, dynamic>))
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

  Future<ApiResponse<List<DoctorDocumentModel>>> getAmbulanceDocuments({
    required String ambulanceId,
  }) async {
    try {
      final response = await _dioService.get(
        AppConstants.endpointAdminAmbulanceDocuments(ambulanceId),
      );
      final body = response.data as Map<String, dynamic>;
      final list = (body['data'] as List? ?? [])
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

  Future<ApiResponse<DoctorDocumentModel>> verifyAmbulanceDocument({
    required String ambulanceId,
    required String documentId,
  }) async {
    try {
      final response = await _dioService.post(
        AppConstants.endpointAdminAmbulanceDocumentVerify(
          ambulanceId,
          documentId,
        ),
        data: const {},
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

  Future<ApiResponse<DoctorDocumentModel>> rejectAmbulanceDocument({
    required String ambulanceId,
    required String documentId,
    required String rejectionReason,
  }) async {
    try {
      final response = await _dioService.post(
        AppConstants.endpointAdminAmbulanceDocumentReject(
          ambulanceId,
          documentId,
        ),
        data: {'rejectionReason': rejectionReason},
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

  Future<ApiResponse<AmbulanceModel>> getAmbulanceDetails({
    required String ambulanceId,
  }) async {
    try {
      final response = await _dioService.get(
        AppConstants.endpointAdminAmbulance(ambulanceId),
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

  Future<ApiResponse<AmbulanceModel>> approveAmbulance({
    required String ambulanceId,
    String? approvalNotes,
  }) async {
    try {
      final response = await _dioService.post(
        AppConstants.endpointAdminAmbulanceApprove(ambulanceId),
        data: {
          if (approvalNotes != null) 'approvalNotes': approvalNotes,
        },
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

  Future<ApiResponse<AmbulanceModel>> rejectAmbulance({
    required String ambulanceId,
    required String rejectionReason,
  }) async {
    try {
      final response = await _dioService.post(
        AppConstants.endpointAdminAmbulanceReject(ambulanceId),
        data: {'rejectionReason': rejectionReason},
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

  // ——— Blood bank admin ———

  Future<ApiResponse<List<BloodBankModel>>> getBloodBanksForVerification({
    int page = 1,
    int pageSize = 20,
    String? status,
  }) async {
    try {
      final response = await _dioService.get(
        AppConstants.endpointAdminBloodBanks,
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          if (status != null && status.isNotEmpty) 'status': status,
        },
      );

      final body = response.data as Map<String, dynamic>;
      final list = (body['data'] as List? ?? [])
          .map((e) => BloodBankModel.fromJson(e as Map<String, dynamic>))
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

  Future<ApiResponse<BloodBankModel>> getBloodBankDetails({
    required String bloodBankId,
  }) async {
    try {
      final response = await _dioService.get(
        AppConstants.endpointAdminBloodBank(bloodBankId),
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

  Future<ApiResponse<BloodBankModel>> approveBloodBank({
    required String bloodBankId,
    String? approvalNotes,
  }) async {
    try {
      final response = await _dioService.post(
        AppConstants.endpointAdminBloodBankApprove(bloodBankId),
        data: {
          if (approvalNotes != null) 'approvalNotes': approvalNotes,
        },
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

  Future<ApiResponse<BloodBankModel>> rejectBloodBank({
    required String bloodBankId,
    required String rejectionReason,
  }) async {
    try {
      final response = await _dioService.post(
        AppConstants.endpointAdminBloodBankReject(bloodBankId),
        data: {'rejectionReason': rejectionReason},
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
