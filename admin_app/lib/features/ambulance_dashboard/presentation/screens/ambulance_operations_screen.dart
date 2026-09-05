import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/repositories/ambulance_registration_repository.dart';

class AmbulanceOperationsScreen extends StatefulWidget {
  const AmbulanceOperationsScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<AmbulanceOperationsScreen> createState() =>
      _AmbulanceOperationsScreenState();
}

class _AmbulanceOperationsScreenState extends State<AmbulanceOperationsScreen>
    with SingleTickerProviderStateMixin {
  final _repo = AmbulanceRegistrationRepository();
  late final TabController _tabs;
  List<Map<String, dynamic>> _requests = [];
  Map<String, dynamic>? _dashboard;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this, initialIndex: widget.initialTab);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final requests = await _repo.getRequests();
    final dashboard = await _repo.getDashboard();
    if (!mounted) return;
    setState(() {
      _requests = requests.data ?? [];
      _dashboard = dashboard.data;
      _error = requests.success ? null : requests.error;
      _loading = false;
    });
  }

  Future<void> _accept(String id) async {
    final response = await _repo.acceptRequest(id);
    if (!mounted) return;
    if (response.success) {
      SnackBarHelper.showSuccess(context, 'Request accepted');
      _load();
    } else {
      SnackBarHelper.showError(context, response.error ?? 'Accept failed');
    }
  }

  Future<void> _reject(String id) async {
    final response = await _repo.rejectRequest(id, reason: 'unavailable');
    if (!mounted) return;
    if (response.success) {
      SnackBarHelper.showSuccess(context, 'Request rejected');
      _load();
    } else {
      SnackBarHelper.showError(context, response.error ?? 'Reject failed');
    }
  }

  Future<void> _advance(String id, String action) async {
    final response = await _repo.tripAction(id, action);
    if (!mounted) return;
    if (response.success) {
      _load();
    } else {
      SnackBarHelper.showError(context, response.error ?? 'Update failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = (_dashboard?['provider'] as Map<String, dynamic>?) ?? {};
    final vehicles = (provider['vehicles'] as List?)?.whereType<Map>().toList() ?? [];
    final drivers = (provider['drivers'] as List?)?.whereType<Map>().toList() ?? [];
    final emergencies = _requests.where((item) {
      final status = item['status']?.toString();
      return item['isEmergency'] == true &&
          (status == 'requested' || status == 'searching_ambulance');
    }).toList();
    final scheduled = _requests.where((item) => item['bookingKind'] == 'scheduled').toList();
    final active = _requests.where((item) => const {
          'ambulance_assigned',
          'driver_accepted',
          'accepted',
          'dispatched',
          'driver_en_route',
          'en_route',
          'arrived_at_pickup',
          'arrived',
          'patient_picked_up',
          'en_route_to_destination',
          'arrived_at_destination',
        }.contains(item['status'])).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ambulance operations'),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Emergency'),
            Tab(text: 'Trips'),
            Tab(text: 'Fleet'),
            Tab(text: 'Drivers'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _requests.isEmpty
              ? AppErrorWidget(message: _error!, onRetry: _load)
              : TabBarView(
                  controller: _tabs,
                  children: [
                    _requestList(emergencies.isEmpty ? scheduled : emergencies, emergency: true),
                    _tripList(active.isEmpty ? _requests : active),
                    _fleetList(vehicles),
                    _driverList(drivers),
                  ],
                ),
    );
  }

  Widget _requestList(List<Map<String, dynamic>> items, {bool emergency = false}) {
    if (items.isEmpty) return const Center(child: Text('No pending requests'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (_, index) {
        final item = items[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  emergency ? 'EMERGENCY AMBULANCE REQUEST' : 'Scheduled request',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: emergency ? const Color(0xFFB71C1C) : null,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text('Pickup: ${item['pickupAddress'] ?? '—'}'),
                Text('Destination: ${item['dropAddress'] ?? item['destinationHospitalName'] ?? '—'}'),
                Text('Required: ${item['vehicleTypeRequested'] ?? '—'}'),
                Text('ETA: ${item['estimatedArrivalMinutes'] ?? '—'} min'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    FilledButton(
                      onPressed: () => _accept(item['id'].toString()),
                      child: const Text('ACCEPT'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => _reject(item['id'].toString()),
                      child: const Text('REJECT'),
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

  Widget _tripList(List<Map<String, dynamic>> items) {
    if (items.isEmpty) return const Center(child: Text('No active trips'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (_, index) {
        final item = items[index];
        return Card(
          child: ListTile(
            title: Text(item['statusLabel']?.toString() ?? item['status'].toString()),
            subtitle: Text('${item['pickupAddress'] ?? ''}\n${item['patientName'] ?? ''}'),
            isThreeLine: true,
            trailing: PopupMenuButton<String>(
              onSelected: (action) => _advance(item['id'].toString(), action),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'start', child: Text('En route')),
                PopupMenuItem(value: 'arrived', child: Text('Arrived at pickup')),
                PopupMenuItem(value: 'pickup', child: Text('Patient picked up')),
                PopupMenuItem(value: 'enroute', child: Text('Heading to destination')),
                PopupMenuItem(value: 'destination', child: Text('Arrived at hospital')),
                PopupMenuItem(value: 'complete', child: Text('Trip completed')),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _fleetList(List<Map> vehicles) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FilledButton.icon(
          onPressed: () => _editVehicle(),
          icon: const Icon(Icons.add),
          label: const Text('Add ambulance'),
        ),
        const SizedBox(height: 12),
        ...vehicles.map(
          (vehicle) => Card(
            child: ListTile(
              title: Text(vehicle['registrationNumber']?.toString() ?? 'Ambulance'),
              subtitle: Text('${vehicle['vehicleType'] ?? ''} · ${vehicle['status'] ?? ''}'),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _editVehicle(existing: Map<String, dynamic>.from(vehicle)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _driverList(List<Map> drivers) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FilledButton.icon(
          onPressed: () => _editDriver(),
          icon: const Icon(Icons.person_add_alt),
          label: const Text('Add driver'),
        ),
        const SizedBox(height: 12),
        ...drivers.map(
          (driver) => Card(
            child: ListTile(
              title: Text(driver['fullName']?.toString() ?? 'Driver'),
              subtitle: Text('${driver['mobileNumber'] ?? ''} · ${driver['status'] ?? ''}'),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _editDriver(existing: Map<String, dynamic>.from(driver)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _editVehicle({Map<String, dynamic>? existing}) async {
    final registration = TextEditingController(text: existing?['registrationNumber']?.toString());
    final type = TextEditingController(text: existing?['vehicleType']?.toString() ?? 'Advanced Life Support');
    var oxygen = existing?['hasOxygen'] == true;
    var ventilator = existing?['hasVentilator'] == true;
    if (!mounted) return;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Add ambulance' : 'Edit ambulance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: registration, decoration: const InputDecoration(labelText: 'Registration number')),
            TextField(controller: type, decoration: const InputDecoration(labelText: 'Type')),
            StatefulBuilder(
              builder: (context, setLocal) => Column(
                children: [
                  CheckboxListTile(
                    value: oxygen,
                    onChanged: (v) => setLocal(() => oxygen = v ?? false),
                    title: const Text('Oxygen'),
                  ),
                  CheckboxListTile(
                    value: ventilator,
                    onChanged: (v) => setLocal(() => ventilator = v ?? false),
                    title: const Text('Ventilator'),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (saved != true) return;
    await _repo.saveVehicle({
      'registrationNumber': registration.text.trim(),
      'vehicleType': type.text.trim(),
      'hasOxygen': oxygen,
      'hasVentilator': ventilator,
      'status': existing?['status'] ?? 'AVAILABLE',
    }, id: existing?['id']?.toString());
    _load();
  }

  Future<void> _editDriver({Map<String, dynamic>? existing}) async {
    final name = TextEditingController(text: existing?['fullName']?.toString());
    final mobile = TextEditingController(text: existing?['mobileNumber']?.toString());
    final pin = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Add driver' : 'Edit driver'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: mobile, decoration: const InputDecoration(labelText: 'Phone')),
            TextField(controller: pin, decoration: const InputDecoration(labelText: 'Driver PIN (optional)'), obscureText: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (saved != true) return;
    await _repo.saveDriver({
      'fullName': name.text.trim(),
      'mobileNumber': mobile.text.trim(),
      if (pin.text.trim().isNotEmpty) 'pin': pin.text.trim(),
      'status': existing?['status'] ?? 'OFFLINE',
      'verificationStatus': existing?['verificationStatus'] ?? 'verified',
    }, id: existing?['id']?.toString());
    _load();
  }
}
