import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../models/bookable_slot_model.dart';
import '../models/api_response_model.dart';
import '../services/dio_service.dart';

class OnlineConsultRepository {
  OnlineConsultRepository({DioService? dioService})
      : _dio = dioService ?? DioService();

  final DioService _dio;

  Future<ApiResponse<BookableSlotsResponse>> getBookableSlots({
    required String doctorId,
    String consultationType = 'online_consult',
  }) async {
    try {
      final response = await _dio.get(
        AppConstants.endpointDoctorBookableSlots,
        queryParameters: {
          'doctorId': doctorId,
          'type': consultationType,
        },
      );
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      return ApiResponse(
        success: body['success'] as bool? ?? true,
        statusCode: body['statusCode'] as int? ?? 200,
        data: BookableSlotsResponse.fromJson(data),
        error: body['success'] == false ? body['error'] as String? : null,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.badResponse) {
        final status = e.response?.statusCode ?? 500;
        final data = e.response?.data;
        if (data is Map<String, dynamic> &&
            (status == 404 || status == 409)) {
          final message =
              (data['error'] ?? data['message']) as String? ??
                  'No slots available';
          return ApiResponse(
            success: true,
            statusCode: status,
            data: BookableSlotsResponse(
              doctorId: doctorId,
              consultationType: consultationType,
              slots: const [],
              message: message,
            ),
          );
        }
      }
      return _handleError(e);
    }
  }

  Future<ApiResponse<SlotHoldResult>> holdSlot({
    required String doctorId,
    required String consultationType,
    required int dayOfWeek,
    required int startHour,
    required DateTime slotStart,
    String? holdId,
  }) async {
    try {
      final response = await _dio.post(
        AppConstants.endpointDoctorSlotHold,
        data: {
          'doctorId': doctorId,
          'consultationType': consultationType,
          'dayOfWeek': dayOfWeek,
          'startHour': startHour,
          'slotStart': slotStart.toIso8601String(),
          if (holdId != null && holdId.isNotEmpty) 'holdId': holdId,
        },
      );
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      return ApiResponse(
        success: body['success'] as bool? ?? false,
        statusCode: body['statusCode'] as int? ?? 201,
        data: SlotHoldResult.fromJson(data),
        error: body['success'] == false
            ? (body['error'] as String? ?? body['message'] as String?)
            : null,
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<void>> releaseSlotHold({required String holdId}) async {
    try {
      final response = await _dio.delete(
        AppConstants.endpointDoctorSlotHoldRelease(holdId),
      );
      final body = response.data as Map<String, dynamic>;
      return ApiResponse(
        success: body['success'] as bool? ?? true,
        statusCode: body['statusCode'] as int? ?? 200,
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<ConsultationBookingResult>> bookHospitalVisit({
    required String doctorId,
    required String patientName,
    required String patientMobile,
    required String patientAddress,
    required String patientCity,
    required String patientPincode,
    String? patientEmail,
    String? patientState,
    String? visitReason,
    String? patientNotes,
    required int dayOfWeek,
    required int startHour,
    required DateTime slotStart,
  }) async {
    try {
      final response = await _dio.post(
        AppConstants.endpointHospitalVisitBook,
        data: {
          'doctorId': doctorId,
          'patientName': patientName,
          'patientMobile': patientMobile,
          'patientAddress': patientAddress,
          'patientCity': patientCity,
          'patientPincode': patientPincode,
          if (patientState != null && patientState.isNotEmpty)
            'patientState': patientState,
          if (patientEmail != null && patientEmail.isNotEmpty)
            'patientEmail': patientEmail,
          if (visitReason != null && visitReason.isNotEmpty)
            'visitReason': visitReason,
          if (patientNotes != null && patientNotes.isNotEmpty)
            'patientNotes': patientNotes,
          'dayOfWeek': dayOfWeek,
          'startHour': startHour,
          'slotStart': slotStart.toIso8601String(),
        },
      );
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      return ApiResponse(
        success: body['success'] as bool? ?? false,
        message: body['message'] as String?,
        statusCode: body['statusCode'] as int? ?? 201,
        data: ConsultationBookingResult.fromJson(data),
        error: body['success'] == false
            ? (body['error'] as String? ?? body['message'] as String?)
            : null,
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<ConsultationBookingResult>> bookOnlineConsult({
    required String doctorId,
    required String patientName,
    required String patientMobile,
    String? patientEmail,
    String? patientNotes,
    required int dayOfWeek,
    required int startHour,
    required DateTime slotStart,
  }) async {
    try {
      final response = await _dio.post(
        AppConstants.endpointOnlineConsultBook,
        data: {
          'doctorId': doctorId,
          'patientName': patientName,
          'patientMobile': patientMobile,
          if (patientEmail != null && patientEmail.isNotEmpty)
            'patientEmail': patientEmail,
          if (patientNotes != null && patientNotes.isNotEmpty)
            'patientNotes': patientNotes,
          'dayOfWeek': dayOfWeek,
          'startHour': startHour,
          'slotStart': slotStart.toIso8601String(),
        },
      );
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      return ApiResponse(
        success: body['success'] as bool? ?? false,
        message: body['message'] as String?,
        statusCode: body['statusCode'] as int? ?? 201,
        data: ConsultationBookingResult.fromJson(data),
        error: body['success'] == false
            ? (body['error'] as String? ?? body['message'] as String?)
            : null,
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<ConsultationBookingResult>> requestHomeVisit({
    required String doctorId,
    required String patientName,
    required String patientMobile,
    required String patientAddress,
    required String patientCity,
    required String patientPincode,
    String? patientEmail,
    String? patientState,
    String? visitReason,
    String? patientNotes,
    double? patientLatitude,
    double? patientLongitude,
    required int dayOfWeek,
    required int startHour,
    required DateTime slotStart,
  }) async {
    try {
      final response = await _dio.post(
        AppConstants.endpointHomeVisitRequest,
        data: {
          'doctorId': doctorId,
          'patientName': patientName,
          'patientMobile': patientMobile,
          'patientAddress': patientAddress,
          'patientCity': patientCity,
          'patientPincode': patientPincode,
          if (patientState != null && patientState.isNotEmpty)
            'patientState': patientState,
          if (patientEmail != null && patientEmail.isNotEmpty)
            'patientEmail': patientEmail,
          if (visitReason != null && visitReason.isNotEmpty)
            'visitReason': visitReason,
          if (patientNotes != null && patientNotes.isNotEmpty)
            'patientNotes': patientNotes,
          if (patientLatitude != null) 'patientLatitude': patientLatitude,
          if (patientLongitude != null) 'patientLongitude': patientLongitude,
          'dayOfWeek': dayOfWeek,
          'startHour': startHour,
          'slotStart': slotStart.toIso8601String(),
        },
      );
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      return ApiResponse(
        success: body['success'] as bool? ?? false,
        message: body['message'] as String?,
        statusCode: body['statusCode'] as int? ?? 201,
        data: ConsultationBookingResult.fromJson(data),
        error: body['success'] == false
            ? (body['error'] as String? ?? body['message'] as String?)
            : null,
      );
    } on DioException catch (e) {
      return _handleError(e);
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
