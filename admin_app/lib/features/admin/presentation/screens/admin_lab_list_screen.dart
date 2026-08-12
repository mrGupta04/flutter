import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/safe_navigation.dart';
import '../../../../shared/widgets/admin_adaptive_shell.dart';
import '../../../../shared/widgets/shimmer_widgets.dart';
import '../../provider/admin_lab_provider.dart';

class AdminLabListScreen extends ConsumerStatefulWidget {
  const AdminLabListScreen({super.key});

  @override
  ConsumerState<AdminLabListScreen> createState() => _AdminLabListScreenState();
}

class _AdminLabListScreenState extends ConsumerState<AdminLabListScreen> {
  String? _statusFilter = 'awaiting_review';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminLabsListProvider.notifier).fetchLabs(status: _statusFilter);
    });
  }

  void _applyFilter(String? status) {
    setState(() => _statusFilter = status);
    ref.read(adminLabsListProvider.notifier).filterByStatus(status);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminLabsListProvider);

    return AdminAdaptiveShell(
      section: AdminNavSection.providers,
      constrainBody: false,
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Lab applications'),
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
                  ? const ShimmerLoadingList()
                  : state.error != null
                      ? Center(child: Text(state.error!))
                      : state.labs.isEmpty
                          ? const Center(child: Text('No lab applications'))
                          : ResponsiveCardList(
                              padding: const EdgeInsets.only(bottom: 24),
                              desktopColumns: 2,
                              largeDesktopColumns: 2,
                              itemCount: state.labs.length,
                              itemBuilder: (context, index) {
                                final lab = state.labs[index];
                                return Card(
                                  margin: EdgeInsets.zero,
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: AppColors.primary
                                          .withValues(alpha: 0.12),
                                      child: const Icon(
                                        Icons.biotech_rounded,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    title: Text(lab.labName ?? 'Lab'),
                                    subtitle: Text(
                                      '${lab.city ?? ''} · ${lab.offeredTests?.length ?? 0} tests',
                                    ),
                                    trailing: const Icon(
                                      Icons.chevron_right_rounded,
                                    ),
                                    onTap: () => SafeNavigation.push(
                                      context,
                                      '${AppConstants.routeAdminLabDetails}/${lab.id}',
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
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
