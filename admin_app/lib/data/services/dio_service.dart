import 'dart:typed_data';

import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/token_storage.dart';
import 'mock_api.dart';

/// Dio instance configuration and API service
class DioService {
  static final DioService _instance = DioService._internal();

  late Dio _dio;

  factory DioService() {
    return _instance;
  }

  DioService._internal() {
    _initializeDio();
  }

  /// Strip leading `/` so paths resolve under `baseUrl` (`.../api/v1/`).
  static String apiPath(String path) {
    return path.startsWith('/') ? path.substring(1) : path;
  }

  /// Full API URI — avoids Dio dropping `/api/v1` when path starts with `/`.
  static Uri resolveUri(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    final base = AppConstants.apiBaseUrl;
    final normalizedBase = base.endsWith('/') ? base : '$base/';
    final uri = Uri.parse('$normalizedBase${apiPath(path)}');
    if (queryParameters == null || queryParameters.isEmpty) {
      return uri;
    }
    return uri.replace(
      queryParameters: queryParameters.map(
        (key, value) => MapEntry(key, value?.toString() ?? ''),
      ),
    );
  }

  /// Initialize Dio with default configuration
  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: const Duration(milliseconds: AppConstants.connectionTimeout),
        receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
        contentType: 'application/json',
        responseType: ResponseType.json,
      ),
    );

    // Add interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onResponse: _onResponse,
        onError: _onError,
      ),
    );
  }

  /// Request interceptor
  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.headers['Accept'] = 'application/json';
    // Multipart uploads must not use application/json — Dio sets the boundary.
    if (options.data is! FormData) {
      options.headers['Content-Type'] = 'application/json';
    } else {
      options.headers.remove('Content-Type');
    }

    options.path = apiPath(options.path);
    options.baseUrl = AppConstants.apiBaseUrl;

    final path = options.path;
    if (path.contains('admin/')) {
      final adminToken = await TokenStorage.instance.getAdminToken();
      if (adminToken != null && adminToken.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $adminToken';
      } else if (AppConstants.adminApiKey.isNotEmpty) {
        options.headers['x-admin-key'] = AppConstants.adminApiKey;
      }
    } else {
      final token = await _getAuthToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    handler.next(options);
  }

  /// Response interceptor
  Future<void> _onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    handler.next(response);
  }

  /// Error interceptor
  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    handler.next(error);
  }

  /// Get Dio instance
  Dio get dio => _dio;

  /// Get auth token from storage
  Future<String?> _getAuthToken() async {
    return TokenStorage.instance.getToken();
  }

  /// Generic GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      if (AppConstants.useMockApi) {
        return MockApi.handleRequest(
          path: path,
          method: 'GET',
          queryParameters: queryParameters,
        );
      }
      final response = await _dio.getUri(
        resolveUri(path, queryParameters: queryParameters),
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException {
      rethrow;
    }
  }

  /// Generic POST request
  Future<Response> post(
    String path, {
    required Map<String, dynamic> data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      if (AppConstants.useMockApi) {
        return MockApi.handleRequest(
          path: path,
          method: 'POST',
          data: data,
          queryParameters: queryParameters,
        );
      }
      final response = await _dio.postUri(
        resolveUri(path, queryParameters: queryParameters),
        data: data,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException {
      rethrow;
    }
  }

  /// Generic PUT request
  Future<Response> put(
    String path, {
    required Map<String, dynamic> data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      if (AppConstants.useMockApi) {
        return MockApi.handleRequest(
          path: path,
          method: 'PUT',
          data: data,
          queryParameters: queryParameters,
        );
      }
      final response = await _dio.putUri(
        resolveUri(path, queryParameters: queryParameters),
        data: data,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException {
      rethrow;
    }
  }

  /// Generic DELETE request
  Future<Response> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      if (AppConstants.useMockApi) {
        return MockApi.handleRequest(
          path: path,
          method: 'DELETE',
          queryParameters: queryParameters,
        );
      }
      final response = await _dio.deleteUri(
        resolveUri(path, queryParameters: queryParameters),
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException {
      rethrow;
    }
  }

  /// Upload file with progress (use [bytes] on web; [filePath] on desktop/mobile).
  Future<Response> uploadFile(
    String path, {
    String? filePath,
    Uint8List? bytes,
    String? filename,
    required String fieldName,
    Map<String, String>? additionalFields,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      if (AppConstants.useMockApi) {
        await _simulateUploadProgress(onSendProgress);
        return MockApi.handleUpload(
          path: path,
          filePath: filePath ?? filename ?? 'upload.bin',
          fields: additionalFields ?? {},
        );
      }

      final resolvedName = filename ??
          (filePath != null ? filePath.split(RegExp(r'[/\\]')).last : 'upload.bin');

      final MultipartFile filePart;
      if (bytes != null) {
        filePart = MultipartFile.fromBytes(bytes, filename: resolvedName);
      } else if (filePath != null) {
        filePart = await MultipartFile.fromFile(filePath, filename: resolvedName);
      } else {
        throw ArgumentError('Either filePath or bytes must be provided');
      }

      final formData = FormData();
      formData.files.add(MapEntry(fieldName, filePart));

      if (additionalFields != null) {
        additionalFields.forEach((key, value) {
          formData.fields.add(MapEntry(key, value));
        });
      }

      final response = await _dio.postUri(
        resolveUri(path),
        data: formData,
        options: Options(
          sendTimeout: const Duration(minutes: 2),
          receiveTimeout: const Duration(minutes: 2),
        ),
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException {
      rethrow;
    }
  }

  Future<void> _simulateUploadProgress(ProgressCallback? onSendProgress) async {
    if (onSendProgress == null) return;
    const total = 100;
    for (var sent = 0; sent <= total; sent += 20) {
      await Future.delayed(const Duration(milliseconds: 120));
      onSendProgress(sent, total);
    }
  }
}
