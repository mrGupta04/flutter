import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/services/tracking_location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../provider/provider_trip_provider.dart';

class ProviderTripScreen extends ConsumerStatefulWidget {
  const ProviderTripScreen({
    super.key,
    required this.bookingId,
    required this.role,
    this.patientName,
    this.patientAddress,
    this.patientLatitude,
    this.patientLongitude,
  });

  final String bookingId;
  final String role;
  final String? patientName;
  final String? patientAddress;
  final double? patientLatitude;
  final double? patientLongitude;

  @override
  ConsumerState<ProviderTripScreen> createState() => _ProviderTripScreenState();
}

class _ProviderTripScreenState extends ConsumerState<ProviderTripScreen> {
  GoogleMapController? _mapController;
  bool _cameraFitted = false;
  late final ProviderTripArgs _args;

  @override
  void initState() {
    super.initState();
    _args = ProviderTripArgs(
      bookingId: widget.bookingId,
      role: widget.role,
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _startTrip() async {
    final ok = await TrackingLocationService.instance.ensurePermissions(context);
    if (!ok || !mounted) return;
    await ref.read(providerTripProvider(_args).notifier).startTrip();
  }

  void _fitCamera(LatLng? patient, LatLng? self) {
    if (_cameraFitted || _mapController == null) return;
    if (patient != null && self != null) {
      _cameraFitted = true;
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(
              patient.latitude < self.latitude ? patient.latitude : self.latitude,
              patient.longitude < self.longitude
                  ? patient.longitude
                  : self.longitude,
            ),
            northeast: LatLng(
              patient.latitude > self.latitude ? patient.latitude : self.latitude,
              patient.longitude > self.longitude
                  ? patient.longitude
                  : self.longitude,
            ),
          ),
          72,
        ),
      );
    } else {
      final focus = self ?? patient;
      if (focus != null) {
        _cameraFitted = true;
        _mapController!.animateCamera(CameraUpdate.newLatLngZoom(focus, 15));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = ref.watch(providerTripProvider(_args));
    final snapshot = trip.snapshot;
    final patientLat = snapshot?.patientLatitude ?? widget.patientLatitude;
    final patientLng = snapshot?.patientLongitude ?? widget.patientLongitude;
    final patient = (patientLat != null && patientLng != null)
        ? LatLng(patientLat, patientLng)
        : null;
    final self = (snapshot?.currentLatitude != null &&
            snapshot?.currentLongitude != null)
        ? LatLng(snapshot!.currentLatitude!, snapshot.currentLongitude!)
        : null;
    final name = snapshot?.patientName ?? widget.patientName ?? 'Patient';
    final address = [
      snapshot?.patientAddress ?? widget.patientAddress,
      snapshot?.patientCity,
    ].where((e) => e != null && e.trim().isNotEmpty).join(', ');
    final onTheWay = snapshot?.isOnTheWay == true;
    final terminal = snapshot?.isTerminal == true;
    final initial = patient ?? self ?? const LatLng(20.5937, 78.9629);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitCamera(patient, self);
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Home visit'),
      ),
      body: trip.loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: initial,
                      zoom: 14,
                    ),
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: false,
                    markers: {
                      if (patient != null)
                        Marker(
                          markerId: const MarkerId('patient'),
                          position: patient,
                          infoWindow: InfoWindow(title: name),
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueAzure,
                          ),
                        ),
                      if (self != null)
                        Marker(
                          markerId: const MarkerId('provider'),
                          position: self,
                          infoWindow: const InfoWindow(title: 'You'),
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueGreen,
                          ),
                        ),
                    },
                    onMapCreated: (controller) => _mapController = controller,
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                  color: AppColors.white,
                  child: SafeArea(
                    top: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          onTheWay
                              ? 'Trip started'
                              : terminal
                                  ? 'Tracking stopped'
                                  : 'Patient location',
                          style: AppTextStyles.titleSmall.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          onTheWay
                              ? 'You are on the way to $name'
                              : name,
                          style: AppTextStyles.bodyMedium,
                        ),
                        if (address.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            address,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        if (trip.error != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            trip.error!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ],
                        if (!trip.socketConnected) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Reconnecting live updates… location is still being saved.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          'Booking ID: ${widget.bookingId}',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (!onTheWay && !terminal)
                          FilledButton(
                            onPressed: trip.starting ? null : _startTrip,
                            child: Text(trip.starting ? 'Starting…' : 'Start trip'),
                          )
                        else if (onTheWay) ...[
                          FilledButton(
                            onPressed: () => ref
                                .read(providerTripProvider(_args).notifier)
                                .markArrived(),
                            child: const Text('Arrived'),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton(
                            onPressed: () => ref
                                .read(providerTripProvider(_args).notifier)
                                .stopTrip(),
                            child: const Text('Stop trip'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
