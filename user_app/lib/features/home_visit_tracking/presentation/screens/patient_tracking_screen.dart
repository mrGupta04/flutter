import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../provider/patient_tracking_provider.dart';
import '../widgets/live_tracking_map.dart';

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

class _PatientTrackingScreenState extends ConsumerState<PatientTrackingScreen> {
  int _resetViewToken = 0;

  Future<void> _call(String? mobile) async {
    if (mobile == null || mobile.trim().isEmpty) return;
    await launchUrl(Uri(scheme: 'tel', path: mobile.trim()));
  }

  String _lastUpdatedLabel(DateTime? at) {
    if (at == null) return 'Waiting for live location';
    final seconds = DateTime.now().difference(at.toLocal()).inSeconds;
    if (seconds < 10) return 'Updated just now';
    if (seconds < 60) return 'Updated ${seconds}s ago';
    return 'Updated ${(seconds / 60).floor()}m ago';
  }

  @override
  Widget build(BuildContext context) {
    final tracking = ref.watch(patientTrackingProvider(widget.bookingId));
    final snapshot = tracking.snapshot;
    final patient = (snapshot?.patientLatitude != null &&
            snapshot?.patientLongitude != null)
        ? LatLng(snapshot!.patientLatitude!, snapshot.patientLongitude!)
        : null;
    final providerPos = (snapshot?.currentLatitude != null &&
            snapshot?.currentLongitude != null)
        ? LatLng(snapshot!.currentLatitude!, snapshot.currentLongitude!)
        : null;

    final isNurse = snapshot?.isNurse == true;
    final routePoints = <LatLng>[
      ...snapshot?.polyline.map((p) => LatLng(p.latitude, p.longitude)) ??
          const [],
    ];
    if (routePoints.length < 2 && patient != null && providerPos != null) {
      routePoints
        ..clear()
        ..add(providerPos)
        ..add(patient);
    }

    final eta = snapshot?.etaMinutes;
    final title = snapshot?.isOnTheWay == true
        ? (isNurse ? 'Nurse is on the way' : 'Doctor is on the way')
        : (snapshot?.statusLabel ?? 'Live tracking');

    if (tracking.error != null && snapshot == null && !tracking.loading) {
      return Scaffold(
        appBar: AppBar(title: Text(isNurse ? 'Track nurse' : 'Track doctor')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(tracking.error!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref
                      .read(patientTrackingProvider(widget.bookingId).notifier)
                      .refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AppColors.grey100,
      body: Stack(
        children: [
          Positioned.fill(
            child: LiveTrackingMap(
              patient: patient,
              provider: providerPos,
              route: routePoints,
              userAgentPackageName: 'com.onemg.care',
              patientLabel: 'Your home',
              providerLabel: snapshot?.providerName ??
                  (isNurse ? 'Nurse' : 'Doctor'),
              followProvider: snapshot?.isOnTheWay == true,
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
                      title,
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
          if (tracking.loading && snapshot == null)
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
            child: Material(
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
                                    eta != null ? '$eta' : '--',
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
                                    snapshot?.providerName ??
                                        (isNurse ? 'Nurse' : 'Doctor'),
                                    style: AppTextStyles.titleSmall.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    snapshot?.distanceText ??
                                        (providerPos == null
                                            ? 'Waiting for live location'
                                            : 'Calculating distance…'),
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _lastUpdatedLabel(snapshot?.lastUpdatedAt),
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (snapshot?.providerMobile != null &&
                                snapshot!.providerMobile!.isNotEmpty)
                              Material(
                                color: AppColors.primary,
                                shape: const CircleBorder(),
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: () => _call(snapshot.providerMobile),
                                  child: const SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: Icon(
                                      Icons.call_rounded,
                                      color: AppColors.white,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (!tracking.socketConnected)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Reconnecting live updates… last location is still shown.',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                        if (tracking.providerOffline)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Provider appears offline. Showing last known location.',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                        if (tracking.error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              tracking.error!,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
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
