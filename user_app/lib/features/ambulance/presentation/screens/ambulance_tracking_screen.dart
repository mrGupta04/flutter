import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/services/dio_service.dart';

class AmbulanceTrackingScreen extends StatefulWidget {
  const AmbulanceTrackingScreen({
    super.key,
    required this.bookingId,
  });

  final String bookingId;

  @override
  State<AmbulanceTrackingScreen> createState() =>
      _AmbulanceTrackingScreenState();
}

class _AmbulanceTrackingScreenState extends State<AmbulanceTrackingScreen> {
  GoogleMapController? _mapController;
  Timer? _pollTimer;
  bool _loading = true;
  String? _error;
  String _status = '';
  LatLng? _pickup;
  LatLng? _ambulance;
  DateTime? _updatedAt;

  @override
  void initState() {
    super.initState();
    _fetch();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _fetch());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    if (widget.bookingId.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Missing booking id';
      });
      return;
    }
    try {
      final response = await DioService().get(
        AppConstants.endpointAmbulanceBooking(widget.bookingId),
      );
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};

      LatLng? pickup;
      final pLat = (data['pickupLatitude'] as num?)?.toDouble();
      final pLng = (data['pickupLongitude'] as num?)?.toDouble();
      if (pLat != null && pLng != null) {
        pickup = LatLng(pLat, pLng);
      }

      LatLng? ambulance;
      final aLat = (data['liveLatitude'] as num?)?.toDouble();
      final aLng = (data['liveLongitude'] as num?)?.toDouble();
      if (aLat != null && aLng != null) {
        ambulance = LatLng(aLat, aLng);
      }

      final updatedRaw = data['liveLocationUpdatedAt'];
      DateTime? updatedAt;
      if (updatedRaw != null) {
        updatedAt = DateTime.tryParse(updatedRaw.toString());
      }

      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = null;
        _status = data['status']?.toString() ?? '';
        _pickup = pickup;
        _ambulance = ambulance;
        _updatedAt = updatedAt;
      });

      final focus = ambulance ?? pickup;
      if (focus != null && _mapController != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(focus, 14),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Set<Marker> get _markers {
    final markers = <Marker>{};
    if (_pickup != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: _pickup!,
          infoWindow: const InfoWindow(title: 'Pickup'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );
    }
    if (_ambulance != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('ambulance'),
          position: _ambulance!,
          infoWindow: const InfoWindow(title: 'Ambulance'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final initial = _ambulance ??
        _pickup ??
        const LatLng(28.6139, 77.2090);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Live ambulance')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _pickup == null && _ambulance == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _fetch,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: initial,
                          zoom: 14,
                        ),
                        markers: _markers,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        onMapCreated: (c) => _mapController = c,
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                      color: AppColors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _status.isEmpty
                                ? 'Tracking…'
                                : 'Status: ${_status.replaceAll('_', ' ')}',
                            style: AppTextStyles.titleSmall.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _ambulance == null
                                ? 'Waiting for ambulance location…'
                                : _updatedAt != null
                                    ? 'Last update: ${_updatedAt!.toLocal()}'
                                    : 'Live location available',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
