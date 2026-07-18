import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../models/api_response_model.dart';
import '../models/bookable_slot_model.dart';
import '../services/dio_service.dart';

class NurseHomeVisitRepository {
  NurseHomeVisitRepository({DioService? dioService})
      : _dio = dioService ?? DioService();

  final DioService _dio;

  Future<ApiResponse<BookableSlotsResponse>> getBookableSlots({
    required String nurseId,
  }) async {
    try {
      final response = await _dio.get(
        AppConstants.endpointNurseBookableSlots,
        queryParameters: {'nurseId': nurseId},
      );
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      return ApiResponse(
        success: body['success'] as bool? ?? true,
        statusCode: body['statusCode'] as int? ?? 200,
        data: BookableSlotsResponse.fromJson(data),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<SlotHoldResult>> holdSlot({
    required String nurseId,
    required int dayOfWeek,
    required int startHour,
    required DateTime slotStart,
    String? holdId,
  }) async {
    try {
      final response = await _dio.post(
        AppConstants.endpointNurseSlotHold,
        data: {
          'nurseId': nurseId,
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
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<void>> releaseSlotHold({required String holdId}) async {
    try {
      final response = await _dio.delete(
        AppConstants.endpointNurseSlotHoldRelease(holdId),
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

  Future<ApiResponse<ConsultationBookingResult>> requestHomeVisit({
    required String nurseId,
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
    String? couponCode,
    required int dayOfWeek,
    required int startHour,
    required DateTime slotStart,
  }) async {
    try {
      final response = await _dio.post(
        AppConstants.endpointNurseHomeVisitRequest,
        data: {
          'nurseId': nurseId,
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
          if (couponCode != null && couponCode.isNotEmpty)
            'couponCode': couponCode.trim().toUpperCase(),
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
