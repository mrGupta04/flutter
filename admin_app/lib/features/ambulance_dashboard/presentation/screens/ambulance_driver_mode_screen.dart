import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';
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
  List<Map<String, dynamic>> _incoming = [];
  Timer? _locationTimer;
  Timer? _pollTimer;

  static const _activeStatuses = {
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
  };

  static const _incomingStatuses = {
    'requested',
    'searching_ambulance',
  };

  @override
  void initState() {
    super.initState();
    _refresh();
    _pollTimer = Timer.periodic(const Duration(seconds: 6), (_) => _refresh());
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    final requests = await _repo.getRequests();
    if (!mounted) return;
    final items = (requests.data ?? []).cast<Map<String, dynamic>>();
    final active = items
        .where((item) => _activeStatuses.contains(item['status']))
        .toList();
    final incoming = items
        .where(
          (item) =>
              _incomingStatuses.contains(item['status']?.toString()) ||
              item['incomingOffer'] == true,
        )
        .toList();
    setState(() {
      _activeTrip = active.isEmpty ? null : active.first;
      _incoming = incoming;
      _loading = false;
    });
  }

  Future<void> _toggle(bool online) async {
    final position = await LocationService.getCurrentPositionWithPrompt(context);
    final response = await _repo.setDriverPresence(
      online: online,
      latitude: position?.latitude,
      longitude: position?.longitude,
    );
    if (!mounted) return;
    if (!response.success) {
      SnackBarHelper.showError(
        context,
        response.error ?? 'Could not update online status',
      );
      return;
    }
    setState(() => _online = online);
    _locationTimer?.cancel();
    if (online) {
      _locationTimer = Timer.periodic(
        const Duration(seconds: 8),
        (_) => _pushLocation(),
      );
    }
  }

  Future<void> _pushLocation() async {
    try {
      final position = await LocationService.getCurrentPosition(
        requestPermissionIfNeeded: false,
      );
      await _repo.setDriverPresence(
        online: true,
        latitude: position.latitude,
        longitude: position.longitude,
      );
      final trip = _activeTrip;
      if (trip == null) return;
      await _repo.updateTripLocation(
        trip['id'].toString(),
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      // Poor GPS / background limits should not crash driver mode.
    }
  }

  Future<void> _accept(Map<String, dynamic> request) async {
    final response = await _repo.acceptRequest(
      request['id'].toString(),
      vehicleId: request['offerVehicleId']?.toString() ??
          request['assignedVehicleId']?.toString(),
      driverId: request['offerDriverId']?.toString(),
      dispatchId: request['dispatchId']?.toString(),
    );
    if (!mounted) return;
    if (!response.success) {
      SnackBarHelper.showError(context, response.error ?? 'Accept failed');
      return;
    }
    SnackBarHelper.showSuccess(context, 'Trip accepted. Navigate to pickup.');
    await _refresh();
    _pushLocation();
  }

  Future<void> _reject(Map<String, dynamic> request) async {
    final response = await _repo.rejectRequest(
      request['id'].toString(),
      reason: 'unavailable',
    );
    if (!mounted) return;
    if (!response.success) {
      SnackBarHelper.showError(context, response.error ?? 'Reject failed');
      return;
    }
    _refresh();
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
    final pickedUp = const {
      'patient_picked_up',
      'en_route_to_destination',
      'arrived_at_destination',
    }.contains(trip['status']);
    final lat = pickedUp ? trip['dropLatitude'] : trip['pickupLatitude'];
    final lng = pickedUp ? trip['dropLongitude'] : trip['pickupLongitude'];
    if (lat == null || lng == null) return;
    await launchUrl(
      Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng'),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _callPatient() async {
    final phone = _activeTrip?['contactPhone'] ?? _activeTrip?['patientMobile'];
    if (phone == null || phone.toString().trim().isEmpty) return;
    await launchUrl(Uri(scheme: 'tel', path: phone.toString().trim()));
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
                  subtitle: Text(
                    _online
                        ? 'You can receive nearby ambulance requests. GPS is sharing.'
                        : 'Go online to appear on the map and accept bookings.',
                  ),
                  activeThumbColor: AppColors.primary,
                ),
                const SizedBox(height: 16),
                if (trip != null) ...[
                  Text('Active trip', style: AppTextStyles.titleSmall),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trip['statusLabel']?.toString() ?? 'Active trip',
                            style: AppTextStyles.titleSmall.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
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
                          OutlinedButton.icon(
                            onPressed: _callPatient,
                            icon: const Icon(Icons.call),
                            label: const Text('Call patient'),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton(
                                onPressed: () => _advance('start'),
                                child: const Text('En route'),
                              ),
                              OutlinedButton(
                                onPressed: () => _advance('arrived'),
                                child: const Text('Arrived'),
                              ),
                              OutlinedButton(
                                onPressed: () => _advance('pickup'),
                                child: const Text('Picked up'),
                              ),
                              OutlinedButton(
                                onPressed: () => _advance('enroute'),
                                child: const Text('To hospital'),
                              ),
                              OutlinedButton(
                                onPressed: () => _advance('destination'),
                                child: const Text('At hospital'),
                              ),
                              FilledButton(
                                onPressed: () => _advance('complete'),
                                child: const Text('Complete'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else if (!_online)
                  const Text('Go online to receive emergency bookings.')
                else if (_incoming.isEmpty)
                  const Text('Waiting for a nearby request...'),
                if (_incoming.isNotEmpty && trip == null) ...[
                  Text('Incoming requests', style: AppTextStyles.titleSmall),
                  const SizedBox(height: 8),
                  ..._incoming.map(
                    (request) => Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              request['isEmergency'] == false
                                  ? 'Scheduled booking'
                                  : 'Emergency request',
                              style: AppTextStyles.titleSmall.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(request['pickupAddress']?.toString() ?? ''),
                            if (request['dropAddress'] != null)
                              Text('To: ${request['dropAddress']}'),
                            Text(
                              'ETA ${request['estimatedArrivalMinutes'] ?? '—'} min',
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton(
                                    onPressed: () => _accept(request),
                                    child: const Text('Accept'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _reject(request),
                                    child: const Text('Reject'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
