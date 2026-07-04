import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/lab_model.dart';
import '../../../data/repositories/lab_repository.dart';
import '../data/lab_model_utils.dart';

export '../../../data/repositories/lab_repository.dart'
    show LabSearchParams, LabExploreSort, LabExploreFilters, LabSearchPage;

final labRepositoryProvider = Provider((ref) => LabRepository());

final labSearchProvider =
    FutureProvider.family<List<LabModel>, LabSearchParams>((ref, params) async {
  final repo = ref.watch(labRepositoryProvider);
  final response = await repo.searchVerified(params);
  if (response.success && response.data != null) {
    return response.data!;
  }
  throw Exception(response.error ?? 'Could not load labs');
});

final labDetailProvider =
    FutureProvider.family<LabModel, String>((ref, labId) async {
  final repo = ref.watch(labRepositoryProvider);
  final response = await repo.getById(labId);
  if (response.success && response.data != null) {
    return response.data!;
  }
  throw Exception(response.error ?? 'Could not load lab');
});

class LabExploreState {
  const LabExploreState({
    this.labs = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.page = 1,
    this.totalPages = 1,
    this.query = '',
    this.filters = const LabExploreFilters(),
    this.sort = LabExploreSort.recommended,
    this.latitude,
    this.longitude,
  });

  final List<LabModel> labs;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int page;
  final int totalPages;
  final String query;
  final LabExploreFilters filters;
  final LabExploreSort sort;
  final double? latitude;
  final double? longitude;

  bool get hasMore => page < totalPages;

  LabExploreState copyWith({
    List<LabModel>? labs,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    int? page,
    int? totalPages,
    String? query,
    LabExploreFilters? filters,
    LabExploreSort? sort,
    double? latitude,
    double? longitude,
    bool clearError = false,
  }) {
    return LabExploreState(
      labs: labs ?? this.labs,
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

List<LabModel> applyLabExploreFiltersAndSort(
  List<LabModel> labs,
  LabExploreFilters filters,
  LabExploreSort sort,
) {
  var result = labs.toList();

  if (filters.homeCollection) {
    result = result.where((l) => l.supportsHomeCollection).toList();
  }
  if (filters.labVisit) {
    result = result.where((l) => l.supportsLabVisit).toList();
  }
  if (filters.openNow) {
    result = result.where((l) => l.isOpenNow).toList();
  }
  if (filters.nablAccredited) {
    result = result.where((l) => l.isNablAccredited).toList();
  }
  if (filters.minRating != null) {
    result =
        result.where((l) => l.ratingValue >= filters.minRating!).toList();
  }

  switch (sort) {
    case LabExploreSort.nearest:
      result.sort((a, b) {
        final da = a.distanceKm ?? double.infinity;
        final db = b.distanceKm ?? double.infinity;
        return da.compareTo(db);
      });
    case LabExploreSort.highestRated:
      result.sort((a, b) => b.ratingValue.compareTo(a.ratingValue));
    case LabExploreSort.lowestPrice:
      result.sort((a, b) {
        final pa = a.startingPriceInr ?? 999999;
        final pb = b.startingPriceInr ?? 999999;
        return pa.compareTo(pb);
      });
    case LabExploreSort.fastestReport:
      result.sort((a, b) {
        final ra = a.reportDeliverySummary ?? '48 hours';
        final rb = b.reportDeliverySummary ?? '48 hours';
        return ra.length.compareTo(rb.length);
      });
    case LabExploreSort.recommended:
      result.sort((a, b) {
        final scoreA = a.ratingValue * 10 - (a.distanceKm ?? 50);
        final scoreB = b.ratingValue * 10 - (b.distanceKm ?? 50);
        return scoreB.compareTo(scoreA);
      });
  }

  return result;
}

class LabExploreNotifier extends StateNotifier<LabExploreState> {
  LabExploreNotifier(this._repo) : super(const LabExploreState());

  final LabRepository _repo;

  Future<void> load({bool refresh = false}) async {
    if (state.isLoading) return;
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      page: refresh ? 1 : state.page,
      labs: refresh ? [] : state.labs,
    );

    final response = await _repo.searchVerifiedPage(
      LabSearchParams(
        query: state.query.isEmpty ? null : state.query,
        homeCollection: state.filters.homeCollection ? true : null,
        latitude: state.latitude,
        longitude: state.longitude,
        page: 1,
      ),
    );

    if (response.success && response.data != null) {
      final page = response.data!;
      final filtered = applyLabExploreFiltersAndSort(
        page.labs,
        state.filters,
        state.sort,
      );
      state = state.copyWith(
        isLoading: false,
        labs: filtered,
        page: page.page,
        totalPages: page.totalPages,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: response.error ?? 'Could not load labs',
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);

    final nextPage = state.page + 1;
    final response = await _repo.searchVerifiedPage(
      LabSearchParams(
        query: state.query.isEmpty ? null : state.query,
        homeCollection: state.filters.homeCollection ? true : null,
        latitude: state.latitude,
        longitude: state.longitude,
        page: nextPage,
      ),
    );

    if (response.success && response.data != null) {
      final page = response.data!;
      final combined = [...state.labs, ...page.labs];
      final filtered = applyLabExploreFiltersAndSort(
        combined,
        state.filters,
        state.sort,
      );
      state = state.copyWith(
        isLoadingMore: false,
        labs: filtered,
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

  void setFilters(LabExploreFilters filters) {
    state = state.copyWith(filters: filters);
    load(refresh: true);
  }

  void setSort(LabExploreSort sort) {
    state = state.copyWith(
      sort: sort,
      labs: applyLabExploreFiltersAndSort(state.labs, state.filters, sort),
    );
  }

  void setLocation(double? lat, double? lng) {
    state = state.copyWith(latitude: lat, longitude: lng);
    load(refresh: true);
  }
}

final labExploreProvider =
    StateNotifierProvider<LabExploreNotifier, LabExploreState>((ref) {
  return LabExploreNotifier(ref.watch(labRepositoryProvider));
});
