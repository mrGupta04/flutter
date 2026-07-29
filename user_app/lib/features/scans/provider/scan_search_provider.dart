import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/scan_center_model.dart';
import '../../../data/repositories/scan_repository.dart';
import '../data/models/scan_procedure_model.dart';
import '../data/scan_model_utils.dart';
import '../data/scans_catalog.dart';

export '../../../data/repositories/scan_repository.dart'
    show
        ScanSearchParams,
        ScanExploreSort,
        ScanExploreFilters,
        ScanSearchPage;
export '../data/scans_catalog.dart'
    show ScansCatalog, scanCategoryFromId, scanProcedureFromOffered;

final scanRepositoryProvider = Provider((ref) => ScanRepository());

final scanSearchProvider =
    FutureProvider.family<List<ScanCenterModel>, ScanSearchParams>(
  (ref, params) async {
    final repo = ref.watch(scanRepositoryProvider);
    final response = await repo.searchVerified(params);
    if (response.success && response.data != null) {
      return response.data!;
    }
    throw Exception(response.error ?? 'Could not load scan centers');
  },
);

final scanCenterDetailProvider =
    FutureProvider.family<ScanCenterModel, String>((ref, id) async {
  final repo = ref.watch(scanRepositoryProvider);
  final response = await repo.getById(id);
  if (response.success && response.data != null) {
    return response.data!;
  }
  throw Exception(response.error ?? 'Could not load scan center');
});

/// Unique scan procedures aggregated from verified centers (no static catalog).
final scanProceduresCatalogProvider =
    FutureProvider.autoDispose<List<ScanProcedure>>((ref) async {
  final repo = ref.watch(scanRepositoryProvider);
  final response = await repo.searchVerified(
    const ScanSearchParams(page: 1, pageSize: 100),
  );
  if (response.success && response.data != null) {
    return ScansCatalog.fromCenters(response.data!);
  }
  throw Exception(response.error ?? 'Could not load scans');
});

class ScanExploreState {
  const ScanExploreState({
    this.centers = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.page = 1,
    this.totalPages = 1,
    this.query = '',
    this.filters = const ScanExploreFilters(),
    this.sort = ScanExploreSort.recommended,
    this.latitude,
    this.longitude,
  });

  final List<ScanCenterModel> centers;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int page;
  final int totalPages;
  final String query;
  final ScanExploreFilters filters;
  final ScanExploreSort sort;
  final double? latitude;
  final double? longitude;

  bool get hasMore => page < totalPages;

  ScanExploreState copyWith({
    List<ScanCenterModel>? centers,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    int? page,
    int? totalPages,
    String? query,
    ScanExploreFilters? filters,
    ScanExploreSort? sort,
    double? latitude,
    double? longitude,
    bool clearError = false,
  }) {
    return ScanExploreState(
      centers: centers ?? this.centers,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      query: query ?? this.query,
      filters: filters ?? this.filters,
      sort: sort ?? this.sort,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}

List<ScanCenterModel> applyScanExploreFiltersAndSort(
  List<ScanCenterModel> centers,
  ScanExploreFilters filters,
  ScanExploreSort sort,
) {
  var result = centers.toList();

  if (filters.homeVisit) {
    result = result.where((c) => c.supportsHomeVisit).toList();
  }
  if (filters.centerVisit) {
    result = result.where((c) => c.supportsCenterVisit).toList();
  }
  if (filters.openNow) {
    result = result.where((c) => c.isOpenNow).toList();
  }
  if (filters.hasOffer) {
    result = result.where((c) => c.hasActiveOfferBadge).toList();
  }
  if (filters.minRating != null) {
    result =
        result.where((c) => c.ratingValue >= filters.minRating!).toList();
  }

  switch (sort) {
    case ScanExploreSort.nearest:
      result.sort((a, b) {
        final da = a.distanceKm ?? double.infinity;
        final db = b.distanceKm ?? double.infinity;
        return da.compareTo(db);
      });
    case ScanExploreSort.highestRated:
      result.sort((a, b) => b.ratingValue.compareTo(a.ratingValue));
    case ScanExploreSort.lowestPrice:
      result.sort((a, b) {
        final pa = a.startingPriceInr ?? 999999;
        final pb = b.startingPriceInr ?? 999999;
        return pa.compareTo(pb);
      });
    case ScanExploreSort.fastestReport:
      result.sort((a, b) {
        final ra = a.reportDeliverySummary ?? '48 hours';
        final rb = b.reportDeliverySummary ?? '48 hours';
        return ra.length.compareTo(rb.length);
      });
    case ScanExploreSort.recommended:
      result.sort((a, b) {
        final scoreA = a.ratingValue * 10 - (a.distanceKm ?? 50);
        final scoreB = b.ratingValue * 10 - (b.distanceKm ?? 50);
        return scoreB.compareTo(scoreA);
      });
  }

  return result;
}

class ScanExploreNotifier extends StateNotifier<ScanExploreState> {
  ScanExploreNotifier(this._repo) : super(const ScanExploreState());

  final ScanRepository _repo;

  Future<void> load({bool refresh = false}) async {
    if (state.isLoading) return;
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      page: refresh ? 1 : state.page,
      centers: refresh ? [] : state.centers,
    );

    final response = await _repo.searchVerifiedPage(
      ScanSearchParams(
        query: state.query.isEmpty ? null : state.query,
        homeVisit: state.filters.homeVisit ? true : null,
        hasOffer: state.filters.hasOffer ? true : null,
        openNow: state.filters.openNow ? true : null,
        latitude: state.latitude,
        longitude: state.longitude,
        page: 1,
      ),
    );

    if (response.success && response.data != null) {
      final page = response.data!;
      final filtered = applyScanExploreFiltersAndSort(
        page.centers,
        state.filters,
        state.sort,
      );
      state = state.copyWith(
        isLoading: false,
        centers: filtered,
        page: page.page,
        totalPages: page.totalPages,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: response.error ?? 'Could not load scan centers',
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);

    final nextPage = state.page + 1;
    final response = await _repo.searchVerifiedPage(
      ScanSearchParams(
        query: state.query.isEmpty ? null : state.query,
        homeVisit: state.filters.homeVisit ? true : null,
        hasOffer: state.filters.hasOffer ? true : null,
        openNow: state.filters.openNow ? true : null,
        latitude: state.latitude,
        longitude: state.longitude,
        page: nextPage,
      ),
    );

    if (response.success && response.data != null) {
      final page = response.data!;
      final combined = [...state.centers, ...page.centers];
      final filtered = applyScanExploreFiltersAndSort(
        combined,
        state.filters,
        state.sort,
      );
      state = state.copyWith(
        isLoadingMore: false,
        centers: filtered,
        page: page.page,
        totalPages: page.totalPages,
      );
    } else {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  void setQuery(String query) {
    state = state.copyWith(query: query);
    load(refresh: true);
  }

  void setFilters(ScanExploreFilters filters) {
    state = state.copyWith(filters: filters);
    load(refresh: true);
  }

  void setSort(ScanExploreSort sort) {
    state = state.copyWith(
      sort: sort,
      centers: applyScanExploreFiltersAndSort(state.centers, state.filters, sort),
    );
  }

  void setLocation(double? lat, double? lng) {
    state = state.copyWith(
      latitude: lat,
      longitude: lng,
      sort: (lat != null && lng != null)
          ? ScanExploreSort.nearest
          : state.sort,
    );
    load(refresh: true);
  }
}

final scanExploreProvider =
    StateNotifierProvider<ScanExploreNotifier, ScanExploreState>((ref) {
  return ScanExploreNotifier(ref.watch(scanRepositoryProvider));
});
