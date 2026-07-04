import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../models/api_response_model.dart';
import '../models/lab_model.dart';
import '../services/dio_service.dart';

enum LabExploreSort {
  recommended('Recommended'),
  nearest('Nearest'),
  highestRated('Highest Rated'),
  lowestPrice('Lowest Price'),
  fastestReport('Fastest Report');

  const LabExploreSort(this.label);
  final String label;
}

class LabExploreFilters {
  const LabExploreFilters({
    this.homeCollection = false,
    this.labVisit = false,
    this.openNow = false,
    this.nablAccredited = false,
    this.minRating,
  });

  final bool homeCollection;
  final bool labVisit;
  final bool openNow;
  final bool nablAccredited;
  final double? minRating;

  LabExploreFilters copyWith({
    bool? homeCollection,
    bool? labVisit,
    bool? openNow,
    bool? nablAccredited,
    double? minRating,
    bool clearMinRating = false,
  }) {
    return LabExploreFilters(
      homeCollection: homeCollection ?? this.homeCollection,
      labVisit: labVisit ?? this.labVisit,
      openNow: openNow ?? this.openNow,
      nablAccredited: nablAccredited ?? this.nablAccredited,
      minRating: clearMinRating ? null : (minRating ?? this.minRating),
    );
  }

  bool get hasActiveFilters =>
      homeCollection ||
      labVisit ||
      openNow ||
      nablAccredited ||
      minRating != null;
}

class LabSearchParams {
  const LabSearchParams({
    this.query,
    this.city,
    this.testId,
    this.homeCollection,
    this.latitude,
    this.longitude,
    this.page = 1,
    this.pageSize = 20,
  });

  final String? query;
  final String? city;
  final String? testId;
  final bool? homeCollection;
  final double? latitude;
  final double? longitude;
  final int page;
  final int pageSize;

  LabSearchParams copyWith({
    String? query,
    String? city,
    String? testId,
    bool? homeCollection,
    double? latitude,
    double? longitude,
    int? page,
    int? pageSize,
  }) {
    return LabSearchParams(
      query: query ?? this.query,
      city: city ?? this.city,
      testId: testId ?? this.testId,
      homeCollection: homeCollection ?? this.homeCollection,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}

class LabSearchPage {
  const LabSearchPage({
    required this.labs,
    required this.page,
    required this.pageSize,
    required this.totalPages,
    required this.total,
  });

  final List<LabModel> labs;
  final int page;
  final int pageSize;
  final int totalPages;
  final int total;

  bool get hasMore => page < totalPages;
}

class LabRepository {
  LabRepository({DioService? dioService})
      : _dioService = dioService ?? DioService();

  final DioService _dioService;

  Future<ApiResponse<List<LabModel>>> searchVerified(
    LabSearchParams params,
  ) async {
    final page = await searchVerifiedPage(params);
    if (page.success && page.data != null) {
      return ApiResponse(
        success: true,
        data: page.data!.labs,
        statusCode: page.statusCode,
      );
    }
    return ApiResponse(
      success: false,
      error: page.error,
      statusCode: page.statusCode,
    );
  }

  Future<ApiResponse<LabSearchPage>> searchVerifiedPage(
    LabSearchParams params,
  ) async {
    try {
      final response = await _dioService.get(
        AppConstants.endpointVerifiedLabs,
        queryParameters: {
          if (params.query != null && params.query!.isNotEmpty)
            'q': params.query,
          if (params.city != null && params.city!.isNotEmpty)
            'city': params.city,
          if (params.testId != null && params.testId!.isNotEmpty)
            'testId': params.testId,
          if (params.homeCollection == true) 'homeCollection': 'true',
          if (params.latitude != null)
            'latitude': params.latitude.toString(),
          if (params.longitude != null)
            'longitude': params.longitude.toString(),
          'page': params.page.toString(),
          'pageSize': params.pageSize.toString(),
        },
      );

      final body = response.data as Map<String, dynamic>;
      final list = (body['data'] as List?)
              ?.map((e) => LabModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      final pagination = body['pagination'] as Map<String, dynamic>? ?? {};

      return ApiResponse(
        success: body['success'] as bool? ?? false,
        message: body['message'] as String?,
        data: LabSearchPage(
          labs: list,
          page: (pagination['currentPage'] as num?)?.toInt() ?? params.page,
          pageSize: (pagination['pageSize'] as num?)?.toInt() ?? params.pageSize,
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

  Future<ApiResponse<LabModel>> getById(String labId) async {
    try {
      final response = await _dioService.get(
        AppConstants.endpointGetLabProfile,
        queryParameters: {'labId': labId},
      );
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>?;
      if (data == null) {
        return ApiResponse(
          success: false,
          error: 'Lab not found',
          statusCode: 404,
        );
      }
      return ApiResponse(
        success: body['success'] as bool? ?? true,
        data: LabModel.fromJson(data),
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
