import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/friendly_error.dart';
import '../../../../data/models/patient_booking_model.dart';
import '../../../../shared/widgets/user_adaptive_scaffold.dart';
import '../../../../shared/widgets/user_app_footer.dart';
import '../../provider/patient_dashboard_provider.dart';
import '../widgets/booking_empty_state.dart';
import '../widgets/unified_booking_card.dart';

class CurrentBookingsScreen extends ConsumerStatefulWidget {
  const CurrentBookingsScreen({super.key});

  @override
  ConsumerState<CurrentBookingsScreen> createState() =>
      _CurrentBookingsScreenState();
}

class _CurrentBookingsScreenState extends ConsumerState<CurrentBookingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(patientDashboardProvider.notifier).loadBookings();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dash = ref.watch(patientDashboardProvider);
    return UserAdaptiveScaffold(
      currentTab: UserNavTab.profile,
      appBar: AppBar(
        title: const Text('Current bookings'),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: 'Active (${dash.activeBookings.length})'),
            Tab(text: 'Upcoming (${dash.upcomingConfirmedBookings.length})'),
            Tab(text: 'Pending (${dash.pendingBookings.length})'),
          ],
        ),
      ),
      body: dash.isLoadingBookings && dash.bookings.isEmpty
          ? const BookingListSkeleton()
          : dash.error != null && dash.bookings.isEmpty
              ? BookingListError(
                  message: friendlyErrorMessage(dash.error!),
                  onRetry: () =>
                      ref.read(patientDashboardProvider.notifier).loadBookings(),
                )
              : TabBarView(
                  controller: _tabs,
                  children: [
                    _BucketList(
                      bookings: dash.activeBookings,
                      emptyTitle: 'No active bookings',
                      emptySubtitle:
                          'Live visits, ambulance trips, and in-progress care appear here.',
                    ),
                    _BucketList(
                      bookings: dash.upcomingConfirmedBookings,
                      emptyTitle: 'No upcoming bookings',
                      emptySubtitle:
                          'Your confirmed healthcare appointments will appear here.',
                    ),
                    _BucketList(
                      bookings: dash.pendingBookings,
                      emptyTitle: 'No pending requests',
                      emptySubtitle:
                          'Requests waiting for provider confirmation or payment appear here.',
                    ),
                  ],
                ),
    );
  }
}

class _BucketList extends ConsumerWidget {
  const _BucketList({
    required this.bookings,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  final List<PatientBookingModel> bookings;
  final String emptyTitle;
  final String emptySubtitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (bookings.isEmpty) {
      return BookingEmptyState(title: emptyTitle, subtitle: emptySubtitle);
    }
    return RefreshIndicator(
      onRefresh: () => ref.read(patientDashboardProvider.notifier).loadBookings(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: bookings.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return UnifiedBookingCard(booking: bookings[index]);
        },
      ),
    );
  }
}

class BookingHistoryScreen extends ConsumerStatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  ConsumerState<BookingHistoryScreen> createState() =>
      _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends ConsumerState<BookingHistoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _search = TextEditingController();
  final _scroll = ScrollController();
  PatientBookingCategory _service = PatientBookingCategory.all;
  Timer? _debounce;

  static const _statusByTab = ['all', 'completed', 'cancelled', 'failed'];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _tabs.addListener(_onTab);
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tabs.removeListener(_onTab);
    _tabs.dispose();
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onTab() {
    if (_tabs.indexIsChanging) return;
    _reload();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 240) {
      ref.read(patientDashboardProvider.notifier).loadHistory(
            refresh: false,
            status: _statusByTab[_tabs.index],
            q: _search.text,
            service: _service == PatientBookingCategory.all ? null : _service,
          );
    }
  }

  void _reload() {
    ref.read(patientDashboardProvider.notifier).loadHistory(
          refresh: true,
          status: _statusByTab[_tabs.index],
          q: _search.text,
          service: _service == PatientBookingCategory.all ? null : _service,
        );
  }

  @override
  Widget build(BuildContext context) {
    final dash = ref.watch(patientDashboardProvider);
    final list = dash.historyBookings;

    return UserAdaptiveScaffold(
      currentTab: UserNavTab.profile,
      appBar: AppBar(
        title: const Text('Booking history'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
            Tab(text: 'Failed'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _search,
              onChanged: (_) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 400), _reload);
              },
              decoration: const InputDecoration(
                hintText: 'Search booking...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final category in [
                  PatientBookingCategory.all,
                  ...PatientBookingCategory.bookingSections,
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(category.label),
                      selected: _service == category,
                      onSelected: (_) {
                        setState(() => _service = category);
                        _reload();
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: dash.isLoadingHistory && list.isEmpty
                ? const BookingListSkeleton()
                : dash.historyError != null && list.isEmpty
                    ? BookingListError(
                        message: friendlyErrorMessage(dash.historyError!),
                        onRetry: _reload,
                      )
                    : list.isEmpty
                        ? const BookingEmptyState(
                            title: 'No booking history yet',
                            subtitle:
                                'Your completed healthcare services will appear here.',
                          )
                        : RefreshIndicator(
                            onRefresh: () async => _reload(),
                            child: ListView.separated(
                              controller: _scroll,
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                              itemCount:
                                  list.length + (dash.historyPagination.hasMore ? 1 : 0),
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                if (index >= list.length) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                return UnifiedBookingCard(booking: list[index]);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
