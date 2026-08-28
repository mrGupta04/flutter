import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/services/geocoding_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/custom_widgets.dart';
import 'selected_location.dart';

class LocationMapPickerPage extends StatefulWidget {
  const LocationMapPickerPage({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
  });

  final double? initialLatitude;
  final double? initialLongitude;

  @override
  State<LocationMapPickerPage> createState() => _LocationMapPickerPageState();
}

class _LocationMapPickerPageState extends State<LocationMapPickerPage> {
  LatLng _target = const LatLng(20.5937, 78.9629);
  String? _preview;
  bool _resolving = false;
  GoogleMapController? _map;

  @override
  void initState() {
    super.initState();
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _target = LatLng(widget.initialLatitude!, widget.initialLongitude!);
    }
    _resolve(_target);
  }

  @override
  void dispose() {
    _map?.dispose();
    super.dispose();
  }

  Future<void> _resolve(LatLng point) async {
    setState(() {
      _target = point;
      _resolving = true;
    });
    try {
      final resolved = await GeocodingService.reverseGeocode(
        latitude: point.latitude,
        longitude: point.longitude,
      );
      if (!mounted) return;
      setState(() {
        _preview = [
          resolved.address,
          if (resolved.city.isNotEmpty) resolved.city,
          if (resolved.state.isNotEmpty) resolved.state,
          if (resolved.pincode.isNotEmpty) resolved.pincode,
        ].join(', ');
        _resolving = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _preview = 'Pinned location';
        _resolving = false;
      });
    }
  }

  void _confirm() {
    Navigator.pop(
      context,
      SelectedLocationResult(
        addressLine: _preview ?? 'Selected location',
        latitude: _target.latitude,
        longitude: _target.longitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pick on map')),
      body: Column(
        children: [
          Expanded(
            child: kIsWeb
                ? Center(
                    child: Text(
                      'Map picking is available on the mobile app.',
                      style: AppTextStyles.bodyMedium,
                    ),
                  )
                : GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _target,
                      zoom: 16,
                    ),
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    markers: {
                      Marker(
                        markerId: const MarkerId('picked'),
                        position: _target,
                      ),
                    },
                    onMapCreated: (controller) => _map = controller,
                    onTap: (point) {
                      _map?.animateCamera(CameraUpdate.newLatLng(point));
                      _resolve(point);
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _resolving ? 'Finding address…' : (_preview ?? ''),
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  CustomButton(
                    label: 'Use this location',
                    isEnabled: !_resolving,
                    onPressed: _confirm,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
