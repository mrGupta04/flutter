import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/services/geocoding_service.dart';
import '../../core/services/live_address_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/custom_widgets.dart';
import '../../data/models/patient_user_model.dart';
import '../../data/repositories/patient_auth_repository.dart';
import '../user_auth/provider/patient_auth_provider.dart';
import 'add_address_screen.dart';
import 'location_options_card.dart';
import 'location_permission_banner.dart';
import 'location_permission_handler.dart';
import 'location_search_bar.dart';
import 'saved_address_card.dart';
import 'selected_location.dart';

class SelectLocationScreen extends ConsumerStatefulWidget {
  const SelectLocationScreen({super.key, this.args});

  final SelectLocationArgs? args;

  @override
  ConsumerState<SelectLocationScreen> createState() =>
      _SelectLocationScreenState();
}

class _SelectLocationScreenState extends ConsumerState<SelectLocationScreen> {
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _debounce;
  List<PlaceSuggestion> _suggestions = [];
  bool _searching = false;
  bool _locating = false;
  String? _detectedAddress;
  double? _hereLat;
  double? _hereLng;
  LocationPermissionUiState _permission = LocationPermissionUiState.denied;
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.args?.initial?.savedAddressId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrapLocation();
      if (widget.args?.autofocusSearch == true) {
        _searchFocus.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _bootstrapLocation() async {
    final state = await LocationPermissionHandler.currentState();
    if (!mounted) return;
    setState(() => _permission = state);
    if (state != LocationPermissionUiState.granted) return;
    await _detectCurrent(prompt: false);
  }

  Future<void> _detectCurrent({required bool prompt}) async {
    setState(() => _locating = true);
    final captured = await LiveAddressService.capture(
      context,
      promptIfNeeded: prompt,
    );
    if (!mounted) return;
    setState(() => _locating = false);
    if (captured == null) {
      final next = await LocationPermissionHandler.currentState();
      if (mounted) setState(() => _permission = next);
      return;
    }
    final resolved = captured.resolved;
    setState(() {
      _permission = LocationPermissionUiState.granted;
      _hereLat = captured.latitude;
      _hereLng = captured.longitude;
      _detectedAddress = resolved == null
          ? null
          : [
              resolved.address,
              if (resolved.city.isNotEmpty) resolved.city,
              if (resolved.state.isNotEmpty) resolved.state,
            ].join(', ');
    });
    if (prompt && resolved != null) {
      _returnResult(
        SelectedLocationResult(
          addressLine: resolved.address,
          city: resolved.city,
          state: resolved.state,
          pincode: resolved.pincode,
          label: 'Current location',
          latitude: captured.latitude,
          longitude: captured.longitude,
        ),
      );
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      if (value.trim().length < 2) {
        if (mounted) setState(() => _suggestions = []);
        return;
      }
      setState(() => _searching = true);
      try {
        final results = await GeocodingService.searchPlaces(value);
        if (!mounted) return;
        setState(() {
          _suggestions = results;
          _searching = false;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _suggestions = [];
          _searching = false;
        });
        SnackBarHelper.showError(context, e.toString());
      }
    });
  }

  void _returnResult(SelectedLocationResult result) {
    Navigator.pop(context, result);
  }

  Future<void> _openAdd({SavedAddressModel? existing}) async {
    final result = await Navigator.of(context).push<SelectedLocationResult>(
      MaterialPageRoute(builder: (_) => AddAddressScreen(existing: existing)),
    );
    if (result != null && mounted) {
      if (existing == null) {
        _returnResult(result);
        return;
      }
      setState(() => _selectedId = result.savedAddressId);
    }
  }

  String? _distanceFor(SavedAddressModel address) {
    if (_hereLat == null ||
        _hereLng == null ||
        address.latitude == null ||
        address.longitude == null) {
      return null;
    }
    final meters = Geolocator.distanceBetween(
      _hereLat!,
      _hereLng!,
      address.latitude!,
      address.longitude!,
    );
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  Future<void> _share(SavedAddressModel address) async {
    await Share.share(address.displayLine, subject: address.label);
  }

  Future<void> _more(SavedAddressModel address) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.star_outline_rounded),
              title: const Text('Set as default'),
              onTap: () => Navigator.pop(ctx, 'default'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded),
              title: const Text('Delete'),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;
    final repo = PatientAuthRepository();
    if (action == 'delete') {
      final res = await repo.deleteAddress(address.id);
      if (!mounted) return;
      if (res.success && res.data != null) {
        ref.read(patientAuthProvider.notifier).setUser(res.data!);
      } else {
        SnackBarHelper.showError(context, res.error ?? 'Could not delete');
      }
      return;
    }
    final res = await repo.saveAddress(
      SavedAddressModel(
        id: address.id,
        label: address.label,
        addressLine: address.addressLine,
        city: address.city,
        state: address.state,
        pincode: address.pincode,
        landmark: address.landmark,
        contactName: address.contactName,
        phone: address.phone,
        latitude: address.latitude,
        longitude: address.longitude,
        isDefault: true,
      ),
    );
    if (!mounted) return;
    if (res.success && res.data != null) {
      ref.read(patientAuthProvider.notifier).setUser(res.data!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(patientAuthProvider).user;
    final addresses = user?.savedAddresses ?? const <SavedAddressModel>[];
    final title = widget.args?.title ?? 'Select a location';
    final maxWidth = MediaQuery.sizeOf(context).width > 720 ? 640.0 : double.infinity;

    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        title: Text(title),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            children: [
              LocationSearchBar(
                controller: _search,
                focusNode: _searchFocus,
                onChanged: (value) {
                  setState(() {});
                  _onSearchChanged(value);
                },
                onClear: () {
                  _search.clear();
                  setState(() => _suggestions = []);
                },
              ),
              if (_searching) ...[
                const SizedBox(height: 8),
                const LinearProgressIndicator(minHeight: 2),
              ],
              if (_search.text.trim().length >= 2) ...[
                const SizedBox(height: 10),
                if (_suggestions.isEmpty && !_searching)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No places found. Try a street, area, or landmark.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: AppDecorations.borderRadiusLg,
                      boxShadow: AppDecorations.softShadow(opacity: 0.04),
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < _suggestions.length; i++) ...[
                          if (i > 0) const Divider(height: 1),
                          ListTile(
                            leading: const Icon(
                              Icons.location_on_outlined,
                              color: AppColors.primary,
                            ),
                            title: Text(
                              _suggestions[i].title,
                              style: AppTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: _suggestions[i].subtitle.isEmpty
                                ? null
                                : Text(
                                    _suggestions[i].subtitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                            trailing: const Icon(
                              Icons.north_west_rounded,
                              size: 16,
                              color: AppColors.grey400,
                            ),
                            onTap: () {
                              final place = _suggestions[i];
                              _returnResult(
                                SelectedLocationResult(
                                  addressLine: place.address.address,
                                  city: place.address.city,
                                  state: place.address.state,
                                  pincode: place.address.pincode,
                                  label: place.title,
                                  latitude: place.latitude,
                                  longitude: place.longitude,
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
              ] else ...[
              const SizedBox(height: 14),
              LocationPermissionBanner(
                state: _permission,
                onEnable: () async {
                  final ok = await LocationPermissionHandler.requestAccess(context);
                  if (ok) await _detectCurrent(prompt: false);
                },
              ),
              if (_permission != LocationPermissionUiState.granted)
                const SizedBox(height: 12),
              LocationOptionsCard(
                onUseCurrentLocation: () => _detectCurrent(prompt: true),
                onAddAddress: () => _openAdd(),
                detectedAddress: _detectedAddress,
                isLocating: _locating,
              ),
              const SizedBox(height: 22),
              Text(
                'SAVED ADDRESSES',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.grey500,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              if (addresses.isEmpty)
                Text(
                  'No saved addresses yet. Add one to reuse it for home visits, labs, and ambulance pickup.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                )
              else
                for (final address in addresses) ...[
                  SavedAddressCard(
                    address: address,
                    selected: _selectedId == address.id,
                    distanceLabel: _distanceFor(address),
                    onTap: () =>
                        _returnResult(SelectedLocationResult.fromSaved(address)),
                    onMore: () => _more(address),
                    onShare: () => _share(address),
                    onEdit: () => _openAdd(existing: address),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
