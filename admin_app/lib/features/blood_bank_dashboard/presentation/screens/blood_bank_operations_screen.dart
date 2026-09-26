import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/repositories/blood_bank_registration_repository.dart';
import '../../../blood_bank_registration/data/blood_bank_registration_catalog.dart';
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
    _tabs = TabController(length: 6, vsync: this, initialIndex: widget.initialTab.clamp(0, 5));
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
            Tab(text: 'Camps'),
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
          _CampsTab(repo: _repo),
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

  Future<void> _addNew() async {
    String group = 'O+';
    String component = 'packed_rbc';
    final units = TextEditingController(text: '1');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add inventory'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: group,
              decoration: const InputDecoration(labelText: 'Blood group'),
              items: kBloodGroups
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (v) => group = v ?? group,
            ),
            DropdownButtonFormField<String>(
              value: component,
              decoration: const InputDecoration(labelText: 'Component'),
              items: kBloodComponents
                  .map((c) => DropdownMenuItem(value: c['id'], child: Text(c['name']!)))
                  .toList(),
              onChanged: (v) => component = v ?? component,
            ),
            TextField(
              controller: units,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Units'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add')),
        ],
      ),
    );
    if (ok != true) return;
    final count = int.tryParse(units.text.trim()) ?? 0;
    if (count < 1) return;
    await widget.repo.addInventoryUnits({
      'bloodGroup': group,
      'componentType': component,
      'units': count,
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No blood inventory has been added.'),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _addNew,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Inventory'),
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FilledButton.icon(
                  onPressed: _addNew,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add inventory'),
                ),
              ),
            );
          }
          final item = _items[index - 1];
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

  Future<void> _act(
    String id,
    String action, {
    Map<String, dynamic>? data,
    String? confirm,
  }) async {
    if (confirm != null) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(confirm),
          content: const Text('This operational action will be recorded in the request timeline.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Back')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm')),
          ],
        ),
      );
      if (ok != true) return;
    }
    await widget.repo.requestAction(id, action, data: data);
    if (!mounted) return;
    await ref.read(bloodBankDashboardProvider.notifier).refreshAll();
  }

  Future<void> _partial(String id, int requested) async {
    final units = await _askNumber(context, 'Approve available units (requested $requested)');
    if (units == null || units < 1) return;
    await _act(id, 'partial', data: {'approvedUnits': units}, confirm: 'Record partial availability?');
  }

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
                'submitted',
                'under_review',
                'document_verification',
                'approved',
                'partially_available',
                'accepted',
                'blood_reserved',
                'ready_for_collection',
                'completed',
                'rejected',
                'cancelled',
                'expired',
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
                                  onPressed: () => _act(order['id'] as String, 'review'),
                                  child: const Text('Review'),
                                ),
                                TextButton(
                                  onPressed: () => _act(
                                    order['id'] as String,
                                    'documents',
                                    confirm: 'Request additional documents?',
                                  ),
                                  child: const Text('Request docs'),
                                ),
                                TextButton(
                                  onPressed: () => _act(
                                    order['id'] as String,
                                    'accept',
                                    confirm: 'Approve and reserve units?',
                                  ),
                                  child: const Text('Approve'),
                                ),
                                TextButton(
                                  onPressed: () => _partial(
                                    order['id'] as String,
                                    (order['units'] as num?)?.toInt() ?? 1,
                                  ),
                                  child: const Text('Partial'),
                                ),
                                TextButton(
                                  onPressed: () => _act(
                                    order['id'] as String,
                                    'reject',
                                    data: {'rejectionReasonCode': 'blood_unavailable'},
                                    confirm: 'Reject this request?',
                                  ),
                                  child: const Text('Reject'),
                                ),
                                TextButton(
                                  onPressed: () => _act(
                                    order['id'] as String,
                                    'reserve',
                                    confirm: 'Reserve inventory units?',
                                  ),
                                  child: const Text('Reserve'),
                                ),
                                TextButton(
                                  onPressed: () => _act(
                                    order['id'] as String,
                                    'ready',
                                    confirm: 'Mark ready for collection?',
                                  ),
                                  child: const Text('Mark ready'),
                                ),
                                TextButton(
                                  onPressed: () => _act(
                                    order['id'] as String,
                                    'collected',
                                    confirm: 'Mark collected / issued?',
                                  ),
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

class _CampsTab extends StatefulWidget {
  const _CampsTab({required this.repo});
  final BloodBankRegistrationRepository repo;

  @override
  State<_CampsTab> createState() => _CampsTabState();
}

class _CampsTabState extends State<_CampsTab> {
  List<Map<String, dynamic>> _camps = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await widget.repo.getCamps();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _camps = res.data ?? const [];
    });
  }

  Future<void> _create() async {
    final title = TextEditingController();
    final address = TextEditingController();
    final contact = TextEditingController();
    final capacity = TextEditingController(text: '50');
    DateTime date = DateTime.now().add(const Duration(days: 3));
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create donation camp'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: title, decoration: const InputDecoration(labelText: 'Camp name')),
              TextField(controller: address, decoration: const InputDecoration(labelText: 'Address')),
              TextField(controller: contact, decoration: const InputDecoration(labelText: 'Contact')),
              TextField(
                controller: capacity,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Capacity'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date'),
                subtitle: Text('${date.day}/${date.month}/${date.year}'),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 180)),
                    initialDate: date,
                  );
                  if (picked != null) date = picked;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Publish')),
        ],
      ),
    );
    if (ok != true || title.text.trim().isEmpty) return;
    await widget.repo.saveCamp({
      'title': title.text.trim(),
      'address': address.text.trim(),
      'contact': contact.text.trim(),
      'capacity': int.tryParse(capacity.text.trim()) ?? 50,
      'date': date.toIso8601String(),
      'startTime': '09:00',
      'endTime': '13:00',
      'status': 'published',
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: FilledButton.icon(
              onPressed: _create,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create camp'),
            ),
          ),
        ),
        Expanded(
          child: _camps.isEmpty
              ? const Center(child: Text('No donation camps scheduled.'))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: _camps.length,
                  itemBuilder: (context, index) {
                    final camp = _camps[index];
                    return Card(
                      child: ListTile(
                        title: Text(camp['title'] as String? ?? 'Donation camp'),
                        subtitle: Text(
                          '${camp['date'] ?? ''} · ${camp['address'] ?? ''}\n'
                          '${camp['registeredCount'] ?? 0}/${camp['capacity'] ?? 0} registered',
                        ),
                        isThreeLine: true,
                        trailing: camp['status'] == 'cancelled'
                            ? const Text('Cancelled')
                            : TextButton(
                                onPressed: () async {
                                  await widget.repo.cancelCamp(camp['id'] as String);
                                  _load();
                                },
                                child: const Text('Cancel'),
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
