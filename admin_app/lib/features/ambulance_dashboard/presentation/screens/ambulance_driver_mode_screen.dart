import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/repositories/ambulance_registration_repository.dart';

class AmbulanceDriverModeScreen extends StatefulWidget {
  const AmbulanceDriverModeScreen({super.key});

  @override
  State<AmbulanceDriverModeScreen> createState() =>
      _AmbulanceDriverModeScreenState();
}

class _AmbulanceDriverModeScreenState extends State<AmbulanceDriverModeScreen> {
  final _repo = AmbulanceRegistrationRepository();
  bool _online = false;
  bool _loading = true;
  Map<String, dynamic>? _activeTrip;
  Timer? _locationTimer;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    final requests = await _repo.getRequests();
    if (!mounted) return;
    final active = (requests.data ?? []).cast<Map<String, dynamic>>().where((item) {
      return const {
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
      }.contains(item['status']);
    }).toList();
    setState(() {
      _activeTrip = active.isEmpty ? null : active.first;
      _loading = false;
    });
  }

  Future<void> _toggle(bool online) async {
    final position = await LocationService.getCurrentPositionWithPrompt(context);
    await _repo.setDriverPresence(
      online: online,
      latitude: position?.latitude,
      longitude: position?.longitude,
    );
    setState(() => _online = online);
    _locationTimer?.cancel();
    if (online) {
      _locationTimer = Timer.periodic(const Duration(seconds: 8), (_) => _pushLocation());
    }
  }

  Future<void> _pushLocation() async {
    final trip = _activeTrip;
    if (trip == null) return;
    try {
      final position = await LocationService.getCurrentPosition(
        requestPermissionIfNeeded: false,
      );
      await _repo.updateTripLocation(
        trip['id'].toString(),
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      // Poor GPS / background limits should not crash driver mode.
    }
  }

  Future<void> _advance(String action) async {
    final trip = _activeTrip;
    if (trip == null) return;
    final response = await _repo.tripAction(trip['id'].toString(), action);
    if (!mounted) return;
    if (!response.success) {
      SnackBarHelper.showError(context, response.error ?? 'Update failed');
      return;
    }
    _refresh();
  }

  Future<void> _navigate() async {
    final trip = _activeTrip;
    if (trip == null) return;
    final lat = trip['pickupLatitude'] ?? trip['dropLatitude'];
    final lng = trip['pickupLongitude'] ?? trip['dropLongitude'];
    if (lat == null || lng == null) return;
    await launchUrl(
      Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng'),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    final trip = _activeTrip;
    return Scaffold(
      appBar: AppBar(title: const Text('Driver mode')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SwitchListTile(
                  value: _online,
                  onChanged: _toggle,
                  title: Text(_online ? 'ONLINE' : 'OFFLINE'),
                  subtitle: const Text('When online, you can receive suitable trip requests.'),
                ),
                const SizedBox(height: 12),
                if (trip == null)
                  const Text('No active trip')
                else ...[
                  Text(trip['statusLabel']?.toString() ?? 'Active trip', style: AppTextStyles.titleSmall),
                  Text('Pickup: ${trip['pickupAddress'] ?? ''}'),
                  Text('Destination: ${trip['dropAddress'] ?? ''}'),
                  Text('Patient: ${trip['patientName'] ?? ''}'),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _navigate,
                    icon: const Icon(Icons.navigation),
                    label: const Text('Open navigation'),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton(onPressed: () => _advance('start'), child: const Text('En route')),
                      OutlinedButton(onPressed: () => _advance('arrived'), child: const Text('Arrived')),
                      OutlinedButton(onPressed: () => _advance('pickup'), child: const Text('Picked up')),
                      OutlinedButton(onPressed: () => _advance('enroute'), child: const Text('To hospital')),
                      OutlinedButton(onPressed: () => _advance('destination'), child: const Text('At hospital')),
                      FilledButton(onPressed: () => _advance('complete'), child: const Text('Complete')),
                    ],
                  ),
                ],
              ],
            ),
    );
  }
}
