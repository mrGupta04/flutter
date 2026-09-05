import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../models/ambulance_booking_model.dart';
import '../models/ambulance_model.dart';
import '../models/api_response_model.dart';
import '../services/dio_service.dart';

class AmbulanceRepository {
  final DioService _dioService;

  AmbulanceRepository({DioService? dioService})
      : _dioService = dioService ?? DioService();

  Future<ApiResponse<List<AmbulanceModel>>> getVerifiedAmbulances({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? city,
    bool? available24x7,
    String? vehicleType,
  }) async {
    try {
      final response = await _dioService.get(
        AppConstants.endpointVerifiedAmbulances,
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          if (search != null && search.isNotEmpty) 'q': search,
          if (city != null && city.isNotEmpty) 'city': city,
          if (available24x7 == true) 'available24x7': 'true',
          if (vehicleType != null && vehicleType.isNotEmpty)
            'vehicleType': vehicleType,
        },
      );

      final body = response.data as Map<String, dynamic>;
      final list = extractApiList(body['data'])
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

  Future<ApiResponse<Map<String, dynamic>>> requestAmbulance({
    required String ambulanceId,
    required String patientName,
    required String patientMobile,
    required String pickupAddress,
    String? patientEmail,
    String? patientId,
    String? pickupCity,
    String? pickupPincode,
    double? pickupLatitude,
    double? pickupLongitude,
    String? dropAddress,
    String? notes,
    String? vehicleTypeRequested,
    bool isEmergency = true,
    String countryCode = '91',
  }) async {
    try {
      final response = await _dioService.post(
        AppConstants.endpointAmbulanceBookings,
        data: {
          'ambulanceId': ambulanceId,
          'patientName': patientName,
          'patientMobile': patientMobile,
          if (patientEmail != null && patientEmail.isNotEmpty)
            'patientEmail': patientEmail,
          if (patientId != null && patientId.isNotEmpty) 'patientId': patientId,
          'pickupAddress': pickupAddress,
          if (pickupCity != null) 'pickupCity': pickupCity,
          if (pickupPincode != null) 'pickupPincode': pickupPincode,
          if (pickupLatitude != null) 'pickupLatitude': pickupLatitude,
          if (pickupLongitude != null) 'pickupLongitude': pickupLongitude,
          if (dropAddress != null) 'dropAddress': dropAddress,
          if (notes != null) 'notes': notes,
          if (vehicleTypeRequested != null)
            'vehicleTypeRequested': vehicleTypeRequested,
          'isEmergency': isEmergency,
          'countryCode': countryCode,
        },
      );
      final body = response.data as Map<String, dynamic>;
      return ApiResponse(
        success: body['success'] as bool? ?? true,
        statusCode: body['statusCode'] as int? ?? 201,
        message: body['message'] as String?,
        data: body['data'] is Map<String, dynamic>
            ? body['data'] as Map<String, dynamic>
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

  Future<ApiResponse<Map<String, dynamic>>> getCatalog() async {
    try {
      final response = await _dioService.get(AppConstants.endpointAmbulanceCatalog);
      final body = response.data as Map<String, dynamic>;
      return ApiResponse(
        success: body['success'] as bool? ?? true,
        data: body['data'] is Map<String, dynamic>
            ? body['data'] as Map<String, dynamic>
            : {},
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> getHospitals({
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await _dioService.get(
        AppConstants.endpointAmbulanceHospitals,
        queryParameters: {
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
        },
      );
      final body = response.data as Map<String, dynamic>;
      final list = extractApiList(body['data'])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      return ApiResponse(success: true, data: list);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> estimateFare(
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _dioService.post(
        AppConstants.endpointAmbulanceFareEstimate,
        data: payload,
      );
      final body = response.data as Map<String, dynamic>;
      return ApiResponse(
        success: body['success'] as bool? ?? true,
        data: body['data'] is Map<String, dynamic>
            ? body['data'] as Map<String, dynamic>
            : {},
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<AmbulanceBookingModel>> createEmergency(
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _dioService.post(
        AppConstants.endpointAmbulanceEmergency,
        data: payload,
      );
      final body = response.data as Map<String, dynamic>;
      final data = body['data'];
      final raw = data is Map && data['booking'] is Map
          ? Map<String, dynamic>.from(data['booking'] as Map)
          : data is Map<String, dynamic>
              ? data
              : <String, dynamic>{};
      return ApiResponse(
        success: body['success'] as bool? ?? true,
        statusCode: body['statusCode'] as int? ?? 201,
        message: body['message'] as String?,
        data: raw.isEmpty ? null : AmbulanceBookingModel.fromJson(raw),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<AmbulanceBookingModel>> createScheduled(
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _dioService.post(
        AppConstants.endpointAmbulanceScheduled,
        data: payload,
      );
      final body = response.data as Map<String, dynamic>;
      final data = body['data'];
      return ApiResponse(
        success: body['success'] as bool? ?? true,
        message: body['message'] as String?,
        data: data is Map<String, dynamic>
            ? AmbulanceBookingModel.fromJson(data)
            : null,
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<List<AmbulanceBookingModel>>> listMyBookings({
    String? group,
  }) async {
    try {
      final response = await _dioService.get(
        AppConstants.endpointAmbulanceMyBookings,
        queryParameters: {if (group != null) 'group': group},
      );
      final body = response.data as Map<String, dynamic>;
      final list = extractApiList(body['data'])
          .whereType<Map>()
          .map((e) => AmbulanceBookingModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      return ApiResponse(success: true, data: list);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<AmbulanceBookingModel>> getMyBooking(String id) async {
    try {
      final response = await _dioService.get(AppConstants.endpointAmbulanceMyBooking(id));
      final body = response.data as Map<String, dynamic>;
      final data = body['data'];
      return ApiResponse(
        success: body['success'] as bool? ?? true,
        data: data is Map<String, dynamic>
            ? AmbulanceBookingModel.fromJson(data)
            : null,
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<AmbulanceBookingModel>> cancelMine(
    String id, {
    String? reason,
  }) async {
    try {
      final response = await _dioService.post(
        AppConstants.endpointAmbulanceCancelMine(id),
        data: {if (reason != null) 'reason': reason},
      );
      final body = response.data as Map<String, dynamic>;
      final data = body['data'];
      return ApiResponse(
        success: body['success'] as bool? ?? true,
        message: body['message'] as String?,
        data: data is Map<String, dynamic>
            ? AmbulanceBookingModel.fromJson(data)
            : null,
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<AmbulanceBookingModel>> retryDispatch(String id) async {
    try {
      final response = await _dioService.post(
        AppConstants.endpointAmbulanceRetryDispatch(id),
        data: const {},
      );
      final body = response.data as Map<String, dynamic>;
      final data = body['data'];
      final raw = data is Map && data['booking'] is Map
          ? Map<String, dynamic>.from(data['booking'] as Map)
          : data is Map<String, dynamic>
              ? data
              : null;
      return ApiResponse(
        success: body['success'] as bool? ?? true,
        message: body['message'] as String?,
        data: raw == null ? null : AmbulanceBookingModel.fromJson(raw),
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> submitReview(
    String id,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _dioService.post(
        AppConstants.endpointAmbulanceReview(id),
        data: payload,
      );
      final body = response.data as Map<String, dynamic>;
      return ApiResponse(
        success: body['success'] as bool? ?? true,
        message: body['message'] as String?,
        data: body['data'] is Map<String, dynamic>
            ? body['data'] as Map<String, dynamic>
            : {},
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> createPaymentOrder(String bookingId) async {
    try {
      final response = await _dioService.post(
        AppConstants.endpointAmbulancePaymentCreate,
        data: {'bookingId': bookingId},
      );
      final body = response.data as Map<String, dynamic>;
      return ApiResponse(
        success: body['success'] as bool? ?? true,
        data: body['data'] is Map<String, dynamic>
            ? body['data'] as Map<String, dynamic>
            : {},
      );
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<ApiResponse<AmbulanceBookingModel>> verifyPayment(
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _dioService.post(
        AppConstants.endpointAmbulancePaymentVerify,
        data: payload,
      );
      final body = response.data as Map<String, dynamic>;
      final data = body['data'];
      return ApiResponse(
        success: body['success'] as bool? ?? true,
        message: body['message'] as String?,
        data: data is Map<String, dynamic>
            ? AmbulanceBookingModel.fromJson(data)
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
