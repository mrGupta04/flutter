import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';

class LiveTrackingMap extends StatefulWidget {
  const LiveTrackingMap({
    super.key,
    required this.patient,
    required this.provider,
    required this.route,
    required this.userAgentPackageName,
    this.patientLabel = 'Home',
    this.providerLabel = 'Nurse',
    this.followProvider = false,
    this.resetViewToken = 0,
    this.bottomPadding = 300,
  });

  final LatLng? patient;
  final LatLng? provider;
  final List<LatLng> route;
  final String userAgentPackageName;
  final String patientLabel;
  final String providerLabel;
  final bool followProvider;
  final int resetViewToken;
  final double bottomPadding;

  @override
  State<LiveTrackingMap> createState() => _LiveTrackingMapState();
}

class _LiveTrackingMapState extends State<LiveTrackingMap> {
  final _controller = MapController();
  bool _ready = false;
  bool _userMoved = false;
  int _fittedToken = -1;

  static const _india = LatLng(20.5937, 78.9629);

  @override
  void didUpdateWidget(covariant LiveTrackingMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_ready) return;
    if (widget.resetViewToken != oldWidget.resetViewToken) {
      _userMoved = false;
      _fit(force: true);
      return;
    }
    if (widget.followProvider &&
        !_userMoved &&
        widget.provider != null &&
        widget.provider != oldWidget.provider) {
      _controller.move(widget.provider!, _controller.camera.zoom);
      return;
    }
    if (_needsFit(oldWidget)) {
      _fit();
    }
  }

  bool _needsFit(LiveTrackingMap oldWidget) {
    return widget.patient != oldWidget.patient ||
        (oldWidget.provider == null && widget.provider != null);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _fit({bool force = false}) {
    if (!_ready) return;
    if (!force && _userMoved && _fittedToken == widget.resetViewToken) return;
    final points = <LatLng>[
      if (widget.patient != null) widget.patient!,
      if (widget.provider != null) widget.provider!,
    ];
    if (points.isEmpty) return;
    _fittedToken = widget.resetViewToken;
    if (points.length == 1) {
      _controller.move(points.first, 15.2);
      return;
    }
    _controller.fitCamera(
      CameraFit.coordinates(
        coordinates: points,
        padding: EdgeInsets.fromLTRB(48, 110, 48, widget.bottomPadding),
        maxZoom: 16,
        minZoom: 11,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.provider ?? widget.patient ?? _india;
    return FlutterMap(
      mapController: _controller,
      options: MapOptions(
        initialCenter: initial,
        initialZoom: 14.6,
        onMapReady: () {
          _ready = true;
          _fit(force: true);
        },
        onPositionChanged: (camera, hasGesture) {
          if (hasGesture) _userMoved = true;
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: widget.userAgentPackageName,
        ),
        if (widget.route.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: widget.route,
                color: AppColors.primary,
                strokeWidth: 6,
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            if (widget.patient != null)
              Marker(
                point: widget.patient!,
                width: 44,
                height: 44,
                alignment: Alignment.bottomCenter,
                child: Tooltip(
                  message: widget.patientLabel,
                  child: const Icon(
                    Icons.home_rounded,
                    color: Color(0xFFE53935),
                    size: 40,
                  ),
                ),
              ),
            if (widget.provider != null)
              Marker(
                point: widget.provider!,
                width: 44,
                height: 44,
                alignment: Alignment.bottomCenter,
                child: Tooltip(
                  message: widget.providerLabel,
                  child: const Icon(
                    Icons.navigation_rounded,
                    color: Color(0xFF1E88E5),
                    size: 36,
                  ),
                ),
              ),
          ],
        ),
        const SimpleAttributionWidget(
          source: Text('OpenStreetMap'),
        ),
      ],
    );
  }
}
