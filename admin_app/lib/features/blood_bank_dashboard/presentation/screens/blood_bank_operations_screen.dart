import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/repositories/blood_bank_registration_repository.dart';
import '../../provider/blood_bank_dashboard_provider.dart';

class BloodBankOperationsScreen extends ConsumerStatefulWidget {
  const BloodBankOperationsScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  ConsumerState<BloodBankOperationsScreen> createState() =>
      _BloodBankOperationsScreenState();
}

class _BloodBankOperationsScreenState extends ConsumerState<BloodBankOperationsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _repo = BloodBankRegistrationRepository();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this, initialIndex: widget.initialTab);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blood bank operations'),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Inventory'),
            Tab(text: 'Requests'),
            Tab(text: 'Emergency'),
            Tab(text: 'Donors'),
            Tab(text: 'Staff'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _InventoryTab(repo: _repo),
          _RequestsTab(repo: _repo),
          _EmergencyTab(repo: _repo),
          _DonorsTab(repo: _repo),
          _StaffTab(repo: _repo),
        ],
      ),
    );
  }
}

class _InventoryTab extends StatefulWidget {
  const _InventoryTab({required this.repo});
  final BloodBankRegistrationRepository repo;

  @override
  State<_InventoryTab> createState() => _InventoryTabState();
}

class _InventoryTabState extends State<_InventoryTab> {
  List<Map<String, dynamic>> _items = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await widget.repo.getInventory();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _items = res.data ?? const [];
    });
  }

  Future<void> _addUnits(Map<String, dynamic> item) async {
    final units = await _askNumber(context, 'Add units for ${item['bloodGroup']}');
    if (units == null || units < 1) return;
    await widget.repo.addInventoryUnits({
      'bloodGroup': item['bloodGroup'],
      'componentType': item['componentType'] ?? 'whole_blood',
      'units': units,
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_items.isEmpty) {
      return const Center(child: Text('No inventory entries yet.'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          final available = (item['availableUnits'] as num?)?.toInt() ?? 0;
          final color = available <= 0
              ? AppColors.error
              : available <= 2
                  ? const Color(0xFFB71C1C)
                  : available <= 5
                      ? AppColors.warning
                      : AppColors.success;
          return Card(
            child: ListTile(
              title: Text('${item['bloodGroup']} · ${item['componentType'] ?? 'whole_blood'}'),
              subtitle: Text(
                'Available $available · Reserved ${item['reservedUnits'] ?? 0} · Expired ${item['expiredUnits'] ?? 0}',
              ),
              trailing: TextButton(
                onPressed: () => _addUnits(item),
                child: const Text('Add units'),
              ),
              leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.15), child: Text('${item['bloodGroup']}', style: TextStyle(color: color, fontSize: 11))),
            ),
          );
        },
      ),
    );
  }
}

class _RequestsTab extends ConsumerStatefulWidget {
  const _RequestsTab({required this.repo});
  final BloodBankRegistrationRepository repo;

  @override
  ConsumerState<_RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends ConsumerState<_RequestsTab> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final dashboard = ref.watch(bloodBankDashboardProvider);
    var orders = dashboard.orders;
    if (_filter != 'all') {
      orders = orders.where((o) => o['status'] == _filter).toList();
    }
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              for (final status in [
                'all',
                'pending',
                'accepted',
                'blood_reserved',
                'ready_for_collection',
                'completed',
                'rejected',
                'cancelled',
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(status.replaceAll('_', ' ')),
                    selected: _filter == status,
                    onSelected: (_) => setState(() => _filter = status),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: orders.isEmpty
              ? const Center(child: Text('No blood requests currently.'))
              : ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return Card(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${order['patientName'] ?? 'Patient'} · ${order['bloodGroup']} ${order['componentType']}',
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            Text('${order['units']} units · ${order['hospitalName'] ?? ''} · ${order['status']}'),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [
                                TextButton(
                                  onPressed: () => widget.repo.requestAction(order['id'] as String, 'accept'),
                                  child: const Text('Accept'),
                                ),
                                TextButton(
                                  onPressed: () => widget.repo.requestAction(
                                    order['id'] as String,
                                    'reject',
                                    data: {'rejectionReasonCode': 'blood_unavailable'},
                                  ),
                                  child: const Text('Reject'),
                                ),
                                TextButton(
                                  onPressed: () => widget.repo.requestAction(order['id'] as String, 'ready'),
                                  child: const Text('Mark ready'),
                                ),
                                TextButton(
                                  onPressed: () => widget.repo.requestAction(order['id'] as String, 'collected'),
                                  child: const Text('Collected'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _EmergencyTab extends ConsumerWidget {
  const _EmergencyTab({required this.repo});
  final BloodBankRegistrationRepository repo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(bloodBankDashboardProvider).emergencyRequests;
    if (items.isEmpty) {
      return const Center(child: Text('No emergency requests currently.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final req = items[index];
        return Card(
          color: const Color(0xFFFFEBEE),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('EMERGENCY', style: TextStyle(color: Color(0xFFB71C1C), fontWeight: FontWeight.w900)),
                Text('${req['bloodGroup']} · ${req['units']} units', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                Text('${req['hospitalName'] ?? 'Hospital'}'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () => repo.respondEmergency(req['id'] as String, action: 'accepted'),
                        child: const Text('ACCEPT'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => repo.respondEmergency(
                          req['id'] as String,
                          action: 'rejected',
                          notes: 'Blood unavailable',
                        ),
                        child: const Text('REJECT'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DonorsTab extends StatefulWidget {
  const _DonorsTab({required this.repo});
  final BloodBankRegistrationRepository repo;

  @override
  State<_DonorsTab> createState() => _DonorsTabState();
}

class _DonorsTabState extends State<_DonorsTab> {
  List<Map<String, dynamic>> _donors = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await widget.repo.getDonors();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _donors = res.data ?? const [];
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_donors.isEmpty) {
      return const Center(child: Text('No consented donor matches to show.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _donors.length,
      itemBuilder: (context, index) {
        final donor = _donors[index];
        return Card(
          child: ListTile(
            title: Text(donor['bloodGroup'] as String? ?? ''),
            subtitle: Text('${donor['city'] ?? 'Nearby'} · ${donor['eligibilityStatus'] ?? ''}'),
          ),
        );
      },
    );
  }
}

class _StaffTab extends StatefulWidget {
  const _StaffTab({required this.repo});
  final BloodBankRegistrationRepository repo;

  @override
  State<_StaffTab> createState() => _StaffTabState();
}

class _StaffTabState extends State<_StaffTab> {
  List<Map<String, dynamic>> _staff = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await widget.repo.getStaff();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _staff = res.data ?? const [];
    });
  }

  Future<void> _add() async {
    final name = TextEditingController();
    final email = TextEditingController();
    String role = 'staff';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add staff'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
            DropdownButtonFormField<String>(
              value: role,
              items: const [
                DropdownMenuItem(value: 'blood_bank_admin', child: Text('Blood Bank Admin')),
                DropdownMenuItem(value: 'inventory_manager', child: Text('Inventory Manager')),
                DropdownMenuItem(value: 'request_manager', child: Text('Request Manager')),
                DropdownMenuItem(value: 'staff', child: Text('Staff')),
              ],
              onChanged: (v) => role = v ?? 'staff',
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok == true && name.text.trim().isNotEmpty) {
      await widget.repo.saveStaff({
        'name': name.text.trim(),
        'email': email.text.trim(),
        'role': role,
      });
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: FilledButton.icon(
              onPressed: _add,
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Add staff'),
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _staff.isEmpty
                  ? const Center(child: Text('No staff accounts yet.'))
                  : ListView.builder(
                      itemCount: _staff.length,
                      itemBuilder: (context, index) {
                        final member = _staff[index];
                        return ListTile(
                          title: Text(member['name'] as String? ?? ''),
                          subtitle: Text('${member['role'] ?? 'staff'} · ${member['email'] ?? ''}'),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

Future<int?> _askNumber(BuildContext context, String title) async {
  final controller = TextEditingController(text: '1');
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Units'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add')),
      ],
    ),
  );
  if (ok != true) return null;
  return int.tryParse(controller.text.trim());
}
