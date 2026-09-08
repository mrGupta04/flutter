import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/socket_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/models/ambulance_booking_model.dart';
import '../../../../data/repositories/ambulance_repository.dart';

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
  final _repo = AmbulanceRepository();
  GoogleMapController? _mapController;
  Timer? _pollTimer;
  bool _loading = true;
  String? _error;
  AmbulanceBookingModel? _booking;

  @override
  void initState() {
    super.initState();
    _fetch();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _fetch());
    unawaited(_listenRealtime());
  }

  Future<void> _listenRealtime() async {
    try {
      await SocketService.instance.connectIfAuthenticated();
      SocketService.instance.joinBookingRoom(widget.bookingId);
      SocketService.instance.on('ambulance_location_updated', _onRealtime);
      SocketService.instance.on('ambulance_event', _onRealtime);
      SocketService.instance.on('ambulance_assigned', _onRealtime);
      SocketService.instance.on('ambulance_driver_accepted', _onRealtime);
      SocketService.instance.on('ambulance_driver_en_route', _onRealtime);
      SocketService.instance.on('ambulance_arrived', _onRealtime);
      SocketService.instance.on('patient_picked_up', _onRealtime);
      SocketService.instance.on('ambulance_trip_started', _onRealtime);
      SocketService.instance.on('ambulance_destination_reached', _onRealtime);
      SocketService.instance.on('ambulance_trip_completed', _onRealtime);
      SocketService.instance.on('ambulance_request_cancelled', _onRealtime);
    } catch (_) {
      // Polling already covers offline / unsigned-in sessions.
    }
  }

  void _onRealtime(dynamic _) {
    _fetch();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    SocketService.instance.off('ambulance_location_updated', _onRealtime);
    SocketService.instance.off('ambulance_event', _onRealtime);
    SocketService.instance.off('ambulance_assigned', _onRealtime);
    SocketService.instance.off('ambulance_driver_accepted', _onRealtime);
    SocketService.instance.off('ambulance_driver_en_route', _onRealtime);
    SocketService.instance.off('ambulance_arrived', _onRealtime);
    SocketService.instance.off('patient_picked_up', _onRealtime);
    SocketService.instance.off('ambulance_trip_started', _onRealtime);
    SocketService.instance.off('ambulance_destination_reached', _onRealtime);
    SocketService.instance.off('ambulance_trip_completed', _onRealtime);
    SocketService.instance.off('ambulance_request_cancelled', _onRealtime);
    if (SocketService.instance.joinedBookingId == widget.bookingId) {
      SocketService.instance.leaveBookingRoom();
    }
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
    final response = await _repo.getMyBooking(widget.bookingId);
    if (!mounted) return;
    if (!response.success || response.data == null) {
      setState(() {
        _loading = false;
        _error = response.error ?? 'Unable to load trip';
      });
      return;
    }
    final booking = response.data!;
    setState(() {
      _loading = false;
      _error = null;
      _booking = booking;
    });
    final focus = _ambulanceLatLng ?? _pickupLatLng;
    if (focus != null && _mapController != null) {
      await _mapController!.animateCamera(CameraUpdate.newLatLngZoom(focus, 14));
    }
  }

  LatLng? get _pickupLatLng {
    final booking = _booking;
    if (booking?.pickupLatitude == null || booking?.pickupLongitude == null) {
      return null;
    }
    return LatLng(booking!.pickupLatitude!, booking.pickupLongitude!);
  }

  LatLng? get _ambulanceLatLng {
    final booking = _booking;
    if (booking?.liveLatitude == null || booking?.liveLongitude == null) {
      return null;
    }
    return LatLng(booking!.liveLatitude!, booking.liveLongitude!);
  }

  LatLng? get _dropLatLng {
    final booking = _booking;
    if (booking?.dropLatitude == null || booking?.dropLongitude == null) {
      return null;
    }
    return LatLng(booking!.dropLatitude!, booking.dropLongitude!);
  }

  Set<Polyline> get _polylines {
    final goingToDrop = const {
      'patient_picked_up',
      'en_route_to_destination',
      'arrived_at_destination',
    }.contains(_booking?.status);
    final points = <LatLng>[
      ?_ambulanceLatLng,
      ?_pickupLatLng,
      if (goingToDrop) ?_dropLatLng,
    ];
    if (points.length < 2) return {};
    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: points,
        color: const Color(0xFF1565C0),
        width: 5,
      ),
    };
  }

  Set<Marker> get _markers {
    final markers = <Marker>{};
    if (_pickupLatLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: _pickupLatLng!,
          infoWindow: const InfoWindow(title: 'Pickup'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );
    }
    if (_dropLatLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: _dropLatLng!,
          infoWindow: InfoWindow(title: _booking?.destinationHospitalName ?? 'Destination'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
    }
    if (_ambulanceLatLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('ambulance'),
          position: _ambulanceLatLng!,
          infoWindow: const InfoWindow(title: 'Ambulance'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }
    return markers;
  }

  Future<void> _call(String? number) async {
    if (number == null || number.trim().isEmpty) return;
    await launchUrl(Uri(scheme: 'tel', path: number.trim()));
  }

  Future<void> _retry() async {
    final response = await _repo.retryDispatch(widget.bookingId);
    if (!mounted) return;
    if (response.success) {
      SnackBarHelper.showSuccess(context, response.message ?? 'Search expanded');
      _fetch();
    } else {
      SnackBarHelper.showError(context, response.error ?? 'Could not expand search');
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = _booking;
    final initial = _ambulanceLatLng ?? _pickupLatLng ?? const LatLng(28.6139, 77.2090);
    final stale = booking?.locationUnavailable == true ||
        (booking?.liveLatitude == null && booking?.canTrack == true);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(booking?.statusLabel ?? 'Ambulance on the way'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => context.push(
              '${AppConstants.routeAmbulanceTripDetail}?id=${widget.bookingId}',
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : booking == null
              ? Center(child: Text(_error ?? 'Trip not found'))
              : Column(
                  children: [
                    if (booking.isSearching)
                      const LinearProgressIndicator(),
                    Expanded(
                      child: Stack(
                        children: [
                          GoogleMap(
                            initialCameraPosition: CameraPosition(target: initial, zoom: 14),
                            markers: _markers,
                            polylines: _polylines,
                            myLocationEnabled: true,
                            myLocationButtonEnabled: true,
                            onMapCreated: (controller) => _mapController = controller,
                          ),
                          if (stale)
                            Positioned(
                              top: 12,
                              left: 12,
                              right: 12,
                              child: Material(
                                color: Colors.black.withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(10),
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Text(
                                    booking.locationMessage ??
                                        'Ambulance location temporarily unavailable',
                                    style: const TextStyle(color: Colors.white),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      decoration: const BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  booking.isSearching
                                      ? 'Finding a nearby ambulance'
                                      : booking.statusLabel ?? 'Ambulance on the way',
                                  style: AppTextStyles.titleSmall.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              Text(
                                booking.estimatedArrivalMinutes == null
                                    ? 'ETA —'
                                    : '${booking.estimatedArrivalMinutes} min',
                                style: AppTextStyles.titleSmall.copyWith(
                                  color: const Color(0xFF1565C0),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            booking.ambulanceServiceName ??
                                'Matching a verified ambulance near your pickup',
                          ),
                          Text(
                            [
                              booking.assignedVehicleType ?? booking.vehicleTypeRequested,
                              booking.assignedVehicleRegistration,
                              booking.assignedDriverName,
                            ].where((item) => item != null && item.toString().isNotEmpty).join(' · '),
                          ),
                          if (booking.pickupAddress != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Pickup: ${booking.pickupAddress}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                          if (booking.fare != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              [
                                'Fare ₹${booking.fare!.total.toStringAsFixed(0)}',
                                if (booking.fare!.perKm != null)
                                  '₹${booking.fare!.perKm!.toStringAsFixed(0)}/km',
                                if (booking.fare!.estimated) 'estimate',
                              ].join(' · '),
                              style: AppTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                          if (booking.needsEscalation) ...[
                            const SizedBox(height: 10),
                            const Text(
                              'No ambulance has accepted yet. Expand the search or call 112 / 108. This app does not replace emergency services.',
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _retry,
                                    child: const Text('Expand search'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: () => _call('112'),
                                    child: const Text('Call 112'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _call(
                                    booking.assignedDriverPhone ??
                                        booking.contactPhone ??
                                        booking.patientMobile,
                                  ),
                                  icon: const Icon(Icons.call),
                                  label: const Text('Call driver'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: booking.canTrack
                                      ? () => context.push(
                                            '${AppConstants.routeBookingChat}?bookingId=${booking.id}&title=${Uri.encodeComponent('Ambulance chat')}',
                                          )
                                      : null,
                                  icon: const Icon(Icons.chat_bubble_outline),
                                  label: const Text('Chat'),
                                ),
                              ),
                            ],
                          ),
                          if (booking.isActive) ...[
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () async {
                                final response = await _repo.cancelMine(
                                  widget.bookingId,
                                  reason: 'User cancelled from live tracking',
                                );
                                if (!mounted) return;
                                if (!context.mounted) return;
                                if (response.success) {
                                  SnackBarHelper.showSuccess(context, 'Trip cancelled');
                                  context.pop();
                                } else {
                                  SnackBarHelper.showError(
                                    context,
                                    response.error ?? 'Could not cancel',
                                  );
                                }
                              },
                              child: const Text('Cancel trip'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
