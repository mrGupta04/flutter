import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/models/blood_bank_model.dart';
import '../../../../data/repositories/blood_bank_repository.dart';
import '../../data/blood_bank_catalog.dart';

class MyBloodRequestsScreen extends StatefulWidget {
  const MyBloodRequestsScreen({super.key});

  @override
  State<MyBloodRequestsScreen> createState() => _MyBloodRequestsScreenState();
}

class _MyBloodRequestsScreenState extends State<MyBloodRequestsScreen>
    with SingleTickerProviderStateMixin {
  final _repo = BloodBankRepository();
  late final TabController _tabs;
  bool _loading = true;
  String? _error;
  List<BloodOrderModel> _orders = const [];
  List<Map<String, dynamic>> _emergencies = const [];

  static const _completed = {
    'completed',
    'collected',
    'delivered',
    'issued',
  };
  static const _cancelled = {
    'cancelled',
    'rejected',
    'expired',
  };

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
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

  List<BloodOrderModel> _ordersFor(String tab) {
    return _orders.where((order) {
      if (tab == 'completed') return _completed.contains(order.status);
      if (tab == 'cancelled') return _cancelled.contains(order.status);
      return !_completed.contains(order.status) && !_cancelled.contains(order.status);
    }).toList();
  }

  List<Map<String, dynamic>> _emergenciesFor(String tab) {
    return _emergencies.where((item) {
      final status = (item['status'] as String? ?? '').toLowerCase();
      if (tab == 'completed') return _completed.contains(status);
      if (tab == 'cancelled') return _cancelled.contains(status);
      return !_completed.contains(status) && !_cancelled.contains(status);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Blood Requests'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? AppErrorWidget(message: _error!, onRetry: _load)
              : TabBarView(
                  controller: _tabs,
                  children: [
                    _RequestList(
                      orders: _ordersFor('active'),
                      emergencies: _emergenciesFor('active'),
                      emptyTitle: "You don't have any blood requests yet.",
                      onRefresh: _load,
                    ),
                    _RequestList(
                      orders: _ordersFor('completed'),
                      emergencies: _emergenciesFor('completed'),
                      emptyTitle: 'No completed requests yet.',
                      onRefresh: _load,
                    ),
                    _RequestList(
                      orders: _ordersFor('cancelled'),
                      emergencies: _emergenciesFor('cancelled'),
                      emptyTitle: 'No cancelled or rejected requests.',
                      onRefresh: _load,
                    ),
                  ],
                ),
    );
  }
}

class _RequestList extends StatelessWidget {
  const _RequestList({
    required this.orders,
    required this.emergencies,
    required this.emptyTitle,
    required this.onRefresh,
  });

  final List<BloodOrderModel> orders;
  final List<Map<String, dynamic>> emergencies;
  final String emptyTitle;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty && emergencies.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          children: [
            const SizedBox(height: 72),
            Icon(Icons.bloodtype_outlined, size: 48, color: AppColors.grey400),
            const SizedBox(height: 12),
            Text(emptyTitle, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Center(
              child: FilledButton(
                onPressed: () => context.push(AppConstants.routeBloodBanks),
                child: const Text('Find Blood Near You'),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          ...emergencies.map((e) => _EmergencyCard(request: e)),
          ...orders.map(
            (order) => Card(
              child: ListTile(
                title: Text(
                  '${order.bloodGroup ?? '-'} · ${bloodComponentLabel(order.componentType)}',
                ),
                subtitle: Text(
                  '${order.id}\n'
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
          '${request['hospitalName'] ?? 'Hospital'}\n${'${request['status'] ?? ''}'.replaceAll('_', ' ')}',
        ),
        isThreeLine: true,
      ),
    );
  }
}
