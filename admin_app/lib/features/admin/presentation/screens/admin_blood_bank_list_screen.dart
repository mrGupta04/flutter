import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/blood_bank_model.dart';
import '../../../../data/models/doctor_model.dart';
import '../../../../shared/widgets/shimmer_widgets.dart';
import '../../provider/admin_blood_bank_provider.dart';

class AdminBloodBankListScreen extends ConsumerStatefulWidget {
  const AdminBloodBankListScreen({super.key});

  @override
  ConsumerState<AdminBloodBankListScreen> createState() =>
      _AdminBloodBankListScreenState();
}

class _AdminBloodBankListScreenState
    extends ConsumerState<AdminBloodBankListScreen> {
  String? _statusFilter = 'awaiting_review';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminBloodBanksListProvider.notifier).fetchBloodBanks(
            status: _statusFilter,
          );
    });
  }

  void _applyFilter(String? status) {
    setState(() => _statusFilter = status);
    ref.read(adminBloodBanksListProvider.notifier).filterByStatus(status);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminBloodBanksListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Blood bank applications'),
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
                    : state.bloodBanks.isEmpty
                        ? const Center(child: Text('No blood bank applications'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: state.bloodBanks.length,
                            itemBuilder: (context, index) {
                              final item = state.bloodBanks[index];
                              return _BloodBankTile(bloodBank: item);
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _BloodBankTile extends StatelessWidget {
  const _BloodBankTile({required this.bloodBank});

  final BloodBankModel bloodBank;

  String get _statusLabel {
    switch (bloodBank.verificationStatus) {
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
          backgroundColor: AppColors.secondary.withValues(alpha: 0.15),
          child: const Icon(Icons.bloodtype_rounded, color: AppColors.secondary),
        ),
        title: Text(bloodBank.institutionName ?? 'Blood bank'),
        subtitle: Text('${bloodBank.city ?? ''} · $_statusLabel'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => context.push(
          '${AppConstants.routeAdminBloodBankDetails}/${bloodBank.id}',
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
