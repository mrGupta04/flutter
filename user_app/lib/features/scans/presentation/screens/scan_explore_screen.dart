import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/user_location_provider.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_back_navigation.dart';
import '../../../../shared/widgets/care_filter_chip.dart';
import '../../../../shared/widgets/diagnostic_cart_icon_button.dart';
import '../../../../shared/widgets/diagnostic_sticky_cart_bar.dart';
import '../../provider/scan_search_provider.dart';
import '../widgets/scan_explore_card.dart';

class ScanExploreScreen extends ConsumerStatefulWidget {
  const ScanExploreScreen({super.key});

  @override
  ConsumerState<ScanExploreScreen> createState() => _ScanExploreScreenState();
}

class _ScanExploreScreenState extends ConsumerState<ScanExploreScreen> {
  late final TextEditingController _searchController;
  late final ScrollController _scrollController;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _scrollController = ScrollController()..addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initExplore());
  }

  Future<void> _initExplore() async {
    final preferred = ref.read(userLocationProvider);
    double? lat = preferred.latitude;
    double? lng = preferred.longitude;

    if (lat == null || lng == null) {
      try {
        if (await LocationService.isServiceEnabled()) {
          final perm = await LocationService.checkPermission();
          if (LocationService.permissionGranted(perm)) {
            final pos = await LocationService.getCurrentPosition(
              requestPermissionIfNeeded: false,
            );
            lat = pos.latitude;
            lng = pos.longitude;
          }
        }
      } catch (_) {}
    }

    if (!mounted) return;
    final notifier = ref.read(scanExploreProvider.notifier);
    if (lat != null && lng != null) {
      notifier.setLocation(lat, lng);
    } else {
      notifier.load(refresh: true);
    }
  }

  void _onLocationResolved(UserLocationState location) {
    if (!location.hasCoordinates) return;
    final state = ref.read(scanExploreProvider);
    if (state.latitude != null && state.longitude != null) return;
    ref.read(scanExploreProvider.notifier).setLocation(
          location.latitude,
          location.longitude,
        );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(scanExploreProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(scanExploreProvider.notifier).setQuery(value.trim());
    });
  }

  Future<void> _showSortSheet(ScanExploreState state) async {
    final picked = await showModalBottomSheet<ScanExploreSort>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: ScanExploreSort.values
              .map(
                (sort) => ListTile(
                  title: Text(sort.label),
                  trailing: state.sort == sort
                      ? const Icon(Icons.check_rounded, color: AppColors.primary)
                      : null,
                  onTap: () => Navigator.pop(context, sort),
                ),
              )
              .toList(),
        ),
      ),
    );
    if (picked != null) {
      ref.read(scanExploreProvider.notifier).setSort(picked);
    }
  }

  Future<void> _showFilterSheet(ScanExploreState state) async {
    var filters = state.filters;
    final updated = await showModalBottomSheet<ScanExploreFilters>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Filters',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Home Visit'),
                    value: filters.homeVisit,
                    onChanged: (v) => setModalState(
                      () => filters = filters.copyWith(homeVisit: v),
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('Center Visit'),
                    value: filters.centerVisit,
                    onChanged: (v) => setModalState(
                      () => filters = filters.copyWith(centerVisit: v),
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('Open Now'),
                    value: filters.openNow,
                    onChanged: (v) => setModalState(
                      () => filters = filters.copyWith(openNow: v),
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('Special Offers'),
                    value: filters.hasOffer,
                    onChanged: (v) => setModalState(
                      () => filters = filters.copyWith(hasOffer: v),
                    ),
                  ),
                  ListTile(
                    title: const Text('Minimum rating'),
                    subtitle: Text(
                      filters.minRating?.toStringAsFixed(1) ?? 'Any',
                    ),
                    trailing: DropdownButton<double?>(
                      value: filters.minRating,
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Any')),
                        DropdownMenuItem(value: 4.0, child: Text('4.0+')),
                        DropdownMenuItem(value: 4.5, child: Text('4.5+')),
                      ],
                      onChanged: (v) => setModalState(
                        () => filters = filters.copyWith(
                          minRating: v,
                          clearMinRating: v == null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(
                            context,
                            const ScanExploreFilters(),
                          ),
                          child: const Text('Clear'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.pop(context, filters),
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (updated != null) {
      ref.read(scanExploreProvider.notifier).setFilters(updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<UserLocationState>(userLocationProvider, (prev, next) {
      _onLocationResolved(next);
    });
    final state = ref.watch(scanExploreProvider);

    return UserTabBackScope(
      isHomeTab: false,
      homeRoute: AppConstants.routeUserHome,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Diagnostic Scans'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppConstants.routeUserHome);
              }
            },
          ),
          actions: [
            IconButton(
              tooltip: 'Browse by scan type',
              icon: const Icon(Icons.category_outlined),
              onPressed: () => context.push(AppConstants.routeScansCatalog),
            ),
            const DiagnosticCartIconButton(),
          ],
        ),
        bottomNavigationBar: const DiagnosticStickyCartBar(),
        body: RefreshIndicator(
          onRefresh: () =>
              ref.read(scanExploreProvider.notifier).load(refresh: true),
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.white,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search scan centers or scans...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          filled: true,
                          fillColor: AppColors.grey50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppColors.border),
                          ),
                        ),
                        onChanged: _onSearchChanged,
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 38,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            CareFilterChip(
                              label: state.filters.hasActiveFilters
                                  ? 'Filters •'
                                  : 'Filters',
                              selected: state.filters.hasActiveFilters,
                              onTap: () => _showFilterSheet(state),
                            ),
                            const SizedBox(width: 8),
                            CareFilterChip(
                              label: 'Sort: ${state.sort.label}',
                              selected: true,
                              onTap: () => _showSortSheet(state),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (state.isLoading && state.centers.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state.error != null && state.centers.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(state.error!, textAlign: TextAlign.center),
                    ),
                  ),
                )
              else if (state.centers.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: Text('No scan centers found')),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index >= state.centers.length) {
                          return state.isLoadingMore
                              ? const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : const SizedBox(height: 8);
                        }
                        final center = state.centers[index];
                        return ScanExploreCard(
                          center: center,
                          onViewDetails: () => context.push(
                            '${AppConstants.routeScanCenterDetail}/${center.id}',
                          ),
                        );
                      },
                      childCount: state.centers.length + 1,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
