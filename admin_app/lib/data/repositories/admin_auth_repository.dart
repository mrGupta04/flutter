import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../models/models.dart';
import '../services/dio_service.dart';

class AdminAuthRepository {
  final DioService _dioService;

  AdminAuthRepository({DioService? dioService})
    : _dioService = dioService ?? DioService();

  Future<ApiResponse<AdminLoginResult>> login({
    required String email,
    required String password,
    bool asApprover = false,
  }) async {
    try {
      final response = await _dioService.post(
        asApprover
            ? AppConstants.endpointApprovalApproverLogin
            : AppConstants.endpointAdminLogin,
        data: {'email': email, 'password': password},
      );

      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      final approver = data['approver'] as Map<String, dynamic>? ?? const {};

      return ApiResponse(
        success: body['success'] as bool? ?? true,
        statusCode: body['statusCode'] as int? ?? 200,
        data: AdminLoginResult(
          token: data['token'] as String? ?? '',
          email: (data['email'] ?? approver['email']) as String? ?? email,
          role:
              (data['role'] ?? approver['role']) as String? ??
              (asApprover ? 'approver' : 'admin'),
          name: (data['name'] ?? approver['name']) as String?,
          canReassign: approver['canReassign'] as bool? ?? false,
          permissions: (approver['permissions'] as List? ?? const [])
              .map((item) => item.toString())
              .toList(),
          refreshToken: data['refreshToken'] as String?,
          sessionId: data['sessionId'] as String?,
        ),
      );
    } on DioException catch (e) {
      return _handleError(e);
    } catch (_) {
      return ApiResponse(
        success: false,
        error: AppConstants.errorSomethingWentWrong,
        statusCode: 500,
      );
    }
  }

  Future<void> logoutApprover() async {
    try {
      await _dioService.post(
        AppConstants.endpointApprovalApproverLogout,
        data: const {},
      );
    } on DioException {
      // Local credentials must still be cleared when the session already
      // expired or the network is unavailable.
    }
  }

  ApiResponse<T> _handleError<T>(DioException error) {
    String message = AppConstants.errorSomethingWentWrong;
    int statusCode = 500;

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      message = AppConstants.errorTimeoutException;
      statusCode = 408;
    } else if (error.type == DioExceptionType.connectionError) {
      message = AppConstants.errorNetworkException;
    } else if (error.type == DioExceptionType.badResponse) {
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

class AdminLoginResult {
  final String token;
  final String email;
  final String role;
  final String? name;
  final bool canReassign;
  final List<String> permissions;
  final String? refreshToken;
  final String? sessionId;

  const AdminLoginResult({
    required this.token,
    required this.email,
    required this.role,
    this.name,
    this.canReassign = false,
    this.permissions = const [],
    this.refreshToken,
    this.sessionId,
  });

  bool get isAdmin => role == 'admin' || role == 'super_admin';
}
