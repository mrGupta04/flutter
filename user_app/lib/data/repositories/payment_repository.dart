import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../models/api_response_model.dart';
import '../models/bookable_slot_model.dart';
import '../models/payment_model.dart';
import '../services/dio_service.dart';

class PaymentRepository {
  PaymentRepository({DioService? dioService})
      : _dio = dioService ?? DioService();

  final DioService _dio;

  Future<ApiResponse<PaymentOrderResponse>> createOrder({
    required String doctorId,
    required String consultationType,
    required String patientName,
    required String patientMobile,
    required int dayOfWeek,
    required int startHour,
    required DateTime slotStart,
    String? patientEmail,
    String? patientNotes,
    String? patientAddress,
    String? patientCity,
    String? patientState,
    String? patientPincode,
    String? visitReason,
    String? couponCode,
  }) async {
    try {
      final response = await _dio.post(
        AppConstants.endpointPaymentCreateOrder,
        data: {
          'doctorId': doctorId,
          'consultationType': consultationType,
          'patientName': patientName,
          'patientMobile': patientMobile,
          if (patientEmail != null && patientEmail.isNotEmpty)
            'patientEmail': patientEmail,
          if (patientNotes != null && patientNotes.isNotEmpty)
            'patientNotes': patientNotes,
          if (patientAddress != null && patientAddress.isNotEmpty)
            'patientAddress': patientAddress,
          if (patientCity != null && patientCity.isNotEmpty)
            'patientCity': patientCity,
          if (patientState != null && patientState.isNotEmpty)
            'patientState': patientState,
          if (patientPincode != null && patientPincode.isNotEmpty)
            'patientPincode': patientPincode,
          if (visitReason != null && visitReason.isNotEmpty)
            'visitReason': visitReason,
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
        statusCode: body['statusCode'] as int? ?? 201,
        data: PaymentOrderResponse.fromJson(data),
        error: body['success'] == false
            ? (body['error'] as String? ?? body['message'] as String?)
            : null,
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<PaymentOrderResponse>> createOrderForBooking({
    required String bookingId,
  }) async {
    try {
      final response = await _dio.post(
        AppConstants.endpointPaymentCreateOrder,
        data: {'bookingId': bookingId},
      );
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      return ApiResponse(
        success: body['success'] as bool? ?? false,
        statusCode: body['statusCode'] as int? ?? 201,
        data: PaymentOrderResponse.fromJson(data),
        error: body['success'] == false
            ? (body['error'] as String? ?? body['message'] as String?)
            : null,
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<ConsultationBookingResult>> verifyPayment(
    PaymentVerifyRequest request,
  ) async {
    try {
      final response = await _dio.post(
        AppConstants.endpointPaymentVerify,
        data: request.toJson(),
      );
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      return ApiResponse(
        success: body['success'] as bool? ?? false,
        message: body['message'] as String?,
        statusCode: body['statusCode'] as int? ?? 200,
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
