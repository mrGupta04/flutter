import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/widgets/accidental_selection_binder.dart';
import '../../../../core/widgets/custom_widgets.dart' as custom;
import '../../../../data/models/consultation_type.dart';
import '../../../../data/models/doctor_model.dart';
import '../../../../shared/widgets/consultation_type_cards.dart';
import '../../../../shared/widgets/doctor_listing_card.dart';
import '../../../../shared/widgets/shimmer_widgets.dart';
import '../../../../shared/widgets/user_adaptive_scaffold.dart';
import '../../../../shared/widgets/user_app_footer.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/providers/user_location_provider.dart';
import '../../../../core/utils/geo_distance_utils.dart';
import '../../../../core/widgets/enable_location_services_dialog.dart';
import '../../data/medical_specialities.dart';
import '../../provider/doctor_search_provider.dart';
import '../../provider/doctor_live_status_provider.dart';
import '../widgets/browse_by_specialty_section.dart';
import '../widgets/doctor_search_result_tile.dart';

class DoctorSearchScreen extends ConsumerStatefulWidget {
  const DoctorSearchScreen({
    super.key,
    this.initialQuery,
    this.initialCity,
    this.initialSpecialization,
    this.initialConsultationType,
  });

  final String? initialQuery;
  final String? initialCity;
  final String? initialSpecialization;
  final ConsultationType? initialConsultationType;

  @override
  ConsumerState<DoctorSearchScreen> createState() => _DoctorSearchScreenState();
}

class _DoctorSearchScreenState extends ConsumerState<DoctorSearchScreen> {
  late final TextEditingController _controller;
  Timer? _debounce;
  String? _query;
  late final String? _city = widget.initialCity;
  String? _specialization;
  late ConsultationType _consultationType;
  double? _nearbyLatitude;
  double? _nearbyLongitude;
  bool _nearbyActive = false;
  bool _isFetchingNearby = false;

  bool get _showsNearbyFilter =>
      _consultationType == ConsultationType.visitSite ||
      _consultationType == ConsultationType.bookHome;

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery;
    _specialization =
        resolveSpecialitySearchTerm(widget.initialSpecialization);
    _consultationType =
        widget.initialConsultationType ?? ConsultationType.onlineConsult;
    _controller = TextEditingController(text: widget.initialQuery ?? '');
    _controller.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyDefaultNearby());
  }

  void _applyDefaultNearby() {
    final location = ref.read(userLocationProvider);
    if (!mounted) return;
    setState(() {
      if (location.hasCoordinates) {
        _nearbyLatitude = location.latitude;
        _nearbyLongitude = location.longitude;
        _nearbyActive = true;
      }
    });
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
      final text = _controller.text.trim();
      setState(() {
        _query = text.isEmpty ? null : text;
      });
    });
  }

  void _clearSearch() {
    setState(() {
      _query = null;
      _controller.clear();
    });
  }

  Future<void> _getDoctorsNearby() async {
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
        'Showing doctors nearest to you.',
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

  DoctorSearchParams get _params => DoctorSearchParams(
        query: _query,
        city: _city,
        specialization: _specialization,
        consultationType: _consultationType,
      );

  bool get _hasSearchText => _controller.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    ref.listen<UserLocationState>(userLocationProvider, (prev, next) {
      if (!mounted) return;
      setState(() {
        if (next.hasCoordinates && (_nearbyLatitude == null || !_nearbyActive)) {
          _nearbyLatitude = next.latitude;
          _nearbyLongitude = next.longitude;
          _nearbyActive = true;
        }
      });
    });

    final asyncResults = ref.watch(doctorSearchProvider(_params));

    return UserAdaptiveScaffold(
      currentTab: UserNavTab.care,
      backgroundColor: AppColors.background,
      constrainBody: true,
      appBar: AppBar(
        title: const Text('Find a doctor'),
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
          child: CaretOnTapTextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Search doctor name, clinic or specialty...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _hasSearchText
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: _clearSearch,
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
              final text = value.trim();
              setState(() => _query = text.isEmpty ? null : text);
            },
          ),
        ),
        const SizedBox(height: 12),
        ConsultationTypeCards(
          selected: _consultationType,
          onSelected: (type) => setState(() {
            _consultationType = type;
            final location = ref.read(userLocationProvider);
            if (location.hasCoordinates) {
              _nearbyLatitude = location.latitude;
              _nearbyLongitude = location.longitude;
              _nearbyActive = true;
            }
          }),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Showing: ${_consultationType.label}',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (_showsNearbyFilter) ...[
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: _isFetchingNearby ? null : _getDoctorsNearby,
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
                    ? 'Doctors nearby (tap to refresh)'
                    : 'Get doctors nearby',
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                foregroundColor: _nearbyActive
                    ? AppColors.primary
                    : AppColors.textPrimary,
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
        ],
        BrowseBySpecialtySection(
          selectedSearchTerm: _specialization,
          onViewAll: () => context.push(AppConstants.routeFindSpecialists),
          onSpecialtySelected: (item) {
            final term = resolveSpecialitySearchTerm(item.searchTerm) ??
                item.searchTerm;
            setState(() {
              _specialization = _specialization == term ? null : term;
            });
          },
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  List<Widget> _buildResultSlivers(AsyncValue<List<DoctorModel>> asyncResults) {
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
            onRetry: () => ref.invalidate(doctorSearchProvider(_params)),
          ),
        ),
      ],
      data: (doctors) {
        final location = ref.watch(userLocationProvider);
        final lat = _nearbyLatitude ?? location.latitude;
        final lng = _nearbyLongitude ?? location.longitude;
        final sortedDoctors = sortDoctorsByProximityAndRating(
          doctors,
          userLatitude: lat,
          userLongitude: lng,
        );

        if (sortedDoctors.isEmpty) {
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
                        'No doctors found',
                        style: AppTextStyles.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try another consultation type or keyword',
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
                .watch(doctorLiveStatusProvider(doctorIdsCacheKey(sortedDoctors)))
                .valueOrNull ??
            const <String, bool>{};

        final columns = ResponsiveUtils.gridColumns(
          context,
          mobile: 1,
          tablet: 2,
          laptop: 2,
          desktop: 3,
        );

        Widget tileFor(int index) {
          final doctor = applyLiveStatus(sortedDoctors[index], liveMap);
          final distanceKm = lat != null && lng != null
              ? doctorDistanceKm(doctor, lat, lng)
              : null;
          return DoctorSearchResultTile(
            doctor: doctor,
            consultationFilter: _consultationType,
            showBottomDivider: false,
            distanceKm: distanceKm,
          );
        }

        if (columns <= 1) {
          return [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList.separated(
                itemCount: sortedDoctors.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: kDoctorCardSpacing),
                itemBuilder: (context, index) => tileFor(index),
              ),
            ),
          ];
        }

        final rowCount = (sortedDoctors.length / columns).ceil();
        return [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList.separated(
              itemCount: rowCount,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: kDoctorCardSpacing),
              itemBuilder: (context, rowIndex) {
                final start = rowIndex * columns;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var j = 0; j < columns; j++) ...[
                      if (j > 0) const SizedBox(width: 12),
                      Expanded(
                        child: start + j < sortedDoctors.length
                            ? tileFor(start + j)
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ];
      },
    );
  }
}
