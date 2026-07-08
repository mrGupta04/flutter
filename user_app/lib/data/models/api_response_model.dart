/// Unwraps list items from an API `data` field that may be a raw [List]
/// or a paginated object `{ data: [...], pagination: {...} }`.
List<dynamic> extractApiList(dynamic raw) {
  if (raw is List) return raw;
  if (raw is Map<String, dynamic>) {
    final nested = raw['data'];
    if (nested is List) return nested;
  }
  return const [];
}

/// Reads pagination metadata from a paginated API `data` object.
Map<String, dynamic> extractApiPagination(
  dynamic raw, {
  Map<String, dynamic> fallback = const {},
}) {
  if (raw is Map<String, dynamic>) {
    final pagination = raw['pagination'];
    if (pagination is Map<String, dynamic>) return pagination;
  }
  return fallback;
}

/// Generic API response wrapper
class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final String? error;
  final int? statusCode;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.error,
    this.statusCode,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) {
    return ApiResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      error: json['error'] as String?,
      statusCode: json['statusCode'] as int?,
    );
  }

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) {
    return {
      'success': success,
      'message': message,
      'data': data != null ? toJsonT(data as T) : null,
      'error': error,
      'statusCode': statusCode,
    };
  }
}

/// Pagination model
class PaginationModel {
  final int currentPage;
  final int totalPages;
  final int pageSize;
  final int totalCount;
  final bool hasNextPage;

  PaginationModel({
    required this.currentPage,
    required this.totalPages,
    required this.pageSize,
    required this.totalCount,
    required this.hasNextPage,
  });

  factory PaginationModel.fromJson(Map<String, dynamic> json) {
    return PaginationModel(
      currentPage: json['currentPage'] as int? ?? 1,
      totalPages: json['totalPages'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 0,
      totalCount: json['totalCount'] as int? ?? 0,
      hasNextPage: json['hasNextPage'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentPage': currentPage,
      'totalPages': totalPages,
      'pageSize': pageSize,
      'totalCount': totalCount,
      'hasNextPage': hasNextPage,
    };
  }
}

/// Paginated response model
class PaginatedResponse<T> {
  final List<T> data;
  final PaginationModel pagination;

  PaginatedResponse({
    required this.data,
    required this.pagination,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) {
    return PaginatedResponse(
      data: (json['data'] as List? ?? [])
          .map((item) => fromJsonT(item))
          .toList(),
      pagination: PaginationModel.fromJson(
        (json['pagination'] as Map<String, dynamic>? ?? {}),
      ),
    );
  }

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) {
    return {
      'data': data.map((item) => toJsonT(item)).toList(),
      'pagination': pagination.toJson(),
    };
  }
}
