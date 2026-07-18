import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../models/api_response_model.dart';
import '../models/scan_center_model.dart';
import '../services/dio_service.dart';

class ScanSearchParams {
  const ScanSearchParams({
    this.query,
    this.city,
    this.scanId,
    this.categoryId,
    this.homeVisit,
    this.hasOffer,
    this.minPrice,
    this.maxPrice,
    this.openNow,
    this.latitude,
    this.longitude,
  });

  final String? query;
  final String? city;
  final String? scanId;
  final String? categoryId;
  final bool? homeVisit;
  final bool? hasOffer;
  final int? minPrice;
  final int? maxPrice;
  final bool? openNow;
  final double? latitude;
  final double? longitude;
}

class ScanRepository {
  final DioService _dioService;

  ScanRepository({DioService? dioService})
      : _dioService = dioService ?? DioService();

  Future<ApiResponse<List<ScanCenterModel>>> searchVerified(
    ScanSearchParams params,
  ) async {
    try {
      final response = await _dioService.get(
        AppConstants.endpointVerifiedScanCenters,
        queryParameters: {
          if (params.query != null && params.query!.isNotEmpty) 'q': params.query,
          if (params.city != null && params.city!.isNotEmpty) 'city': params.city,
          if (params.scanId != null && params.scanId!.isNotEmpty)
            'scanId': params.scanId,
          if (params.categoryId != null && params.categoryId!.isNotEmpty)
            'categoryId': params.categoryId,
          if (params.homeVisit == true) 'homeVisit': 'true',
          if (params.hasOffer == true) 'hasOffer': 'true',
          if (params.minPrice != null) 'minPrice': params.minPrice.toString(),
          if (params.maxPrice != null) 'maxPrice': params.maxPrice.toString(),
          if (params.openNow == true) 'openNow': 'true',
          if (params.latitude != null) 'latitude': params.latitude.toString(),
          if (params.longitude != null) 'longitude': params.longitude.toString(),
        },
      );

      final body = response.data as Map<String, dynamic>;
      final list = extractApiList(body['data'])
          .map((e) => ScanCenterModel.fromJson(e as Map<String, dynamic>))
          .toList();

      return ApiResponse(
        success: body['success'] as bool? ?? false,
        message: body['message'] as String?,
        data: list,
        statusCode: body['statusCode'] as int? ?? 200,
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

  Future<ApiResponse<ScanCenterModel>> getById(String id) async {
    try {
      final response = await _dioService.get(
        AppConstants.endpointGetScanCenterProfile,
        queryParameters: {'scanCenterId': id},
      );

      return ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ScanCenterModel.fromJson(json as Map<String, dynamic>),
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

  Future<ApiResponse<Map<String, dynamic>>> createBooking({
    required String scanCenterId,
    required String patientName,
    required String patientMobile,
    required String scanName,
    required DateTime scheduledDate,
    required String timeSlot,
    String? patientEmail,
    String? patientId,
    String? scanId,
    String? categoryId,
    String? countryCode,
    int? totalAmount,
    bool contrastRequired = false,
    String? preparationNotes,
    String? prescriptionFileName,
    String? paymentMethod,
    String? notes,
  }) async {
    try {
      final response = await _dioService.post(
        AppConstants.endpointScanBookings,
        data: {
          'scanCenterId': scanCenterId,
          'patientName': patientName,
          'patientMobile': patientMobile,
          if (patientEmail != null) 'patientEmail': patientEmail,
          if (patientId != null) 'patientId': patientId,
          if (countryCode != null) 'countryCode': countryCode,
          'scanName': scanName,
          if (scanId != null) 'scanId': scanId,
          if (categoryId != null) 'categoryId': categoryId,
          'scheduledDate': scheduledDate.toIso8601String(),
          'timeSlot': timeSlot,
          if (totalAmount != null) 'totalAmount': totalAmount,
          'contrastRequired': contrastRequired,
          if (preparationNotes != null) 'preparationNotes': preparationNotes,
          if (prescriptionFileName != null)
            'prescriptionFileName': prescriptionFileName,
          if (paymentMethod != null) 'paymentMethod': paymentMethod,
          if (notes != null) 'notes': notes,
        },
      );
      final body = response.data as Map<String, dynamic>;
      return ApiResponse(
        success: body['success'] as bool? ?? true,
        message: body['message'] as String?,
        statusCode: body['statusCode'] as int? ?? 201,
        data: body['data'] is Map<String, dynamic>
            ? body['data'] as Map<String, dynamic>
            : null,
        error: body['success'] == false
            ? (body['error'] as String? ?? body['message'] as String?)
            : null,
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

  Future<ApiResponse<Map<String, dynamic>>> createPaymentOrder(
    String bookingId,
  ) async {
    try {
      final response = await _dioService.post(
        AppConstants.endpointScanPaymentsCreateOrder,
        data: {'bookingId': bookingId},
      );
      final body = response.data as Map<String, dynamic>;
      return ApiResponse(
        success: body['success'] as bool? ?? true,
        message: body['message'] as String?,
        data: body['data'] is Map<String, dynamic>
            ? body['data'] as Map<String, dynamic>
            : null,
        statusCode: body['statusCode'] as int? ?? 200,
        error: body['success'] == false
            ? (body['error'] as String? ?? body['message'] as String?)
            : null,
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> verifyPayment({
    required String bookingId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    try {
      final response = await _dioService.post(
        AppConstants.endpointScanPaymentsVerify,
        data: {
          'bookingId': bookingId,
          'razorpayOrderId': razorpayOrderId,
          'razorpayPaymentId': razorpayPaymentId,
          'razorpaySignature': razorpaySignature,
        },
      );
      final body = response.data as Map<String, dynamic>;
      return ApiResponse(
        success: body['success'] as bool? ?? true,
        message: body['message'] as String?,
        data: body['data'] is Map<String, dynamic>
            ? body['data'] as Map<String, dynamic>
            : null,
        statusCode: body['statusCode'] as int? ?? 200,
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
    }
    return ApiResponse<T>(success: false, error: message, statusCode: statusCode);
  }
}
