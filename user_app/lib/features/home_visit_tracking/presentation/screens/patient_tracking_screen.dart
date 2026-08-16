import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../provider/patient_tracking_provider.dart';

class PatientTrackingScreen extends ConsumerStatefulWidget {
  const PatientTrackingScreen({
    super.key,
    required this.bookingId,
  });

  final String bookingId;

  @override
  ConsumerState<PatientTrackingScreen> createState() =>
      _PatientTrackingScreenState();
}

class _PatientTrackingScreenState extends ConsumerState<PatientTrackingScreen>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  AnimationController? _markerAnim;
  LatLng? _animatedProvider;
  LatLng? _animFrom;
  LatLng? _animTo;
  bool _cameraFitted = false;
  bool _userMovedCamera = false;

  @override
  void dispose() {
    _markerAnim?.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _animateProvider(LatLng next) {
    final from = _animatedProvider ?? next;
    _markerAnim?.dispose();
    _animFrom = from;
    _animTo = next;
    _markerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..addListener(() {
        final a = _animFrom;
        final b = _animTo;
        if (a == null || b == null) return;
        final t = Curves.easeInOut.transform(_markerAnim!.value);
        setState(() {
          _animatedProvider = LatLng(
            a.latitude + (b.latitude - a.latitude) * t,
            a.longitude + (b.longitude - a.longitude) * t,
          );
        });
      });
    _markerAnim!.forward();
    if (!_userMovedCamera && _mapController != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLng(next));
    }
  }

  Future<void> _fitOnce(LatLng? patient, LatLng? provider) async {
    if (_cameraFitted || _mapController == null) return;
    if (patient != null && provider != null) {
      _cameraFitted = true;
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(
              patient.latitude < provider.latitude
                  ? patient.latitude
                  : provider.latitude,
              patient.longitude < provider.longitude
                  ? patient.longitude
                  : provider.longitude,
            ),
            northeast: LatLng(
              patient.latitude > provider.latitude
                  ? patient.latitude
                  : provider.latitude,
              patient.longitude > provider.longitude
                  ? patient.longitude
                  : provider.longitude,
            ),
          ),
          72,
        ),
      );
    } else {
      final focus = provider ?? patient;
      if (focus != null) {
        _cameraFitted = true;
        await _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(focus, 15),
        );
      }
    }
  }

  Future<void> _call(String? mobile) async {
    if (mobile == null || mobile.trim().isEmpty) return;
    final uri = Uri(scheme: 'tel', path: mobile.trim());
    await launchUrl(uri);
  }

  String _lastUpdatedLabel(DateTime? at) {
    if (at == null) return 'Waiting for live location';
    final seconds = DateTime.now().difference(at.toLocal()).inSeconds;
    if (seconds < 10) return 'Updated just now';
    if (seconds < 60) return 'Updated ${seconds}s ago';
    final minutes = (seconds / 60).floor();
    return 'Updated ${minutes}m ago';
  }

  @override
  Widget build(BuildContext context) {
    final tracking = ref.watch(patientTrackingProvider(widget.bookingId));
    final snapshot = tracking.snapshot;
    final patient = (snapshot?.patientLatitude != null &&
            snapshot?.patientLongitude != null)
        ? LatLng(snapshot!.patientLatitude!, snapshot.patientLongitude!)
        : null;
    final rawProvider = (snapshot?.currentLatitude != null &&
            snapshot?.currentLongitude != null)
        ? LatLng(snapshot!.currentLatitude!, snapshot.currentLongitude!)
        : null;

    if (rawProvider != null &&
        (_animatedProvider == null ||
            _animTo == null ||
            _animTo!.latitude != rawProvider.latitude ||
            _animTo!.longitude != rawProvider.longitude)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _animateProvider(rawProvider);
        _fitOnce(patient, rawProvider);
      });
    } else if (patient != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fitOnce(patient, rawProvider);
      });
    }

    final providerPos = _animatedProvider ?? rawProvider;
    final initial = providerPos ?? patient ?? const LatLng(20.5937, 78.9629);
    final title = snapshot?.isNurse == true ? 'Track nurse' : 'Track doctor';
    final polylines = <Polyline>{};
    if (snapshot != null && snapshot.polyline.length >= 2) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          color: AppColors.primary,
          width: 5,
          points: snapshot.polyline
              .map((p) => LatLng(p.latitude, p.longitude))
              .toList(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title)),
      body: tracking.loading && snapshot == null
          ? const Center(child: CircularProgressIndicator())
          : tracking.error != null && snapshot == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(tracking.error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () => ref
                              .read(
                                patientTrackingProvider(widget.bookingId)
                                    .notifier,
                              )
                              .refresh(),
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
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        zoomControlsEnabled: false,
                        markers: {
                          if (patient != null)
                            Marker(
                              markerId: const MarkerId('patient'),
                              position: patient,
                              infoWindow: const InfoWindow(title: 'You'),
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueAzure,
                              ),
                            ),
                          if (providerPos != null)
                            Marker(
                              markerId: const MarkerId('provider'),
                              position: providerPos,
                              rotation: snapshot?.heading ?? 0,
                              flat: true,
                              infoWindow: InfoWindow(
                                title: snapshot?.providerName ?? 'Provider',
                              ),
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueGreen,
                              ),
                            ),
                        },
                        polylines: polylines,
                        onMapCreated: (controller) => _mapController = controller,
                        onCameraMoveStarted: () => _userMovedCamera = true,
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
                              snapshot?.isOnTheWay == true
                                  ? (snapshot!.isNurse
                                      ? '🚗 Nurse is on the way'
                                      : '🚗 Doctor is on the way')
                                  : (snapshot?.statusLabel ?? 'Live tracking'),
                              style: AppTextStyles.titleSmall.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (snapshot?.providerName != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                snapshot!.providerName!,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Text(
                              snapshot?.distanceText ??
                                  (providerPos == null
                                      ? 'Waiting for live location'
                                      : 'Calculating distance…'),
                              style: AppTextStyles.titleSmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (snapshot?.etaMinutes != null)
                              Text(
                                'Estimated arrival: ${snapshot!.etaMinutes} min',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            else if (snapshot?.durationText != null)
                              Text(
                                'Estimated arrival: ${snapshot!.durationText}',
                                style: AppTextStyles.bodyMedium,
                              ),
                            const SizedBox(height: 4),
                            Text(
                              _lastUpdatedLabel(snapshot?.lastUpdatedAt),
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (!tracking.socketConnected)
                              Text(
                                'Reconnecting live updates…',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.warning,
                                ),
                              ),
                            if (tracking.providerOffline)
                              Text(
                                'Provider appears offline. Showing last known location.',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.warning,
                                ),
                              ),
                            if (tracking.error != null)
                              Text(
                                tracking.error!,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.error,
                                ),
                              ),
                            const SizedBox(height: 12),
                            if (snapshot?.providerMobile != null &&
                                snapshot!.providerMobile!.isNotEmpty)
                              FilledButton.icon(
                                onPressed: () => _call(snapshot.providerMobile),
                                icon: const Icon(Icons.call_rounded, size: 18),
                                label: Text(
                                  snapshot.isNurse ? 'Call nurse' : 'Call doctor',
                                ),
                              ),
                            const SizedBox(height: 8),
                            Text(
                              'Booking ID: ${widget.bookingId}',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
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
