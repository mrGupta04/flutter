import 'dart:math' as math;
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/india_geography.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/safe_navigation.dart';
import '../../../../core/utils/validation_utils.dart';
import '../../../../core/widgets/app_back_navigation.dart';
import '../../../../core/widgets/accidental_selection_binder.dart';
import '../../../../data/models/approval_management_models.dart';
import '../../../../shared/widgets/address_autocomplete_field.dart';
import '../../../../shared/widgets/admin_adaptive_shell.dart';
import '../../provider/admin_auth_provider.dart';
import '../../provider/approval_management_provider.dart';

enum _ConsoleSection {
  overview,
  requests,
  notifications,
  approvers,
  performance,
  audit,
  config,
  reports,
}

class ApprovalManagementScreen extends ConsumerStatefulWidget {
  const ApprovalManagementScreen({super.key});

  @override
  ConsumerState<ApprovalManagementScreen> createState() =>
      _ApprovalManagementScreenState();
}

class _ApprovalManagementScreenState
    extends ConsumerState<ApprovalManagementScreen> {
  final _searchController = TextEditingController();
  _ConsoleSection _section = _ConsoleSection.overview;
  bool _dark = false;
  _OverviewMetric? _metricFocus;
  String? _metricCategory;
  late final AppBackHandler _backHandler = _onSystemBack;

  @override
  void initState() {
    super.initState();
    AppBackButtonScope.addHandler(_backHandler);
    Future.microtask(_reload);
  }

  /// Overview is the screen root. Back closes drill-down / other tabs first
  /// instead of exiting the app (this route is often opened with go()).
  bool _onSystemBack() {
    final path = GoRouter.maybeOf(context)?.state.uri.path ?? '';
    if (path != AppConstants.routeApprovalManagement) return false;
    if (_metricCategory != null) {
      setState(() => _metricCategory = null);
      return true;
    }
    if (_metricFocus != null) {
      _closeMetricDrilldown();
      return true;
    }
    if (_section != _ConsoleSection.overview) {
      _selectSection(_ConsoleSection.overview);
      return true;
    }
    return false;
  }

  Future<void> _reload() {
    final notifier = ref.read(approvalManagementProvider.notifier);
    return ref.read(adminAuthProvider).isApprover
        ? notifier.loadForApprover()
        : notifier.loadAll();
  }

  void _selectSection(_ConsoleSection section) {
    setState(() {
      _section = section;
      // Leaving or re-tapping Overview exits metric drill-down.
      _metricFocus = null;
      _metricCategory = null;
    });
  }

  Future<void> _openMetric(_OverviewMetric metric) async {
    if (metric == _OverviewMetric.approversOnline) {
      _selectSection(_ConsoleSection.approvers);
      return;
    }

    setState(() {
      _section = _ConsoleSection.overview;
      _metricFocus = metric;
      _metricCategory = null;
    });

    final notifier = ref.read(approvalManagementProvider.notifier);
    await notifier.setRequestFilters(
      status: metric.apiStatus,
      clearStatus: metric.apiStatus == null,
      clearCategory: true,
      clearApprover: true,
      search: '',
    );
  }

  void _closeMetricDrilldown() {
    setState(() {
      _metricFocus = null;
      _metricCategory = null;
    });
  }

  /// Shared by admin and approver: open full provider KYC (per-document
  /// verify/reject) before final approve. Used from Requests, Overview, and
  /// Notifications.
  Future<void> _openProviderProfile(ApprovalRequestModel request) async {
    if (SafeNavigation.isLocked) return;
    final path = _kycDetailPath(request.providerType, request.providerId);
    if (path != null) {
      await ref
          .read(approvalManagementProvider.notifier)
          .markRequestViewed(request);
      if (!mounted) return;
      await SafeNavigation.push(context, path);
      return;
    }
    await _showRequestDetails(request);
  }

  @override
  void dispose() {
    AppBackButtonScope.removeHandler(_backHandler);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(approvalManagementProvider);
    final palette = _Palette(_dark);
    final isApprover = ref.watch(
      adminAuthProvider.select((value) => value.isApprover),
    );
    final navItems = isApprover ? _approverNavItems : _navItems;

    ref.listen(approvalManagementProvider.select((value) => value.error), (
      previous,
      next,
    ) {
      if (next != null && next != previous && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next)));
      }
    });

    return AdminAdaptiveShell(
      section: AdminNavSection.approvals,
      constrainBody: false,
      backgroundColor: palette.background,
      appBar: AppBar(
        title: const Text('Approval Management'),
        automaticallyImplyLeading: false,
        leading: AppBackButtonScope.canNavigateBack(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => AppBackButtonScope.navigateBack(context),
              )
            : null,
        actions: [
          Tooltip(
            message: _dark ? 'Light mode' : 'Dark mode',
            child: IconButton(
              icon: Icon(
                _dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              ),
              onPressed: () => setState(() => _dark = !_dark),
            ),
          ),
          Tooltip(
            message: 'Notifications',
            child: IconButton(
              icon: Badge(
                isLabelVisible: state.unreadNotifications > 0,
                label: Text('${state.unreadNotifications}'),
                child: const Icon(Icons.notifications_none_rounded),
              ),
              onPressed: () => _selectSection(_ConsoleSection.notifications),
            ),
          ),
          Tooltip(
            message: 'Refresh',
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _reload,
            ),
          ),
          Tooltip(
            message: 'Sign out',
            child: IconButton(
              icon: const Icon(Icons.logout_rounded),
              onPressed: () async {
                await ref.read(adminAuthProvider.notifier).logout();
                if (!context.mounted) return;
                context.go(AppConstants.routeAdminLogin);
              },
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 1040;
          final content = _buildContent(state, palette, wide);
          if (wide) {
            return Row(
              children: [
                _SideNav(
                  palette: palette,
                  selected: _section,
                  items: navItems,
                  onSelected: _selectSection,
                ),
                Expanded(child: content),
              ],
            );
          }
          return Column(
            children: [
              _MobileNav(
                palette: palette,
                selected: _section,
                items: navItems,
                onSelected: _selectSection,
              ),
              Expanded(child: content),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(
    ApprovalManagementState state,
    _Palette palette,
    bool wide,
  ) {
    if (state.isLoading && state.requests.isEmpty && state.approvers.isEmpty) {
      return _SkeletonConsole(palette: palette);
    }

    final child = switch (_section) {
      _ConsoleSection.overview =>
        _metricFocus == null
            ? _OverviewPane(
                state: state,
                palette: palette,
                isApprover: ref.read(adminAuthProvider).isApprover,
                userName: ref.watch(
                  adminAuthProvider.select((value) => value.name),
                ),
                onOpenRequests: () => _selectSection(_ConsoleSection.requests),
                onOpenMetric: _openMetric,
              )
            : _MetricDrilldownPane(
                state: state,
                palette: palette,
                metric: _metricFocus!,
                selectedCategory: _metricCategory,
                onBack: () {
                  if (_metricCategory != null) {
                    setState(() => _metricCategory = null);
                  } else {
                    _closeMetricDrilldown();
                  }
                },
                onSelectCategory: (category) =>
                    setState(() => _metricCategory = category),
                onOpenProvider: _openProviderProfile,
              ),
      _ConsoleSection.requests => _RequestsPane(
        state: state,
        palette: palette,
        searchController: _searchController,
        onShowDetails: _openProviderProfile,
        onAction: _showActionDialog,
        onAssign: _showAssignDialog,
        canAssign:
            !ref.read(adminAuthProvider).isApprover ||
            ref.read(adminAuthProvider).canReassign,
        onSaveFilter: _saveRequestFilter,
      ),
      _ConsoleSection.notifications => _NotificationsPane(
        state: state,
        palette: palette,
        onMarkAll: () => ref
            .read(approvalManagementProvider.notifier)
            .markAllNotificationsRead(),
        onOpen: (notification) async {
          await ref
              .read(approvalManagementProvider.notifier)
              .markNotificationRead(notification.id);
          final requestId = notification.data['requestId']?.toString();
          if (requestId == null || requestId.isEmpty) return;
          final request = state.requests
              .where((item) => item.id == requestId)
              .firstOrNull;
          if (request != null) {
            _selectSection(_ConsoleSection.requests);
            await _openProviderProfile(request);
          }
        },
      ),
      _ConsoleSection.approvers => _ApproversPane(
        state: state,
        palette: palette,
        onCreate: () => _showApproverDialog(),
        onOpenProfile: _showApproverPerformance,
        onEdit: _showApproverDialog,
        onStatus: _confirmApproverStatus,
        onResetPassword: _resetApproverPassword,
        onDelete: _confirmDeleteApprover,
      ),
      _ConsoleSection.performance => _PerformancePane(
        state: state,
        palette: palette,
        onOpenApprover: _showApproverPerformance,
      ),
      _ConsoleSection.audit => _AuditPane(state: state, palette: palette),
      _ConsoleSection.config => _ConfigPane(
        state: state,
        palette: palette,
        onEdit: _showRuleDialog,
      ),
      _ConsoleSection.reports => _ReportsPane(
        state: state,
        palette: palette,
        onExport: _exportReport,
      ),
    };

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              wide ? 28 : 16,
              20,
              wide ? 28 : 16,
              32,
            ),
            children: [child],
          ),
        ),
        if (state.isMutating)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                color: palette.background.withValues(alpha: 0.36),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _showActionDialog(
    ApprovalRequestModel request,
    String action,
  ) async {
    // Final approve must go through full profile + per-document verification.
    if (action == 'approve') {
      final path = _kycDetailPath(request.providerType, request.providerId);
      if (path != null) {
        _toast(
          'Open KYC review: verify each document first, then final approve.',
        );
        await _openProviderProfile(request);
        return;
      }
    }

    final remarksController = TextEditingController();
    final remarksFormKey = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(_actionTitle(action)),
          content: SizedBox(
            width: 460,
            child: Form(
              key: remarksFormKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: CaretOnTapTextFormField(
                controller: remarksController,
                validator: (value) => ValidationUtils.validateRemarks(value),
                decoration: const InputDecoration(
                  labelText: 'Mandatory remarks *',
                  hintText: 'Add verification notes for audit history',
                ),
                minLines: 4,
                maxLines: 6,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (!(remarksFormKey.currentState?.validate() ?? false)) {
                  return;
                }
                Navigator.pop(context, true);
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
    if (ok != true) {
      remarksController.dispose();
      return;
    }
    final success = await ref
        .read(approvalManagementProvider.notifier)
        .actionRequest(
          request: request,
          action: action,
          remarks: remarksController.text.trim(),
        );
    remarksController.dispose();
    if (!mounted) return;
    if (success) {
      _toast('Approval action recorded');
    } else {
      final err = ref.read(approvalManagementProvider).error;
      _toast(
        err?.trim().isNotEmpty == true
            ? err!
            : 'Action failed. Open KYC review, verify documents, then try again.',
      );
    }
  }

  Future<void> _showAssignDialog(ApprovalRequestModel request) async {
    final eligibleApprovers = await ref
        .read(approvalManagementProvider.notifier)
        .getEligibleApprovers(request);
    if (!mounted) return;
    final remarksController = TextEditingController();
    final assignFormKey = GlobalKey<FormState>();
    String strategy = 'manual';
    String? approverId = request.currentAssigneeId;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Assign request'),
              content: SizedBox(
                width: 520,
                child: Form(
                  key: assignFormKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: strategy,
                      isExpanded: true,
                      itemHeight: kMinInteractiveDimension,
                      menuMaxHeight: 280,
                      borderRadius: BorderRadius.circular(12),
                      decoration: const InputDecoration(labelText: 'Strategy'),
                      items: const [
                        DropdownMenuItem(
                          value: 'manual',
                          child: Text('Manual'),
                        ),
                        DropdownMenuItem(
                          value: 'least_busy',
                          child: Text('Least busy'),
                        ),
                        DropdownMenuItem(
                          value: 'round_robin',
                          child: Text('Round robin'),
                        ),
                        DropdownMenuItem(
                          value: 'region_based',
                          child: Text('Region based'),
                        ),
                        DropdownMenuItem(
                          value: 'category_based',
                          child: Text('Category based'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => strategy = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    if (strategy == 'manual')
                      DropdownButtonFormField<String>(
                        initialValue: approverId?.isEmpty == true
                            ? null
                            : approverId,
                        isExpanded: true,
                        itemHeight: kMinInteractiveDimension,
                        menuMaxHeight: 280,
                        borderRadius: BorderRadius.circular(12),
                        decoration: const InputDecoration(
                          labelText: 'Approver',
                        ),
                        items: eligibleApprovers
                            .map(
                              (approver) => DropdownMenuItem(
                                value: approver['id']!,
                                child: Text(approver['name'] ?? 'Approver'),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setDialogState(() => approverId = value),
                      ),
                    const SizedBox(height: 12),
                    CaretOnTapTextFormField(
                      controller: remarksController,
                      validator: (value) {
                        if (request.currentAssigneeId != null) {
                          return ValidationUtils.validateRemarks(value);
                        }
                        if (value == null || value.trim().isEmpty) return null;
                        return ValidationUtils.validateRemarks(value);
                      },
                      decoration: InputDecoration(
                        labelText: request.currentAssigneeId != null
                            ? 'Remarks *'
                            : 'Remarks',
                      ),
                      minLines: 3,
                      maxLines: 4,
                    ),
                  ],
                ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (!(assignFormKey.currentState?.validate() ?? false)) {
                      return;
                    }
                    if (strategy == 'manual' &&
                        (approverId == null || approverId!.isEmpty)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Choose an approver')),
                      );
                      return;
                    }
                    Navigator.pop(context, true);
                  },
                  child: const Text('Assign'),
                ),
              ],
            );
          },
        );
      },
    );
    if (ok != true) {
      remarksController.dispose();
      return;
    }
    final success = await ref
        .read(approvalManagementProvider.notifier)
        .assignRequest(
          request: request,
          approverId: strategy == 'manual' ? approverId : null,
          strategy: strategy,
          remarks: remarksController.text.trim(),
        );
    remarksController.dispose();
    if (mounted && success) _toast('Request assigned');
  }

  Future<void> _showApproverDialog([ApproverModel? approver]) async {
    final firstName = TextEditingController(text: approver?.firstName ?? '');
    final lastName = TextEditingController(text: approver?.lastName ?? '');
    final employeeId = TextEditingController(text: approver?.employeeId ?? '');
    final email = TextEditingController(text: approver?.email ?? '');
    final phone = TextEditingController(text: approver?.phone ?? '');
    final password = TextEditingController();
    final department = TextEditingController(text: approver?.department ?? '');
    final designation = TextEditingController(
      text: approver?.designation ?? '',
    );
    final profilePicture = TextEditingController(
      text: approver?.profilePicture ?? '',
    );
    final country = TextEditingController(
      text: approver?.regions.firstOrNull?.country ?? '',
    );
    final stateController = TextEditingController(
      text: approver?.regions.firstOrNull?.state ?? '',
    );
    final district = TextEditingController(
      text: approver?.regions.firstOrNull?.district ?? '',
    );
    final city = TextEditingController(
      text: approver?.regions.firstOrNull?.city ?? '',
    );
    final pincode = TextEditingController(
      text: approver?.regions.firstOrNull?.pincode ?? '',
    );
    var status = approver?.status ?? 'active';
    var canReassign = approver?.canReassign ?? false;
    final formKey = GlobalKey<FormState>();
    var permissionsError = '';
    final permissions = <String>{...?approver?.permissions};
    var categories = ref.read(approvalManagementProvider).config.categories;
    if (categories.isEmpty) {
      // Ensure permission chips always cover every provider type.
      await ref.read(approvalManagementProvider.notifier).refreshConfig();
      categories = ref.read(approvalManagementProvider).config.categories;
    }
    if (categories.isEmpty) {
      categories = _fallbackApprovalCategories;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                approver == null ? 'Create approver' : 'Edit approver',
              ),
              content: SizedBox(
                width: 760,
                child: Form(
                  key: formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _dialogField(
                            firstName,
                            'First name',
                            required: true,
                            textCapitalization: TextCapitalization.words,
                            validator: (value) => ValidationUtils.validateName(
                              value,
                              fieldName: 'First name',
                            ),
                          ),
                          _dialogField(
                            lastName,
                            'Last name',
                            required: true,
                            textCapitalization: TextCapitalization.words,
                            validator: (value) => ValidationUtils.validateName(
                              value,
                              fieldName: 'Last name',
                            ),
                          ),
                          _dialogField(
                            employeeId,
                            'Employee ID',
                            required: true,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[A-Za-z0-9\-_]'),
                              ),
                              LengthLimitingTextInputFormatter(20),
                            ],
                            validator: ValidationUtils.validateEmployeeId,
                          ),
                          _dialogField(
                            email,
                            'Email',
                            required: true,
                            keyboardType: TextInputType.emailAddress,
                            validator: ValidationUtils.validateEmail,
                          ),
                          _dialogField(
                            phone,
                            'Phone',
                            keyboardType: TextInputType.phone,
                            inputFormatters:
                                ValidationUtils.mobileInputFormatters(),
                            validator: ValidationUtils.validateOptionalPhone,
                          ),
                          if (approver == null)
                            _dialogField(
                              password,
                              'Password',
                              obscure: true,
                              required: true,
                              validator: ValidationUtils.validatePassword,
                            )
                          else
                            _dialogField(
                              password,
                              'New password',
                              obscure: true,
                              validator: ValidationUtils.validateOptionalPassword,
                            ),
                          _dialogField(
                            department,
                            'Department',
                            validator: (value) =>
                                ValidationUtils.validateOptionalOrganizationName(
                              value,
                              fieldName: 'Department',
                            ),
                          ),
                          _dialogField(
                            designation,
                            'Designation',
                            validator: (value) =>
                                ValidationUtils.validateOptionalOrganizationName(
                              value,
                              fieldName: 'Designation',
                            ),
                          ),
                          _dialogField(
                            profilePicture,
                            'Profile picture URL',
                            keyboardType: TextInputType.url,
                            validator: (value) => ValidationUtils.validateOptionalUrl(
                              value,
                              fieldName: 'Profile picture URL',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Can approve (select all that apply)',
                        style: AppTextStyles.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select every category this approver can verify: Doctor, Nurse, Lab, Scan/MRI, Ambulance, Blood Bank, etc. Matching applications appear in their Requests queue.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: categories.map((category) {
                          return FilterChip(
                            selected: permissions.contains(category.slug),
                            label: Text(category.name),
                            onSelected: (selected) {
                              setDialogState(() {
                                if (selected) {
                                  permissions.add(category.slug);
                                } else {
                                  permissions.remove(category.slug);
                                }
                                if (permissions.isNotEmpty) {
                                  permissionsError = '';
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      if (permissionsError.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          permissionsError,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      Text(
                        'Location access (optional — leave blank for all regions)',
                        style: AppTextStyles.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          AddressAutocompleteField(
                            controller: country,
                            label: 'Country',
                            hint: 'Type to search, e.g. India',
                            width: 220,
                            options: IndiaGeography.countries,
                            validator: (value) =>
                                ValidationUtils.validateOptionalPlaceName(
                              value,
                              fieldName: 'Country',
                            ),
                            onChanged: (_) => setDialogState(() {}),
                            onSelected: (_) => setDialogState(() {}),
                          ),
                          AddressAutocompleteField(
                            controller: stateController,
                            label: 'State',
                            hint: 'e.g. Karnataka',
                            width: 220,
                            options: IndiaGeography.statesForCountry(
                              country.text,
                            ),
                            validator: (value) =>
                                ValidationUtils.validateOptionalPlaceName(
                              value,
                              fieldName: 'State',
                            ),
                            onChanged: (_) => setDialogState(() {}),
                            onSelected: (_) => setDialogState(() {}),
                          ),
                          AddressAutocompleteField(
                            controller: district,
                            label: 'District',
                            hint: 'e.g. Bengaluru Urban',
                            width: 220,
                            options: IndiaGeography.districtsFor(
                              state: stateController.text,
                              country: country.text,
                            ),
                            validator: (value) =>
                                ValidationUtils.validateOptionalPlaceName(
                              value,
                              fieldName: 'District',
                            ),
                            onChanged: (_) => setDialogState(() {}),
                            onSelected: (_) => setDialogState(() {}),
                          ),
                          AddressAutocompleteField(
                            controller: city,
                            label: 'City',
                            hint: 'e.g. Bengaluru',
                            width: 220,
                            options: IndiaGeography.districtsFor(
                              state: stateController.text,
                              country: country.text,
                            ),
                            validator: (value) =>
                                ValidationUtils.validateOptionalPlaceName(
                              value,
                              fieldName: 'City',
                            ),
                          ),
                          _dialogField(
                            pincode,
                            'PIN code',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(6),
                            ],
                            validator: ValidationUtils.validateOptionalPincode,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        children: [
                          ChoiceChip(
                            selected: status == 'active',
                            label: const Text('Active'),
                            onSelected: (_) =>
                                setDialogState(() => status = 'active'),
                          ),
                          ChoiceChip(
                            selected: status == 'inactive',
                            label: const Text('Inactive'),
                            onSelected: (_) =>
                                setDialogState(() => status = 'inactive'),
                          ),
                          FilterChip(
                            selected: canReassign,
                            label: const Text('Can reassign'),
                            onSelected: (value) =>
                                setDialogState(() => canReassign = value),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final valid = formKey.currentState?.validate() ?? false;
                    if (permissions.isEmpty) {
                      setDialogState(
                        () => permissionsError =
                            'Select at least one provider category',
                      );
                    }
                    if (!valid || permissions.isEmpty) return;
                    Navigator.pop(context, true);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (ok == true) {
      final region = ApproverRegionModel(
        country: country.text,
        state: stateController.text,
        district: district.text,
        city: city.text,
        pincode: pincode.text,
      ).toJson();
      final payload = {
        'firstName': firstName.text.trim(),
        'lastName': lastName.text.trim(),
        'employeeId': employeeId.text.trim(),
        'email': email.text.trim(),
        'phone': phone.text.trim(),
        if (password.text.isNotEmpty) 'password': password.text,
        'department': department.text.trim(),
        'designation': designation.text.trim(),
        'profilePicture': profilePicture.text.trim(),
        'status': status,
        'permissions': permissions.toList(),
        'regions': region.isEmpty ? [] : [region],
        'canReassign': canReassign,
      };
      final notifier = ref.read(approvalManagementProvider.notifier);
      final success = approver == null
          ? await notifier.createApprover(payload)
          : await notifier.updateApprover(approver.id, payload);
      if (mounted && success) {
        _toast(approver == null ? 'Approver created' : 'Approver updated');
      }
    }

    for (final controller in [
      firstName,
      lastName,
      employeeId,
      email,
      phone,
      password,
      department,
      designation,
      profilePicture,
      country,
      stateController,
      district,
      city,
      pincode,
    ]) {
      controller.dispose();
    }
  }

  Widget _dialogField(
    TextEditingController controller,
    String label, {
    bool obscure = false,
    bool required = false,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return _ApproverDialogField(
      controller: controller,
      label: label,
      obscure: obscure,
      requiredField: required,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
    );
  }

  Future<void> _confirmApproverStatus(ApproverModel approver) async {
    final next = approver.status == 'active' ? 'inactive' : 'active';
    final ok = await _confirm(
      title: '${next == 'active' ? 'Activate' : 'Deactivate'} approver',
      body: '${approver.name} will be marked $next.',
    );
    if (ok != true) return;
    final success = await ref
        .read(approvalManagementProvider.notifier)
        .setApproverStatus(approver, next);
    if (mounted && success) _toast('Approver $next');
  }

  Future<void> _resetApproverPassword(ApproverModel approver) async {
    final ok = await _confirm(
      title: 'Reset password',
      body: 'A temporary password will be generated for ${approver.name}.',
    );
    if (ok != true) return;
    final temporaryPassword = await ref
        .read(approvalManagementProvider.notifier)
        .resetApproverPassword(approver);
    if (!mounted || temporaryPassword == null) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Temporary password'),
        content: SelectableText(temporaryPassword),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteApprover(ApproverModel approver) async {
    final ok = await _confirm(
      title: 'Delete approver',
      body:
          '${approver.name} will be deactivated and hidden from active management. Audit history remains intact.',
    );
    if (ok != true) return;
    final success = await ref
        .read(approvalManagementProvider.notifier)
        .deleteApprover(approver);
    if (mounted && success) _toast('Approver deleted');
  }

  Future<void> _showRequestDetails(ApprovalRequestModel request) async {
    final viewedRequest = await ref
        .read(approvalManagementProvider.notifier)
        .markRequestViewed(request);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => _RequestDetailsDialog(
        request: viewedRequest,
        onOpenKyc: () {
          if (SafeNavigation.isLocked) return;
          final path = _kycDetailPath(
            viewedRequest.providerType,
            viewedRequest.providerId,
          );
          if (path == null) {
            _toast('KYC detail screen is not available for this provider type');
            return;
          }
          Navigator.pop(context);
          SafeNavigation.push(context, path);
        },
      ),
    );
  }

  Future<void> _saveRequestFilter() async {
    final controller = TextEditingController();
    final filterFormKey = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save filter'),
        content: Form(
          key: filterFormKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: CaretOnTapTextFormField(
            controller: controller,
            validator: (value) => ValidationUtils.validateRequired(
              value,
              fieldName: 'Filter name',
              minLength: 2,
              maxLength: 40,
            ),
            decoration: const InputDecoration(labelText: 'Filter name *'),
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (!(filterFormKey.currentState?.validate() ?? false)) return;
              Navigator.pop(context, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok == true && controller.text.trim().isNotEmpty) {
      final success = await ref
          .read(approvalManagementProvider.notifier)
          .saveCurrentRequestFilter(controller.text.trim());
      if (mounted && success) _toast('Filter saved');
    }
    controller.dispose();
  }

  Future<void> _showApproverPerformance(ApproverModel approver) async {
    final state = ref.read(approvalManagementProvider);
    final palette = _Palette(_dark);
    final recent = state.requests
        .where(
          (request) =>
              request.currentAssigneeId == approver.id ||
              request.approvalHistory.any(
                (item) =>
                    (item['actor'] as Map?)?['id']?.toString() == approver.id,
              ),
        )
        .take(10)
        .toList();
    final metrics = [
      _ApproverStat(
        label: 'Assigned',
        value: approver.assigned,
        tone: palette.primary,
        icon: Icons.assignment_ind_outlined,
      ),
      _ApproverStat(
        label: 'Approved',
        value: approver.approved,
        tone: palette.success,
        icon: Icons.verified_outlined,
      ),
      _ApproverStat(
        label: 'Rejected',
        value: approver.rejected,
        tone: palette.danger,
        icon: Icons.cancel_outlined,
      ),
      _ApproverStat(
        label: 'Pending',
        value: approver.pending,
        tone: palette.warning,
        icon: Icons.pending_actions_outlined,
      ),
      _ApproverStat(
        label: 'Escalated',
        value: approver.escalations,
        tone: const Color(0xFF7C3AED),
        icon: Icons.support_agent_outlined,
      ),
    ];
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: palette.surface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              approver.name,
              style: AppTextStyles.titleLarge.copyWith(color: palette.text),
            ),
            const SizedBox(height: 4),
            Text(
              [
                approver.employeeId,
                approver.email,
                _titleCase(approver.status),
              ].where((part) => part.trim().isNotEmpty).join(' · '),
              style: AppTextStyles.bodySmall.copyWith(color: palette.muted),
            ),
          ],
        ),
        content: SizedBox(
          width: 720,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: metrics
                      .map(
                        (metric) => SizedBox(
                          width: 128,
                          child: _ApproverStatTile(
                            palette: palette,
                            stat: metric,
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _MiniBadge(
                      label: 'Avg time ${_duration(approver.averageApprovalTimeMinutes)}',
                    ),
                    _MiniBadge(label: 'Accept ${approver.acceptanceRate}%'),
                    _MiniBadge(label: 'Reject ${approver.rejectionRate}%'),
                    _MiniBadge(label: 'Workload ${approver.workload}'),
                    if (approver.lastLoginAt != null)
                      _MiniBadge(
                        label: 'Last login ${_dateTime(approver.lastLoginAt)}',
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'Workload mix',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: palette.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 200,
                  child: _BarChart(
                    points: metrics
                        .map(
                          (metric) => ChartPointModel(
                            label: metric.label,
                            value: metric.value,
                          ),
                        )
                        .toList(),
                    color: AppColors.primary,
                    showValues: true,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Recent activity',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: palette.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                if (recent.isEmpty)
                  Text(
                    'No recent activity',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: palette.muted,
                    ),
                  )
                else
                  ...recent.map(
                    (request) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: palette.surfaceAlt,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: palette.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  request.provider.name,
                                  style: AppTextStyles.titleSmall.copyWith(
                                    color: palette.text,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_friendlyCategoryLabel(request.providerCategory)} · ${_date(request.updatedAt)}',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: palette.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _StatusPill(status: request.status),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showApproverDialog(approver);
            },
            child: const Text('Edit profile'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRuleDialog(
    ProviderCategoryModel category,
    ApprovalRuleModel rule,
  ) async {
    final slaController = TextEditingController(text: '${rule.slaHours}');
    final escalationController = TextEditingController(
      text: '${rule.escalationHours}',
    );
    var strategy = rule.assignmentStrategy;
    var active = rule.active;
    final levels = rule.approvalLevels
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    if (levels.isEmpty) {
      levels.addAll([
        {
          'id': 'level_1_approver',
          'name': 'Primary Approver',
          'role': 'approver',
          'required': true,
          'order': 1,
        },
        {
          'id': 'level_2_admin',
          'name': 'Admin Review',
          'role': 'super_admin',
          'required': false,
          'order': 2,
        },
      ]);
    }
    final strategies = ref
        .read(approvalManagementProvider)
        .config
        .assignmentStrategies;
    final ruleFormKey = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Configure ${category.name}'),
          content: SizedBox(
            width: 520,
            child: Form(
              key: ruleFormKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CaretOnTapTextFormField(
                    controller: slaController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    validator: (value) => ValidationUtils.validateHours(
                      value,
                      fieldName: 'SLA hours',
                    ),
                    decoration: const InputDecoration(labelText: 'SLA hours *'),
                  ),
                  const SizedBox(height: 12),
                  CaretOnTapTextFormField(
                    controller: escalationController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    validator: (value) {
                      final hoursError = ValidationUtils.validateHours(
                        value,
                        fieldName: 'Escalation hours',
                        min: 0,
                      );
                      if (hoursError != null) return hoursError;
                      final sla = int.tryParse(slaController.text.trim());
                      final escalation = int.tryParse(value?.trim() ?? '');
                      if (sla != null && escalation != null && escalation >= sla) {
                        return 'Escalation hours must be less than SLA hours';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Escalation hours (near-deadline window) *',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: strategy,
                    isExpanded: true,
                    itemHeight: kMinInteractiveDimension,
                    menuMaxHeight: 280,
                    borderRadius: BorderRadius.circular(12),
                    decoration: const InputDecoration(
                      labelText: 'Assignment strategy',
                    ),
                    items: strategies
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(_titleCase(item)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => strategy = value);
                      }
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Active'),
                    value: active,
                    onChanged: (value) => setDialogState(() => active = value),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Approval levels',
                        style: AppTextStyles.titleSmall,
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {
                          setDialogState(() {
                            levels.add({
                              'id': 'level_${levels.length + 1}',
                              'name': 'Level ${levels.length + 1}',
                              'role': 'approver',
                              'required': true,
                              'order': levels.length + 1,
                            });
                          });
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add level'),
                      ),
                    ],
                  ),
                  ...levels.asMap().entries.map((entry) {
                    final index = entry.key;
                    final level = entry.value;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            CaretOnTapTextFormField(
                              initialValue: level['name']?.toString() ?? '',
                              validator: (value) =>
                                  ValidationUtils.validateRequired(
                                value,
                                fieldName: 'Level name',
                                minLength: 2,
                                maxLength: 40,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Level name *',
                              ),
                              onChanged: (value) => level['name'] = value,
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              initialValue:
                                  level['role']?.toString() ?? 'approver',
                              isExpanded: true,
                              itemHeight: kMinInteractiveDimension,
                              menuMaxHeight: 280,
                              borderRadius: BorderRadius.circular(12),
                              decoration: const InputDecoration(
                                labelText: 'Role',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'approver',
                                  child: Text('Approver'),
                                ),
                                DropdownMenuItem(
                                  value: 'admin',
                                  child: Text('Admin'),
                                ),
                                DropdownMenuItem(
                                  value: 'super_admin',
                                  child: Text('Super Admin'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setDialogState(() => level['role'] = value);
                                }
                              },
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Required'),
                              value: level['required'] != false,
                              onChanged: (value) {
                                setDialogState(() => level['required'] = value);
                              },
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                tooltip: 'Remove level',
                                onPressed: levels.length <= 1
                                    ? null
                                    : () {
                                        setDialogState(() {
                                          levels.removeAt(index);
                                          for (var i = 0; i < levels.length; i++) {
                                            levels[i]['order'] = i + 1;
                                          }
                                        });
                                      },
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (!(ruleFormKey.currentState?.validate() ?? false)) return;
                Navigator.pop(context, true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (ok == true) {
      final normalizedLevels = [
        for (var i = 0; i < levels.length; i++)
          {
            ...levels[i],
            'id': levels[i]['id'] ?? 'level_${i + 1}',
            'order': i + 1,
            'required': levels[i]['required'] != false,
          },
      ];
      final success = await ref
          .read(approvalManagementProvider.notifier)
          .updateRule(
            category: category,
            rule: rule,
            slaHours: int.parse(slaController.text),
            escalationHours: int.parse(escalationController.text),
            assignmentStrategy: strategy,
            active: active,
            approvalLevels: normalizedLevels,
          );
      if (mounted && success) _toast('Approval rule updated');
    }
    slaController.dispose();
    escalationController.dispose();
  }

  Future<void> _exportReport(String format) async {
    final content = await ref
        .read(approvalManagementProvider.notifier)
        .exportReport(format: format);
    if (!mounted) return;
    if (content == null || content.isEmpty) {
      _toast('Unable to prepare ${format.toUpperCase()} export');
      return;
    }
    await Clipboard.setData(ClipboardData(text: content));
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${format.toUpperCase()} export ready'),
        content: SizedBox(
          width: 640,
          height: 360,
          child: SelectableText(content),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: content));
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Copy again'),
          ),
        ],
      ),
    );
    _toast('${format.toUpperCase()} report copied to clipboard');
  }

  Future<bool?> _confirm({required String title, required String body}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _toast(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _Palette {
  const _Palette(this.dark);

  final bool dark;

  Color get background => dark ? const Color(0xFF0F1419) : AppColors.background;
  Color get surface => dark ? const Color(0xFF171D24) : AppColors.white;
  Color get surfaceAlt => dark ? const Color(0xFF202833) : AppColors.grey50;
  Color get border => dark ? const Color(0xFF2D3845) : AppColors.border;
  Color get text => dark ? const Color(0xFFE8EDF3) : AppColors.textPrimary;
  Color get muted => dark ? const Color(0xFF9AA7B4) : AppColors.textSecondary;
  Color get primary => AppColors.primary;
  Color get warning => AppColors.warning;
  Color get danger => AppColors.error;
  Color get success => AppColors.success;
}

class _SideNav extends StatelessWidget {
  const _SideNav({
    required this.palette,
    required this.selected,
    required this.items,
    required this.onSelected,
  });

  final _Palette palette;
  final _ConsoleSection selected;
  final List<_NavItem> items;
  final ValueChanged<_ConsoleSection> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 264,
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(right: BorderSide(color: palette.border)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enterprise approvals',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: palette.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'RBAC · SLA · Audit',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: palette.muted,
                    ),
                  ),
                ],
              ),
            ),
            ...items.map(
              (item) => _NavButton(
                item: item,
                selected: selected == item.section,
                palette: palette,
                onTap: () => onSelected(item.section),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileNav extends StatelessWidget {
  const _MobileNav({
    required this.palette,
    required this.selected,
    required this.items,
    required this.onSelected,
  });

  final _Palette palette;
  final _ConsoleSection selected;
  final List<_NavItem> items;
  final ValueChanged<_ConsoleSection> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: palette.surface,
      height: 58,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          return ChoiceChip(
            avatar: Icon(item.icon, size: 18),
            selected: selected == item.section,
            label: Text(item.label),
            onSelected: (_) => onSelected(item.section),
          );
        },
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final _Palette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: selected ? AppColors.primaryLight : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 20,
                  color: selected ? AppColors.primary : palette.muted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.label,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: selected ? AppColors.primaryDark : palette.text,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OverviewPane extends StatelessWidget {
  const _OverviewPane({
    required this.state,
    required this.palette,
    required this.onOpenRequests,
    required this.onOpenMetric,
    required this.isApprover,
    this.userName,
  });

  final ApprovalManagementState state;
  final _Palette palette;
  final VoidCallback onOpenRequests;
  final ValueChanged<_OverviewMetric> onOpenMetric;
  final bool isApprover;
  final String? userName;

  @override
  Widget build(BuildContext context) {
    final stats = state.dashboard.stats;
    final title = (userName?.trim().isNotEmpty == true)
        ? userName!.trim()
        : (isApprover ? 'Approver' : 'Command center');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PaneHeader(
          palette: palette,
          title: title,
          subtitle: isApprover
              ? 'Your approval queue across assigned categories and regions'
              : 'Transparent approval control across categories and regions',
          trailing: FilledButton.icon(
            onPressed: onOpenRequests,
            icon: const Icon(Icons.rule_folder_outlined),
            label: const Text('Review queue'),
          ),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final itemWidth = width >= 1100
                ? (width - 44) / 4
                : width >= 720
                ? (width - 22) / 2
                : width;
            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                _MetricCard(
                  palette: palette,
                  width: itemWidth,
                  icon: Icons.business_center_outlined,
                  label: isApprover ? 'Approved today' : 'Total providers',
                  value: isApprover
                      ? '${stats.approvalsToday}'
                      : '${stats.totalProviders}',
                  tone: palette.primary,
                  onTap: () => onOpenMetric(
                    isApprover
                        ? _OverviewMetric.approvedToday
                        : _OverviewMetric.totalProviders,
                  ),
                ),
                _MetricCard(
                  palette: palette,
                  width: itemWidth,
                  icon: Icons.pending_actions_outlined,
                  label: 'Pending',
                  value: '${stats.pending}',
                  tone: palette.warning,
                  onTap: () => onOpenMetric(_OverviewMetric.pending),
                ),
                _MetricCard(
                  palette: palette,
                  width: itemWidth,
                  icon: Icons.verified_outlined,
                  label: isApprover ? 'Rejected today' : 'Approved',
                  value: isApprover
                      ? '${stats.rejectionsToday}'
                      : '${stats.approved}',
                  tone: palette.success,
                  onTap: () => onOpenMetric(
                    isApprover
                        ? _OverviewMetric.rejectedToday
                        : _OverviewMetric.approved,
                  ),
                ),
                _MetricCard(
                  palette: palette,
                  width: itemWidth,
                  icon: Icons.report_gmailerrorred_outlined,
                  label: 'Past deadline',
                  value: '${stats.slaBreached}',
                  tone: palette.danger,
                  onTap: () => onOpenMetric(_OverviewMetric.slaBreached),
                ),
                _MetricCard(
                  palette: palette,
                  width: itemWidth,
                  icon: Icons.hourglass_top_outlined,
                  label: 'Need documents',
                  value: '${stats.needDocuments}',
                  tone: palette.warning,
                  onTap: () => onOpenMetric(_OverviewMetric.needDocuments),
                ),
                _MetricCard(
                  palette: palette,
                  width: itemWidth,
                  icon: Icons.support_agent_outlined,
                  label: 'Escalated',
                  value: '${stats.escalated}',
                  tone: palette.danger,
                  onTap: () => onOpenMetric(_OverviewMetric.escalated),
                ),
                _MetricCard(
                  palette: palette,
                  width: itemWidth,
                  icon: Icons.speed_outlined,
                  label: 'Avg approval time',
                  value: _duration(stats.averageApprovalTimeMinutes),
                  tone: palette.primary,
                  onTap: () => onOpenMetric(_OverviewMetric.avgApprovalTime),
                ),
                _MetricCard(
                  palette: palette,
                  width: itemWidth,
                  icon: Icons.online_prediction_outlined,
                  label: isApprover ? 'On hold' : 'Approvers online',
                  value: isApprover
                      ? '${stats.onHold}'
                      : '${stats.approversOnline}',
                  tone: palette.success,
                  onTap: () => onOpenMetric(
                    isApprover
                        ? _OverviewMetric.onHold
                        : _OverviewMetric.approversOnline,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final twoColumns = constraints.maxWidth >= 900;
            final panelWidth = twoColumns
                ? (constraints.maxWidth - 14) / 2
                : constraints.maxWidth;
            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                _Panel(
                  palette: palette,
                  width: panelWidth,
                  title: 'Approval trend',
                  child: SizedBox(
                    height: 220,
                    child: _LineAreaChart(
                      points: state.dashboard.charts.approvalTrend,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                _Panel(
                  palette: palette,
                  width: panelWidth,
                  title: 'Provider growth',
                  child: SizedBox(
                    height: 220,
                    child: _BarChart(
                      points: state.dashboard.charts.providerGrowth,
                      color: const Color(0xFF4568DC),
                    ),
                  ),
                ),
                _Panel(
                  palette: palette,
                  width: panelWidth,
                  title: 'Status mix',
                  child: SizedBox(
                    height: 220,
                    child: _DonutChart(
                      points: state.dashboard.charts.statusMix,
                    ),
                  ),
                ),
                _Panel(
                  palette: palette,
                  width: panelWidth,
                  title: 'Recent activity',
                  child: _RecentRequestsList(
                    palette: palette,
                    requests: state.dashboard.recentRequests,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _MetricDrilldownPane extends StatelessWidget {
  const _MetricDrilldownPane({
    required this.state,
    required this.palette,
    required this.metric,
    required this.selectedCategory,
    required this.onBack,
    required this.onSelectCategory,
    required this.onOpenProvider,
  });

  final ApprovalManagementState state;
  final _Palette palette;
  final _OverviewMetric metric;
  final String? selectedCategory;
  final VoidCallback onBack;
  final ValueChanged<String> onSelectCategory;
  final ValueChanged<ApprovalRequestModel> onOpenProvider;

  List<ApprovalRequestModel> get _filteredRequests {
    return state.requests.where(metric.matches).toList();
  }

  Map<String, List<ApprovalRequestModel>> get _byCategory {
    final map = <String, List<ApprovalRequestModel>>{};
    for (final request in _filteredRequests) {
      final key = request.providerCategory.trim().isEmpty
          ? (request.providerType.trim().isEmpty
                ? 'other'
                : request.providerType)
          : request.providerCategory;
      final normalized = key.trim().toLowerCase().replaceAll('-', '_');
      if (normalized == 'doctor' || normalized == 'doctors') {
        for (final bucket in _doctorServiceBuckets(request)) {
          map.putIfAbsent(bucket, () => []).add(request);
        }
      } else {
        map.putIfAbsent(key, () => []).add(request);
      }
    }
    return map;
  }

  /// Splits doctors into Online / Home visit / Hospital visit sections.
  List<String> _doctorServiceBuckets(ApprovalRequestModel request) {
    final provider = request.provider;
    final details = request.providerDetails;
    bool flag(bool? snapshot, String detailsKey) {
      if (snapshot == true) return true;
      final raw = details[detailsKey];
      return raw == true;
    }

    final online = flag(provider.offersOnlineConsult, 'offersOnlineConsult');
    final home = flag(provider.offersBookHome, 'offersBookHome');
    final hospital = flag(provider.offersVisitSite, 'offersVisitSite');
    final buckets = <String>[
      if (online) 'doctor_online',
      if (home) 'doctor_home_visit',
      if (hospital) 'doctor_hospital_visit',
    ];
    // Legacy doctors with no consultation flags still appear in every doctor section.
    if (buckets.isEmpty) {
      return const [
        'doctor_online',
        'doctor_home_visit',
        'doctor_hospital_visit',
      ];
    }
    return buckets;
  }

  String _categoryName(String slug) {
    for (final category in state.config.categories) {
      if (category.slug == slug) return category.name;
    }
    for (final category in _fallbackApprovalCategories) {
      if (category.slug == slug) return category.name;
    }
    return _friendlyCategoryLabel(slug);
  }

  @override
  Widget build(BuildContext context) {
    final categories = _byCategory.entries.toList()
      ..sort((a, b) {
        final orderA = _categorySortOrder(a.key);
        final orderB = _categorySortOrder(b.key);
        if (orderA != orderB) return orderA.compareTo(orderB);
        return b.value.length.compareTo(a.value.length);
      });
    final inCategory = selectedCategory != null;
    final providers = inCategory
        ? (_byCategory[selectedCategory] ?? const <ApprovalRequestModel>[])
        : const <ApprovalRequestModel>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Back',
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _PaneHeader(
                palette: palette,
                title: inCategory
                    ? _categoryName(selectedCategory!)
                    : metric.title,
                subtitle: inCategory
                    ? '${providers.length} provider${providers.length == 1 ? '' : 's'} · tap a card for full profile'
                    : 'Choose a provider type to review ${metric.title.toLowerCase()}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (state.isLoading && state.requests.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (!inCategory && categories.isEmpty)
          _EmptyState(
            icon: Icons.inbox_outlined,
            title: 'No providers found',
            subtitle: 'Nothing matches this metric right now.',
            palette: palette,
          )
        else if (!inCategory)
          ...categories.map((entry) {
            final slug = entry.key;
            final count = entry.value.length;
            final tone = _categoryTone(slug, palette);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onSelectCategory(slug),
                  borderRadius: BorderRadius.circular(8),
                  child: _Panel(
                    palette: palette,
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: tone.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(_categoryIcon(slug), color: tone),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _categoryName(slug),
                                style: AppTextStyles.titleSmall.copyWith(
                                  color: palette.text,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$count provider${count == 1 ? '' : 's'}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: palette.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '$count',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: palette.text,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right_rounded, color: palette.muted),
                      ],
                    ),
                  ),
                ),
              ),
            );
          })
        else if (providers.isEmpty)
          _EmptyState(
            icon: Icons.person_search_outlined,
            title: 'No providers in this category',
            subtitle: 'Try another provider type from the previous list.',
            palette: palette,
          )
        else
          ...providers.map(
            (request) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ProviderProfileCard(
                request: request,
                palette: palette,
                showDuration: metric == _OverviewMetric.avgApprovalTime,
                onTap: () => onOpenProvider(request),
              ),
            ),
          ),
      ],
    );
  }
}

class _ProviderProfileCard extends StatelessWidget {
  const _ProviderProfileCard({
    required this.request,
    required this.palette,
    required this.onTap,
    this.showDuration = false,
  });

  final ApprovalRequestModel request;
  final _Palette palette;
  final VoidCallback onTap;
  final bool showDuration;

  @override
  Widget build(BuildContext context) {
    final location = [
      request.provider.city,
      request.provider.state,
    ].where((part) => part != null && part.trim().isNotEmpty).join(', ');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: _Panel(
          palette: palette,
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: palette.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _categoryIcon(request.providerCategory),
                  color: palette.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.provider.name,
                      style: AppTextStyles.titleSmall.copyWith(
                        color: palette.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        _friendlyCategoryLabel(request.providerCategory),
                        if (location.isNotEmpty) location,
                        if (request.provider.phone?.isNotEmpty == true)
                          request.provider.phone!,
                      ].join(' · '),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: palette.muted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _StatusPill(status: request.status),
                        _SlaPill(request: request),
                        if (showDuration &&
                            request.approvalDurationMinutes != null)
                          _MiniBadge(
                            label:
                                'Time ${_duration(request.approvalDurationMinutes!)}',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: palette.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequestsPane extends ConsumerWidget {
  const _RequestsPane({
    required this.state,
    required this.palette,
    required this.searchController,
    required this.onShowDetails,
    required this.onAction,
    required this.onAssign,
    required this.canAssign,
    required this.onSaveFilter,
  });

  final ApprovalManagementState state;
  final _Palette palette;
  final TextEditingController searchController;
  final ValueChanged<ApprovalRequestModel> onShowDetails;
  final void Function(ApprovalRequestModel request, String action) onAction;
  final ValueChanged<ApprovalRequestModel> onAssign;
  final bool canAssign;
  final VoidCallback onSaveFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(approvalManagementProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PaneHeader(
          palette: palette,
          title: 'Approval requests',
          subtitle:
              'Tap a card to open full profile, verify documents one by one, then final approve',
          trailing: Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onSaveFilter,
                icon: const Icon(Icons.bookmark_add_outlined),
                label: const Text('Save filter'),
              ),
              FilledButton.icon(
                onPressed: () => notifier.refreshRequests(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
        if (state.savedFilters.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: state.savedFilters
                .map(
                  (filter) => InputChip(
                    label: Text(filter.name),
                    onPressed: () => notifier.applySavedFilter(filter),
                    onDeleted: () => notifier.deleteSavedFilter(filter.id),
                  ),
                )
                .toList(),
          ),
        ],
        const SizedBox(height: 14),
        _Panel(
          palette: palette,
          title: 'Filters',
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 280,
                child: CaretOnTapTextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded),
                    hintText: 'Search provider, city, ID',
                  ),
                  onSubmitted: (value) =>
                      notifier.setRequestFilters(search: value.trim()),
                ),
              ),
              _FilterMenu(
                label: 'Status',
                value: state.requestStatusFilter,
                values: const [
                  'pending',
                  'approved',
                  'rejected',
                  'on_hold',
                  'needs_documents',
                  'escalated',
                ],
                onSelected: (value) => notifier.setRequestFilters(
                  status: value,
                  clearStatus: value == null,
                ),
              ),
              _FilterMenu(
                label: 'Category',
                value: state.categoryFilter,
                values: state.config.categories.map((c) => c.slug).toList(),
                labels: {
                  for (final category in state.config.categories)
                    category.slug: category.name,
                },
                onSelected: (value) => notifier.setRequestFilters(
                  category: value,
                  clearCategory: value == null,
                ),
              ),
              _FilterMenu(
                label: 'Approver',
                value: state.approverFilter,
                values: state.approvers.map((a) => a.id).toList(),
                labels: {
                  for (final approver in state.approvers)
                    approver.id: approver.name,
                },
                onSelected: (value) => notifier.setRequestFilters(
                  approverId: value,
                  clearApprover: value == null,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _Panel(
          palette: palette,
          title: 'Queue',
          child: state.requests.isEmpty
              ? _EmptyState(
                  icon: Icons.rule_folder_outlined,
                  title: 'No requests found',
                  subtitle:
                      'Try clearing filters or syncing provider submissions.',
                  palette: palette,
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 780) {
                      return Column(
                        children: state.requests
                            .map(
                              (request) => _RequestCard(
                                request: request,
                                palette: palette,
                                onTap: () => onShowDetails(request),
                                onAssign: () => onAssign(request),
                                canAssign: canAssign,
                                onAction: (action) => onAction(request, action),
                              ),
                            )
                            .toList(),
                      );
                    }
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingTextStyle: AppTextStyles.labelMedium.copyWith(
                          color: palette.muted,
                          fontWeight: FontWeight.w800,
                        ),
                        columns: const [
                          DataColumn(label: Text('Provider')),
                          DataColumn(label: Text('Type')),
                          DataColumn(label: Text('Assigned')),
                          DataColumn(label: Text('Registered')),
                          DataColumn(label: Text('Priority')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('SLA')),
                          DataColumn(label: Text('Assignee')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: state.requests.map((request) {
                          return DataRow(
                            onSelectChanged: (_) => onShowDetails(request),
                            cells: [
                              DataCell(
                                SizedBox(
                                  width: 190,
                                  child: Text(
                                    request.provider.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(_titleCase(request.providerCategory)),
                              ),
                              DataCell(Text(_date(request.assignedAt))),
                              DataCell(
                                Text(_date(request.provider.registrationDate)),
                              ),
                              DataCell(
                                _PriorityPill(priority: request.priority),
                              ),
                              DataCell(_StatusPill(status: request.status)),
                              DataCell(_SlaPill(request: request)),
                              DataCell(
                                SizedBox(
                                  width: 150,
                                  child: Text(
                                    request.currentAssigneeName ?? 'Unassigned',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (canAssign)
                                      Tooltip(
                                        message: 'Assign',
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.swap_horiz_rounded,
                                          ),
                                          onPressed: () => onAssign(request),
                                        ),
                                      ),
                                    _ActionMenu(
                                      onSelected: (action) =>
                                          onAction(request, action),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ApproversPane extends StatelessWidget {
  const _ApproversPane({
    required this.state,
    required this.palette,
    required this.onCreate,
    required this.onOpenProfile,
    required this.onEdit,
    required this.onStatus,
    required this.onResetPassword,
    required this.onDelete,
  });

  final ApprovalManagementState state;
  final _Palette palette;
  final VoidCallback onCreate;
  final ValueChanged<ApproverModel> onOpenProfile;
  final ValueChanged<ApproverModel> onEdit;
  final ValueChanged<ApproverModel> onStatus;
  final ValueChanged<ApproverModel> onResetPassword;
  final ValueChanged<ApproverModel> onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PaneHeader(
          palette: palette,
          title: 'Approver management',
          subtitle:
              'Tap an approver to open their profile, workload, and recent activity',
          trailing: FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.person_add_alt_1_outlined),
            label: const Text('New approver'),
          ),
        ),
        const SizedBox(height: 14),
        _Panel(
          palette: palette,
          title: 'Approvers',
          child: state.approvers.isEmpty
              ? _EmptyState(
                  icon: Icons.people_alt_outlined,
                  title: 'No approvers yet',
                  subtitle:
                      'Create the first approver to start role-based review.',
                  palette: palette,
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 780) {
                      return Column(
                        children: state.approvers
                            .map(
                              (approver) => _ApproverListCard(
                                approver: approver,
                                palette: palette,
                                onTap: () => onOpenProfile(approver),
                                onEdit: () => onEdit(approver),
                                onStatus: () => onStatus(approver),
                                onResetPassword: () =>
                                    onResetPassword(approver),
                                onDelete: () => onDelete(approver),
                              ),
                            )
                            .toList(),
                      );
                    }
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        showCheckboxColumn: false,
                        columns: const [
                          DataColumn(label: Text('Approver')),
                          DataColumn(label: Text('Permissions')),
                          DataColumn(label: Text('Region')),
                          DataColumn(label: Text('Workload')),
                          DataColumn(label: Text('Approved')),
                          DataColumn(label: Text('Rejected')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: state.approvers.map((approver) {
                          return DataRow(
                            onSelectChanged: (_) => onOpenProfile(approver),
                            cells: [
                              DataCell(
                                SizedBox(
                                  width: 220,
                                  child: ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    onTap: () => onOpenProfile(approver),
                                    title: Text(approver.name),
                                    subtitle: Text(
                                      '${approver.employeeId} · ${approver.email}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 230,
                                  child: Text(
                                    approver.permissions
                                        .map(_titleCase)
                                        .join(', '),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              DataCell(Text(_regionLabel(approver))),
                              DataCell(Text('${approver.workload}')),
                              DataCell(Text('${approver.approved}')),
                              DataCell(Text('${approver.rejected}')),
                              DataCell(_StatusPill(status: approver.status)),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Tooltip(
                                      message: 'Edit',
                                      child: IconButton(
                                        icon: const Icon(Icons.edit_outlined),
                                        onPressed: () => onEdit(approver),
                                      ),
                                    ),
                                    Tooltip(
                                      message: approver.status == 'active'
                                          ? 'Deactivate'
                                          : 'Activate',
                                      child: IconButton(
                                        icon: Icon(
                                          approver.status == 'active'
                                              ? Icons.pause_circle_outline
                                              : Icons.play_circle_outline,
                                        ),
                                        onPressed: () => onStatus(approver),
                                      ),
                                    ),
                                    Tooltip(
                                      message: 'Reset password',
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.lock_reset_rounded,
                                        ),
                                        onPressed: () =>
                                            onResetPassword(approver),
                                      ),
                                    ),
                                    Tooltip(
                                      message: 'Delete',
                                      child: IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        onPressed: () => onDelete(approver),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ApproverListCard extends StatelessWidget {
  const _ApproverListCard({
    required this.approver,
    required this.palette,
    required this.onTap,
    required this.onEdit,
    required this.onStatus,
    required this.onResetPassword,
    required this.onDelete,
  });

  final ApproverModel approver;
  final _Palette palette;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onStatus;
  final VoidCallback onResetPassword;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: palette.surfaceAlt,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: palette.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            approver.name,
                            style: AppTextStyles.titleSmall.copyWith(
                              color: palette.text,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${approver.employeeId} · ${approver.email}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: palette.muted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    _StatusPill(status: approver.status),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded, color: palette.muted),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MiniBadge(
                      label: approver.permissions.isEmpty
                          ? 'No permissions'
                          : approver.permissions.map(_titleCase).join(', '),
                    ),
                    _MiniBadge(label: _regionLabel(approver)),
                    _MiniBadge(label: 'Workload ${approver.workload}'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Edit',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: onEdit,
                    ),
                    IconButton(
                      tooltip: approver.status == 'active'
                          ? 'Deactivate'
                          : 'Activate',
                      icon: Icon(
                        approver.status == 'active'
                            ? Icons.pause_circle_outline
                            : Icons.play_circle_outline,
                      ),
                      onPressed: onStatus,
                    ),
                    IconButton(
                      tooltip: 'Reset password',
                      icon: const Icon(Icons.lock_reset_rounded),
                      onPressed: onResetPassword,
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PerformancePane extends StatelessWidget {
  const _PerformancePane({
    required this.state,
    required this.palette,
    required this.onOpenApprover,
  });

  final ApprovalManagementState state;
  final _Palette palette;
  final ValueChanged<ApproverModel> onOpenApprover;

  @override
  Widget build(BuildContext context) {
    final approvers = [...state.approvers]
      ..sort((a, b) => b.assigned.compareTo(a.assigned));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PaneHeader(
          palette: palette,
          title: 'Approver performance',
          subtitle:
              'Each card is one approver. Open details to see only that person’s numbers.',
        ),
        const SizedBox(height: 14),
        if (approvers.isEmpty)
          _Panel(
            palette: palette,
            child: _EmptyState(
              icon: Icons.insights_outlined,
              title: 'No approvers yet',
              subtitle: 'Create approvers first to track performance.',
              palette: palette,
            ),
          )
        else
          ...approvers.map(
            (approver) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ApproverPerformanceCard(
                palette: palette,
                approver: approver,
                onOpen: () => onOpenApprover(approver),
              ),
            ),
          ),
      ],
    );
  }
}

class _ApproverPerformanceCard extends StatelessWidget {
  const _ApproverPerformanceCard({
    required this.palette,
    required this.approver,
    required this.onOpen,
  });

  final _Palette palette;
  final ApproverModel approver;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: palette.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.person_outline_rounded, color: palette.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      approver.name,
                      style: AppTextStyles.titleSmall.copyWith(
                        color: palette.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        approver.employeeId,
                        approver.email,
                      ].where((part) => part.trim().isNotEmpty).join(' · '),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: palette.muted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _StatusPill(status: approver.status),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: onOpen,
                icon: const Icon(Icons.insights_outlined, size: 18),
                label: const Text('View'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniBadge(label: 'Assigned ${approver.assigned}'),
              _MiniBadge(label: 'Approved ${approver.approved}'),
              _MiniBadge(label: 'Rejected ${approver.rejected}'),
              _MiniBadge(label: 'Pending ${approver.pending}'),
              _MiniBadge(label: 'Escalated ${approver.escalations}'),
              _MiniBadge(
                label: 'Avg ${_duration(approver.averageApprovalTimeMinutes)}',
              ),
              _MiniBadge(label: 'Accept ${approver.acceptanceRate}%'),
              _MiniBadge(
                label: 'Last login ${_date(approver.lastLoginAt)}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AuditPane extends StatelessWidget {
  const _AuditPane({required this.state, required this.palette});

  final ApprovalManagementState state;
  final _Palette palette;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PaneHeader(
          palette: palette,
          title: 'Audit logs',
          subtitle:
              'Immutable action history with user, IP, device, and timestamp',
        ),
        const SizedBox(height: 14),
        _Panel(
          palette: palette,
          title: 'System events',
          child: state.auditLogs.isEmpty
              ? _EmptyState(
                  icon: Icons.history_edu_outlined,
                  title: 'No audit events',
                  subtitle: 'Actions will appear here as the workflow is used.',
                  palette: palette,
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('When')),
                      DataColumn(label: Text('User')),
                      DataColumn(label: Text('Action')),
                      DataColumn(label: Text('Entity')),
                      DataColumn(label: Text('IP')),
                      DataColumn(label: Text('Device')),
                    ],
                    rows: state.auditLogs.map((log) {
                      return DataRow(
                        cells: [
                          DataCell(Text(_dateTime(log.createdAt))),
                          DataCell(Text(log.actorName ?? 'System')),
                          DataCell(Text(_titleCase(log.action))),
                          DataCell(Text(log.entityLabel ?? log.entityType)),
                          DataCell(Text(log.ip ?? '')),
                          DataCell(
                            SizedBox(
                              width: 220,
                              child: Text(
                                log.device ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
        ),
      ],
    );
  }
}

class _ConfigPane extends StatelessWidget {
  const _ConfigPane({
    required this.state,
    required this.palette,
    required this.onEdit,
  });

  final ApprovalManagementState state;
  final _Palette palette;
  final void Function(ProviderCategoryModel category, ApprovalRuleModel rule)
  onEdit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PaneHeader(
          palette: palette,
          title: 'Rules and categories',
          subtitle:
              'Configuration-backed categories, SLA windows, and assignment strategy',
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth >= 900
                ? (constraints.maxWidth - 28) / 3
                : constraints.maxWidth;
            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: state.config.categories.map((category) {
                final rule = state.config.rules
                    .where((item) => item.providerCategory == category.slug)
                    .firstOrNull;
                return _Panel(
                  palette: palette,
                  width: cardWidth,
                  title: category.name,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.description ?? 'Provider category',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: palette.muted,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _MiniBadge(label: '${category.slaHours}h SLA'),
                          _MiniBadge(
                            label: _titleCase(
                              rule?.assignmentStrategy ?? 'least_busy',
                            ),
                          ),
                          _MiniBadge(
                            label: category.active ? 'Active' : 'Inactive',
                          ),
                          _MiniBadge(
                            label:
                                '${rule?.approvalLevels.length ?? 0} levels',
                          ),
                        ],
                      ),
                      if ((rule?.approvalLevels ?? const []).isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          rule!.approvalLevels
                              .map(
                                (level) =>
                                    level['name']?.toString() ??
                                    level['role']?.toString() ??
                                    'Level',
                              )
                              .join(' → '),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: palette.muted,
                          ),
                        ),
                      ],
                      if (rule != null) ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () => onEdit(category, rule),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Configure'),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _ReportsPane extends StatelessWidget {
  const _ReportsPane({
    required this.state,
    required this.palette,
    required this.onExport,
  });

  final ApprovalManagementState state;
  final _Palette palette;
  final ValueChanged<String> onExport;

  @override
  Widget build(BuildContext context) {
    final summary =
        state.report['summary'] as Map<String, dynamic>? ?? const {};
    final sla =
        state.report['slaCompliance'] as Map<String, dynamic>? ?? const {};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PaneHeader(
          palette: palette,
          title: 'Reports',
          subtitle:
              'Daily, weekly, monthly, yearly approval reporting and export readiness',
          trailing: Wrap(
            spacing: 8,
            children: ['csv', 'excel', 'pdf']
                .map(
                  (format) => OutlinedButton.icon(
                    onPressed: () => onExport(format),
                    icon: const Icon(Icons.ios_share_outlined),
                    label: Text(format.toUpperCase()),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth >= 760
                ? (constraints.maxWidth - 14) / 2
                : constraints.maxWidth;
            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                _Panel(
                  palette: palette,
                  width: width,
                  title: 'Approval report',
                  child: Column(
                    children: [
                      _ReportRow('Pending', '${summary['pending'] ?? 0}'),
                      _ReportRow('Approved', '${summary['approved'] ?? 0}'),
                      _ReportRow('Rejected', '${summary['rejected'] ?? 0}'),
                      _ReportRow(
                        'Average approval time',
                        _duration(
                          _asInt(summary['averageApprovalTimeMinutes']),
                        ),
                      ),
                    ],
                  ),
                ),
                _Panel(
                  palette: palette,
                  width: width,
                  title: 'SLA compliance',
                  child: Column(
                    children: [
                      _ReportRow('Open requests', '${sla['totalOpen'] ?? 0}'),
                      _ReportRow('Breached', '${sla['breached'] ?? 0}'),
                      _ReportRow(
                        'Compliance',
                        _compliance(
                          _asInt(sla['totalOpen']),
                          _asInt(sla['breached']),
                        ),
                      ),
                      _ReportRow(
                        'Generated',
                        _dateTime(_dateAny(state.report['generatedAt'])),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _PaneHeader extends StatelessWidget {
  const _PaneHeader({
    required this.palette,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final _Palette palette;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 720;
        final text = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.headlineSmall.copyWith(
                color: palette.text,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTextStyles.bodyMedium.copyWith(color: palette.muted),
            ),
          ],
        );
        if (trailing == null) return text;
        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [text, const SizedBox(height: 12), trailing!],
          );
        }
        return Row(
          children: [
            Expanded(child: text),
            const SizedBox(width: 12),
            trailing!,
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.palette,
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
    required this.tone,
    this.onTap,
  });

  final _Palette palette;
  final double width;
  final IconData icon;
  final String label;
  final String value;
  final Color tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: _Panel(
            palette: palette,
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: tone.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: tone),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value,
                        style: AppTextStyles.titleLarge.copyWith(
                          color: palette.text,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        label,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: palette.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: palette.muted,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.palette,
    required this.child,
    this.title,
    this.width,
  });

  final _Palette palette;
  final Widget child;
  final String? title;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: AppTextStyles.titleMedium.copyWith(
                color: palette.text,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
    if (width == null) return content;
    return SizedBox(width: width, child: content);
  }
}

class _RecentRequestsList extends StatelessWidget {
  const _RecentRequestsList({required this.palette, required this.requests});

  final _Palette palette;
  final List<ApprovalRequestModel> requests;

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return _EmptyState(
        icon: Icons.inbox_outlined,
        title: 'No recent requests',
        subtitle: 'Provider submissions will appear here.',
        palette: palette,
      );
    }
    return Column(
      children: requests.map((request) {
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(request.provider.name),
          subtitle: Text(
            '${_titleCase(request.providerCategory)} · ${_date(request.updatedAt)}',
          ),
          trailing: _StatusPill(status: request.status),
        );
      }).toList(),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.palette,
    required this.onTap,
    required this.onAssign,
    required this.onAction,
    required this.canAssign,
  });

  final ApprovalRequestModel request;
  final _Palette palette;
  final VoidCallback onTap;
  final VoidCallback onAssign;
  final ValueChanged<String> onAction;
  final bool canAssign;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.border),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.provider.name,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: palette.text,
                    ),
                  ),
                ),
                _StatusPill(status: request.status),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MiniBadge(label: _titleCase(request.providerCategory)),
                _MiniBadge(label: request.currentAssigneeName ?? 'Unassigned'),
                _SlaPill(request: request),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (canAssign)
                  TextButton.icon(
                    onPressed: onAssign,
                    icon: const Icon(Icons.swap_horiz_rounded),
                    label: const Text('Assign'),
                  ),
                _ActionMenu(onSelected: onAction),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionMenu extends StatelessWidget {
  const _ActionMenu({required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Approval actions',
      icon: const Icon(Icons.more_horiz_rounded),
      onSelected: onSelected,
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: 'approve',
          child: Text('Open KYC & final approve'),
        ),
        PopupMenuItem(value: 'reject', child: Text('Reject')),
        PopupMenuItem(
          value: 'request_documents',
          child: Text('Request documents'),
        ),
        PopupMenuItem(value: 'on_hold', child: Text('Put on hold')),
        PopupMenuItem(value: 'escalate', child: Text('Escalate')),
        PopupMenuItem(value: 'add_note', child: Text('Add internal note')),
      ],
    );
  }
}

class _FilterMenu extends StatelessWidget {
  const _FilterMenu({
    required this.label,
    required this.value,
    required this.values,
    required this.onSelected,
    this.labels = const {},
  });

  final String label;
  final String? value;
  final List<String> values;
  final Map<String, String> labels;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String?>(
      tooltip: label,
      onSelected: onSelected,
      itemBuilder: (_) => [
        const PopupMenuItem<String?>(value: null, child: Text('All')),
        ...values.map(
          (item) => PopupMenuItem<String?>(
            value: item,
            child: Text(labels[item] ?? _titleCase(item)),
          ),
        ),
      ],
      child: InputChip(
        avatar: const Icon(Icons.filter_list_rounded, size: 18),
        label: Text(
          value == null ? label : labels[value] ?? _titleCase(value!),
        ),
        onPressed: null,
      ),
    );
  }
}

class _PriorityPill extends StatelessWidget {
  const _PriorityPill({required this.priority});

  final String priority;

  @override
  Widget build(BuildContext context) {
    final color = priority == 'urgent' || priority == 'high'
        ? AppColors.error
        : priority == 'low'
        ? AppColors.grey500
        : AppColors.primary;
    return _ColorPill(label: _titleCase(priority), color: color);
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'approved' || 'active' => AppColors.success,
      'rejected' || 'inactive' => AppColors.error,
      'needs_documents' || 'on_hold' => AppColors.warning,
      'escalated' => const Color(0xFF7C3AED),
      _ => AppColors.primary,
    };
    return _ColorPill(label: _titleCase(status), color: color);
  }
}

class _SlaPill extends StatelessWidget {
  const _SlaPill({required this.request});

  final ApprovalRequestModel request;

  @override
  Widget build(BuildContext context) {
    final color = switch (request.slaState) {
      'overdue' => AppColors.error,
      'near_deadline' => AppColors.warning,
      _ => AppColors.success,
    };
    final text = request.status == 'approved' || request.status == 'rejected'
        ? 'Complete'
        : request.remainingSlaMinutes < 0
        ? '${request.remainingSlaMinutes.abs()}m overdue'
        : _duration(request.remainingSlaMinutes);
    return _ColorPill(label: text, color: color);
  }
}

class _ColorPill extends StatelessWidget {
  const _ColorPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 28),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: AppTextStyles.labelSmall),
    );
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: AppTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.palette,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final _Palette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 42, color: palette.muted),
            const SizedBox(height: 10),
            Text(
              title,
              style: AppTextStyles.titleSmall.copyWith(color: palette.text),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTextStyles.bodySmall.copyWith(color: palette.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationsPane extends StatelessWidget {
  const _NotificationsPane({
    required this.state,
    required this.palette,
    required this.onMarkAll,
    required this.onOpen,
  });

  final ApprovalManagementState state;
  final _Palette palette;
  final Future<void> Function() onMarkAll;
  final ValueChanged<ApprovalNotificationModel> onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PaneHeader(
          palette: palette,
          title: 'Notifications',
          subtitle: 'Assignments, SLA alerts, escalations, and workflow events',
          trailing: OutlinedButton.icon(
            onPressed: state.unreadNotifications == 0 ? null : () => onMarkAll(),
            icon: const Icon(Icons.done_all_outlined),
            label: const Text('Mark all read'),
          ),
        ),
        const SizedBox(height: 14),
        _Panel(
          palette: palette,
          title: 'Inbox',
          child: state.notifications.isEmpty
              ? _EmptyState(
                  icon: Icons.notifications_none_rounded,
                  title: 'No notifications',
                  subtitle: 'Workflow alerts will appear here',
                  palette: palette,
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.notifications.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final notification = state.notifications[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        notification.isUnread
                            ? Icons.mark_email_unread_outlined
                            : Icons.mark_email_read_outlined,
                        color: notification.isUnread
                            ? AppColors.primary
                            : palette.muted,
                      ),
                      title: Text(
                        notification.title,
                        style: TextStyle(
                          fontWeight: notification.isUnread
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        '${notification.body}\n${_dateTime(notification.createdAt)}',
                      ),
                      isThreeLine: true,
                      onTap: () => onOpen(notification),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _RequestDetailsDialog extends StatelessWidget {
  const _RequestDetailsDialog({
    required this.request,
    required this.onOpenKyc,
  });

  final ApprovalRequestModel request;
  final VoidCallback onOpenKyc;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: AlertDialog(
        title: Text(request.provider.name),
        content: SizedBox(
          width: 760,
          height: 560,
          child: Column(
            children: [
              const TabBar(
                tabs: [
                  Tab(text: 'Overview'),
                  Tab(text: 'Provider data'),
                  Tab(text: 'Approval levels'),
                  Tab(text: 'Timeline'),
                  Tab(text: 'Assignments'),
                  Tab(text: 'Notes'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _DetailsOverview(request: request),
                    _ProviderDataView(data: request.providerDetails),
                    _MapListView(items: request.approvalLevels),
                    _TimelineView(events: request.timeline),
                    _MapListView(items: request.assignmentHistory),
                    _MapListView(items: request.internalNotes),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: onOpenKyc,
            icon: const Icon(Icons.verified_user_outlined),
            label: const Text('Open KYC review'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

class _DetailsOverview extends StatelessWidget {
  const _DetailsOverview({required this.request});

  final ApprovalRequestModel request;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 16),
      children: [
        _ReportRow('Provider ID', request.providerId),
        _ReportRow('Type', _titleCase(request.providerCategory)),
        _ReportRow('Email', request.provider.email ?? ''),
        _ReportRow('Phone', request.provider.phone ?? ''),
        _ReportRow('City', request.provider.city ?? ''),
        _ReportRow('State', request.provider.state ?? ''),
        _ReportRow('PIN code', request.provider.pincode ?? ''),
        _ReportRow('Status', _titleCase(request.status)),
        _ReportRow('Assignee', request.currentAssigneeName ?? 'Unassigned'),
        _ReportRow(
          'Registration date',
          _dateTime(request.provider.registrationDate),
        ),
        _ReportRow('SLA due', _dateTime(request.slaDueAt)),
        _ReportRow('Last remarks', request.lastRemarks ?? ''),
      ],
    );
  }
}

class _ProviderDataView extends StatelessWidget {
  const _ProviderDataView({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.where((entry) {
      final key = entry.key.toLowerCase();
      return !key.contains('password') &&
          !key.contains('token') &&
          !key.contains('hash');
    }).toList();
    if (entries.isEmpty) {
      return const Center(child: Text('No additional provider data'));
    }
    return ListView.separated(
      padding: const EdgeInsets.only(top: 16),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          title: Text(_titleCase(entry.key)),
          subtitle: SelectableText(_formatProviderValue(entry.value)),
        );
      },
    );
  }
}

class _TimelineView extends StatelessWidget {
  const _TimelineView({required this.events});

  final List<ApprovalTimelineEventModel> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const Center(child: Text('No timeline events'));
    return ListView.builder(
      padding: const EdgeInsets.only(top: 16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                  ),
                ),
                if (index < events.length - 1)
                  Container(width: 1, height: 58, color: AppColors.border),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _titleCase(event.action),
                      style: AppTextStyles.titleSmall,
                    ),
                    Text(
                      '${event.actorName ?? 'System'} · ${_dateTime(event.createdAt)}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (event.remarks?.isNotEmpty == true)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(event.remarks!),
                      ),
                    if (event.ip?.isNotEmpty == true)
                      Text(
                        '${event.ip} · ${event.device ?? ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MapListView extends StatelessWidget {
  const _MapListView({required this.items});

  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const Center(child: Text('No records'));
    return ListView.separated(
      padding: const EdgeInsets.only(top: 16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(),
      itemBuilder: (context, index) {
        final item = items[index];
        final title =
            item['toApproverName'] ??
            item['levelName'] ??
            item['action'] ??
            item['note'] ??
            item['remarks'] ??
            'Record';
        final actor = item['assignedBy'] ?? item['actor'];
        final actorName = actor is Map ? actor['name']?.toString() : null;
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(title.toString()),
          subtitle: Text(
            '${_titleCase(item['status']?.toString() ?? '')}'
            '${actorName == null ? '' : ' · $actorName'}'
            '${item['createdAt'] == null ? '' : ' · ${_dateTime(_dateAny(item['createdAt']))}'}\n'
            '${item['remarks'] ?? item['note'] ?? ''}',
          ),
          isThreeLine: true,
        );
      },
    );
  }
}

class _LineAreaChart extends StatelessWidget {
  const _LineAreaChart({required this.points, required this.color});

  final List<ChartPointModel> points;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const Center(child: Text('No data'));
    return CustomPaint(
      painter: _LineAreaPainter(points: points, color: color),
      child: const SizedBox.expand(),
    );
  }
}

class _LineAreaPainter extends CustomPainter {
  _LineAreaPainter({required this.points, required this.color});

  final List<ChartPointModel> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final maxValue = math.max(
      1,
      points.map((p) => p.value).reduce(math.max).toDouble(),
    );
    final path = Path();
    final fill = Path();
    for (var i = 0; i < points.length; i++) {
      final x = points.length == 1 ? 0.0 : i * size.width / (points.length - 1);
      final y =
          size.height - (points[i].value / maxValue) * (size.height - 24) - 12;
      if (i == 0) {
        path.moveTo(x, y);
        fill.moveTo(x, size.height);
        fill.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fill.lineTo(x, y);
      }
    }
    fill.lineTo(size.width, size.height);
    fill.close();
    canvas.drawPath(fill, Paint()..color = color.withValues(alpha: 0.10));
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _LineAreaPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.color != color;
  }
}

class _BarChart extends StatelessWidget {
  const _BarChart({
    required this.points,
    required this.color,
    this.showValues = false,
  });

  final List<ChartPointModel> points;
  final Color color;
  final bool showValues;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const Center(child: Text('No data'));
    final maxValue = math.max(
      1,
      points.map((p) => p.value).reduce(math.max).toDouble(),
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: points.map((point) {
        final heightFactor = point.value <= 0
            ? 0.0
            : (point.value / maxValue).clamp(0.08, 1.0).toDouble();
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (showValues)
                  Text(
                    '${point.value.round()}',
                    style: AppTextStyles.labelMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                if (showValues) const SizedBox(height: 4),
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      heightFactor: heightFactor == 0 ? 0.03 : heightFactor,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: point.value <= 0
                              ? color.withValues(alpha: 0.18)
                              : color.withValues(alpha: 0.82),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  point.label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ApproverStat {
  const _ApproverStat({
    required this.label,
    required this.value,
    required this.tone,
    required this.icon,
  });

  final String label;
  final int value;
  final Color tone;
  final IconData icon;
}

class _ApproverStatTile extends StatelessWidget {
  const _ApproverStatTile({required this.palette, required this.stat});

  final _Palette palette;
  final _ApproverStat stat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(stat.icon, size: 18, color: stat.tone),
          const SizedBox(height: 8),
          Text(
            '${stat.value}',
            style: AppTextStyles.titleLarge.copyWith(
              color: palette.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            stat.label,
            style: AppTextStyles.bodySmall.copyWith(color: palette.muted),
          ),
        ],
      ),
    );
  }
}

class _DonutChart extends StatelessWidget {
  const _DonutChart({required this.points});

  final List<ChartPointModel> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const Center(child: Text('No data'));
    return Row(
      children: [
        Expanded(
          child: CustomPaint(
            painter: _DonutPainter(points: points),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 140,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: points.map((point) {
              final color =
                  _chartColors[points.indexOf(point) % _chartColors.length];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(width: 8, height: 8, color: color),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${point.label} ${point.value}',
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelSmall,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.points});

  final List<ChartPointModel> points;

  @override
  void paint(Canvas canvas, Size size) {
    final total = points.fold<num>(0, (sum, point) => sum + point.value);
    final rect = Offset.zero & size;
    final stroke = math.min(size.width, size.height) * 0.18;
    var start = -math.pi / 2;
    for (var i = 0; i < points.length; i++) {
      final sweep = total == 0 ? 0.0 : (points[i].value / total) * math.pi * 2;
      canvas.drawArc(
        rect.deflate(stroke),
        start,
        sweep,
        false,
        Paint()
          ..color = _chartColors[i % _chartColors.length]
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}

class _SkeletonConsole extends StatelessWidget {
  const _SkeletonConsole({required this.palette});

  final _Palette palette;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Container(width: 280, height: 28, color: palette.border),
        const SizedBox(height: 18),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: List.generate(
            8,
            (_) => Container(
              width: 240,
              height: 98,
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: palette.border),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NavItem {
  const _NavItem(this.section, this.icon, this.label);

  final _ConsoleSection section;
  final IconData icon;
  final String label;
}

const _navItems = [
  _NavItem(
    _ConsoleSection.overview,
    Icons.dashboard_customize_outlined,
    'Overview',
  ),
  _NavItem(_ConsoleSection.requests, Icons.rule_folder_outlined, 'Requests'),
  _NavItem(
    _ConsoleSection.notifications,
    Icons.notifications_none_rounded,
    'Notifications',
  ),
  _NavItem(_ConsoleSection.approvers, Icons.people_alt_outlined, 'Approvers'),
  _NavItem(_ConsoleSection.performance, Icons.insights_outlined, 'Performance'),
  _NavItem(_ConsoleSection.audit, Icons.history_edu_outlined, 'Audit logs'),
  _NavItem(_ConsoleSection.config, Icons.tune_outlined, 'Rules'),
  _NavItem(_ConsoleSection.reports, Icons.file_download_outlined, 'Reports'),
];

/// Approver uses the same Requests → full KYC document review flow as admin.
const _approverNavItems = [
  _NavItem(
    _ConsoleSection.overview,
    Icons.dashboard_customize_outlined,
    'Overview',
  ),
  _NavItem(_ConsoleSection.requests, Icons.rule_folder_outlined, 'My requests'),
  _NavItem(
    _ConsoleSection.notifications,
    Icons.notifications_none_rounded,
    'Notifications',
  ),
];

const _chartColors = [
  AppColors.primary,
  Color(0xFF4568DC),
  Color(0xFFF59E0B),
  Color(0xFFEF4444),
  Color(0xFF7C3AED),
  Color(0xFF0EA5E9),
];

enum _OverviewMetric {
  totalProviders,
  approvedToday,
  pending,
  approved,
  rejectedToday,
  slaBreached,
  needDocuments,
  escalated,
  avgApprovalTime,
  onHold,
  approversOnline,
}

extension on _OverviewMetric {
  String get title => switch (this) {
    _OverviewMetric.totalProviders => 'Total providers',
    _OverviewMetric.approvedToday => 'Approved today',
    _OverviewMetric.pending => 'Pending',
    _OverviewMetric.approved => 'Approved',
    _OverviewMetric.rejectedToday => 'Rejected today',
    _OverviewMetric.slaBreached => 'Past deadline',
    _OverviewMetric.needDocuments => 'Need documents',
    _OverviewMetric.escalated => 'Escalated',
    _OverviewMetric.avgApprovalTime => 'Avg approval time',
    _OverviewMetric.onHold => 'On hold',
    _OverviewMetric.approversOnline => 'Approvers online',
  };

  /// Status sent to the API when opening this metric. Null means all statuses.
  String? get apiStatus => switch (this) {
    _OverviewMetric.pending => 'pending',
    _OverviewMetric.approved ||
    _OverviewMetric.approvedToday ||
    _OverviewMetric.avgApprovalTime =>
      'approved',
    _OverviewMetric.rejectedToday => 'rejected',
    _OverviewMetric.needDocuments => 'needs_documents',
    _OverviewMetric.escalated => 'escalated',
    _OverviewMetric.onHold => 'on_hold',
    _OverviewMetric.totalProviders ||
    _OverviewMetric.slaBreached ||
    _OverviewMetric.approversOnline =>
      null,
  };

  bool matches(ApprovalRequestModel request) {
    switch (this) {
      case _OverviewMetric.totalProviders:
        return true;
      case _OverviewMetric.pending:
        return request.status == 'pending';
      case _OverviewMetric.approved:
      case _OverviewMetric.avgApprovalTime:
        return request.status == 'approved';
      case _OverviewMetric.approvedToday:
        return request.status == 'approved' &&
            _isSameDay(request.completedAt ?? request.updatedAt);
      case _OverviewMetric.rejectedToday:
        return request.status == 'rejected' &&
            _isSameDay(request.completedAt ?? request.updatedAt);
      case _OverviewMetric.needDocuments:
        return request.status == 'needs_documents';
      case _OverviewMetric.escalated:
        return request.status == 'escalated';
      case _OverviewMetric.onHold:
        return request.status == 'on_hold';
      case _OverviewMetric.slaBreached:
        return request.slaState == 'overdue';
      case _OverviewMetric.approversOnline:
        return false;
    }
  }
}

bool _isSameDay(DateTime? value) {
  if (value == null) return false;
  final now = DateTime.now();
  final local = value.toLocal();
  return local.year == now.year &&
      local.month == now.month &&
      local.day == now.day;
}

int _categorySortOrder(String slug) {
  switch (slug.trim().toLowerCase().replaceAll('-', '_')) {
    case 'doctor_online':
      return 10;
    case 'doctor_home_visit':
      return 11;
    case 'doctor_hospital_visit':
      return 12;
    case 'doctor':
    case 'doctors':
      return 13;
    case 'nurse':
    case 'nurses':
    case 'nursing':
      return 20;
    case 'scan_center':
    case 'scan':
    case 'scans':
    case 'mri':
    case 'mri_center':
      return 30;
    case 'laboratory':
    case 'lab':
    case 'labs':
    case 'diagnostic_lab':
      return 40;
    case 'blood_bank':
    case 'bloodbank':
    case 'blood':
      return 50;
    case 'ambulance':
    case 'ambulances':
      return 60;
    default:
      return 100;
  }
}

IconData _categoryIcon(String slug) {
  switch (slug.trim().toLowerCase().replaceAll('-', '_')) {
    case 'doctor_online':
    case 'doctor':
    case 'doctors':
      return Icons.videocam_rounded;
    case 'doctor_home_visit':
      return Icons.home_rounded;
    case 'doctor_hospital_visit':
      return Icons.local_hospital_rounded;
    case 'nurse':
    case 'nurses':
    case 'nursing':
    case 'home_care':
      return Icons.health_and_safety_rounded;
    case 'laboratory':
    case 'lab':
    case 'labs':
    case 'diagnostic_lab':
    case 'pathology':
      return Icons.biotech_rounded;
    case 'scan_center':
    case 'scan':
    case 'scans':
    case 'mri':
    case 'mri_center':
    case 'imaging':
    case 'radiology':
      return Icons.radar_rounded;
    case 'ambulance':
    case 'ambulances':
      return Icons.local_shipping_rounded;
    case 'blood_bank':
    case 'bloodbank':
    case 'blood':
      return Icons.bloodtype_rounded;
    case 'hospital':
      return Icons.local_hospital_rounded;
    case 'pharmacy':
      return Icons.local_pharmacy_rounded;
    default:
      return Icons.business_center_outlined;
  }
}

Color _categoryTone(String slug, _Palette palette) {
  switch (slug.trim().toLowerCase().replaceAll('-', '_')) {
    case 'doctor_home_visit':
      return const Color(0xFF0EA5E9);
    case 'doctor_hospital_visit':
      return const Color(0xFF7C3AED);
    case 'nurse':
    case 'nurses':
    case 'nursing':
    case 'home_care':
      return palette.warning;
    case 'scan_center':
    case 'scan':
    case 'scans':
    case 'mri':
    case 'ambulance':
      return palette.danger;
    case 'laboratory':
    case 'lab':
    case 'labs':
      return const Color(0xFF4568DC);
    default:
      return palette.primary;
  }
}

String _friendlyCategoryLabel(String slug) {
  switch (slug.trim().toLowerCase().replaceAll('-', '_')) {
    case 'doctor_online':
      return 'Online doctors';
    case 'doctor_home_visit':
      return 'Home visit doctors';
    case 'doctor_hospital_visit':
      return 'Hospital visit doctors';
    case 'doctor':
    case 'doctors':
      return 'Doctors';
    case 'nurse':
    case 'nurses':
    case 'nursing':
      return 'Home nurses';
    case 'laboratory':
    case 'lab':
    case 'labs':
    case 'diagnostic_lab':
      return 'Labs';
    case 'scan_center':
    case 'scan':
    case 'scans':
    case 'mri':
    case 'mri_center':
      return 'Scan / MRI';
    case 'ambulance':
    case 'ambulances':
      return 'Ambulance';
    case 'blood_bank':
    case 'bloodbank':
    case 'blood':
      return 'Blood banks';
    case 'home_care':
      return 'Home care';
    default:
      return _titleCase(slug);
  }
}

String? _kycDetailPath(String providerType, String providerId) {
  if (providerId.isEmpty) return null;
  switch (providerType.trim().toLowerCase().replaceAll('-', '_')) {
    case 'doctor':
    case 'doctors':
      return '${AppConstants.routeAdminDoctorDetails}/$providerId';
    case 'nurse':
    case 'nurses':
    case 'nursing':
      return '${AppConstants.routeAdminNurseDetails}/$providerId';
    case 'ambulance':
    case 'ambulances':
    case 'ambulance_service':
      return '${AppConstants.routeAdminAmbulanceDetails}/$providerId';
    case 'blood_bank':
    case 'bloodbank':
    case 'blood':
    case 'blood_banks':
      return '${AppConstants.routeAdminBloodBankDetails}/$providerId';
    case 'laboratory':
    case 'lab':
    case 'labs':
    case 'diagnostic_lab':
    case 'pathology':
      return '${AppConstants.routeAdminLabDetails}/$providerId';
    case 'scan_center':
    case 'scan':
    case 'scans':
    case 'mri':
    case 'mri_center':
    case 'mri_scan':
    case 'imaging':
    case 'radiology':
      return '${AppConstants.routeAdminScanDetails}/$providerId';
    default:
      return null;
  }
}

/// Fallback chips if config API has not loaded yet.
const _fallbackApprovalCategories = <ProviderCategoryModel>[
  ProviderCategoryModel(
    slug: 'doctor',
    name: 'Doctor',
    active: true,
    slaHours: 24,
    sortOrder: 10,
  ),
  ProviderCategoryModel(
    slug: 'nurse',
    name: 'Nurse',
    active: true,
    slaHours: 18,
    sortOrder: 20,
  ),
  ProviderCategoryModel(
    slug: 'laboratory',
    name: 'Lab / Diagnostic Lab',
    active: true,
    slaHours: 12,
    sortOrder: 40,
  ),
  ProviderCategoryModel(
    slug: 'scan_center',
    name: 'Scan / MRI Center',
    active: true,
    slaHours: 12,
    sortOrder: 50,
  ),
  ProviderCategoryModel(
    slug: 'ambulance',
    name: 'Ambulance',
    active: true,
    slaHours: 8,
    sortOrder: 70,
  ),
  ProviderCategoryModel(
    slug: 'blood_bank',
    name: 'Blood Bank',
    active: true,
    slaHours: 12,
    sortOrder: 80,
  ),
  ProviderCategoryModel(
    slug: 'hospital',
    name: 'Hospital',
    active: true,
    slaHours: 48,
    sortOrder: 30,
  ),
  ProviderCategoryModel(
    slug: 'pharmacy',
    name: 'Pharmacy',
    active: true,
    slaHours: 12,
    sortOrder: 60,
  ),
  ProviderCategoryModel(
    slug: 'home_care',
    name: 'Home Care',
    active: true,
    slaHours: 18,
    sortOrder: 90,
  ),
  ProviderCategoryModel(
    slug: 'other',
    name: 'Other Categories',
    active: true,
    slaHours: 24,
    sortOrder: 120,
  ),
];

String _titleCase(String value) {
  return value
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String _date(DateTime? value) {
  if (value == null) return '-';
  return DateFormat('dd MMM').format(value);
}

String _dateTime(DateTime? value) {
  if (value == null) return '-';
  return DateFormat('dd MMM yyyy, hh:mm a').format(value);
}

DateTime? _dateAny(dynamic value) {
  if (value is DateTime) return value;
  if (value == null) return null;
  return DateTime.tryParse(value.toString())?.toLocal();
}

String _duration(int minutes) {
  if (minutes <= 0) return '0m';
  final hours = minutes ~/ 60;
  final mins = minutes % 60;
  if (hours <= 0) return '${mins}m';
  if (mins == 0) return '${hours}h';
  return '${hours}h ${mins}m';
}

String _actionTitle(String action) {
  return switch (action) {
    'approve' => 'Approve provider',
    'reject' => 'Reject provider',
    'request_documents' => 'Request additional documents',
    'on_hold' => 'Put provider on hold',
    'escalate' => 'Escalate to admin',
    'add_note' => 'Add internal note',
    _ => _titleCase(action),
  };
}

String _regionLabel(ApproverModel approver) {
  final region = approver.regions.firstOrNull;
  if (region == null) return 'All regions';
  final parts = [
    region.city,
    region.district,
    region.state,
    region.country,
    region.pincode,
  ].where((part) => part != null && part.trim().isNotEmpty).cast<String>();
  return parts.isEmpty ? 'All regions' : parts.join(', ');
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _compliance(int totalOpen, int breached) {
  if (totalOpen <= 0) return '100%';
  return '${(((totalOpen - breached) / totalOpen) * 100).round()}%';
}

String _formatProviderValue(dynamic value) {
  if (value == null) return '-';
  if (value is Map || value is List) {
    try {
      return const JsonEncoder.withIndent('  ').convert(value);
    } catch (_) {
      return value.toString();
    }
  }
  return value.toString();
}

class _ApproverDialogField extends StatefulWidget {
  const _ApproverDialogField({
    required this.controller,
    required this.label,
    this.obscure = false,
    this.requiredField = false,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final bool obscure;
  final bool requiredField;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;

  @override
  State<_ApproverDialogField> createState() => _ApproverDialogFieldState();
}

class _ApproverDialogFieldState extends State<_ApproverDialogField> {
  late bool _hidden;

  @override
  void initState() {
    super.initState();
    _hidden = widget.obscure;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: CaretOnTapTextFormField(
        controller: widget.controller,
        obscureText: widget.obscure && _hidden,
        keyboardType: widget.keyboardType,
        inputFormatters: widget.inputFormatters,
        textCapitalization: widget.textCapitalization,
        validator: widget.validator,
        decoration: InputDecoration(
          labelText: widget.requiredField ? '${widget.label} *' : widget.label,
          suffixIcon: widget.obscure
              ? IconButton(
                  tooltip: _hidden ? 'Show password' : 'Hide password',
                  icon: Icon(
                    _hidden
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(() => _hidden = !_hidden),
                )
              : null,
        ),
      ),
    );
  }
}
