import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/repositories/admin_repository.dart';

class AdminBloodAnalyticsScreen extends StatefulWidget {
  const AdminBloodAnalyticsScreen({super.key});

  @override
  State<AdminBloodAnalyticsScreen> createState() => _AdminBloodAnalyticsScreenState();
}

class _AdminBloodAnalyticsScreenState extends State<AdminBloodAnalyticsScreen> {
  final _repo = AdminRepository();
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await _repo.getBloodAnalytics();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = res.success ? null : res.error;
      _data = res.data;
    });
  }

  @override
  Widget build(BuildContext context) {
    final totals = (_data?['totals'] as Map?)?.cast<String, dynamic>() ?? {};
    final charts = (_data?['charts'] as Map?)?.cast<String, dynamic>() ?? {};

    return Scaffold(
      appBar: AppBar(title: const Text('Blood bank analytics')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? AppErrorWidget(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _metric('Total banks', totals['totalBloodBanks']),
                          _metric('Verified', totals['verifiedBloodBanks']),
                          _metric('Pending', totals['pendingVerification']),
                          _metric('Active', totals['activeBloodBanks']),
                          _metric('Inventory', totals['totalInventory']),
                          _metric('Emergencies', totals['emergencyRequests']),
                          _metric('Pending requests', totals['pendingRequests']),
                          _metric('Completed', totals['completedRequests']),
                          _metric('Donors', totals['registeredDonors']),
                          _metric('Active donors', totals['activeDonors']),
                          _metric('Completion', '${totals['completionRate'] ?? 0}%'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text('Blood group demand', style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      ...((charts['bloodGroupDemand'] as List?) ?? const []).map((row) {
                        final item = Map<String, dynamic>.from(row as Map);
                        return ListTile(
                          dense: true,
                          title: Text('${item['_id'] ?? ''}'),
                          trailing: Text('${item['count'] ?? 0}'),
                        );
                      }),
                      const SizedBox(height: 12),
                      Text('Availability', style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w800)),
                      ...((charts['bloodGroupAvailability'] as List?) ?? const []).map((row) {
                        final item = Map<String, dynamic>.from(row as Map);
                        return ListTile(
                          dense: true,
                          title: Text('${item['_id'] ?? ''}'),
                          trailing: Text('${item['available'] ?? 0} units'),
                        );
                      }),
                      const SizedBox(height: 12),
                      Text(
                        'Critical groups: ${((totals['criticalBloodGroups'] as List?) ?? const []).join(', ')}',
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _metric(String label, Object? value) {
    return SizedBox(
      width: 150,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.labelSmall),
              const SizedBox(height: 6),
              Text('$value', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}
