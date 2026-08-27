import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/safe_navigation.dart';
import '../../../../core/widgets/custom_widgets.dart' as custom;
import '../../../../data/models/doctor_model.dart';
import '../../../../shared/widgets/admin_adaptive_shell.dart';
import '../../../../shared/widgets/doctor_listing_card.dart';
import '../../../../shared/widgets/shimmer_widgets.dart';
import '../../provider/admin_provider.dart';

/// Admin screen listing doctor applications pending approval.
///
/// [serviceType] filters by offered consultation mode:
/// `online` | `home_visit` | `hospital_visit`
class AdminDoctorListScreen extends ConsumerStatefulWidget {
  const AdminDoctorListScreen({super.key, this.serviceType});

  final String? serviceType;

  @override
  ConsumerState<AdminDoctorListScreen> createState() =>
      _AdminDoctorListScreenState();
}

class _AdminDoctorListScreenState extends ConsumerState<AdminDoctorListScreen> {
  String? _statusFilter = 'awaiting_review';

  String get _title {
    switch (widget.serviceType) {
      case 'online':
        return 'Online doctor applications';
      case 'home_visit':
        return 'Home visit doctor applications';
      case 'hospital_visit':
        return 'Hospital visit doctor applications';
      default:
        return 'Doctor applications';
    }
  }

  List<DoctorModel> _byService(List<DoctorModel> doctors) {
    switch (widget.serviceType) {
      case 'online':
        return doctors.where((d) => d.offersOnlineConsult).toList();
      case 'home_visit':
        return doctors.where((d) => d.offersBookHome).toList();
      case 'hospital_visit':
        return doctors.where((d) => d.offersVisitSite).toList();
      default:
        return doctors;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  void _loadDoctors() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminDoctorsListProvider.notifier).fetchDoctors(
            status: _statusFilter,
          );
    });
  }

  void _applyFilter(String? status) {
    setState(() => _statusFilter = status);
    ref.read(adminDoctorsListProvider.notifier).filterByStatus(status);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminDoctorsListProvider);

    return AdminAdaptiveShell(
      section: AdminNavSection.providers,
      constrainBody: false,
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: ResponsivePage(
        padding: ResponsiveUtils.pagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Under review',
                    selected: _statusFilter == 'awaiting_review',
                    onTap: () => _applyFilter('awaiting_review'),
                  ),
                  _FilterChip(
                    label: 'Verified',
                    selected: _statusFilter == 'verified',
                    onTap: () => _applyFilter('verified'),
                  ),
                  _FilterChip(
                    label: 'Rejected',
                    selected: _statusFilter == 'rejected',
                    onTap: () => _applyFilter('rejected'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _statusFilter == 'verified'
                    ? 'Verified doctors live on the user app'
                    : _statusFilter == 'rejected'
                        ? 'Rejected applications'
                        : 'Review each document, then verify and publish on the user app',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Expanded(child: _buildBody(state)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AdminDoctorsListState state) {
    if (state.isLoading) {
      return const ShimmerLoadingList();
    }

    if (state.error != null) {
      return custom.AppErrorWidget(
        message: state.error!,
        onRetry: () => ref.read(adminDoctorsListProvider.notifier).fetchDoctors(
              status: _statusFilter,
            ),
      );
    }

    final doctors = _byService(state.doctors);

    if (doctors.isEmpty) {
      return custom.EmptyStateWidget(
        icon: Icons.inbox_outlined,
        title: 'No doctors found',
        message: _statusFilter == 'awaiting_review'
            ? 'New registrations for this service will appear here.'
            : 'No applications match this filter.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(adminDoctorsListProvider.notifier).fetchDoctors(
            status: _statusFilter,
          ),
      child: ResponsiveCardList(
        padding: const EdgeInsets.only(bottom: 24),
        spacing: kDoctorCardSpacing,
        desktopColumns: 2,
        largeDesktopColumns: 2,
        itemCount: doctors.length,
        itemBuilder: (context, index) {
          final doctor = doctors[index];
          return _DoctorListTile(
            doctor: doctor,
            showBottomDivider: false,
            onTap: () async {
              final id = doctor.id;
              if (id == null || id.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'This application has no profile id. Cannot open details.',
                    ),
                  ),
                );
                return;
              }
              await SafeNavigation.push(
                context,
                '${AppConstants.routeAdminDoctorDetails}/$id',
                extra: doctor,
              );
              if (mounted) {
                ref.read(adminDoctorsListProvider.notifier).fetchDoctors(
                      status: _statusFilter,
                    );
              }
            },
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
            color: selected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
        selected: selected,
        showCheckmark: false,
        selectedColor: AppColors.primaryLight,
        backgroundColor: AppColors.white,
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _DoctorListTile extends StatelessWidget {
  const _DoctorListTile({
    required this.doctor,
    required this.onTap,
    this.showBottomDivider = true,
  });

  final DoctorModel doctor;
  final VoidCallback onTap;
  final bool showBottomDivider;

  bool get _canVerify {
    final status = doctor.verificationStatus;
    return status == VerificationStatus.pending ||
        status == VerificationStatus.underReview;
  }

  @override
  Widget build(BuildContext context) {
    final status = _statusLabel(doctor.verificationStatus);
    final statusColor = _statusColor(doctor.verificationStatus);

    return DoctorListingCard(
      doctor: doctor,
      onTap: onTap,
      onAdminActionTap: onTap,
      actionStyle: DoctorCardActionStyle.admin,
      showVerifiedIcon: false,
      showBottomDivider: showBottomDivider,
      showActionButtons: _canVerify,
      adminActionLabel: 'Verify doctor',
      adminActionSubtitle: 'Review & publish on user app',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (doctor.isProfileDisabled)
            const _StatusChip(label: 'Disabled', color: AppColors.grey600),
          _StatusChip(label: status, color: statusColor),
        ],
      ),
    );
  }

  String _statusLabel(VerificationStatus? status) {
    switch (status) {
      case VerificationStatus.verified:
        return 'Approved';
      case VerificationStatus.rejected:
        return 'Rejected';
      case VerificationStatus.underReview:
      case VerificationStatus.pending:
      default:
        return 'Needs review';
    }
  }

  Color _statusColor(VerificationStatus? status) {
    switch (status) {
      case VerificationStatus.verified:
        return AppColors.success;
      case VerificationStatus.rejected:
        return AppColors.error;
      case VerificationStatus.underReview:
      case VerificationStatus.pending:
      default:
        return AppColors.warning;
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}
