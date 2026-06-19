import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/ambulance_model.dart';
import '../../../../data/models/doctor_model.dart';
import '../../../../shared/widgets/shimmer_widgets.dart';
import '../../provider/admin_ambulance_provider.dart';

class AdminAmbulanceListScreen extends ConsumerStatefulWidget {
  const AdminAmbulanceListScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminAmbulancesListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ambulance applications'),
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
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: state.ambulances.length,
                            itemBuilder: (context, index) {
                              final item = state.ambulances[index];
                              return _AmbulanceTile(ambulance: item);
                            },
                          ),
          ),
        ],
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
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
          child: const Icon(Icons.local_shipping_rounded),
        ),
        title: Text(ambulance.serviceName ?? 'Ambulance'),
        subtitle: Text('${ambulance.city ?? ''} · $_statusLabel'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => context.push(
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
