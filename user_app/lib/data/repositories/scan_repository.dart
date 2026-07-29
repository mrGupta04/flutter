import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../models/api_response_model.dart';
import '../models/scan_center_model.dart';
import '../services/dio_service.dart';

enum ScanExploreSort {
  recommended('Recommended'),
  nearest('Nearest'),
  highestRated('Highest Rated'),
  lowestPrice('Lowest Price'),
  fastestReport('Fastest Report');

  const ScanExploreSort(this.label);
  final String label;
}

class ScanExploreFilters {
  const ScanExploreFilters({
    this.homeVisit = false,
    this.centerVisit = false,
    this.openNow = false,
    this.hasOffer = false,
    this.minRating,
  });

  final bool homeVisit;
  final bool centerVisit;
  final bool openNow;
  final bool hasOffer;
  final double? minRating;

  ScanExploreFilters copyWith({
    bool? homeVisit,
    bool? centerVisit,
    bool? openNow,
    bool? hasOffer,
    double? minRating,
    bool clearMinRating = false,
  }) {
    return ScanExploreFilters(
      homeVisit: homeVisit ?? this.homeVisit,
      centerVisit: centerVisit ?? this.centerVisit,
      openNow: openNow ?? this.openNow,
      hasOffer: hasOffer ?? this.hasOffer,
      minRating: clearMinRating ? null : (minRating ?? this.minRating),
    );
  }

  bool get hasActiveFilters =>
      homeVisit || centerVisit || openNow || hasOffer || minRating != null;
}

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
    this.page = 1,
    this.pageSize = 20,
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
  final int page;
  final int pageSize;

  ScanSearchParams copyWith({
    String? query,
    String? city,
    String? scanId,
    String? categoryId,
    bool? homeVisit,
    bool? hasOffer,
    int? minPrice,
    int? maxPrice,
    bool? openNow,
    double? latitude,
    double? longitude,
    int? page,
    int? pageSize,
  }) {
    return ScanSearchParams(
      query: query ?? this.query,
      city: city ?? this.city,
      scanId: scanId ?? this.scanId,
      categoryId: categoryId ?? this.categoryId,
      homeVisit: homeVisit ?? this.homeVisit,
      hasOffer: hasOffer ?? this.hasOffer,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      openNow: openNow ?? this.openNow,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScanSearchParams &&
        other.query == query &&
        other.city == city &&
        other.scanId == scanId &&
        other.categoryId == categoryId &&
        other.homeVisit == homeVisit &&
        other.hasOffer == hasOffer &&
        other.minPrice == minPrice &&
        other.maxPrice == maxPrice &&
        other.openNow == openNow &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.page == page &&
        other.pageSize == pageSize;
  }

  @override
  int get hashCode => Object.hash(
        query,
        city,
        scanId,
        categoryId,
        homeVisit,
        hasOffer,
        minPrice,
        maxPrice,
        openNow,
        latitude,
        longitude,
        page,
        pageSize,
      );
}

class ScanSearchPage {
  const ScanSearchPage({
    required this.centers,
    required this.page,
    required this.pageSize,
    required this.totalPages,
    required this.total,
  });

  final List<ScanCenterModel> centers;
  final int page;
  final int pageSize;
  final int totalPages;
  final int total;

  bool get hasMore => page < totalPages;
}

class ScanRepository {
  ScanRepository({DioService? dioService})
      : _dioService = dioService ?? DioService();

  final DioService _dioService;

  Future<ApiResponse<List<ScanCenterModel>>> searchVerified(
    ScanSearchParams params,
  ) async {
    final page = await searchVerifiedPage(params);
    if (page.success && page.data != null) {
      return ApiResponse(
        success: true,
        data: page.data!.centers,
        statusCode: page.statusCode,
      );
    }
    return ApiResponse(
      success: false,
      error: page.error,
      statusCode: page.statusCode,
    );
  }

  Future<ApiResponse<ScanSearchPage>> searchVerifiedPage(
    ScanSearchParams params,
  ) async {
    try {
      final response = await _dioService.get(
        AppConstants.endpointVerifiedScanCenters,
        queryParameters: {
          if (params.query != null && params.query!.isNotEmpty)
            'q': params.query,
          if (params.city != null && params.city!.isNotEmpty)
            'city': params.city,
          if (params.scanId != null && params.scanId!.isNotEmpty)
            'scanId': params.scanId,
          if (params.categoryId != null && params.categoryId!.isNotEmpty)
            'categoryId': params.categoryId,
          if (params.homeVisit == true) 'homeVisit': 'true',
          if (params.hasOffer == true) 'hasOffer': 'true',
          if (params.minPrice != null) 'minPrice': params.minPrice.toString(),
          if (params.maxPrice != null) 'maxPrice': params.maxPrice.toString(),
          if (params.openNow == true) 'openNow': 'true',
          if (params.latitude != null)
            'latitude': params.latitude.toString(),
          if (params.longitude != null)
            'longitude': params.longitude.toString(),
          'page': params.page.toString(),
          'pageSize': params.pageSize.toString(),
        },
      );

      final body = response.data as Map<String, dynamic>;
      final raw = body['data'];
      final list = extractApiList(raw)
          .map((e) => ScanCenterModel.fromJson(e as Map<String, dynamic>))
          .toList();
      final pagination = extractApiPagination(raw);

      return ApiResponse(
        success: body['success'] as bool? ?? false,
        message: body['message'] as String?,
        data: ScanSearchPage(
          centers: list,
          page: (pagination['currentPage'] as num?)?.toInt() ?? params.page,
          pageSize:
              (pagination['pageSize'] as num?)?.toInt() ?? params.pageSize,
          totalPages: (pagination['totalPages'] as num?)?.toInt() ?? 1,
          total: (pagination['total'] as num?)?.toInt() ?? list.length,
        ),
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
    return ApiResponse<T>(
      success: false,
      error: message,
      statusCode: statusCode,
    );
  }
}
