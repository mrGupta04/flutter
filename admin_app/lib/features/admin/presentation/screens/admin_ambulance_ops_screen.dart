import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/repositories/ambulance_registration_repository.dart';

class AdminAmbulanceOpsScreen extends StatefulWidget {
  const AdminAmbulanceOpsScreen({super.key});

  @override
  State<AdminAmbulanceOpsScreen> createState() => _AdminAmbulanceOpsScreenState();
}

class _AdminAmbulanceOpsScreenState extends State<AdminAmbulanceOpsScreen> {
  final _repo = AmbulanceRegistrationRepository();
  Map<String, dynamic>? _overview;
  List<Map<String, dynamic>> _bookings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final overview = await _repo.adminOverview();
    final bookings = await _repo.adminBookings();
    if (!mounted) return;
    setState(() {
      _overview = overview.data;
      _bookings = bookings.data ?? [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final stats = _overview ?? {};
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ambulance management'),
        actions: [
          IconButton(
            onPressed: () => context.push(AppConstants.routeAdminAmbulanceLive),
            icon: const Icon(Icons.map_outlined),
          ),
          IconButton(
            onPressed: () => context.push(AppConstants.routeAdminAmbulancePricing),
            icon: const Icon(Icons.payments_outlined),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip('Providers', stats['totalProviders']),
                    _chip('Verified', stats['verifiedProviders']),
                    _chip('Ambulances', stats['totalAmbulances']),
                    _chip('Available', stats['availableAmbulances']),
                    _chip('Active trips', stats['activeTrips']),
                    _chip('Emergencies', stats['emergencyRequests']),
                    _chip('Completed', stats['completedTrips']),
                    _chip('Cancelled', stats['cancelledTrips']),
                    _chip('Drivers online', stats['driversOnline']),
                    _chip('Revenue', '₹${stats['revenue'] ?? 0}'),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Recent trips', style: AppTextStyles.titleSmall),
                ..._bookings.take(20).map(
                  (item) => Card(
                    child: ListTile(
                      title: Text(item['statusLabel']?.toString() ?? item['status'].toString()),
                      subtitle: Text(
                        '${item['ambulanceServiceName'] ?? 'Unassigned'}\n${item['pickupAddress'] ?? ''}',
                      ),
                      isThreeLine: true,
                      trailing: TextButton(
                        onPressed: () async {
                          await _repo.reassign(item['id'].toString());
                          _load();
                        },
                        child: const Text('Reassign'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _chip(String label, dynamic value) {
    return Chip(label: Text('$label: $value'));
  }
}
