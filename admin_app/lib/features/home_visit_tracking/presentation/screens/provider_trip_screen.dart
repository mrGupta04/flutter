import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/services/tracking_location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../provider/provider_trip_provider.dart';
import '../widgets/live_tracking_map.dart';

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
  int _resetViewToken = 0;
  late final ProviderTripArgs _args;

  @override
  void initState() {
    super.initState();
    _args = ProviderTripArgs(
      bookingId: widget.bookingId,
      role: widget.role,
    );
  }

  Future<void> _startTrip() async {
    final ok =
        await TrackingLocationService.instance.ensurePermissions(context);
    if (!ok || !mounted) return;
    await ref.read(providerTripProvider(_args).notifier).startTrip();
  }

  Future<void> _openDirections(LatLng dest) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${dest.latitude},${dest.longitude}&travelmode=driving',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      await launchUrl(uri);
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
    final eta = snapshot?.etaMinutes;
    final distance = snapshot?.distanceText;

    final routePoints = <LatLng>[
      ...?snapshot?.polyline
          .map((p) => LatLng(p.latitude, p.longitude)),
    ];
    if (routePoints.length < 2 && patient != null && self != null) {
      routePoints
        ..clear()
        ..add(self)
        ..add(patient);
    }

    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AppColors.grey100,
      body: Stack(
        children: [
          Positioned.fill(
            child: LiveTrackingMap(
              patient: patient,
              provider: self,
              route: routePoints,
              userAgentPackageName: 'com.onemg.admin',
              patientLabel: name,
              providerLabel: 'You',
              followProvider: onTheWay,
              resetViewToken: _resetViewToken,
            ),
          ),
          Positioned(
            top: topInset + 8,
            left: 12,
            right: 12,
            child: Row(
              children: [
                _RoundMapButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => Navigator.maybePop(context),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 16,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      onTheWay
                          ? 'On the way to $name'
                          : terminal
                              ? 'Visit tracking ended'
                              : 'Navigate to $name',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (trip.loading)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(minHeight: 2),
            ),
          Positioned(
            right: 16,
            bottom: 292,
            child: _RoundMapButton(
              icon: Icons.my_location_rounded,
              onTap: () => setState(() => _resetViewToken++),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _TripSheet(
              name: name,
              address: address,
              onTheWay: onTheWay,
              terminal: terminal,
              etaMinutes: eta,
              distanceText: distance,
              durationText: snapshot?.durationText,
              error: trip.error,
              socketConnected: trip.socketConnected,
              starting: trip.starting,
              patient: patient,
              onStart: _startTrip,
              onArrived: () =>
                  ref.read(providerTripProvider(_args).notifier).markArrived(),
              onStop: () =>
                  ref.read(providerTripProvider(_args).notifier).stopTrip(),
              onNavigate:
                  patient == null ? null : () => _openDirections(patient),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundMapButton extends StatelessWidget {
  const _RoundMapButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

class _TripSheet extends StatelessWidget {
  const _TripSheet({
    required this.name,
    required this.address,
    required this.onTheWay,
    required this.terminal,
    required this.etaMinutes,
    required this.distanceText,
    required this.durationText,
    required this.error,
    required this.socketConnected,
    required this.starting,
    required this.patient,
    required this.onStart,
    required this.onArrived,
    required this.onStop,
    required this.onNavigate,
  });

  final String name;
  final String address;
  final bool onTheWay;
  final bool terminal;
  final int? etaMinutes;
  final String? distanceText;
  final String? durationText;
  final String? error;
  final bool socketConnected;
  final bool starting;
  final LatLng? patient;
  final VoidCallback onStart;
  final VoidCallback onArrived;
  final VoidCallback onStop;
  final VoidCallback? onNavigate;

  @override
  Widget build(BuildContext context) {
    final etaLabel = etaMinutes != null
        ? '$etaMinutes min'
        : (durationText ?? (onTheWay ? '…' : '--'));

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 24,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.grey300,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            etaLabel.replaceAll(' min', ''),
                            style: AppTextStyles.titleLarge.copyWith(
                              fontWeight: FontWeight.w900,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          Text(
                            'min',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            onTheWay
                                ? 'Heading to patient'
                                : terminal
                                    ? 'Tracking stopped'
                                    : 'Ready to start trip',
                            style: AppTextStyles.titleSmall.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            [
                              if (distanceText != null &&
                                  distanceText!.isNotEmpty)
                                distanceText,
                              name,
                            ].join(' · '),
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (address.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              address,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    error!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ],
                if (onTheWay && !socketConnected) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Reconnecting live updates… GPS is still being saved.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (!onTheWay && !terminal)
                  FilledButton(
                    onPressed: starting ? null : onStart,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(starting ? 'Starting…' : 'Start trip'),
                  )
                else if (onTheWay) ...[
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: onArrived,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('I have arrived'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 52,
                        width: 52,
                        child: OutlinedButton(
                          onPressed: onNavigate,
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Icon(Icons.turn_right_rounded),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: onStop,
                    child: const Text('Stop trip'),
                  ),
                ]
                else if (patient != null)
                  OutlinedButton.icon(
                    onPressed: onNavigate,
                    icon: const Icon(Icons.directions_rounded),
                    label: const Text('Open in Google Maps'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
