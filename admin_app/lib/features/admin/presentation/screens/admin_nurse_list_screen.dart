import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/doctor_model.dart';
import '../../../../data/models/nurse_model.dart';
import '../../../../shared/widgets/shimmer_widgets.dart';
import '../../provider/admin_nurse_provider.dart';

class AdminNurseListScreen extends ConsumerStatefulWidget {
  const AdminNurseListScreen({super.key});

  @override
  ConsumerState<AdminNurseListScreen> createState() =>
      _AdminNurseListScreenState();
}

class _AdminNurseListScreenState extends ConsumerState<AdminNurseListScreen> {
  String? _statusFilter = 'awaiting_review';

  @override
  void initState() {
    super.initState();
    _loadNurses();
  }

  void _loadNurses() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminNursesListProvider.notifier).fetchNurses(
            status: _statusFilter,
          );
    });
  }

  void _applyFilter(String? status) {
    setState(() => _statusFilter = status);
    ref.read(adminNursesListProvider.notifier).filterByStatus(status);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminNursesListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Nurse applications'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              _statusFilter == 'verified'
                  ? 'Nurses live on the user app'
                  : _statusFilter == 'rejected'
                      ? 'Rejected applications'
                      : 'Open an application to verify and publish on the user app',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: state.isLoading
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: ShimmerLoadingList(),
                  )
                : state.error != null
                    ? Center(child: Text(state.error!))
                    : state.nurses.isEmpty
                        ? Center(
                            child: Text(
                              _statusFilter == 'awaiting_review'
                                  ? 'No nurse applications waiting for review'
                                  : 'No nurse applications',
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: state.nurses.length,
                            itemBuilder: (context, index) {
                              final nurse = state.nurses[index];
                              return _NurseTile(nurse: nurse);
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _NurseTile extends StatelessWidget {
  const _NurseTile({required this.nurse});

  final NurseModel nurse;

  bool get _canVerify {
    final status = nurse.verificationStatus;
    return status == VerificationStatus.pending ||
        status == VerificationStatus.underReview;
  }

  String get _statusLabel {
    switch (nurse.verificationStatus) {
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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.secondary.withValues(alpha: 0.15),
          child: const Icon(Icons.health_and_safety_rounded),
        ),
        title: Text(nurse.displayName),
        subtitle: Text(
          '${nurse.qualification ?? ''} · ${nurse.city ?? ''}\n$_statusLabel',
        ),
        isThreeLine: true,
        trailing: _canVerify
            ? const Chip(
                label: Text('Verify'),
                visualDensity: VisualDensity.compact,
              )
            : const Icon(Icons.chevron_right_rounded),
        onTap: () => context.push(
          '${AppConstants.routeAdminNurseDetails}/${nurse.id}',
        ),
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
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}
