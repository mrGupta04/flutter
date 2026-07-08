import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../models/api_response_model.dart';
import '../models/blood_payment_model.dart';
import '../models/blood_bank_model.dart';
import '../services/dio_service.dart';

class BloodBankRepository {
  final DioService _dioService;

  BloodBankRepository({DioService? dioService})
      : _dioService = dioService ?? DioService();

  Future<ApiResponse<List<BloodBankModel>>> getVerifiedBloodBanks({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? city,
    String? pincode,
    String? area,
    bool? available24x7,
    String? bloodGroup,
    bool? hasApheresis,
    bool? emergencySupply,
    bool? homeDelivery,
    bool? openNow,
    String? componentType,
    bool? hasDiscount,
    double? minRating,
    double? maxPrice,
    double? latitude,
    double? longitude,
    double? maxDistanceKm,
  }) async {
    try {
      final response = await _dioService.get(
        AppConstants.endpointVerifiedBloodBanks,
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          if (search != null && search.isNotEmpty) 'q': search,
          if (city != null && city.isNotEmpty) 'city': city,
          if (pincode != null && pincode.isNotEmpty) 'pincode': pincode,
          if (area != null && area.isNotEmpty) 'area': area,
          if (available24x7 == true) 'available24x7': 'true',
          if (bloodGroup != null && bloodGroup.isNotEmpty) 'bloodGroup': bloodGroup,
          if (hasApheresis == true) 'hasApheresis': 'true',
          if (emergencySupply == true) 'emergencySupply': 'true',
          if (homeDelivery == true) 'homeDelivery': 'true',
          if (openNow == true) 'openNow': 'true',
          if (componentType != null && componentType.isNotEmpty)
            'componentType': componentType,
          if (hasDiscount == true) 'hasDiscount': 'true',
          if (minRating != null) 'minRating': minRating.toString(),
          if (maxPrice != null) 'maxPrice': maxPrice.toString(),
          if (latitude != null) 'latitude': latitude.toString(),
          if (longitude != null) 'longitude': longitude.toString(),
          if (maxDistanceKm != null) 'maxDistanceKm': maxDistanceKm.toString(),
        },
      );

      final body = response.data as Map<String, dynamic>;
      final list = extractApiList(body['data'])
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
      return ApiResponse(success: false, error: 'An unexpected error occurred', statusCode: 500);
    }
  }

  Future<ApiResponse<BloodBankModel>> getBloodBankProfile(String bloodBankId) async {
    try {
      final response = await _dioService.get(
        AppConstants.endpointGetBloodBankProfile,
        queryParameters: {'bloodBankId': bloodBankId},
      );
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>;
      return ApiResponse(
        success: body['success'] as bool? ?? true,
        statusCode: body['statusCode'] as int? ?? 200,
        data: BloodBankModel.fromJson(data),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<List<BloodReviewModel>>> getReviews(String bloodBankId) async {
    try {
      final response = await _dioService.get(
        AppConstants.endpointBloodBankReviews,
        queryParameters: {'bloodBankId': bloodBankId},
      );
      final body = response.data as Map<String, dynamic>;
      final list = (body['data'] as List? ?? [])
          .map((e) => BloodReviewModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return ApiResponse(
        success: body['success'] as bool? ?? true,
        statusCode: body['statusCode'] as int? ?? 200,
        data: list,
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<BloodOrderModel>> placeOrder(Map<String, dynamic> payload) async {
    try {
      final response = await _dioService.post(
        AppConstants.endpointBloodBankBookings,
        data: payload,
      );
      final body = response.data as Map<String, dynamic>;
      return ApiResponse(
        success: body['success'] as bool? ?? true,
        statusCode: body['statusCode'] as int? ?? 200,
        data: BloodOrderModel.fromJson(body['data'] as Map<String, dynamic>),
        message: body['message'] as String?,
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<BloodOrderModel>> getOrder(String orderId) async {
    try {
      final response = await _dioService.get(
        '${AppConstants.endpointBloodBankBookings}/$orderId',
      );
      final body = response.data as Map<String, dynamic>;
      return ApiResponse(
        success: body['success'] as bool? ?? true,
        statusCode: body['statusCode'] as int? ?? 200,
        data: BloodOrderModel.fromJson(body['data'] as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> createEmergencyRequest(
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _dioService.post(
        AppConstants.endpointBloodBankEmergency,
        data: payload,
      );
      final body = response.data as Map<String, dynamic>;
      return ApiResponse(
        success: body['success'] as bool? ?? true,
        statusCode: body['statusCode'] as int? ?? 200,
        data: body['data'] as Map<String, dynamic>,
        message: body['message'] as String?,
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<BloodPaymentOrderResponse>> createBloodPaymentOrder(
    String orderId,
  ) async {
    try {
      final response = await _dioService.post(
        AppConstants.endpointBloodBankPaymentCreateOrder,
        data: {'orderId': orderId},
      );
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      return ApiResponse(
        success: body['success'] as bool? ?? false,
        statusCode: body['statusCode'] as int? ?? 201,
        data: BloodPaymentOrderResponse.fromJson(data),
        error: body['success'] == false
            ? (body['error'] as String? ?? body['message'] as String?)
            : null,
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<BloodOrderModel>> verifyBloodPayment(
    BloodPaymentVerifyRequest request,
  ) async {
    try {
      final response = await _dioService.post(
        AppConstants.endpointBloodBankPaymentVerify,
        data: request.toJson(),
      );
      final body = response.data as Map<String, dynamic>;
      return ApiResponse(
        success: body['success'] as bool? ?? false,
        message: body['message'] as String?,
        statusCode: body['statusCode'] as int? ?? 200,
        data: BloodOrderModel.fromJson(body['data'] as Map<String, dynamic>),
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
    if (error.type == DioExceptionType.connectionError) {
      message = AppConstants.errorNetworkException;
    } else if (error.type == DioExceptionType.badResponse) {
      statusCode = error.response?.statusCode ?? 500;
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        message = (data['error'] ?? data['message'] ?? message) as String;
      }
    }
    return ApiResponse<T>(success: false, error: message, statusCode: statusCode);
  }
}
