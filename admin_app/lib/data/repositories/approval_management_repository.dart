import 'package:dio/dio.dart';

import '../../core/constants/app_constants.dart';
import '../models/api_response_model.dart';
import '../models/approval_management_models.dart';
import '../services/dio_service.dart';

class ApprovalManagementRepository {
  ApprovalManagementRepository({DioService? dioService})
    : _dioService = dioService ?? DioService();

  final DioService _dioService;

  Future<ApiResponse<ApprovalDashboardModel>> getDashboard() async {
    try {
      final response = await _dioService.get(
        AppConstants.endpointApprovalDashboard,
      );
      final body = response.data as Map<String, dynamic>;
      return ApiResponse(
        success: body['success'] as bool? ?? true,
        statusCode: body['statusCode'] as int? ?? 200,
        data: ApprovalDashboardModel.fromJson(
          body['data'] as Map<String, dynamic>? ?? const {},
        ),
        message: body['message'] as String?,
      );
    } on DioException catch (e) {
      return _handleError(e);
    } catch (_) {
      return _unexpected();
    }
  }

  Future<ApiResponse<List<ApproverModel>>> getApprovers({
    String? status,
    String? search,
  }) async {
    try {
      final response = await _dioService.get(
        AppConstants.endpointApprovalApprovers,
        queryParameters: {
          if (status != null && status.isNotEmpty) 'status': status,
          if (search != null && search.isNotEmpty) 'q': search,
        },
      );
      final body = response.data as Map<String, dynamic>;
      final list = extractApiList(body['data'])
          .whereType<Map>()
          .map(
            (item) => ApproverModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
      return ApiResponse(
        success: body['success'] as bool? ?? true,
        statusCode: body['statusCode'] as int? ?? 200,
        data: list,
      );
    } on DioException catch (e) {
      return _handleError(e);
    } catch (_) {
      return _unexpected();
    }
  }

  Future<ApiResponse<ApproverModel>> createApprover(
    Map<String, dynamic> payload,
  ) async {
    return _approverMutation(
      () => _dioService.post(
        AppConstants.endpointApprovalApprovers,
        data: payload,
      ),
    );
  }

  Future<ApiResponse<ApproverModel>> updateApprover(
    String approverId,
    Map<String, dynamic> payload,
  ) async {
    return _approverMutation(
      () => _dioService.put(
        AppConstants.endpointApprovalApprover(approverId),
        data: payload,
      ),
    );
  }

  Future<ApiResponse<ApproverModel>> setApproverStatus({
    required String approverId,
    required String status,
    String? reason,
  }) async {
    return _approverMutation(
      () => _dioService.patch(
        AppConstants.endpointApprovalApproverStatus(approverId),
        data: {
          'status': status,
          if (reason != null && reason.trim().isNotEmpty) 'reason': reason,
        },
      ),
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> resetApproverPassword({
    required String approverId,
    String? password,
  }) async {
    try {
      final response = await _dioService.post(
        AppConstants.endpointApprovalApproverResetPassword(approverId),
        data: {
          if (password != null && password.isNotEmpty) 'password': password,
        },
      );
      final body = response.data as Map<String, dynamic>;
      return ApiResponse(
        success: body['success'] as bool? ?? true,
        statusCode: body['statusCode'] as int? ?? 200,
        data: body['data'] as Map<String, dynamic>? ?? const {},
        message: body['message'] as String?,
      );
    } on DioException catch (e) {
      return _handleError(e);
    } catch (_) {
      return _unexpected();
    }
  }

  Future<ApiResponse<bool>> deleteApprover(String approverId) async {
    try {
      final response = await _dioService.delete(
        AppConstants.endpointApprovalApprover(approverId),
      );
      final body = response.data as Map<String, dynamic>;
      return ApiResponse(
        success: body['success'] as bool? ?? true,
        statusCode: body['statusCode'] as int? ?? 200,
        data: true,
        message: body['message'] as String?,
      );
    } on DioException catch (e) {
      return _handleError(e);
    } catch (_) {
      return _unexpected();
    }
  }

  Future<ApiResponse<List<ApprovalRequestModel>>> getRequests({
    String? status,
    String? category,
    String? approverId,
    String? search,
  }) async {
    try {
      final response = await _dioService.get(
        AppConstants.endpointApprovalRequests,
        queryParameters: {
          if (status != null && status.isNotEmpty) 'status': status,
          if (category != null && category.isNotEmpty) 'category': category,
          if (approverId != null && approverId.isNotEmpty)
            'approverId': approverId,
          if (search != null && search.isNotEmpty) 'q': search,
          'pageSize': 100,
        },
      );
      final body = response.data as Map<String, dynamic>;
      final list = extractApiList(body['data'])
          .whereType<Map>()
          .map(
            (item) =>
                ApprovalRequestModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
      return ApiResponse(
        success: body['success'] as bool? ?? true,
        statusCode: body['statusCode'] as int? ?? 200,
        data: list,
      );
    } on DioException catch (e) {
      return _handleError(e);
    } catch (_) {
      return _unexpected();
    }
  }

  Future<ApiResponse<ApprovalRequestModel>> assignRequest({
    required String requestId,
    String? approverId,
    required String strategy,
    String? remarks,
  }) async {
    return _requestMutation(
      () => _dioService.post(
        AppConstants.endpointApprovalRequestAssign(requestId),
        data: {
          if (approverId != null && approverId.isNotEmpty)
            'approverId': approverId,
          'strategy': strategy,
          if (remarks != null && remarks.trim().isNotEmpty) 'remarks': remarks,
        },
      ),
    );
  }

  Future<ApiResponse<ApprovalRequestModel>> getRequest(String requestId) async {
    try {
      final response = await _dioService.get(
        AppConstants.endpointApprovalRequest(requestId),
      );
      final body = response.data as Map<String, dynamic>;
      return ApiResponse(
        success: body['success'] as bool? ?? true,
        statusCode: body['statusCode'] as int? ?? 200,
        data: ApprovalRequestModel.fromJson(
          body['data'] as Map<String, dynamic>? ?? const {},
        ),
        message: body['message'] as String?,
      );
    } on DioException catch (e) {
      return _handleError(e);
    } catch (_) {
      return _unexpected();
    }
  }

  Future<ApiResponse<List<Map<String, String>>>> getEligibleApprovers(
    String requestId,
  ) async {
    try {
      final response = await _dioService.get(
        AppConstants.endpointApprovalRequestEligibleApprovers(requestId),
      );
      final body = response.data as Map<String, dynamic>;
      final data = extractApiList(body['data'])
          .whereType<Map>()
          .map(
            (item) => {
              'id': item['id']?.toString() ?? '',
              'name': item['name']?.toString() ?? 'Approver',
            },
          )
          .where((item) => item['id']!.isNotEmpty)
          .toList();
      return ApiResponse(
        success: body['success'] as bool? ?? true,
        statusCode: body['statusCode'] as int? ?? 200,
        data: data,
      );
    } on DioException catch (e) {
      return _handleError(e);
    } catch (_) {
      return _unexpected();
    }
  }

  Future<ApiResponse<ApprovalRequestModel>> markRequestViewed(
    String requestId,
  ) async {
    return _requestMutation(
      () => _dioService.post(
        AppConstants.endpointApprovalRequestView(requestId),
        data: const {},
      ),
    );
  }

  Future<ApiResponse<ApprovalRequestModel>> actionRequest({
    required String requestId,
    required String action,
    required String remarks,
    String? reassignToApproverId,
  }) async {
    return _requestMutation(
      () => _dioService.post(
        AppConstants.endpointApprovalRequestAction(requestId),
        data: {
          'action': action,
          'remarks': remarks,
          if (reassignToApproverId != null && reassignToApproverId.isNotEmpty)
            'reassignToApproverId': reassignToApproverId,
        },
      ),
    );
  }

  Future<ApiResponse<List<AuditLogModel>>> getAuditLogs({
    String? search,
  }) async {
    try {
      final response = await _dioService.get(
        AppConstants.endpointApprovalAuditLogs,
        queryParameters: {
          if (search != null && search.isNotEmpty) 'q': search,
          'pageSize': 100,
        },
      );
      final body = response.data as Map<String, dynamic>;
      final list = extractApiList(body['data'])
          .whereType<Map>()
          .map(
            (item) => AuditLogModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
      return ApiResponse(
        success: body['success'] as bool? ?? true,
        statusCode: body['statusCode'] as int? ?? 200,
        data: list,
      );
    } on DioException catch (e) {
      return _handleError(e);
    } catch (_) {
      return _unexpected();
    }
  }

  Future<ApiResponse<ApprovalConfigModel>> getConfig() async {
    try {
      final response = await _dioService.get(
        AppConstants.endpointApprovalConfig,
      );
      final body = response.data as Map<String, dynamic>;
      return ApiResponse(
        success: body['success'] as bool? ?? true,
        statusCode: body['statusCode'] as int? ?? 200,
        data: ApprovalConfigModel.fromJson(
          body['data'] as Map<String, dynamic>? ?? const {},
        ),
      );
    } on DioException catch (e) {
      return _handleError(e);
    } catch (_) {
      return _unexpected();
    }
  }

  Future<ApiResponse<ApprovalConfigModel>> updateConfig(
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _dioService.put(
        AppConstants.endpointApprovalConfig,
        data: payload,
      );
      final body = response.data as Map<String, dynamic>;
      return ApiResponse(
        success: body['success'] as bool? ?? true,
        statusCode: body['statusCode'] as int? ?? 200,
        data: ApprovalConfigModel.fromJson(
          body['data'] as Map<String, dynamic>? ?? const {},
        ),
        message: body['message'] as String?,
      );
    } on DioException catch (e) {
      return _handleError(e);
    } catch (_) {
      return _unexpected();
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getReport({
    String period = 'monthly',
    String? format,
  }) async {
    try {
      final response = await _dioService.get(
        AppConstants.endpointApprovalReports,
        queryParameters: {
          'period': period,
          if (format != null && format.isNotEmpty) 'format': format,
        },
      );
      final body = response.data as Map<String, dynamic>;
      return ApiResponse(
        success: body['success'] as bool? ?? true,
        statusCode: body['statusCode'] as int? ?? 200,
        data: body['data'] as Map<String, dynamic>? ?? const {},
      );
    } on DioException catch (e) {
      return _handleError(e);
    } catch (_) {
      return _unexpected();
    }
  }

  Future<ApiResponse<List<ApprovalNotificationModel>>> getNotifications({
    bool unreadOnly = false,
  }) async {
    try {
      final response = await _dioService.get(
        AppConstants.endpointApprovalNotifications,
        queryParameters: {
          if (unreadOnly) 'unreadOnly': 'true',
        },
      );
      final body = response.data as Map<String, dynamic>;
      final list = extractApiList(body['data'])
          .whereType<Map>()
          .map(
            (item) => ApprovalNotificationModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
      final unreadCount = _asInt((body['meta'] as Map?)?['unreadCount']);
      return ApiResponse(
        success: body['success'] as bool? ?? true,
        statusCode: body['statusCode'] as int? ?? 200,
        data: list,
        message: unreadCount.toString(),
      );
    } on DioException catch (e) {
      return _handleError(e);
    } catch (_) {
      return _unexpected();
    }
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<ApiResponse<ApprovalNotificationModel>> markNotificationRead(
    String id,
  ) async {
    try {
      final response = await _dioService.post(
        AppConstants.endpointApprovalNotificationRead(id),
        data: const {},
      );
      final body = response.data as Map<String, dynamic>;
      return ApiResponse(
        success: body['success'] as bool? ?? true,
        statusCode: body['statusCode'] as int? ?? 200,
        data: ApprovalNotificationModel.fromJson(
          body['data'] as Map<String, dynamic>? ?? const {},
        ),
      );
    } on DioException catch (e) {
      return _handleError(e);
    } catch (_) {
      return _unexpected();
    }
  }

  Future<ApiResponse<bool>> markAllNotificationsRead() async {
    try {
      final response = await _dioService.post(
        AppConstants.endpointApprovalNotificationsReadAll,
        data: const {},
      );
      final body = response.data as Map<String, dynamic>;
      return ApiResponse(
        success: body['success'] as bool? ?? true,
        statusCode: body['statusCode'] as int? ?? 200,
        data: true,
      );
    } on DioException catch (e) {
      return _handleError(e);
    } catch (_) {
      return _unexpected();
    }
  }

  Future<ApiResponse<List<ApprovalSavedFilterModel>>> getSavedFilters({
    String scope = 'requests',
  }) async {
    try {
      final response = await _dioService.get(
        AppConstants.endpointApprovalSavedFilters,
        queryParameters: {'scope': scope},
      );
      final body = response.data as Map<String, dynamic>;
      final list = extractApiList(body['data'])
          .whereType<Map>()
          .map(
            (item) => ApprovalSavedFilterModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
      return ApiResponse(
        success: body['success'] as bool? ?? true,
        statusCode: body['statusCode'] as int? ?? 200,
        data: list,
      );
    } on DioException catch (e) {
      return _handleError(e);
    } catch (_) {
      return _unexpected();
    }
  }

  Future<ApiResponse<ApprovalSavedFilterModel>> createSavedFilter(
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _dioService.post(
        AppConstants.endpointApprovalSavedFilters,
        data: payload,
      );
      final body = response.data as Map<String, dynamic>;
      return ApiResponse(
        success: body['success'] as bool? ?? true,
        statusCode: body['statusCode'] as int? ?? 200,
        data: ApprovalSavedFilterModel.fromJson(
          body['data'] as Map<String, dynamic>? ?? const {},
        ),
        message: body['message'] as String?,
      );
    } on DioException catch (e) {
      return _handleError(e);
    } catch (_) {
      return _unexpected();
    }
  }

  Future<ApiResponse<bool>> deleteSavedFilter(String id) async {
    try {
      final response = await _dioService.delete(
        AppConstants.endpointApprovalSavedFilter(id),
      );
      final body = response.data as Map<String, dynamic>;
      return ApiResponse(
        success: body['success'] as bool? ?? true,
        statusCode: body['statusCode'] as int? ?? 200,
        data: true,
        message: body['message'] as String?,
      );
    } on DioException catch (e) {
      return _handleError(e);
    } catch (_) {
      return _unexpected();
    }
  }

  Future<ApiResponse<ApproverModel>> _approverMutation(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      final response = await request();
      final body = response.data as Map<String, dynamic>;
      return ApiResponse(
        success: body['success'] as bool? ?? true,
        statusCode: body['statusCode'] as int? ?? 200,
        data: ApproverModel.fromJson(
          body['data'] as Map<String, dynamic>? ?? const {},
        ),
        message: body['message'] as String?,
      );
    } on DioException catch (e) {
      return _handleError(e);
    } catch (_) {
      return _unexpected();
    }
  }

  Future<ApiResponse<ApprovalRequestModel>> _requestMutation(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      final response = await request();
      final body = response.data as Map<String, dynamic>;
      return ApiResponse(
        success: body['success'] as bool? ?? true,
        statusCode: body['statusCode'] as int? ?? 200,
        data: ApprovalRequestModel.fromJson(
          body['data'] as Map<String, dynamic>? ?? const {},
        ),
        message: body['message'] as String?,
      );
    } on DioException catch (e) {
      return _handleError(e);
    } catch (_) {
      return _unexpected();
    }
  }

  ApiResponse<T> _unexpected<T>() {
    return ApiResponse<T>(
      success: false,
      error: AppConstants.errorSomethingWentWrong,
      statusCode: 500,
    );
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
