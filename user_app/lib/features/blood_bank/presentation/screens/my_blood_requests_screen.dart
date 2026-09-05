import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/models/blood_bank_model.dart';
import '../../../../data/repositories/blood_bank_repository.dart';

class MyBloodRequestsScreen extends StatefulWidget {
  const MyBloodRequestsScreen({super.key});

  @override
  State<MyBloodRequestsScreen> createState() => _MyBloodRequestsScreenState();
}

class _MyBloodRequestsScreenState extends State<MyBloodRequestsScreen> {
  final _repo = BloodBankRepository();
  bool _loading = true;
  String? _error;
  List<BloodOrderModel> _orders = const [];
  List<Map<String, dynamic>> _emergencies = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final orders = await _repo.listMyRequests();
    final emergencies = await _repo.listMyEmergencyRequests();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (!orders.success && !emergencies.success) {
        _error = orders.error ?? emergencies.error ?? 'Unable to load requests';
      }
      _orders = orders.data ?? const [];
      _emergencies = emergencies.data ?? const [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Blood Requests')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? AppErrorWidget(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    children: [
                      if (_orders.isEmpty && _emergencies.isEmpty)
                        const _EmptyRequests()
                      else ...[
                        if (_emergencies.isNotEmpty) ...[
                          Text('Emergency', style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          ..._emergencies.map((e) => _EmergencyCard(request: e)),
                          const SizedBox(height: 16),
                        ],
                        ..._orders.map(
                          (order) => Card(
                            child: ListTile(
                              title: Text('${order.bloodGroup ?? '-'} · ${order.componentType ?? ''}'),
                              subtitle: Text(
                                '${order.units} units · ${order.hospitalName ?? 'Hospital'}\n'
                                '${order.status.replaceAll('_', ' ')}',
                              ),
                              isThreeLine: true,
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: () => context.push(
                                '${AppConstants.routeBloodRequestDetail}/${order.id}',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }
}

class _EmergencyCard extends StatelessWidget {
  const _EmergencyCard({required this.request});

  final Map<String, dynamic> request;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFFEBEE),
      child: ListTile(
        leading: const Icon(Icons.emergency_rounded, color: Color(0xFFB71C1C)),
        title: Text('${request['bloodGroup'] ?? ''} · ${request['units'] ?? ''} units'),
        subtitle: Text(
          '${request['hospitalName'] ?? 'Hospital'}\n${request['status'] ?? ''}'.replaceAll('_', ' '),
        ),
        isThreeLine: true,
      ),
    );
  }
}

class _EmptyRequests extends StatelessWidget {
  const _EmptyRequests();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        children: [
          const Icon(Icons.bloodtype_outlined, size: 48, color: AppColors.grey400),
          const SizedBox(height: 12),
          const Text('No active blood requests.'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.push(AppConstants.routeEmergencyBloodRequest),
            child: const Text('Create Emergency Request'),
          ),
        ],
      ),
    );
  }
}
