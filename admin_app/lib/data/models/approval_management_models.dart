class ApprovalDashboardModel {
  const ApprovalDashboardModel({
    required this.stats,
    required this.charts,
    required this.recentRequests,
    required this.approverPerformance,
  });

  final ApprovalStatsModel stats;
  final ApprovalChartsModel charts;
  final List<ApprovalRequestModel> recentRequests;
  final List<ApproverModel> approverPerformance;

  factory ApprovalDashboardModel.fromJson(Map<String, dynamic> json) {
    return ApprovalDashboardModel(
      stats: ApprovalStatsModel.fromJson(
        json['stats'] as Map<String, dynamic>? ?? const {},
      ),
      charts: ApprovalChartsModel.fromJson(
        json['charts'] as Map<String, dynamic>? ?? const {},
      ),
      recentRequests: (json['recentRequests'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                ApprovalRequestModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      approverPerformance: (json['approverPerformance'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) => ApproverModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
    );
  }

  static const empty = ApprovalDashboardModel(
    stats: ApprovalStatsModel.empty,
    charts: ApprovalChartsModel.empty,
    recentRequests: [],
    approverPerformance: [],
  );
}

class ApprovalStatsModel {
  const ApprovalStatsModel({
    required this.totalProviders,
    required this.pending,
    required this.approved,
    required this.rejected,
    required this.onHold,
    required this.needDocuments,
    required this.escalated,
    required this.approversOnline,
    required this.averageApprovalTimeMinutes,
    required this.slaBreached,
    required this.approvalsToday,
    required this.rejectionsToday,
    required this.weeklyApprovals,
    required this.monthlyApprovals,
  });

  final int totalProviders;
  final int pending;
  final int approved;
  final int rejected;
  final int onHold;
  final int needDocuments;
  final int escalated;
  final int approversOnline;
  final int averageApprovalTimeMinutes;
  final int slaBreached;
  final int approvalsToday;
  final int rejectionsToday;
  final int weeklyApprovals;
  final int monthlyApprovals;

  factory ApprovalStatsModel.fromJson(Map<String, dynamic> json) {
    return ApprovalStatsModel(
      totalProviders: _int(json['totalProviders']),
      pending: _int(json['pending']),
      approved: _int(json['approved']),
      rejected: _int(json['rejected']),
      onHold: _int(json['onHold']),
      needDocuments: _int(json['needDocuments']),
      escalated: _int(json['escalated']),
      approversOnline: _int(json['approversOnline']),
      averageApprovalTimeMinutes: _int(json['averageApprovalTimeMinutes']),
      slaBreached: _int(json['slaBreached']),
      approvalsToday: _int(json['approvalsToday']),
      rejectionsToday: _int(json['rejectionsToday']),
      weeklyApprovals: _int(json['weeklyApprovals']),
      monthlyApprovals: _int(json['monthlyApprovals']),
    );
  }

  static const empty = ApprovalStatsModel(
    totalProviders: 0,
    pending: 0,
    approved: 0,
    rejected: 0,
    onHold: 0,
    needDocuments: 0,
    escalated: 0,
    approversOnline: 0,
    averageApprovalTimeMinutes: 0,
    slaBreached: 0,
    approvalsToday: 0,
    rejectionsToday: 0,
    weeklyApprovals: 0,
    monthlyApprovals: 0,
  );
}

class ApprovalChartsModel {
  const ApprovalChartsModel({
    required this.approvalTrend,
    required this.providerGrowth,
    required this.providerMix,
    required this.statusMix,
  });

  final List<ChartPointModel> approvalTrend;
  final List<ChartPointModel> providerGrowth;
  final List<ChartPointModel> providerMix;
  final List<ChartPointModel> statusMix;

  factory ApprovalChartsModel.fromJson(Map<String, dynamic> json) {
    return ApprovalChartsModel(
      approvalTrend: _points(json['approvalTrend']),
      providerGrowth: _points(json['providerGrowth']),
      providerMix: _points(json['providerMix']),
      statusMix: _points(json['statusMix']),
    );
  }

  static const empty = ApprovalChartsModel(
    approvalTrend: [],
    providerGrowth: [],
    providerMix: [],
    statusMix: [],
  );
}

class ChartPointModel {
  const ChartPointModel({required this.label, required this.value, this.date});

  final String label;
  final num value;
  final String? date;

  factory ChartPointModel.fromJson(Map<String, dynamic> json) {
    return ChartPointModel(
      label: json['label']?.toString() ?? json['date']?.toString() ?? '',
      value: _num(json['value']),
      date: json['date']?.toString(),
    );
  }
}

class ApproverModel {
  const ApproverModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.name,
    required this.employeeId,
    required this.email,
    required this.status,
    required this.permissions,
    required this.regions,
    this.phone,
    this.department,
    this.designation,
    this.profilePicture,
    this.canReassign = false,
    this.workload = 0,
    this.assigned = 0,
    this.approved = 0,
    this.rejected = 0,
    this.pending = 0,
    this.averageApprovalTimeMinutes = 0,
    this.acceptanceRate = 0,
    this.rejectionRate = 0,
    this.escalations = 0,
    this.lastLoginAt,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String name;
  final String employeeId;
  final String email;
  final String? phone;
  final String? department;
  final String? designation;
  final String? profilePicture;
  final String status;
  final List<String> permissions;
  final List<ApproverRegionModel> regions;
  final bool canReassign;
  final int workload;
  final int assigned;
  final int approved;
  final int rejected;
  final int pending;
  final int averageApprovalTimeMinutes;
  final int acceptanceRate;
  final int rejectionRate;
  final int escalations;
  final DateTime? lastLoginAt;

  factory ApproverModel.fromJson(Map<String, dynamic> json) {
    final firstName = json['firstName']?.toString() ?? '';
    final lastName = json['lastName']?.toString() ?? '';
    final name =
        json['name']?.toString() ??
        [firstName, lastName].where((part) => part.isNotEmpty).join(' ');
    return ApproverModel(
      id: json['id']?.toString() ?? '',
      firstName: firstName,
      lastName: lastName,
      name: name,
      employeeId: json['employeeId']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      department: json['department']?.toString(),
      designation: json['designation']?.toString(),
      profilePicture: json['profilePicture']?.toString(),
      status: json['status']?.toString() ?? 'inactive',
      permissions: (json['permissions'] as List? ?? const [])
          .map((item) => item.toString())
          .toList(),
      regions: (json['regions'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                ApproverRegionModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      canReassign: json['canReassign'] == true,
      workload: _int(json['workload']),
      assigned: _int(json['assigned']),
      approved: _int(json['approved']),
      rejected: _int(json['rejected']),
      pending: _int(json['pending']),
      averageApprovalTimeMinutes: _int(json['averageApprovalTimeMinutes']),
      acceptanceRate: _int(json['acceptanceRate']),
      rejectionRate: _int(json['rejectionRate']),
      escalations: _int(json['escalations']),
      lastLoginAt: _date(json['lastLoginAt']),
    );
  }
}

class ApproverRegionModel {
  const ApproverRegionModel({
    this.country,
    this.state,
    this.district,
    this.city,
    this.pincode,
  });

  final String? country;
  final String? state;
  final String? district;
  final String? city;
  final String? pincode;

  factory ApproverRegionModel.fromJson(Map<String, dynamic> json) {
    return ApproverRegionModel(
      country: json['country']?.toString(),
      state: json['state']?.toString(),
      district: json['district']?.toString(),
      city: json['city']?.toString(),
      pincode: json['pincode']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    if (country?.trim().isNotEmpty == true) 'country': country!.trim(),
    if (state?.trim().isNotEmpty == true) 'state': state!.trim(),
    if (district?.trim().isNotEmpty == true) 'district': district!.trim(),
    if (city?.trim().isNotEmpty == true) 'city': city!.trim(),
    if (pincode?.trim().isNotEmpty == true) 'pincode': pincode!.trim(),
  };
}

class ApprovalRequestModel {
  const ApprovalRequestModel({
    required this.id,
    required this.providerId,
    required this.providerType,
    required this.providerCategory,
    required this.provider,
    required this.priority,
    required this.status,
    required this.remainingSlaMinutes,
    required this.slaState,
    required this.timeline,
    required this.assignmentHistory,
    required this.approvalHistory,
    required this.approvalLevels,
    required this.internalNotes,
    this.providerDetails = const {},
    this.currentAssigneeId,
    this.currentAssigneeName,
    this.currentApprovalLevel = 1,
    this.assignedAt,
    this.slaDueAt,
    this.completedAt,
    this.approvalDurationMinutes,
    this.lastRemarks,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String providerId;
  final String providerType;
  final String providerCategory;
  final ProviderSnapshotModel provider;
  final String priority;
  final String status;
  final String? currentAssigneeId;
  final String? currentAssigneeName;
  final int currentApprovalLevel;
  final DateTime? assignedAt;
  final DateTime? slaDueAt;
  final int remainingSlaMinutes;
  final String slaState;
  final DateTime? completedAt;
  final int? approvalDurationMinutes;
  final String? lastRemarks;
  final List<ApprovalTimelineEventModel> timeline;
  final List<Map<String, dynamic>> assignmentHistory;
  final List<Map<String, dynamic>> approvalHistory;
  final List<Map<String, dynamic>> approvalLevels;
  final List<Map<String, dynamic>> internalNotes;
  final Map<String, dynamic> providerDetails;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ApprovalRequestModel.fromJson(Map<String, dynamic> json) {
    return ApprovalRequestModel(
      id: json['id']?.toString() ?? '',
      providerId: json['providerId']?.toString() ?? '',
      providerType: json['providerType']?.toString() ?? '',
      providerCategory: json['providerCategory']?.toString() ?? '',
      provider: ProviderSnapshotModel.fromJson(
        json['provider'] as Map<String, dynamic>? ?? const {},
      ),
      priority: json['priority']?.toString() ?? 'normal',
      status: json['status']?.toString() ?? 'pending',
      currentAssigneeId: json['currentAssigneeId']?.toString(),
      currentAssigneeName: json['currentAssigneeName']?.toString(),
      currentApprovalLevel: _int(json['currentApprovalLevel']),
      assignedAt: _date(json['assignedAt']),
      slaDueAt: _date(json['slaDueAt']),
      remainingSlaMinutes: _int(json['remainingSlaMinutes']),
      slaState: json['slaState']?.toString() ?? 'within_sla',
      completedAt: _date(json['completedAt']),
      approvalDurationMinutes: json['approvalDurationMinutes'] == null
          ? null
          : _int(json['approvalDurationMinutes']),
      lastRemarks: json['lastRemarks']?.toString(),
      timeline: (json['timeline'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) => ApprovalTimelineEventModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      assignmentHistory: (json['assignmentHistory'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(),
      approvalHistory: (json['approvalHistory'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(),
      approvalLevels: (json['approvalLevels'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(),
      internalNotes: (json['internalNotes'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(),
      providerDetails: json['providerDetails'] is Map
          ? Map<String, dynamic>.from(json['providerDetails'] as Map)
          : const {},
      createdAt: _date(json['createdAt']),
      updatedAt: _date(json['updatedAt']),
    );
  }
}

class ProviderSnapshotModel {
  const ProviderSnapshotModel({
    required this.name,
    this.email,
    this.phone,
    this.country,
    this.state,
    this.district,
    this.city,
    this.pincode,
    this.registrationDate,
    this.rawStatus,
  });

  final String name;
  final String? email;
  final String? phone;
  final String? country;
  final String? state;
  final String? district;
  final String? city;
  final String? pincode;
  final DateTime? registrationDate;
  final String? rawStatus;

  factory ProviderSnapshotModel.fromJson(Map<String, dynamic> json) {
    return ProviderSnapshotModel(
      name: json['name']?.toString() ?? 'Provider',
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      country: json['country']?.toString(),
      state: json['state']?.toString(),
      district: json['district']?.toString(),
      city: json['city']?.toString(),
      pincode: json['pincode']?.toString(),
      registrationDate: _date(json['registrationDate']),
      rawStatus: json['rawStatus']?.toString(),
    );
  }
}

class ApprovalTimelineEventModel {
  const ApprovalTimelineEventModel({
    required this.id,
    required this.action,
    this.actorName,
    this.actorRole,
    this.remarks,
    this.ip,
    this.device,
    this.createdAt,
  });

  final String id;
  final String action;
  final String? actorName;
  final String? actorRole;
  final String? remarks;
  final String? ip;
  final String? device;
  final DateTime? createdAt;

  factory ApprovalTimelineEventModel.fromJson(Map<String, dynamic> json) {
    final actor = json['actor'] as Map<String, dynamic>? ?? const {};
    return ApprovalTimelineEventModel(
      id: json['id']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
      actorName: actor['name']?.toString(),
      actorRole: actor['role']?.toString(),
      remarks: json['remarks']?.toString(),
      ip: json['ip']?.toString(),
      device: json['device']?.toString(),
      createdAt: _date(json['createdAt']),
    );
  }
}

class AuditLogModel {
  const AuditLogModel({
    required this.id,
    required this.action,
    required this.entityType,
    this.actorName,
    this.actorRole,
    this.entityLabel,
    this.ip,
    this.device,
    this.createdAt,
  });

  final String id;
  final String action;
  final String entityType;
  final String? actorName;
  final String? actorRole;
  final String? entityLabel;
  final String? ip;
  final String? device;
  final DateTime? createdAt;

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(
      id: json['id']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
      entityType: json['entityType']?.toString() ?? '',
      actorName: json['actorName']?.toString(),
      actorRole: json['actorRole']?.toString(),
      entityLabel: json['entityLabel']?.toString(),
      ip: json['ip']?.toString(),
      device: json['device']?.toString(),
      createdAt: _date(json['createdAt']),
    );
  }
}

class ApprovalConfigModel {
  const ApprovalConfigModel({
    required this.categories,
    required this.rules,
    required this.assignmentStrategies,
  });

  final List<ProviderCategoryModel> categories;
  final List<ApprovalRuleModel> rules;
  final List<String> assignmentStrategies;

  factory ApprovalConfigModel.fromJson(Map<String, dynamic> json) {
    return ApprovalConfigModel(
      categories: (json['categories'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                ProviderCategoryModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      rules: (json['rules'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                ApprovalRuleModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      assignmentStrategies: (json['assignmentStrategies'] as List? ?? const [])
          .map((item) => item.toString())
          .toList(),
    );
  }

  static const empty = ApprovalConfigModel(
    categories: [],
    rules: [],
    assignmentStrategies: [],
  );
}

class ProviderCategoryModel {
  const ProviderCategoryModel({
    required this.slug,
    required this.name,
    required this.active,
    required this.slaHours,
    this.description,
    this.sortOrder = 0,
  });

  final String slug;
  final String name;
  final String? description;
  final bool active;
  final int slaHours;
  final int sortOrder;

  factory ProviderCategoryModel.fromJson(Map<String, dynamic> json) {
    return ProviderCategoryModel(
      slug: json['slug']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      active: json['active'] != false,
      slaHours: _int(json['slaHours']),
      sortOrder: _int(json['sortOrder']),
    );
  }

  Map<String, dynamic> toJson() => {
    'slug': slug,
    'name': name,
    'description': description,
    'active': active,
    'slaHours': slaHours,
    'sortOrder': sortOrder,
  };
}

class ApprovalRuleModel {
  const ApprovalRuleModel({
    required this.providerCategory,
    required this.assignmentStrategy,
    required this.slaHours,
    required this.active,
    this.escalationHours = 0,
    this.approvalLevels = const [],
  });

  final String providerCategory;
  final String assignmentStrategy;
  final int slaHours;
  final int escalationHours;
  final bool active;
  final List<Map<String, dynamic>> approvalLevels;

  factory ApprovalRuleModel.fromJson(Map<String, dynamic> json) {
    return ApprovalRuleModel(
      providerCategory: json['providerCategory']?.toString() ?? '',
      assignmentStrategy: json['assignmentStrategy']?.toString() ?? '',
      slaHours: _int(json['slaHours']),
      escalationHours: _int(json['escalationHours']),
      active: json['active'] != false,
      approvalLevels: (json['approvalLevels'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'providerCategory': providerCategory,
    'assignmentStrategy': assignmentStrategy,
    'slaHours': slaHours,
    'escalationHours': escalationHours,
    'active': active,
    'approvalLevels': approvalLevels,
  };
}

List<ChartPointModel> _points(dynamic raw) {
  return (raw as List? ?? const [])
      .whereType<Map>()
      .map((item) => ChartPointModel.fromJson(Map<String, dynamic>.from(item)))
      .toList();
}

DateTime? _date(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString())?.toLocal();
}

int _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

num _num(dynamic value) {
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '') ?? 0;
}

class ApprovalNotificationModel {
  const ApprovalNotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.data = const {},
    this.readAt,
    this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic> data;
  final DateTime? readAt;
  final DateTime? createdAt;

  bool get isUnread => readAt == null;

  factory ApprovalNotificationModel.fromJson(Map<String, dynamic> json) {
    return ApprovalNotificationModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      data: json['data'] is Map
          ? Map<String, dynamic>.from(json['data'] as Map)
          : const {},
      readAt: _date(json['readAt']),
      createdAt: _date(json['createdAt']),
    );
  }
}

class ApprovalSavedFilterModel {
  const ApprovalSavedFilterModel({
    required this.id,
    required this.name,
    required this.scope,
    this.filters = const {},
    this.isDefault = false,
  });

  final String id;
  final String name;
  final String scope;
  final Map<String, dynamic> filters;
  final bool isDefault;

  factory ApprovalSavedFilterModel.fromJson(Map<String, dynamic> json) {
    return ApprovalSavedFilterModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      scope: json['scope']?.toString() ?? 'requests',
      filters: json['filters'] is Map
          ? Map<String, dynamic>.from(json['filters'] as Map)
          : const {},
      isDefault: json['isDefault'] == true,
    );
  }
}
