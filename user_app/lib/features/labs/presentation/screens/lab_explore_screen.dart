import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/care_filter_chip.dart';
import '../../provider/lab_search_provider.dart';
import '../widgets/lab_explore_card.dart';
import '../widgets/lab_sticky_cart_bar.dart';

class LabExploreScreen extends ConsumerStatefulWidget {
  const LabExploreScreen({super.key});

  @override
  ConsumerState<LabExploreScreen> createState() => _LabExploreScreenState();
}

class _LabExploreScreenState extends ConsumerState<LabExploreScreen> {
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
    double? lat;
    double? lng;
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
    if (!mounted) return;
    final notifier = ref.read(labExploreProvider.notifier);
    if (lat != null && lng != null) {
      notifier.setLocation(lat, lng);
    } else {
      notifier.load(refresh: true);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(labExploreProvider.notifier).loadMore();
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
      ref.read(labExploreProvider.notifier).setQuery(value.trim());
    });
  }

  Future<void> _showSortSheet(LabExploreState state) async {
    final picked = await showModalBottomSheet<LabExploreSort>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: LabExploreSort.values
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
      ref.read(labExploreProvider.notifier).setSort(picked);
    }
  }

  Future<void> _showFilterSheet(LabExploreState state) async {
    var filters = state.filters;
    final updated = await showModalBottomSheet<LabExploreFilters>(
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
                    title: const Text('Home Collection'),
                    value: filters.homeCollection,
                    onChanged: (v) =>
                        setModalState(() => filters = filters.copyWith(homeCollection: v)),
                  ),
                  SwitchListTile(
                    title: const Text('Lab Visit'),
                    value: filters.labVisit,
                    onChanged: (v) =>
                        setModalState(() => filters = filters.copyWith(labVisit: v)),
                  ),
                  SwitchListTile(
                    title: const Text('Open Now'),
                    value: filters.openNow,
                    onChanged: (v) =>
                        setModalState(() => filters = filters.copyWith(openNow: v)),
                  ),
                  SwitchListTile(
                    title: const Text('NABL Accredited'),
                    value: filters.nablAccredited,
                    onChanged: (v) => setModalState(
                      () => filters = filters.copyWith(nablAccredited: v),
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
                            const LabExploreFilters(),
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
      ref.read(labExploreProvider.notifier).setFilters(updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(labExploreProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Lab Tests'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      bottomNavigationBar: const LabStickyCartBar(),
      body: RefreshIndicator(
        onRefresh: () => ref.read(labExploreProvider.notifier).load(refresh: true),
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
                        hintText: 'Search labs or tests...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: AppColors.grey50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
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
            if (state.isLoading && state.labs.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state.error != null && state.labs.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(state.error!, textAlign: TextAlign.center),
                  ),
                ),
              )
            else if (state.labs.isEmpty)
              const SliverFillRemaining(
                child: Center(child: Text('No laboratories found')),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= state.labs.length) {
                        return state.isLoadingMore
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : const SizedBox(height: 8);
                      }
                      final lab = state.labs[index];
                      return LabExploreCard(
                        lab: lab,
                        onViewDetails: () => context.push(
                          '${AppConstants.routeLabDetail}/${lab.id}',
                        ),
                      );
                    },
                    childCount: state.labs.length + 1,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
