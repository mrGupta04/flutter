import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/approval_management_models.dart';
import '../../../data/repositories/approval_management_repository.dart';
import 'admin_auth_provider.dart';

final approvalManagementRepositoryProvider = Provider((ref) {
  return ApprovalManagementRepository();
});

final approvalManagementProvider =
    StateNotifierProvider<ApprovalManagementNotifier, ApprovalManagementState>((
      ref,
    ) {
      final isApprover = ref.watch(
        adminAuthProvider.select((state) => state.isApprover),
      );
      return ApprovalManagementNotifier(
        ref.watch(approvalManagementRepositoryProvider),
        isApprover: isApprover,
      );
    });

class ApprovalManagementState {
  const ApprovalManagementState({
    this.dashboard = ApprovalDashboardModel.empty,
    this.approvers = const [],
    this.requests = const [],
    this.auditLogs = const [],
    this.config = ApprovalConfigModel.empty,
    this.report = const {},
    this.notifications = const [],
    this.savedFilters = const [],
    this.unreadNotifications = 0,
    this.isLoading = false,
    this.isMutating = false,
    this.error,
    this.requestStatusFilter,
    this.categoryFilter,
    this.approverFilter,
    this.searchQuery = '',
  });

  final ApprovalDashboardModel dashboard;
  final List<ApproverModel> approvers;
  final List<ApprovalRequestModel> requests;
  final List<AuditLogModel> auditLogs;
  final ApprovalConfigModel config;
  final Map<String, dynamic> report;
  final List<ApprovalNotificationModel> notifications;
  final List<ApprovalSavedFilterModel> savedFilters;
  final int unreadNotifications;
  final bool isLoading;
  final bool isMutating;
  final String? error;
  final String? requestStatusFilter;
  final String? categoryFilter;
  final String? approverFilter;
  final String searchQuery;

  ApprovalManagementState copyWith({
    ApprovalDashboardModel? dashboard,
    List<ApproverModel>? approvers,
    List<ApprovalRequestModel>? requests,
    List<AuditLogModel>? auditLogs,
    ApprovalConfigModel? config,
    Map<String, dynamic>? report,
    List<ApprovalNotificationModel>? notifications,
    List<ApprovalSavedFilterModel>? savedFilters,
    int? unreadNotifications,
    bool? isLoading,
    bool? isMutating,
    String? error,
    String? requestStatusFilter,
    String? categoryFilter,
    String? approverFilter,
    String? searchQuery,
    bool clearError = false,
    bool clearStatusFilter = false,
    bool clearCategoryFilter = false,
    bool clearApproverFilter = false,
  }) {
    return ApprovalManagementState(
      dashboard: dashboard ?? this.dashboard,
      approvers: approvers ?? this.approvers,
      requests: requests ?? this.requests,
      auditLogs: auditLogs ?? this.auditLogs,
      config: config ?? this.config,
      report: report ?? this.report,
      notifications: notifications ?? this.notifications,
      savedFilters: savedFilters ?? this.savedFilters,
      unreadNotifications: unreadNotifications ?? this.unreadNotifications,
      isLoading: isLoading ?? this.isLoading,
      isMutating: isMutating ?? this.isMutating,
      error: clearError ? null : error ?? this.error,
      requestStatusFilter: clearStatusFilter
          ? null
          : requestStatusFilter ?? this.requestStatusFilter,
      categoryFilter: clearCategoryFilter
          ? null
          : categoryFilter ?? this.categoryFilter,
      approverFilter: clearApproverFilter
          ? null
          : approverFilter ?? this.approverFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class ApprovalManagementNotifier
    extends StateNotifier<ApprovalManagementState> {
  ApprovalManagementNotifier(this._repository, {required bool isApprover})
    : _isApprover = isApprover,
      super(const ApprovalManagementState());

  final ApprovalManagementRepository _repository;
  final bool _isApprover;

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final dashboard = await _repository.getDashboard();
    final approvers = await _repository.getApprovers();
    final requests = await _repository.getRequests(
      status: state.requestStatusFilter,
      category: state.categoryFilter,
      approverId: state.approverFilter,
      search: state.searchQuery,
    );
    final auditLogs = await _repository.getAuditLogs();
    final config = await _repository.getConfig();
    final report = await _repository.getReport();
    final notifications = await _repository.getNotifications();
    final savedFilters = await _repository.getSavedFilters();

    final firstError = [
      dashboard.error,
      approvers.error,
      requests.error,
      auditLogs.error,
      config.error,
      report.error,
      notifications.error,
      savedFilters.error,
    ].whereType<String>().firstOrNull;

    state = state.copyWith(
      dashboard: dashboard.data ?? state.dashboard,
      approvers: approvers.data ?? state.approvers,
      requests: requests.data ?? state.requests,
      auditLogs: auditLogs.data ?? state.auditLogs,
      config: config.data ?? state.config,
      report: report.data ?? state.report,
      notifications: notifications.data ?? state.notifications,
      savedFilters: savedFilters.data ?? state.savedFilters,
      unreadNotifications: int.tryParse(notifications.message ?? '') ??
          notifications.data?.where((item) => item.isUnread).length ??
          state.unreadNotifications,
      isLoading: false,
      error: firstError,
    );
  }

  Future<void> loadForApprover() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final dashboard = await _repository.getDashboard();
    final requests = await _repository.getRequests(
      status: state.requestStatusFilter,
      category: state.categoryFilter,
      search: state.searchQuery,
    );
    final notifications = await _repository.getNotifications();
    final savedFilters = await _repository.getSavedFilters();
    state = state.copyWith(
      dashboard: dashboard.data ?? state.dashboard,
      requests: requests.data ?? state.requests,
      notifications: notifications.data ?? state.notifications,
      savedFilters: savedFilters.data ?? state.savedFilters,
      unreadNotifications: int.tryParse(notifications.message ?? '') ??
          notifications.data?.where((item) => item.isUnread).length ??
          state.unreadNotifications,
      isLoading: false,
      error:
          dashboard.error ??
          requests.error ??
          notifications.error ??
          savedFilters.error,
    );
  }

  Future<void> refreshDashboard() async {
    final response = await _repository.getDashboard();
    if (response.success && response.data != null) {
      state = state.copyWith(dashboard: response.data, clearError: true);
    } else {
      state = state.copyWith(error: response.error);
    }
  }

  Future<void> refreshRequests() async {
    final response = await _repository.getRequests(
      status: state.requestStatusFilter,
      category: state.categoryFilter,
      approverId: state.approverFilter,
      search: state.searchQuery,
    );
    if (response.success && response.data != null) {
      state = state.copyWith(requests: response.data, clearError: true);
    } else {
      state = state.copyWith(error: response.error);
    }
  }

  Future<void> refreshApprovers() async {
    final response = await _repository.getApprovers();
    if (response.success && response.data != null) {
      state = state.copyWith(approvers: response.data, clearError: true);
    } else {
      state = state.copyWith(error: response.error);
    }
  }

  Future<void> setRequestFilters({
    String? status,
    String? category,
    String? approverId,
    String? search,
    bool clearStatus = false,
    bool clearCategory = false,
    bool clearApprover = false,
  }) async {
    state = state.copyWith(
      requestStatusFilter: status,
      categoryFilter: category,
      approverFilter: approverId,
      searchQuery: search,
      clearStatusFilter: clearStatus,
      clearCategoryFilter: clearCategory,
      clearApproverFilter: clearApprover,
    );
    await refreshRequests();
  }

  Future<bool> createApprover(Map<String, dynamic> payload) async {
    state = state.copyWith(isMutating: true, clearError: true);
    final response = await _repository.createApprover(payload);
    await _afterMutation(response.error);
    return response.success;
  }

  Future<bool> updateApprover(String id, Map<String, dynamic> payload) async {
    state = state.copyWith(isMutating: true, clearError: true);
    final response = await _repository.updateApprover(id, payload);
    await _afterMutation(response.error);
    return response.success;
  }

  Future<bool> setApproverStatus(ApproverModel approver, String status) async {
    state = state.copyWith(isMutating: true, clearError: true);
    final response = await _repository.setApproverStatus(
      approverId: approver.id,
      status: status,
    );
    await _afterMutation(response.error);
    return response.success;
  }

  Future<String?> resetApproverPassword(ApproverModel approver) async {
    state = state.copyWith(isMutating: true, clearError: true);
    final response = await _repository.resetApproverPassword(
      approverId: approver.id,
    );
    await _afterMutation(response.error);
    if (!response.success) return null;
    return response.data?['temporaryPassword']?.toString();
  }

  Future<bool> deleteApprover(ApproverModel approver) async {
    state = state.copyWith(isMutating: true, clearError: true);
    final response = await _repository.deleteApprover(approver.id);
    await _afterMutation(response.error);
    return response.success;
  }

  Future<bool> updateRule({
    required ProviderCategoryModel category,
    required ApprovalRuleModel rule,
    required int slaHours,
    required int escalationHours,
    required String assignmentStrategy,
    required bool active,
    List<Map<String, dynamic>>? approvalLevels,
  }) async {
    state = state.copyWith(isMutating: true, clearError: true);
    final response = await _repository.updateConfig({
      'categories': [
        {...category.toJson(), 'slaHours': slaHours, 'active': active},
      ],
      'rules': [
        {
          ...rule.toJson(),
          'slaHours': slaHours,
          'escalationHours': escalationHours,
          'assignmentStrategy': assignmentStrategy,
          'active': active,
          if (approvalLevels != null) 'approvalLevels': approvalLevels,
        },
      ],
    });
    if (!response.success || response.data == null) {
      state = state.copyWith(isMutating: false, error: response.error);
      return false;
    }
    state = state.copyWith(
      config: response.data,
      isMutating: false,
      clearError: true,
    );
    await refreshDashboard();
    return true;
  }

  Future<String?> exportReport({
    String period = 'monthly',
    required String format,
  }) async {
    final response = await _repository.getReport(
      period: period,
      format: format,
    );
    if (!response.success || response.data == null) {
      state = state.copyWith(error: response.error);
      return null;
    }
    state = state.copyWith(report: response.data, clearError: true);
    final export = response.data!['export'];
    if (export is Map) {
      return (export['csv'] ?? export['text'])?.toString();
    }
    return null;
  }

  Future<void> refreshNotifications() async {
    final response = await _repository.getNotifications();
    if (!response.success) {
      state = state.copyWith(error: response.error);
      return;
    }
    state = state.copyWith(
      notifications: response.data ?? const [],
      unreadNotifications: int.tryParse(response.message ?? '') ??
          response.data?.where((item) => item.isUnread).length ??
          0,
      clearError: true,
    );
  }

  Future<void> markNotificationRead(String id) async {
    await _repository.markNotificationRead(id);
    await refreshNotifications();
  }

  Future<void> markAllNotificationsRead() async {
    await _repository.markAllNotificationsRead();
    await refreshNotifications();
  }

  Future<bool> saveCurrentRequestFilter(String name) async {
    final response = await _repository.createSavedFilter({
      'name': name,
      'scope': 'requests',
      'filters': {
        if (state.requestStatusFilter != null)
          'status': state.requestStatusFilter,
        if (state.categoryFilter != null) 'category': state.categoryFilter,
        if (state.approverFilter != null) 'approverId': state.approverFilter,
        if (state.searchQuery.isNotEmpty) 'search': state.searchQuery,
      },
    });
    if (!response.success) {
      state = state.copyWith(error: response.error);
      return false;
    }
    final filters = await _repository.getSavedFilters();
    state = state.copyWith(
      savedFilters: filters.data ?? state.savedFilters,
      clearError: true,
    );
    return true;
  }

  Future<void> applySavedFilter(ApprovalSavedFilterModel filter) async {
    await setRequestFilters(
      status: filter.filters['status']?.toString(),
      category: filter.filters['category']?.toString(),
      approverId: filter.filters['approverId']?.toString(),
      search: filter.filters['search']?.toString() ?? '',
      clearStatus: filter.filters['status'] == null,
      clearCategory: filter.filters['category'] == null,
      clearApprover: filter.filters['approverId'] == null,
    );
  }

  Future<bool> deleteSavedFilter(String id) async {
    final response = await _repository.deleteSavedFilter(id);
    if (!response.success) {
      state = state.copyWith(error: response.error);
      return false;
    }
    final filters = await _repository.getSavedFilters();
    state = state.copyWith(
      savedFilters: filters.data ?? state.savedFilters,
      clearError: true,
    );
    return true;
  }

  Future<bool> assignRequest({
    required ApprovalRequestModel request,
    String? approverId,
    required String strategy,
    String? remarks,
  }) async {
    state = state.copyWith(isMutating: true, clearError: true);
    final response = await _repository.assignRequest(
      requestId: request.id,
      approverId: approverId,
      strategy: strategy,
      remarks: remarks,
    );
    await _afterMutation(response.error);
    return response.success;
  }

  Future<List<Map<String, String>>> getEligibleApprovers(
    ApprovalRequestModel request,
  ) async {
    final response = await _repository.getEligibleApprovers(request.id);
    if (!response.success) {
      state = state.copyWith(error: response.error);
      return const [];
    }
    return response.data ?? const [];
  }

  Future<ApprovalRequestModel> markRequestViewed(
    ApprovalRequestModel request,
  ) async {
    final response = await _repository.markRequestViewed(request.id);
    final updated = response.data;
    if (!response.success || updated == null) {
      state = state.copyWith(error: response.error);
      return request;
    }
    final detailResponse = await _repository.getRequest(request.id);
    final detailed = detailResponse.data ?? updated;
    state = state.copyWith(
      requests: [
        for (final item in state.requests)
          if (item.id == detailed.id) detailed else item,
      ],
      clearError: true,
    );
    return detailed;
  }

  Future<bool> actionRequest({
    required ApprovalRequestModel request,
    required String action,
    required String remarks,
    String? reassignToApproverId,
  }) async {
    state = state.copyWith(isMutating: true, clearError: true);
    final response = await _repository.actionRequest(
      requestId: request.id,
      action: action,
      remarks: remarks,
      reassignToApproverId: reassignToApproverId,
    );
    await _afterMutation(response.error);
    return response.success;
  }

  Future<void> _afterMutation(String? error) async {
    if (error != null) {
      state = state.copyWith(isMutating: false, error: error);
      return;
    }
    state = state.copyWith(isMutating: false, clearError: true);
    if (_isApprover) {
      await loadForApprover();
    } else {
      await loadAll();
    }
  }
}
