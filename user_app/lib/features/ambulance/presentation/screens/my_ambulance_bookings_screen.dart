import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/ambulance_booking_model.dart';
import '../../../../data/repositories/ambulance_repository.dart';

class MyAmbulanceBookingsScreen extends StatefulWidget {
  const MyAmbulanceBookingsScreen({super.key});

  @override
  State<MyAmbulanceBookingsScreen> createState() =>
      _MyAmbulanceBookingsScreenState();
}

class _MyAmbulanceBookingsScreenState extends State<MyAmbulanceBookingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  List<AmbulanceBookingModel> _bookings = [];
  bool _loading = true;

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
    final response = await AmbulanceRepository().listMyBookings();
    if (!mounted) return;
    setState(() {
      _bookings = response.data ?? [];
      _loading = false;
    });
  }

  List<AmbulanceBookingModel> _group(String group) {
    if (group == 'active') {
      return _bookings.where((item) => item.isActive && item.isEmergency).toList();
    }
    if (group == 'upcoming') {
      return _bookings
          .where((item) => item.bookingKind == 'scheduled' && item.isActive)
          .toList();
    }
    return _bookings.where((item) => !item.isActive).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My ambulance bookings'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabs,
              children: [
                _list(_group('active')),
                _list(_group('upcoming')),
                _list(_group('completed')),
              ],
            ),
    );
  }

  Widget _list(List<AmbulanceBookingModel> items) {
    if (items.isEmpty) {
      return const Center(child: Text('No trips in this list'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, index) {
          final item = items[index];
          return Card(
            child: ListTile(
              title: Text(item.ambulanceServiceName ?? item.vehicleTypeRequested ?? 'Ambulance'),
              subtitle: Text(
                [
                  item.id.substring(0, 8),
                  item.pickupAddress,
                  item.dropAddress,
                  item.statusLabel ?? item.status,
                  if (item.fare != null) '₹${item.fare!.total}',
                  if (item.createdAt != null)
                    DateFormat('dd MMM, hh:mm a').format(item.createdAt!),
                ].whereType<String>().where((v) => v.isNotEmpty).join('\n'),
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                if (item.canTrack || item.isSearching) {
                  context.push('${AppConstants.routeAmbulanceTrack}?bookingId=${item.id}');
                } else {
                  context.push('${AppConstants.routeAmbulanceTripDetail}?id=${item.id}');
                }
              },
            ),
          );
        },
      ),
    );
  }
}
