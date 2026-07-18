import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/api_response_model.dart';
import '../../../../data/services/dio_service.dart';
import '../../../../shared/widgets/healthcare_ui.dart';

final adminOverviewProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final dio = DioService();
  final response = await dio.get(AppConstants.endpointAdminOverview);
  final body = response.data as Map<String, dynamic>;
  if (body['success'] != true) {
    throw Exception(body['error'] ?? 'Failed to load overview');
  }
  return body['data'] as Map<String, dynamic>? ?? {};
});

class AdminOverviewScreen extends ConsumerWidget {
  const AdminOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminOverviewProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Marketplace overview')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (data) {
          final stats = data['stats'] as Map<String, dynamic>? ?? {};
          final pending =
              data['pendingByType'] as Map<String, dynamic>? ?? {};
          final recent =
              (data['recentBookings'] as List?)?.cast<dynamic>() ?? [];

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(adminOverviewProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _StatChip(
                      label: 'Patients',
                      value: '${stats['patients'] ?? 0}',
                    ),
                    _StatChip(
                      label: 'Bookings',
                      value: '${stats['totalBookings'] ?? 0}',
                    ),
                    _StatChip(
                      label: 'Pending KYC',
                      value: '${stats['pendingApprovals'] ?? 0}',
                    ),
                    _StatChip(
                      label: 'Revenue',
                      value: '₹${stats['revenueInr'] ?? 0}',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const MarketplaceSectionTitle(title: 'Pending verifications'),
                const SizedBox(height: 8),
                Text(
                  'Doctors ${pending['doctors'] ?? 0} · Nurses ${pending['nurses'] ?? 0} · '
                  'Labs ${pending['labs'] ?? 0} · Scans ${pending['scanCenters'] ?? 0} · '
                  'Ambulance ${pending['ambulances'] ?? 0} · Blood ${pending['bloodBanks'] ?? 0}',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                ServiceBenefitCard(
                  icon: Icons.receipt_long_rounded,
                  title: 'All bookings',
                  subtitle: 'Consults, labs, scans, ambulance',
                  color: AppColors.primary,
                  onTap: () =>
                      context.push(AppConstants.routeAdminBookings),
                ),
                const SizedBox(height: 10),
                ServiceBenefitCard(
                  icon: Icons.people_outline_rounded,
                  title: 'Patients',
                  subtitle: 'Search registered patient accounts',
                  color: AppColors.secondary,
                  onTap: () =>
                      context.push(AppConstants.routeAdminPatients),
                ),
                const SizedBox(height: 10),
                ServiceBenefitCard(
                  icon: Icons.support_agent_rounded,
                  title: 'Support tickets',
                  subtitle: 'Reply · resolve patient issues',
                  color: AppColors.primary,
                  onTap: () =>
                      context.push(AppConstants.routeAdminSupportTickets),
                ),
                const SizedBox(height: 10),
                ServiceBenefitCard(
                  icon: Icons.local_offer_outlined,
                  title: 'Coupons',
                  subtitle: 'Create and manage discount codes',
                  color: AppColors.secondary,
                  onTap: () => context.push(AppConstants.routeAdminCoupons),
                ),
                const SizedBox(height: 10),
                ServiceBenefitCard(
                  icon: Icons.view_carousel_outlined,
                  title: 'CMS banners',
                  subtitle: 'Home hero slides for the user app',
                  color: AppColors.primary,
                  onTap: () =>
                      context.push(AppConstants.routeAdminCmsBanners),
                ),
                const SizedBox(height: 10),
                ServiceBenefitCard(
                  icon: Icons.currency_exchange_rounded,
                  title: 'Refunds',
                  subtitle: 'Mark bookings as refunded',
                  color: AppColors.primary,
                  onTap: () => context.push(AppConstants.routeAdminRefunds),
                ),
                const SizedBox(height: 20),
                const MarketplaceSectionTitle(title: 'Recent bookings'),
                const SizedBox(height: 8),
                if (recent.isEmpty)
                  const Text('No recent bookings')
                else
                  ...recent.take(10).map((raw) {
                    final m = Map<String, dynamic>.from(raw as Map);
                    return Card(
                      child: ListTile(
                        title: Text(m['title']?.toString() ?? 'Booking'),
                        subtitle: Text(
                          '${m['type'] ?? ''} · ${m['status'] ?? ''} · ₹${m['amount'] ?? 0}',
                        ),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class AdminBookingsScreen extends ConsumerStatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  ConsumerState<AdminBookingsScreen> createState() =>
      _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends ConsumerState<AdminBookingsScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

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
    try {
      final response =
          await DioService().get(AppConstants.endpointAdminBookings);
      final body = response.data as Map<String, dynamic>;
      final list = extractApiList(body['data']);
      setState(() {
        _items = list
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All bookings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final b = _items[i];
                      return Card(
                        child: ListTile(
                          title: Text(b['patientName']?.toString() ?? 'Patient'),
                          subtitle: Text(
                            '${b['category']} · ${b['label'] ?? ''}\n'
                            '${b['providerName'] ?? ''} · ${b['status']} · '
                            '${b['paymentStatus'] ?? '—'} · ₹${b['amount'] ?? 0}',
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class AdminPatientsScreen extends ConsumerStatefulWidget {
  const AdminPatientsScreen({super.key});

  @override
  ConsumerState<AdminPatientsScreen> createState() =>
      _AdminPatientsScreenState();
}

class _AdminPatientsScreenState extends ConsumerState<AdminPatientsScreen> {
  final _search = TextEditingController();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await DioService().get(
        AppConstants.endpointAdminPatients,
        queryParameters: {
          if (_search.text.trim().isNotEmpty) 'q': _search.text.trim(),
        },
      );
      final body = response.data as Map<String, dynamic>;
      final list = extractApiList(body['data']);
      setState(() {
        _items =
            list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Patients')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: 'Search name, email, mobile',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _load,
                ),
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _load(),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final p = _items[i];
                            final name =
                                '${p['firstName'] ?? ''} ${p['lastName'] ?? ''}'
                                    .trim();
                            return Card(
                              child: ListTile(
                                title: Text(name.isEmpty ? 'Patient' : name),
                                subtitle: Text(
                                  '${p['email'] ?? ''}\n${p['mobileNumber'] ?? ''}',
                                ),
                                isThreeLine: true,
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class AdminSupportTicketsScreen extends ConsumerStatefulWidget {
  const AdminSupportTicketsScreen({super.key});

  @override
  ConsumerState<AdminSupportTicketsScreen> createState() =>
      _AdminSupportTicketsScreenState();
}

class _AdminSupportTicketsScreenState
    extends ConsumerState<AdminSupportTicketsScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  String? _statusFilter;

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
    try {
      final response = await DioService().get(
        AppConstants.endpointAdminSupportTickets,
        queryParameters: {
          if (_statusFilter != null) 'status': _statusFilter,
        },
      );
      final body = response.data as Map<String, dynamic>;
      final list = extractApiList(body['data']);
      setState(() {
        _items =
            list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _updateTicket(Map<String, dynamic> ticket) async {
    final replyCtrl = TextEditingController(
      text: ticket['adminReply']?.toString() ?? '',
    );
    String status = ticket['status']?.toString() ?? 'open';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ticket['subject']?.toString() ?? 'Ticket'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(ticket['message']?.toString() ?? ''),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'open', child: Text('Open')),
                  DropdownMenuItem(
                    value: 'in_progress',
                    child: Text('In progress'),
                  ),
                  DropdownMenuItem(
                    value: 'resolved',
                    child: Text('Resolved'),
                  ),
                  DropdownMenuItem(value: 'closed', child: Text('Closed')),
                ],
                onChanged: (v) {
                  if (v != null) status = v;
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: replyCtrl,
                decoration: const InputDecoration(labelText: 'Admin reply'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await DioService().post(
        AppConstants.endpointAdminSupportTicketStatus(
          ticket['id']?.toString() ?? '',
        ),
        data: {
          'status': status,
          'adminReply': replyCtrl.text.trim(),
        },
      );
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      replyCtrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support tickets'),
        actions: [
          PopupMenuButton<String?>(
            tooltip: 'Filter',
            onSelected: (v) {
              setState(() => _statusFilter = v);
              _load();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: null, child: Text('All')),
              PopupMenuItem(value: 'open', child: Text('Open')),
              PopupMenuItem(value: 'in_progress', child: Text('In progress')),
              PopupMenuItem(value: 'resolved', child: Text('Resolved')),
              PopupMenuItem(value: 'closed', child: Text('Closed')),
            ],
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _items.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 120),
                            Center(child: Text('No tickets')),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final t = _items[i];
                            return Card(
                              child: ListTile(
                                title: Text(
                                  t['subject']?.toString() ?? 'Ticket',
                                ),
                                subtitle: Text(
                                  '${t['patientName'] ?? ''} · ${t['category']}\n'
                                  '${t['status']} · ${t['message'] ?? ''}',
                                ),
                                isThreeLine: true,
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => _updateTicket(t),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}

class AdminCouponsScreen extends ConsumerStatefulWidget {
  const AdminCouponsScreen({super.key});

  @override
  ConsumerState<AdminCouponsScreen> createState() => _AdminCouponsScreenState();
}

class _AdminCouponsScreenState extends ConsumerState<AdminCouponsScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

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
    try {
      final response =
          await DioService().get(AppConstants.endpointAdminCoupons);
      final body = response.data as Map<String, dynamic>;
      final list = extractApiList(body['data']);
      setState(() {
        _items =
            list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _upsert({Map<String, dynamic>? existing}) async {
    final codeCtrl =
        TextEditingController(text: existing?['code']?.toString() ?? '');
    final valueCtrl = TextEditingController(
      text: existing?['discountValue']?.toString() ?? '10',
    );
    final minCtrl = TextEditingController(
      text: existing?['minOrderInr']?.toString() ?? '0',
    );
    String type = existing?['discountType']?.toString() ?? 'percentage';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'New coupon' : 'Edit coupon'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeCtrl,
                decoration: const InputDecoration(labelText: 'Code'),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(
                    value: 'percentage',
                    child: Text('Percent'),
                  ),
                  DropdownMenuItem(value: 'flat', child: Text('Flat ₹')),
                ],
                onChanged: (v) {
                  if (v != null) type = v;
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: valueCtrl,
                decoration: const InputDecoration(labelText: 'Value'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: minCtrl,
                decoration:
                    const InputDecoration(labelText: 'Min order (₹)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await DioService().post(
        AppConstants.endpointAdminCoupons,
        data: {
          'code': codeCtrl.text.trim().toUpperCase(),
          'discountType': type,
          'discountValue': num.tryParse(valueCtrl.text.trim()) ?? 0,
          'minOrderInr': num.tryParse(minCtrl.text.trim()) ?? 0,
          'active': true,
        },
      );
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      codeCtrl.dispose();
      valueCtrl.dispose();
      minCtrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Coupons')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _upsert(),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final c = _items[i];
                      return Card(
                        child: ListTile(
                          title: Text(c['code']?.toString() ?? ''),
                          subtitle: Text(
                            '${c['discountType']} ${c['discountValue']} · '
                            'min ₹${c['minOrderInr'] ?? 0} · '
                            'used ${c['usageCount'] ?? 0}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _upsert(existing: c),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class AdminCmsScreen extends ConsumerStatefulWidget {
  const AdminCmsScreen({super.key});

  @override
  ConsumerState<AdminCmsScreen> createState() => _AdminCmsScreenState();
}

class _AdminCmsScreenState extends ConsumerState<AdminCmsScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

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
    try {
      final response =
          await DioService().get(AppConstants.endpointAdminCmsBanners);
      final body = response.data as Map<String, dynamic>;
      final list = extractApiList(body['data']);
      setState(() {
        _items =
            list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _upsert({Map<String, dynamic>? existing}) async {
    final titleCtrl =
        TextEditingController(text: existing?['title']?.toString() ?? '');
    final subtitleCtrl =
        TextEditingController(text: existing?['subtitle']?.toString() ?? '');
    final imageCtrl =
        TextEditingController(text: existing?['imageUrl']?.toString() ?? '');
    final linkCtrl =
        TextEditingController(text: existing?['linkUrl']?.toString() ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'New banner' : 'Edit banner'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: subtitleCtrl,
                decoration: const InputDecoration(labelText: 'Subtitle'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: imageCtrl,
                decoration: const InputDecoration(labelText: 'Image URL'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: linkCtrl,
                decoration: const InputDecoration(labelText: 'Link URL (optional)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await DioService().post(
        AppConstants.endpointAdminCmsBanners,
        data: {
          if (existing?['id'] != null) 'id': existing!['id'],
          'title': titleCtrl.text.trim(),
          'subtitle': subtitleCtrl.text.trim(),
          'imageUrl': imageCtrl.text.trim(),
          if (linkCtrl.text.trim().isNotEmpty) 'linkUrl': linkCtrl.text.trim(),
          'placement': 'home_hero',
          'active': true,
          'sortOrder': existing?['sortOrder'] ?? _items.length,
        },
      );
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      titleCtrl.dispose();
      subtitleCtrl.dispose();
      imageCtrl.dispose();
      linkCtrl.dispose();
    }
  }

  Future<void> _delete(String id) async {
    try {
      await DioService().delete(AppConstants.endpointAdminCmsBanner(id));
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CMS banners')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _upsert(),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final b = _items[i];
                      return Card(
                        child: ListTile(
                          title: Text(b['title']?.toString() ?? ''),
                          subtitle: Text(
                            '${b['subtitle'] ?? ''}\n${b['imageUrl'] ?? ''}',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _upsert(existing: b),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () {
                                  final id = b['id']?.toString();
                                  if (id != null) _delete(id);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class AdminRefundsScreen extends ConsumerStatefulWidget {
  const AdminRefundsScreen({super.key});

  @override
  ConsumerState<AdminRefundsScreen> createState() =>
      _AdminRefundsScreenState();
}

class _AdminRefundsScreenState extends ConsumerState<AdminRefundsScreen> {
  final _bookingId = TextEditingController();
  final _reason = TextEditingController();
  String _category = 'consultation';
  bool _submitting = false;
  String? _result;

  @override
  void dispose() {
    _bookingId.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_bookingId.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking ID is required')),
      );
      return;
    }
    setState(() {
      _submitting = true;
      _result = null;
    });
    try {
      final response = await DioService().post(
        AppConstants.endpointAdminRefunds,
        data: {
          'bookingId': _bookingId.text.trim(),
          'category': _category,
          'reason': _reason.text.trim(),
        },
      );
      final body = response.data as Map<String, dynamic>;
      setState(() {
        _result = body['message']?.toString() ?? 'Refund recorded';
      });
    } catch (e) {
      setState(() => _result = e.toString());
    } finally {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Record refund')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Marks payment status as refunded for the booking. '
            'Does not move money in Razorpay automatically.',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: const [
              DropdownMenuItem(
                value: 'consultation',
                child: Text('Consultation'),
              ),
              DropdownMenuItem(value: 'lab', child: Text('Lab')),
              DropdownMenuItem(value: 'scan', child: Text('Scan')),
              DropdownMenuItem(value: 'blood', child: Text('Blood')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _category = v);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bookingId,
            decoration: const InputDecoration(labelText: 'Booking ID'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reason,
            decoration: const InputDecoration(labelText: 'Reason'),
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Record refund'),
          ),
          if (_result != null) ...[
            const SizedBox(height: 16),
            Text(_result!),
          ],
        ],
      ),
    );
  }
}
