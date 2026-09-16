import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/service_faqs.dart';
import '../../../../core/providers/user_location_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/user_auth_guard.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../data/models/ambulance_booking_model.dart';
import '../../../../data/models/ambulance_model.dart';
import '../../../../data/models/ambulance_vehicle_types.dart';
import '../../../../data/repositories/ambulance_repository.dart';
import '../../../../features/select_location/select_location_navigation.dart';
import '../../../../features/select_location/selected_location.dart';
import '../../../../features/user_auth/provider/patient_auth_provider.dart';
import '../../../../shared/widgets/service_faq_section.dart';

const _kDefaultCenter = LatLng(28.6139, 77.2090);
const _kRapidoPrimaryIds = [
  'first_responder',
  'bls',
  'basic',
  'als',
  'icu',
  'cardiac',
];

enum _RapidoTab { bike, bls, als, icu, all }

extension _RapidoTabX on _RapidoTab {
  String get label => switch (this) {
        _RapidoTab.bike => 'Bike',
        _RapidoTab.bls => 'BLS',
        _RapidoTab.als => 'ALS',
        _RapidoTab.icu => 'ICU',
        _RapidoTab.all => 'All',
      };
}

class AmbulanceHubScreen extends ConsumerStatefulWidget {
  const AmbulanceHubScreen({super.key});

  @override
  ConsumerState<AmbulanceHubScreen> createState() => _AmbulanceHubScreenState();
}

class _AmbulanceHubScreenState extends ConsumerState<AmbulanceHubScreen> {
  final _repo = AmbulanceRepository();
  GoogleMapController? _mapController;
  SelectedLocationResult? _pickup;
  SelectedLocationResult? _drop;
  String _vehicleType = 'bls';
  _RapidoTab _rapidoTab = _RapidoTab.all;
  AmbulanceBookingModel? _active;
  List<Map<String, dynamic>> _nearby = [];
  Map<String, double> _fares = {};
  bool _estimating = false;
  bool _submitting = false;
  bool _loadingNearby = false;

  List<AmbulanceVehicleType> get _rideTypes => _typesForTab(_rapidoTab);

  List<AmbulanceVehicleType> _typesForTab(_RapidoTab tab) {
    List<AmbulanceVehicleType> byIds(List<String> ids) {
      return ids
          .map(
            (id) => ambulanceVehicleTypes
                .where((type) => type.id == id)
                .firstOrNull,
          )
          .whereType<AmbulanceVehicleType>()
          .toList();
    }

    switch (tab) {
      case _RapidoTab.bike:
        return byIds(const ['first_responder']);
      case _RapidoTab.bls:
        return byIds(const ['bls', 'basic']);
      case _RapidoTab.als:
        return byIds(const ['als', 'cardiac', 'trauma']);
      case _RapidoTab.icu:
        return byIds(const ['icu', 'neonatal', 'pediatric', 'isolation']);
      case _RapidoTab.all:
        final primary = byIds(_kRapidoPrimaryIds);
        final rest = ambulanceVehicleTypes
            .where((type) => !_kRapidoPrimaryIds.contains(type.id))
            .toList();
        return [...primary, ...rest];
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await ref.read(userLocationProvider.notifier).ensureResolved(context);
    if (!mounted) return;
    final location = ref.read(userLocationProvider);
    if (location.hasCoordinates) {
      setState(() {
        _pickup = SelectedLocationResult(
          addressLine: location.displayPlaceCity ?? location.displayCity,
          city: location.city,
          latitude: location.latitude,
          longitude: location.longitude,
          label: 'Current location',
        );
      });
      _moveCamera();
    }
    await Future.wait([_loadActive(), _loadNearby(), _refreshEstimate()]);
  }

  Future<void> _loadActive() async {
    try {
      final response = await _repo.listMyBookings(group: 'active');
      if (!mounted) return;
      AmbulanceBookingModel? active;
      for (final item in response.data ?? <AmbulanceBookingModel>[]) {
        if (item.isActive) {
          active = item;
          break;
        }
      }
      setState(() => _active = active);
    } catch (_) {}
  }

  Future<void> _loadNearby() async {
    final lat = _pickup?.latitude;
    final lng = _pickup?.longitude;
    if (lat == null || lng == null) return;
    setState(() => _loadingNearby = true);
    var pins = <Map<String, dynamic>>[];
    final nearby = await _repo.getNearby(
      latitude: lat,
      longitude: lng,
      vehicleType: _vehicleType,
    );
    if (nearby.success && nearby.data != null) {
      pins = nearby.data!;
    }
    if (pins.isEmpty) {
      final verified = await _repo.getVerifiedAmbulances(pageSize: 40);
      for (final ambulance in verified.data ?? <AmbulanceModel>[]) {
        final vehicles = ambulance.vehicles ?? [];
        final live = vehicles.where((v) => v.isLiveAvailable).toList();
        final source = live.isNotEmpty ? live : vehicles.take(1);
        for (final vehicle in source) {
          pins.add({
            'ambulanceId': ambulance.id,
            'ambulanceServiceName': ambulance.serviceName,
            'vehicleId': vehicle.id,
            'vehicleType': vehicle.vehicleType,
            'latitude': vehicle.currentLatitude ?? ambulance.latitude,
            'longitude': vehicle.currentLongitude ?? ambulance.longitude,
            'etaMinutes': null,
          });
        }
        if (vehicles.isEmpty &&
            ambulance.latitude != null &&
            ambulance.longitude != null) {
          pins.add({
            'ambulanceId': ambulance.id,
            'ambulanceServiceName': ambulance.serviceName,
            'vehicleId': ambulance.id,
            'vehicleType': ambulance.vehicleTypes?.firstOrNull,
            'latitude': ambulance.latitude,
            'longitude': ambulance.longitude,
          });
        }
      }
    }
    if (!mounted) return;
    setState(() {
      _nearby = pins
          .where((item) => item['latitude'] != null && item['longitude'] != null)
          .take(20)
          .toList();
      _loadingNearby = false;
    });
    _moveCamera();
  }

  Future<void> _refreshEstimate() async {
    if (_pickup?.latitude == null) return;
    setState(() => _estimating = true);
    final types = _rideTypes.map((type) => type.id).toSet();
    final results = await Future.wait(
      types.map((id) async {
        final estimate = await _repo.estimateFare({
          'vehicleType': id,
          'pickupLatitude': _pickup?.latitude,
          'pickupLongitude': _pickup?.longitude,
          'dropLatitude': _drop?.latitude,
          'dropLongitude': _drop?.longitude,
          'isEmergency': true,
        });
        final fare = estimate.data?['fare'];
        final total = fare is Map ? (fare['total'] as num?)?.toDouble() : null;
        return MapEntry(id, total);
      }),
    );
    if (!mounted) return;
    setState(() {
      _fares = {
        for (final entry in results)
          if (entry.value != null) entry.key: entry.value!,
      };
      _estimating = false;
    });
  }

  Future<void> _pickLocation({required bool pickup}) async {
    final result = await openSelectLocation(
      context,
      args: SelectLocationArgs(initial: pickup ? _pickup : _drop),
    );
    if (result == null || !mounted) return;
    setState(() {
      if (pickup) {
        _pickup = result;
      } else {
        _drop = result;
      }
    });
    _moveCamera();
    await Future.wait([_loadNearby(), _refreshEstimate()]);
  }

  Future<void> _moveCamera() async {
    final controller = _mapController;
    if (controller == null) return;
    final points = <LatLng>[
      if (_pickup?.hasCoordinates == true)
        LatLng(_pickup!.latitude!, _pickup!.longitude!),
      if (_drop?.hasCoordinates == true)
        LatLng(_drop!.latitude!, _drop!.longitude!),
      ..._nearby.take(6).map((item) {
        return LatLng(
          (item['latitude'] as num).toDouble(),
          (item['longitude'] as num).toDouble(),
        );
      }),
    ];
    if (points.isEmpty) return;
    if (points.length == 1) {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(points.first, 14.5),
      );
      return;
    }
    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;
    for (final point in points) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }
    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        72,
      ),
    );
  }

  Set<Marker> get _markers {
    final markers = <Marker>{};
    if (_pickup?.hasCoordinates == true) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: LatLng(_pickup!.latitude!, _pickup!.longitude!),
          infoWindow: const InfoWindow(title: 'Pickup'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );
    }
    if (_drop?.hasCoordinates == true) {
      markers.add(
        Marker(
          markerId: const MarkerId('drop'),
          position: LatLng(_drop!.latitude!, _drop!.longitude!),
          infoWindow: InfoWindow(title: _drop?.label ?? 'Destination'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
    }
    for (final item in _nearby) {
      final lat = (item['latitude'] as num?)?.toDouble();
      final lng = (item['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;
      final id = '${item['vehicleId'] ?? item['ambulanceId']}-$lat-$lng';
      markers.add(
        Marker(
          markerId: MarkerId(id),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: item['ambulanceServiceName']?.toString() ?? 'Ambulance',
            snippet: item['etaMinutes'] != null
                ? '${item['etaMinutes']} min away'
                : item['vehicleType']?.toString(),
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }
    return markers;
  }

  Set<Polyline> get _polylines {
    if (_pickup?.hasCoordinates != true || _drop?.hasCoordinates != true) {
      return {};
    }
    return {
      Polyline(
        polylineId: const PolylineId('trip'),
        points: [
          LatLng(_pickup!.latitude!, _pickup!.longitude!),
          LatLng(_drop!.latitude!, _drop!.longitude!),
        ],
        color: AppColors.primary,
        width: 4,
      ),
    };
  }

  Future<void> _callEmergency() async {
    final uri = Uri.parse('tel:112');
    if (!await launchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _bookNow() async {
    final loggedIn = await ensureUserLoggedIn(
      context,
      message: 'Please log in before requesting an ambulance.',
    );
    if (!loggedIn || !mounted) return;
    if (_pickup == null || _pickup!.addressLine.trim().length < 5) {
      SnackBarHelper.showError(context, 'Set your pickup location');
      return;
    }

    final user = ref.read(patientAuthProvider).user;
    var name = user?.fullName.trim() ?? '';
    var mobile = (user?.mobileNumber ?? '').trim();
    if (name.length < 2 || mobile.isEmpty) {
      final details = await _askPatientDetails(name: name, mobile: mobile);
      if (details == null || !mounted) return;
      name = details.$1;
      mobile = details.$2;
    }
    if (name.length < 2) {
      SnackBarHelper.showError(context, 'Patient name is required');
      return;
    }

    setState(() => _submitting = true);
    final response = await _repo.createEmergency({
      'patientName': name,
      'patientMobile': mobile.isEmpty ? user?.mobileNumber : mobile,
      'contactPerson': user?.fullName,
      'contactPhone': mobile,
      'pickupAddress': _pickup!.displayLine,
      'pickupCity': _pickup!.city,
      'pickupPincode': _pickup!.pincode,
      'pickupLatitude': _pickup!.latitude,
      'pickupLongitude': _pickup!.longitude,
      'dropAddress': _drop?.displayLine,
      'dropCity': _drop?.city,
      'dropLatitude': _drop?.latitude,
      'dropLongitude': _drop?.longitude,
      'destinationType': _drop == null ? 'other' : 'hospital',
      'destinationHospitalName': _drop?.label,
      'vehicleTypeRequested': _vehicleType,
    });
    if (!mounted) return;
    setState(() => _submitting = false);
    if (response.success && response.data != null) {
      context.go(
        '${AppConstants.routeAmbulanceTrack}?bookingId=${response.data!.id}',
      );
    } else {
      SnackBarHelper.showError(
        context,
        response.error ?? 'Could not book an ambulance',
      );
    }
  }

  Future<(String, String)?> _askPatientDetails({
    required String name,
    required String mobile,
  }) {
    final nameController = TextEditingController(text: name);
    final mobileController = TextEditingController(text: mobile);
    return showModalBottomSheet<(String, String)>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            20 + MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Who should we pick up?',
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Patient name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: mobileController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Mobile number'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  Navigator.pop(
                    ctx,
                    (
                      nameController.text.trim(),
                      mobileController.text.trim(),
                    ),
                  );
                },
                child: const Text('Continue'),
              ),
            ],
          ),
        );
      },
    ).whenComplete(() {
      nameController.dispose();
      mobileController.dispose();
    });
  }

  String? _nearbyTypeId(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final value = raw.trim().toLowerCase();
    for (final type in ambulanceVehicleTypes) {
      if (type.id == value ||
          type.chipLabel.toLowerCase() == value ||
          type.label.toLowerCase() == value) {
        return type.id;
      }
    }
    return null;
  }

  Map<String, int> get _etas {
    final map = <String, int>{};
    for (final item in _nearby) {
      final id = _nearbyTypeId(item['vehicleType']?.toString());
      final eta = item['etaMinutes'];
      if (id == null || eta is! num) continue;
      final minutes = eta.round();
      final current = map[id];
      if (current == null || minutes < current) map[id] = minutes;
    }
    return map;
  }

  String? get _quickestTypeId {
    final etas = _etas;
    if (etas.isEmpty) return null;
    return etas.entries.reduce((a, b) => a.value <= b.value ? a : b).key;
  }

  Future<void> _selectTab(_RapidoTab tab) async {
    setState(() {
      _rapidoTab = tab;
      final types = _typesForTab(tab);
      if (types.isNotEmpty &&
          !types.any((type) => type.id == _vehicleType)) {
        _vehicleType = types.first.id;
      }
    });
    await Future.wait([_loadNearby(), _refreshEstimate()]);
  }

  String _fareLabel(String typeId) {
    final fare = _fares[typeId];
    if (fare == null) return _estimating ? '…' : 'Fare';
    return '₹${fare.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final initial = _pickup?.hasCoordinates == true
        ? LatLng(_pickup!.latitude!, _pickup!.longitude!)
        : _kDefaultCenter;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: initial, zoom: 14),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            compassEnabled: false,
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
              _moveCamera();
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      _RoundIconButton(
                        icon: Icons.arrow_back_rounded,
                        onTap: () => context.pop(),
                      ),
                      const Spacer(),
                      Material(
                        color: AppColors.primary,
                        elevation: 2,
                        borderRadius: BorderRadius.circular(24),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () => _pickLocation(pickup: false),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Text(
                              _drop == null ? '+ Add stop' : 'Change drop',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _RoundIconButton(
                        icon: Icons.sos_rounded,
                        foreground: const Color(0xFFB71C1C),
                        onTap: _callEmergency,
                      ),
                      const SizedBox(width: 8),
                      _RoundIconButton(
                        icon: Icons.history_rounded,
                        onTap: () async {
                          final loggedIn = await ensureUserLoggedIn(context);
                          if (!loggedIn || !mounted) return;
                          context.push(AppConstants.routeMyAmbulanceBookings);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _LocationCard(
                    pickup: _pickup,
                    drop: _drop,
                    onPickupTap: () => _pickLocation(pickup: true),
                    onDropTap: () => _pickLocation(pickup: false),
                  ),
                ],
              ),
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.46,
            minChildSize: 0.36,
            maxChildSize: 0.92,
            builder: (context, scrollController) {
              return _BookingSheet(
                scrollController: scrollController,
                active: _active,
                rideTypes: _rideTypes,
                selectedType: _vehicleType,
                selectedTab: _rapidoTab,
                fareLabel: _fareLabel,
                etas: _etas,
                quickestTypeId: _quickestTypeId,
                submitting: _submitting,
                nearbyCount: _nearby.length,
                onSelectTab: _selectTab,
                onSelectType: (id) async {
                  setState(() => _vehicleType = id);
                  await Future.wait([_loadNearby(), _refreshEstimate()]);
                },
                onBook: _bookNow,
                onSchedule: () async {
                  final loggedIn = await ensureUserLoggedIn(context);
                  if (!loggedIn || !mounted) return;
                  context.push(AppConstants.routeAmbulanceScheduled);
                },
                onBrowse: () => context.push(AppConstants.routeAmbulanceSearch),
                onTrack: () => context.push(
                  '${AppConstants.routeAmbulanceTrack}?bookingId=${_active!.id}',
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    this.foreground,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 2,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: foreground ?? AppColors.textPrimary),
        ),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.pickup,
    required this.drop,
    required this.onPickupTap,
    required this.onDropTap,
  });

  final SelectedLocationResult? pickup;
  final SelectedLocationResult? drop;
  final VoidCallback onPickupTap;
  final VoidCallback onDropTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 3,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: [
            Column(
              children: [
                const Icon(Icons.circle, color: AppColors.primary, size: 12),
                Container(
                  width: 2,
                  height: 22,
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  color: AppColors.grey200,
                ),
                const Icon(Icons.square, color: AppColors.textPrimary, size: 11),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: [
                  _LocationRow(
                    value: pickup?.displayLine ?? 'Current location',
                    onTap: onPickupTap,
                  ),
                  const Divider(height: 14, color: AppColors.divider),
                  _LocationRow(
                    value: drop?.displayLine ?? 'Drop hospital or address',
                    placeholder: drop == null,
                    onTap: onDropTap,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({
    required this.value,
    required this.onTap,
    this.placeholder = false,
  });

  final String value;
  final VoidCallback onTap;
  final bool placeholder;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: double.infinity,
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: placeholder ? AppColors.textTertiary : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _BookingSheet extends StatelessWidget {
  const _BookingSheet({
    required this.scrollController,
    required this.active,
    required this.rideTypes,
    required this.selectedType,
    required this.selectedTab,
    required this.fareLabel,
    required this.etas,
    required this.quickestTypeId,
    required this.submitting,
    required this.nearbyCount,
    required this.onSelectTab,
    required this.onSelectType,
    required this.onBook,
    required this.onSchedule,
    required this.onBrowse,
    required this.onTrack,
  });

  final ScrollController scrollController;
  final AmbulanceBookingModel? active;
  final List<AmbulanceVehicleType> rideTypes;
  final String selectedType;
  final _RapidoTab selectedTab;
  final String Function(String typeId) fareLabel;
  final Map<String, int> etas;
  final String? quickestTypeId;
  final bool submitting;
  final int nearbyCount;
  final ValueChanged<_RapidoTab> onSelectTab;
  final ValueChanged<String> onSelectType;
  final VoidCallback onBook;
  final VoidCallback onSchedule;
  final VoidCallback onBrowse;
  final VoidCallback onTrack;

  String _rideLabel(String id) {
    return ambulanceVehicleTypes
        .firstWhere(
          (type) => type.id == id,
          orElse: () => ambulanceVehicleTypes.first,
        )
        .chipLabel;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 18,
      shadowColor: Colors.black26,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            if (active != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Material(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                  child: ListTile(
                    onTap: onTrack,
                    dense: true,
                    leading: const Icon(
                      Icons.near_me_rounded,
                      color: AppColors.primaryDark,
                    ),
                    title: Text(
                      active!.statusLabel ?? 'Ambulance on the way',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    subtitle: Text(
                      active!.ambulanceServiceName ?? 'Tap to track live',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                  ),
                ),
              ),
            SizedBox(
              height: 46,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                children: [
                  for (final tab in _RapidoTab.values) ...[
                    _RapidoTabChip(
                      label: tab.label,
                      selected: selectedTab == tab,
                      onTap: () => onSelectTab(tab),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(6, 4, 6, 8),
                children: [
                  for (final type in rideTypes)
                    _RapidoRideRow(
                      type: type,
                      selected: type.id == selectedType,
                      fare: fareLabel(type.id),
                      etaMinutes: etas[type.id],
                      isQuickest: type.id == quickestTypeId,
                      onTap: () => onSelectType(type.id),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                    child: Text(
                      nearbyCount > 0
                          ? '$nearbyCount nearby · nearest free vehicle assigned first'
                          : 'We’ll assign the nearest free ambulance',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const ServiceFaqSection(
                    title: "General FAQs for Ambulance Services",
                    items: ServiceFaqs.ambulance,
                    padding: EdgeInsets.fromLTRB(10, 12, 10, 8),
                  ),
                ],
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet_outlined, size: 20),
                  const SizedBox(width: 6),
                  const Text(
                    'Cash',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                  const Spacer(),
                  const Icon(Icons.percent_rounded, size: 16, color: AppColors.primary),
                  TextButton(
                    onPressed: onBrowse,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text(
                      'Offers',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  TextButton(
                    onPressed: onSchedule,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Later'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: SizedBox(
                height: 54,
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    disabledBackgroundColor: AppColors.primarySoft,
                    disabledForegroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: submitting ? null : onBook,
                  child: submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: AppColors.white,
                          ),
                        )
                      : Text(
                          'Book ${_rideLabel(selectedType)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                            letterSpacing: 0.2,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RapidoTabChip extends StatelessWidget {
  const _RapidoTabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : Colors.white,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.grey300,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: selected ? AppColors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _RapidoRideRow extends StatelessWidget {
  const _RapidoRideRow({
    required this.type,
    required this.selected,
    required this.fare,
    required this.onTap,
    this.etaMinutes,
    this.isQuickest = false,
  });

  final AmbulanceVehicleType type;
  final bool selected;
  final String fare;
  final int? etaMinutes;
  final bool isQuickest;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final etaText = etaMinutes == null
        ? '${type.detail}'
        : '${etaMinutes!} mins away';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: selected ? AppColors.primaryLight : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.fromLTRB(10, 12, 14, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? AppColors.primary : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : AppColors.grey100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    type.icon,
                    size: 30,
                    color: selected ? AppColors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              type.chipLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (isQuickest) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: const Text(
                                'Fastest',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        etaText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  fare,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

