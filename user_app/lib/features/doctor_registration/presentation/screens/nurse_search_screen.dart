import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/geo_distance_utils.dart';
import '../../../../core/widgets/custom_widgets.dart' as custom;
import '../../../../core/widgets/enable_location_services_dialog.dart';
import '../../../../data/models/nurse_model.dart';
import '../../../../shared/widgets/care_provider_listing_cards.dart';
import '../../../../shared/widgets/doctor_listing_card.dart';
import '../../../../shared/widgets/searchable_filter_dropdown.dart';
import '../../../../shared/widgets/shimmer_widgets.dart';
import '../../../../shared/widgets/user_app_footer.dart';
import '../../provider/care_filter_constants.dart';
import '../../provider/nurse_search_provider.dart';
import '../../provider/nurse_live_status_provider.dart';
import '../../../nurse_home_visit/nurse_home_visit_navigation.dart';
import '../../../../core/utils/provider_location_utils.dart';
import 'nurse_profile_screen.dart';

class NurseSearchScreen extends ConsumerStatefulWidget {
  const NurseSearchScreen({
    super.key,
    this.initialQuery,
    this.initialCity,
    this.initialSpecialization,
  });

  final String? initialQuery;
  final String? initialCity;
  final String? initialSpecialization;

  @override
  ConsumerState<NurseSearchScreen> createState() => _NurseSearchScreenState();
}

class _NurseSearchScreenState extends ConsumerState<NurseSearchScreen> {
  late final TextEditingController _controller;
  Timer? _debounce;
  String? _query;
  String? _city;
  String? _specialization;
  String? _gender;
  int? _minYearsExperience;
  double? _nearbyLatitude;
  double? _nearbyLongitude;
  bool _nearbyActive = false;
  bool _isFetchingNearby = false;

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery;
    _city = widget.initialCity;
    _specialization = widget.initialSpecialization;
    _controller = TextEditingController(text: widget.initialQuery ?? '');
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() {
        _query = _controller.text.trim().isEmpty
            ? null
            : _controller.text.trim();
      });
    });
  }

  void _clearFilters() {
    setState(() {
      _query = null;
      _city = null;
      _specialization = null;
      _gender = null;
      _minYearsExperience = null;
      _nearbyActive = false;
      _nearbyLatitude = null;
      _nearbyLongitude = null;
      _controller.clear();
    });
  }

  NurseSearchParams get _params => NurseSearchParams(
        query: _query,
        city: _city,
        specialization: _specialization,
        minYearsExperience: _minYearsExperience,
        gender: _gender,
      );

  bool get _hasActiveFilters =>
      _params.hasTextFilters || _controller.text.trim().isNotEmpty;

  Future<void> _getNursesNearby() async {
    setState(() => _isFetchingNearby = true);
    try {
      final hasAccess = await _ensureLocationAccess();
      if (!hasAccess || !mounted) return;

      final position = await LocationService.getCurrentPosition(
        requestPermissionIfNeeded: false,
      );
      if (!mounted) return;
      setState(() {
        _nearbyLatitude = position.latitude;
        _nearbyLongitude = position.longitude;
        _nearbyActive = true;
      });
      custom.SnackBarHelper.showSuccess(
        context,
        'Showing nurses nearest to you.',
      );
    } on LocationFailure catch (e) {
      if (mounted) await _handleLocationFailure(e);
    } finally {
      if (mounted) setState(() => _isFetchingNearby = false);
    }
  }

  Future<bool> _ensureLocationAccess() async {
    if (!mounted) return false;
    return LocationService.ensureReady(context);
  }

  Future<void> _handleLocationFailure(LocationFailure error) async {
    final message = error.message.toLowerCase();
    if (message.contains('turned off') || message.contains('disabled')) {
      if (!mounted) return;
      final turnOn = await EnableLocationServicesDialog.show(context);
      if (turnOn) await LocationService.openLocationSettings();
      return;
    }

    if (message.contains('blocked') || message.contains('denied')) {
      if (!mounted) return;
      final turnOn = await EnableLocationServicesDialog.show(
        context,
        message:
            "This app requires location access to function properly. Please enable location permission by clicking the 'Turn On' button below.",
      );
      if (turnOn) await LocationService.openAppSettings();
      return;
    }

    custom.SnackBarHelper.showError(context, error.message);
  }

  @override
  Widget build(BuildContext context) {
    final asyncResults = ref.watch(nurseSearchProvider(_params));

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const UserBottomNavBar(currentTab: UserNavTab.care),
      appBar: AppBar(
        title: const Text('Find a nurse'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildFilters()),
          ..._buildResultSlivers(asyncResults),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Search by name, qualification, keyword...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _hasActiveFilters
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: _clearFilters,
                    )
                  : null,
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
            textInputAction: TextInputAction.search,
            onSubmitted: (value) {
              setState(() {
                _query = value.trim().isEmpty ? null : value.trim();
              });
            },
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: OutlinedButton.icon(
            onPressed: _isFetchingNearby ? null : _getNursesNearby,
            icon: _isFetchingNearby
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    _nearbyActive
                        ? Icons.near_me_rounded
                        : Icons.my_location_rounded,
                  ),
            label: Text(
              _nearbyActive
                  ? 'Nurses nearby (tap to refresh)'
                  : 'Get nurses nearby',
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              foregroundColor:
                  _nearbyActive ? AppColors.primary : AppColors.textPrimary,
              side: BorderSide(
                color: _nearbyActive
                    ? AppColors.primary.withValues(alpha: 0.55)
                    : AppColors.border,
              ),
              backgroundColor: _nearbyActive
                  ? AppColors.primary.withValues(alpha: 0.06)
                  : AppColors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SearchableFilterDropdown(
            label: 'City',
            value: _city,
            allLabel: 'All cities',
            searchHint: 'Search city...',
            options: doctorSearchCities,
            onChanged: (city) => setState(() => _city = city),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SearchableFilterDropdown(
            label: 'Specialization',
            value: _specialization,
            allLabel: 'All specializations',
            searchHint: 'Search specialization...',
            options: nurseSpecializationFilters,
            onChanged: (specialization) =>
                setState(() => _specialization = specialization),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FilterDropdown<String?>(
            label: 'Gender',
            value: _gender,
            items: [null, ...nurseGenderFilters],
            itemLabel: (gender) => gender ?? 'All genders',
            onChanged: (gender) => setState(() => _gender = gender),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FilterDropdown<int?>(
            label: 'Years of experience',
            value: _minYearsExperience,
            items: doctorMinExperienceOptions,
            itemLabel: doctorMinExperienceLabel,
            onChanged: (years) => setState(() => _minYearsExperience = years),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  List<Widget> _buildResultSlivers(AsyncValue<List<NurseModel>> asyncResults) {
    return asyncResults.when(
      loading: () => const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: ShimmerLoadingList(),
          ),
        ),
      ],
      error: (error, _) => [
        SliverFillRemaining(
          hasScrollBody: false,
          child: custom.AppErrorWidget(
            message: error.toString(),
            onRetry: () => ref.invalidate(nurseSearchProvider(_params)),
          ),
        ),
      ],
      data: (nurses) {
        final sortedNurses = _nearbyActive &&
                _nearbyLatitude != null &&
                _nearbyLongitude != null
            ? sortNursesByDistance(
                nurses,
                _nearbyLatitude!,
                _nearbyLongitude!,
              )
            : nurses;

        if (sortedNurses.isEmpty) {
          return [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.person_search_rounded,
                        size: 48,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No nurses found',
                        style: AppTextStyles.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try another city, specialty, gender, experience, or keyword',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ];
        }

        final liveMap = ref
                .watch(
                  nurseLiveStatusProvider(nurseIdsCacheKey(sortedNurses)),
                )
                .valueOrNull ??
            const <String, bool>{};

        return [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList.separated(
              itemCount: sortedNurses.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: kDoctorCardSpacing),
              itemBuilder: (_, index) {
                final nurse =
                    applyNurseLiveStatus(sortedNurses[index], liveMap);
                final distanceKm = _nearbyActive &&
                        _nearbyLatitude != null &&
                        _nearbyLongitude != null
                    ? nurseDistanceKm(nurse, _nearbyLatitude!, _nearbyLongitude!)
                    : null;
                return NurseListingCard(
                  nurse: nurse,
                  distanceLabel: formatNearbyDistanceLabel(distanceKm),
                  onTap: () => openNurseProfile(context, nurse),
                  onBookHomeVisit: () =>
                      openNurseHomeVisitBooking(context, nurse),
                  onOpenMapTap: nurseHasMapLocation(nurse)
                      ? () => openNurseInGoogleMaps(context, nurse)
                      : null,
                );
              },
            ),
          ),
        ];
      },
    );
  }
}
