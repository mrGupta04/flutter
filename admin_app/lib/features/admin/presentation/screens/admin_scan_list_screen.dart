import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/shimmer_widgets.dart';
import '../../provider/admin_scan_provider.dart';

class AdminScanListScreen extends ConsumerStatefulWidget {
  const AdminScanListScreen({super.key});

  @override
  ConsumerState<AdminScanListScreen> createState() => _AdminScanListScreenState();
}

class _AdminScanListScreenState extends ConsumerState<AdminScanListScreen> {
  String? _statusFilter = 'awaiting_review';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(adminScanCentersListProvider.notifier)
          .fetchScanCenters(status: _statusFilter);
    });
  }

  void _applyFilter(String? status) {
    setState(() => _statusFilter = status);
    ref.read(adminScanCentersListProvider.notifier).filterByStatus(status);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminScanCentersListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Scan center applications'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Needs review',
                  selected: _statusFilter == 'awaiting_review',
                  onTap: () => _applyFilter('awaiting_review'),
                ),
                _FilterChip(
                  label: 'Approved',
                  selected: _statusFilter == 'verified',
                  onTap: () => _applyFilter('verified'),
                ),
                _FilterChip(
                  label: 'Rejected',
                  selected: _statusFilter == 'rejected',
                  onTap: () => _applyFilter('rejected'),
                ),
                _FilterChip(
                  label: 'Suspended',
                  selected: _statusFilter == 'suspended',
                  onTap: () => _applyFilter('suspended'),
                ),
              ],
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
                    : state.centers.isEmpty
                        ? const Center(child: Text('No scan center applications'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: state.centers.length,
                            itemBuilder: (context, index) {
                              final center = state.centers[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        AppColors.primary.withValues(alpha: 0.12),
                                    child: const Icon(
                                      Icons.radar_rounded,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  title: Text(center.centerName ?? 'Scan center'),
                                  subtitle: Text(
                                    '${center.city ?? ''} · ${center.offeredScans?.length ?? 0} scans',
                                  ),
                                  trailing:
                                      const Icon(Icons.chevron_right_rounded),
                                  onTap: () => context.push(
                                    '${AppConstants.routeAdminScanDetails}/${center.id}',
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
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
