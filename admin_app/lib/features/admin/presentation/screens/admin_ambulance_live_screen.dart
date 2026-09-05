import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../data/repositories/ambulance_registration_repository.dart';

class AdminAmbulanceLiveScreen extends StatefulWidget {
  const AdminAmbulanceLiveScreen({super.key});

  @override
  State<AdminAmbulanceLiveScreen> createState() =>
      _AdminAmbulanceLiveScreenState();
}

class _AdminAmbulanceLiveScreenState extends State<AdminAmbulanceLiveScreen> {
  final _repo = AmbulanceRegistrationRepository();
  Map<String, dynamic>? _selected;
  List<Map<String, dynamic>> _ambulances = [];
  List<Map<String, dynamic>> _trips = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final response = await _repo.adminLive();
    if (!mounted) return;
    final data = response.data ?? {};
    setState(() {
      _ambulances = (data['ambulances'] as List?)
              ?.whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [];
      _trips = (data['trips'] as List?)
              ?.whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [];
    });
  }

  Set<Marker> get _markers {
    final markers = <Marker>{};
    for (final ambulance in _ambulances) {
      final lat = (ambulance['latitude'] as num?)?.toDouble();
      final lng = (ambulance['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;
      final busy = ambulance['status'] == 'BUSY';
      markers.add(
        Marker(
          markerId: MarkerId('v-${ambulance['vehicleId']}'),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: ambulance['registration']?.toString() ?? 'Ambulance',
            snippet: '${ambulance['providerName']} · ${ambulance['status']}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            busy ? BitmapDescriptor.hueRed : BitmapDescriptor.hueGreen,
          ),
          onTap: () => setState(() => _selected = ambulance),
        ),
      );
    }
    for (final trip in _trips) {
      final lat = (trip['pickupLatitude'] as num?)?.toDouble();
      final lng = (trip['pickupLongitude'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;
      markers.add(
        Marker(
          markerId: MarkerId('p-${trip['id']}'),
          position: LatLng(lat, lng),
          infoWindow: const InfoWindow(title: 'Pickup'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live ambulance operations'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(AppConstants.defaultMapLat, AppConstants.defaultMapLng),
                zoom: 11,
              ),
              markers: _markers,
            ),
          ),
          if (_selected != null)
            ListTile(
              title: Text(_selected!['registration']?.toString() ?? 'Ambulance'),
              subtitle: Text(
                [
                  _selected!['providerName'],
                  _selected!['status'],
                  if (_selected!['currentBookingId'] != null)
                    'Trip ${_selected!['currentBookingId']}',
                ].whereType<String>().join(' · '),
              ),
            ),
        ],
      ),
    );
  }
}
