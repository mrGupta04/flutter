import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/user_location_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/widgets/custom_widgets.dart' as custom;
import '../../../../data/models/ambulance_model.dart';
import '../../../../shared/widgets/ambulance_care_filter_cards.dart';
import '../../../../shared/widgets/care_provider_listing_cards.dart';
import '../../../../shared/widgets/doctor_listing_card.dart';
import '../../../../shared/widgets/horizontal_filter_chips.dart';
import '../../../../shared/widgets/shimmer_widgets.dart';
import '../../../../shared/widgets/user_adaptive_scaffold.dart';
import '../../../../shared/widgets/user_app_footer.dart';
import '../../../ambulance/presentation/widgets/ambulance_action_sheet.dart';
import '../../provider/ambulance_search_provider.dart';
import '../../provider/care_filter_constants.dart';

class AmbulanceSearchScreen extends ConsumerStatefulWidget {
  const AmbulanceSearchScreen({
    super.key,
    this.initialQuery,
    this.initialCity,
    this.initialVehicleType,
  });

  final String? initialQuery;
  final String? initialCity;
  final String? initialVehicleType;

  @override
  ConsumerState<AmbulanceSearchScreen> createState() =>
      _AmbulanceSearchScreenState();
}

class _AmbulanceSearchScreenState extends ConsumerState<AmbulanceSearchScreen> {
  late final TextEditingController _controller;
  Timer? _debounce;
  String? _query;
  String? _city;
  String? _vehicleType;
  AmbulanceCareFilter _careFilter = AmbulanceCareFilter.all;
  String? _locationPrefill;

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery;
    _city = widget.initialCity;
    _vehicleType = widget.initialVehicleType;
    _controller = TextEditingController(
      text: widget.initialQuery ?? widget.initialVehicleType ?? '',
    );
    _controller.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyDefaultLocation());
  }

  void _applyDefaultLocation() {
    final location = ref.read(userLocationProvider);
    if (!mounted) return;
    setState(() {
      _city ??= location.city;
      _applyLocationPrefill(location);
    });
  }

  void _applyLocationPrefill(UserLocationState location) {
    final hasTypedQuery =
        (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) ||
            (widget.initialVehicleType != null &&
                widget.initialVehicleType!.trim().isNotEmpty);
    if (hasTypedQuery) return;

    final label = location.displayPlaceCity;
    if (label == null || label.isEmpty) return;

    final current = _controller.text.trim();
    final canReplace = current.isEmpty ||
        (_locationPrefill != null && current == _locationPrefill);
    if (!canReplace) return;

    _locationPrefill = label;
    if (current != label) {
      _controller.value = TextEditingValue(
        text: label,
        selection: TextSelection.collapsed(offset: label.length),
      );
    }
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
        setState(() {
          _query = null;
          _vehicleType = null;
        });
        return;
      }
      setState(() {
        _query = text.isEmpty ? null : text;
        _city = null;
        _vehicleType = null;
        _locationPrefill = null;
      });
    });
  }

  AmbulanceSearchParams get _params => AmbulanceSearchParams(
        query: _query,
        city: _city,
        vehicleType: _vehicleType,
        careFilter: _careFilter,
      );

  @override
  Widget build(BuildContext context) {
    ref.listen<UserLocationState>(userLocationProvider, (prev, next) {
      if (!mounted) return;
      setState(() {
        _city ??= next.city;
        _applyLocationPrefill(next);
      });
    });

    final asyncResults = ref.watch(ambulanceSearchProvider(_params));

    return UserAdaptiveScaffold(
      currentTab: UserNavTab.care,
      backgroundColor: AppColors.background,
      constrainBody: true,
      appBar: AppBar(
        title: const Text('Find ambulance'),
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
              hintText: 'Search service name, city, area...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
            onSubmitted: (value) => setState(() {
              final text = value.trim();
              if (_locationPrefill != null && text == _locationPrefill!.trim()) {
                _query = null;
                return;
              }
              _query = text.isEmpty ? null : text;
              _city = null;
              _vehicleType = null;
              _locationPrefill = null;
            }),
          ),
        ),
        const SizedBox(height: 12),
        AmbulanceCareFilterCards(
          selected: _careFilter,
          onSelected: (f) => setState(() => _careFilter = f),
        ),
        const SizedBox(height: 8),
        HorizontalFilterChips(
          labels: popularCareCities,
          selected: _city,
          onSelected: (city) => setState(() {
            _city = city;
            if (city != null) {
              _vehicleType = null;
              _query = null;
              _locationPrefill = city;
              _controller.text = city;
            } else {
              _locationPrefill = null;
              _controller.clear();
            }
          }),
        ),
        const SizedBox(height: 8),
        HorizontalFilterChips(
          labels: ambulanceVehicleTypeFilters,
          selected: _vehicleType,
          onSelected: (type) => setState(() {
            _vehicleType = type;
            if (type != null) {
              _city = null;
              _query = null;
              _locationPrefill = null;
              _controller.text = type;
            } else {
              _controller.clear();
            }
          }),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  List<Widget> _buildResultSlivers(
    AsyncValue<List<AmbulanceModel>> asyncResults,
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
            message: error.toString(),
            onRetry: () => ref.invalidate(ambulanceSearchProvider(_params)),
          ),
        ),
      ],
      data: (items) {
        if (items.isEmpty) {
          return [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  'No ambulance services found.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
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
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList.separated(
                itemCount: items.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: kDoctorCardSpacing),
                itemBuilder: (context, index) => AmbulanceListingCard(
                  ambulance: items[index],
                  onTap: () => showAmbulanceActionSheet(
                    context,
                    ambulance: items[index],
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
                        child: start + j < items.length
                            ? AmbulanceListingCard(
                                ambulance: items[start + j],
                                onTap: () => showAmbulanceActionSheet(
                                  context,
                                  ambulance: items[start + j],
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
