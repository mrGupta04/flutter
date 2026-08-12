import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/safe_navigation.dart';
import '../../../../data/models/ambulance_model.dart';
import '../../../../data/models/doctor_model.dart';
import '../../../../shared/widgets/admin_adaptive_shell.dart';
import '../../../../shared/widgets/shimmer_widgets.dart';
import '../../provider/admin_ambulance_provider.dart';

class AdminAmbulanceListScreen extends ConsumerStatefulWidget {
  const AdminAmbulanceListScreen({
    super.key,
    this.embedded = false,
    this.scrollHeader,
  });

  /// When true, renders list content only (no Scaffold / AppBar).
  final bool embedded;

  /// Optional hub header that scrolls away with the list (not sticky).
  final Widget? scrollHeader;

  @override
  ConsumerState<AdminAmbulanceListScreen> createState() =>
      _AdminAmbulanceListScreenState();
}

class _AdminAmbulanceListScreenState
    extends ConsumerState<AdminAmbulanceListScreen> {
  String? _statusFilter = 'awaiting_review';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminAmbulancesListProvider.notifier).fetchAmbulances(
            status: _statusFilter,
          );
    });
  }

  void _applyFilter(String? status) {
    setState(() => _statusFilter = status);
    ref.read(adminAmbulancesListProvider.notifier).filterByStatus(status);
  }

  Widget _statusFilters({required bool embedded}) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: embedded
          ? const EdgeInsets.fromLTRB(16, 8, 16, 8)
          : const EdgeInsets.only(bottom: 8),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminAmbulancesListProvider);

    if (widget.embedded) {
      return ColoredBox(
        color: AppColors.background,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (widget.scrollHeader != null)
              SliverToBoxAdapter(child: widget.scrollHeader),
            SliverToBoxAdapter(child: _statusFilters(embedded: true)),
            if (state.isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: ShimmerLoadingList(),
                ),
              )
            else if (state.error != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text(state.error!)),
              )
            else if (state.ambulances.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text('No ambulance applications')),
              )
            else
              ResponsiveCardSliver(
                padding: const EdgeInsets.all(16),
                itemCount: state.ambulances.length,
                itemBuilder: (context, index) {
                  return _AmbulanceTile(ambulance: state.ambulances[index]);
                },
              ),
          ],
        ),
      );
    }

    final content = Column(
      children: [
        _statusFilters(embedded: false),
        Expanded(
          child: state.isLoading
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: ShimmerLoadingList(),
                )
              : state.error != null
                  ? Center(child: Text(state.error!))
                  : state.ambulances.isEmpty
                      ? const Center(child: Text('No ambulance applications'))
                      : ResponsiveCardList(
                          padding: const EdgeInsets.only(bottom: 24),
                          desktopColumns: 2,
                          largeDesktopColumns: 2,
                          itemCount: state.ambulances.length,
                          itemBuilder: (context, index) {
                            return _AmbulanceTile(
                              ambulance: state.ambulances[index],
                            );
                          },
                        ),
        ),
      ],
    );

    return AdminAdaptiveShell(
      section: AdminNavSection.providers,
      constrainBody: false,
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ambulance applications'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: ResponsivePage(
        padding: ResponsiveUtils.pagePadding(context),
        child: content,
      ),
    );
  }
}

class _AmbulanceTile extends StatelessWidget {
  const _AmbulanceTile({required this.ambulance});

  final AmbulanceModel ambulance;

  String get _statusLabel {
    switch (ambulance.verificationStatus) {
      case VerificationStatus.verified:
        return 'Approved';
      case VerificationStatus.rejected:
        return 'Rejected';
      default:
        return 'Needs review';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
          child: const Icon(Icons.local_shipping_rounded),
        ),
        title: Text(ambulance.serviceName ?? 'Ambulance'),
        subtitle: Text('${ambulance.city ?? ''} · $_statusLabel'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => SafeNavigation.push(
          context,
          '${AppConstants.routeAdminAmbulanceDetails}/${ambulance.id}',
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
