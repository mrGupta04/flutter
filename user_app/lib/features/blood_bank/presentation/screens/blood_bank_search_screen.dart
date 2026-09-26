import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/user_location_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/widgets/accidental_selection_binder.dart';
import '../../../../core/widgets/custom_widgets.dart' as custom;
import '../../../../data/models/blood_bank_model.dart';
import '../../../../shared/widgets/care_provider_listing_cards.dart';
import '../../../../shared/widgets/horizontal_filter_chips.dart';
import '../../../../shared/widgets/searchable_filter_dropdown.dart';
import '../../../../shared/widgets/shimmer_widgets.dart';
import '../../../../shared/widgets/user_adaptive_scaffold.dart';
import '../../../../shared/widgets/user_app_footer.dart';
import '../../../doctor_registration/provider/care_filter_constants.dart';
import '../../data/blood_bank_catalog.dart';
import '../../provider/blood_bank_search_provider.dart';

class BloodBankSearchScreen extends ConsumerStatefulWidget {
  const BloodBankSearchScreen({
    super.key,
    this.initialQuery,
    this.initialCity,
    this.initialBloodGroup,
    this.initialComponentType,
    this.initialRadiusKm,
  });

  final String? initialQuery;
  final String? initialCity;
  final String? initialBloodGroup;
  final String? initialComponentType;
  final String? initialRadiusKm;

  @override
  ConsumerState<BloodBankSearchScreen> createState() =>
      _BloodBankSearchScreenState();
}

class _BloodBankSearchScreenState extends ConsumerState<BloodBankSearchScreen> {
  late final TextEditingController _controller;
  Timer? _debounce;
  String? _query;
  String? _city;
  String? _bloodGroup;
  String? _componentType;
  BloodBankCareFilter _careFilter = BloodBankCareFilter.all;
  String? _locationPrefill;
  String? _bankType;
  bool _showMap = false;
  double? _maxDistanceKm;

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery;
    _city = widget.initialCity;
    _bloodGroup = widget.initialBloodGroup;
    _componentType = widget.initialComponentType;
    _maxDistanceKm = double.tryParse(widget.initialRadiusKm ?? '');
    _controller = TextEditingController(
      text: widget.initialQuery ?? widget.initialBloodGroup ?? '',
    );
    _controller.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyDefaultLocation());
  }

  void _applyDefaultLocation() {
    final location = ref.read(userLocationProvider);
    if (!mounted) return;
    setState(() {
      _city ??= location.city;
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
      if (_locationPrefill != null && text == _locationPrefill!.trim()) {
        setState(() => _query = null);
        return;
      }
      setState(() {
        _query = text.isEmpty ? null : text;
        _city = null;
        _bloodGroup = null;
        _locationPrefill = null;
      });
    });
  }

  BloodBankSearchParams get _params {
    final location = ref.read(userLocationProvider);
    return BloodBankSearchParams(
        query: _query,
        city: _city,
        bloodGroup: _bloodGroup,
        componentType: _componentType,
        careFilter: _careFilter,
        latitude: location.latitude,
        longitude: location.longitude,
        maxDistanceKm: _maxDistanceKm,
        bankType: _bankType,
      );
  }

  Future<void> _openFilters() async {
    String? group = _bloodGroup;
    String? component = _componentType;
    String? type = _bankType;
    double radius = _maxDistanceKm ?? 10;
    BloodBankCareFilter care = _careFilter;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Filters', style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final g in kBloodGroups)
                        ChoiceChip(
                          label: Text(g),
                          selected: group == g,
                          onSelected: (_) => setSheet(() => group = group == g ? null : g),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final c in kBloodComponents)
                        ChoiceChip(
                          label: Text(c['name']!),
                          selected: component == c['id'],
                          onSelected: (_) =>
                              setSheet(() => component = component == c['id'] ? null : c['id']),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final t in kBloodBankTypes)
                        ChoiceChip(
                          label: Text(t['name']!),
                          selected: type == t['id'],
                          onSelected: (_) =>
                              setSheet(() => type = type == t['id'] ? null : t['id']),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final km in kBloodSearchRadiiKm)
                        ChoiceChip(
                          label: Text('$km km'),
                          selected: radius == km.toDouble(),
                          onSelected: (_) => setSheet(() => radius = km.toDouble()),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: BloodBankCareFilter.values
                        .map(
                          (f) => ChoiceChip(
                            label: Text(f.label),
                            selected: care == f,
                            onSelected: (_) => setSheet(() => care = f),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      setState(() {
                        _bloodGroup = group;
                        _componentType = component;
                        _bankType = type;
                        _maxDistanceKm = radius;
                        _careFilter = care;
                      });
                      Navigator.pop(ctx);
                    },
                    child: const Text('Apply filters'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<UserLocationState>(userLocationProvider, (prev, next) {
      if (!mounted) return;
      setState(() {
        _city ??= next.city;
      });
    });

    final location = ref.watch(userLocationProvider);
    final params = BloodBankSearchParams(
      query: _query,
      city: _city,
      bloodGroup: _bloodGroup,
      componentType: _componentType,
      careFilter: _careFilter,
      latitude: location.latitude,
      longitude: location.longitude,
      maxDistanceKm: _maxDistanceKm,
      bankType: _bankType,
    );
    final asyncResults = ref.watch(bloodBankSearchProvider(params));

    return UserAdaptiveScaffold(
      currentTab: UserNavTab.care,
      backgroundColor: AppColors.background,
      constrainBody: true,
      appBar: AppBar(
        title: const Text('Find blood bank'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            tooltip: _showMap ? 'List view' : 'Map view',
            icon: Icon(_showMap ? Icons.view_list_rounded : Icons.map_outlined),
            onPressed: () => setState(() => _showMap = !_showMap),
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: _openFilters,
          ),
          IconButton(
            icon: const Icon(Icons.emergency_rounded, color: Color(0xFFB71C1C)),
            onPressed: () => context.push(AppConstants.routeEmergencyBloodRequest),
          ),
        ],
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
              hintText: 'Name, city, area, pincode...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: BloodBankCareFilter.values
                .map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(f.label),
                      selected: _careFilter == f,
                      onSelected: (_) => setState(() => _careFilter = f),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SearchableFilterDropdown(
            label: 'City',
            value: _city,
            allLabel: 'All cities',
            searchHint: 'Search city or district...',
            options: doctorSearchCities,
            sections: careCityPickerSections,
            matchOption: karnatakaPlaceMatchesQuery,
            onChanged: (city) => setState(() {
              _city = city;
              _query = null;
              _locationPrefill = null;
            }),
          ),
        ),
        const SizedBox(height: 8),
        HorizontalFilterChips(
          labels: bloodGroupFilters,
          selected: _bloodGroup,
          onSelected: (group) => setState(() => _bloodGroup = group),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  List<Widget> _buildResultSlivers(
    AsyncValue<List<BloodBankModel>> asyncResults,
  ) {
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
            message: 'Unable to load blood availability. Please try again.',
            onRetry: () => ref.invalidate(bloodBankSearchProvider(_params)),
          ),
        ),
      ],
      data: (items) {
        if (items.isEmpty) {
          return [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bloodtype_outlined, size: 48, color: AppColors.grey400),
                    const SizedBox(height: 12),
                    Text(
                      'Sorry, no matching blood is currently available nearby.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Try a larger radius or contact blood banks directly for emergency needs.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => setState(() {
                        _maxDistanceKm = (_maxDistanceKm ?? 10) >= 50
                            ? 50
                            : ((_maxDistanceKm ?? 10) * 2);
                      }),
                      child: const Text('Expand Search Radius'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => context.push(AppConstants.routeEmergencyBloodRequest),
                      child: const Text('Contact Blood Banks'),
                    ),
                  ],
                ),
              ),
            ),
          ];
        }

        final columns = ResponsiveUtils.gridColumns(
          context,
          mobile: 1,
          tablet: 2,
          laptop: 2,
          desktop: 3,
        );

        if (columns <= 1) {
          return [
            if (_showMap)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Map markers will appear here when maps are configured. Showing ${items.length} nearby blood banks.',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList.separated(
                itemCount: items.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) => BloodBankListingCard(
                  bloodBank: items[index],
                  highlightGroup: _bloodGroup,
                  highlightComponent: _componentType,
                  onTap: () => context.push(
                    '${AppConstants.routeBloodBankDetail}/${items[index].id}',
                  ),
                  onOrder: () => context.push(
                    '${AppConstants.routeBloodBankDetail}/${items[index].id}',
                  ),
                ),
              ),
            ),
          ];
        }

        final rowCount = (items.length / columns).ceil();
        return [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList.separated(
              itemCount: rowCount,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, rowIndex) {
                final start = rowIndex * columns;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var j = 0; j < columns; j++) ...[
                      if (j > 0) const SizedBox(width: 12),
                      Expanded(
                        child: start + j < items.length
                            ? BloodBankListingCard(
                                bloodBank: items[start + j],
                                highlightGroup: _bloodGroup,
                                highlightComponent: _componentType,
                                onTap: () => context.push(
                                  '${AppConstants.routeBloodBankDetail}/${items[start + j].id}',
                                ),
                                onOrder: () => context.push(
                                  '${AppConstants.routeBloodBankDetail}/${items[start + j].id}',
                                ),
                              )
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
