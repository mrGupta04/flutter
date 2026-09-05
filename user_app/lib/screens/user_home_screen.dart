import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_constants.dart';
import '../core/widgets/app_back_navigation.dart';
import '../core/providers/user_location_provider.dart';
import '../core/services/token_storage.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_decorations.dart';
import '../core/theme/app_text_styles.dart';
import '../data/models/doctor_model.dart';
import '../data/models/patient_booking_model.dart';
import '../features/nurse_home_visit/nurse_home_visit_navigation.dart';
import '../features/doctor_registration/data/medical_specialities.dart';
import '../features/doctor_registration/presentation/widgets/doctor_search_result_tile.dart';
import '../features/doctor_registration/provider/doctor_live_status_provider.dart';
import '../features/doctor_registration/provider/verified_doctors_provider.dart';
import '../features/labs/data/health_package_visuals.dart';
import '../features/labs/data/models/health_package.dart';
import '../features/labs/presentation/screens/health_package_screen.dart';
import '../features/notifications/presentation/screens/notifications_screen.dart';
import '../features/user_auth/presentation/widgets/patient_header_avatar.dart';
import '../features/user_auth/provider/patient_auth_provider.dart';
import '../features/user_dashboard/provider/patient_dashboard_provider.dart';
import '../core/utils/geo_distance_utils.dart';
import '../core/utils/responsive_utils.dart';
import '../shared/widgets/health_service_card.dart';
import '../shared/widgets/healthcare_ui.dart';
import '../shared/widgets/marketplace_provider_card_ui.dart';
import '../shared/widgets/user_adaptive_scaffold.dart';
import '../shared/widgets/user_app_footer.dart';

/// Patient marketplace home — healthcare discovery dashboard.
class UserHomeScreen extends ConsumerStatefulWidget {
  const UserHomeScreen({super.key});

  @override
  ConsumerState<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends ConsumerState<UserHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeLoadBookings();
      _requestLocationOnOpen();
    });
  }

  Future<void> _maybeLoadBookings() async {
    final loggedIn = await TokenStorage.instance.isPatientLoggedIn();
    if (loggedIn && mounted) {
      ref.read(patientDashboardProvider.notifier).loadBookings();
    }
  }

  Future<void> _requestLocationOnOpen() async {
    if (!mounted) return;
    await ref.read(userLocationProvider.notifier).ensureResolved(context);
  }

  Future<void> _refreshHome() async {
    ref.invalidate(verifiedDoctorsProvider);
    if (mounted) {
      await ref
          .read(userLocationProvider.notifier)
          .ensureResolved(context, forcePrompt: false);
    }
    if (await TokenStorage.instance.isPatientLoggedIn()) {
      await ref.read(patientDashboardProvider.notifier).refreshAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(patientAuthProvider);
    final user = auth.user;
    final dash = ref.watch(patientDashboardProvider);
    final location = ref.watch(userLocationProvider);
    final doctorsAsync = ref.watch(verifiedDoctorsProvider);
    final nextBooking = dash.upcomingBookings.isNotEmpty
        ? dash.upcomingBookings.first
        : null;
    final loggedIn = auth.isLoggedIn;

    Widget constrain(Widget child) => ResponsivePage(child: child);

    return UserTabBackScope(
      isHomeTab: true,
      homeRoute: AppConstants.routeUserHome,
      child: UserAdaptiveScaffold(
        currentTab: UserNavTab.home,
        body: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _refreshHome,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: OneMgHeader(
                  locationLabel: location.hasCoordinates
                      ? 'Near you in'
                      : 'Service available in',
                  locationValue:
                      location.displayPlaceCity ?? location.displayCity,
                  greeting: _homeGreeting(user?.firstName),
                  searchHint: 'Search doctors, hospitals, nurses, labs...',
                  trailing: user != null
                      ? PatientHeaderAvatar(user: user)
                      : const Icon(Icons.person_outline_rounded, size: 20),
                  onTrailingTap: () => _onProfileTap(context, ref),
                  onLocationTap: () => ref
                      .read(userLocationProvider.notifier)
                      .ensureResolved(context, forcePrompt: true),
                  actions: user == null
                      ? null
                      : const NotificationBellButton(iconColor: AppColors.white),
                  onSearchTap: () =>
                      context.push(AppConstants.routeGlobalSearch),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 14)),
              SliverToBoxAdapter(
                child: constrain(
                  _HomeQuickActions(
                    onEmergency: () => _openServiceRoute(
                      AppConstants.routeAmbulanceHub,
                    ),
                    onFindBlood: () => _openServiceRoute(
                      AppConstants.routeBloodBanks,
                    ),
                    onMyBookings: () => _openMyBookings(context),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              SliverToBoxAdapter(
                child: constrain(
                  HealthServiceGrid(
                    items: _homeServices
                        .map(
                          (service) => HealthServiceItem(
                            title: service.title,
                            subtitle: service.subtitle,
                            icon: service.icon,
                            color: service.color,
                            illustrationImage: service.illustrationImage,
                            illustrationScale: service.illustrationScale,
                            onTap: () => _openService(context, service),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              if (loggedIn) ...[
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
                SliverToBoxAdapter(
                  child: constrain(
                    _UpcomingBookingSection(
                      isLoading: dash.isLoadingBookings && nextBooking == null,
                      error: nextBooking == null ? dash.error : null,
                      booking: nextBooking,
                      onRetry: () => ref
                          .read(patientDashboardProvider.notifier)
                          .loadBookings(),
                      onExplore: () => _scrollToProvidersHint(context),
                      onOpenBooking: nextBooking == null
                          ? () {}
                          : () => _openUpcomingBooking(nextBooking),
                    ),
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              SliverToBoxAdapter(
                child: constrain(
                  MarketplaceSectionTitle(
                    title: 'Popular Providers',
                    actionLabel: 'See all',
                    onAction: () => _openDoctorSearch(context),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: constrain(
                  _HomeProviderRail(
                    asyncDoctors: doctorsAsync,
                    emptyTitle: 'No popular providers yet',
                    emptySubtitle: 'Verified doctors will appear here.',
                    errorTitle: 'Unable to load popular providers',
                    onRetry: () => ref.invalidate(verifiedDoctorsProvider),
                    onSearch: () => context.push(AppConstants.routeGlobalSearch),
                    itemBuilder: (doctors) => _DoctorCardRail(
                      doctors: doctors.take(8).toList(growable: false),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              SliverToBoxAdapter(
                child: constrain(
                  MarketplaceSectionTitle(
                    title: 'Providers Near You',
                    actionLabel: location.hasCoordinates ? 'See all' : null,
                    onAction: location.hasCoordinates
                        ? () => _openDoctorSearch(context)
                        : null,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: constrain(
                  _NearbyProvidersSection(
                    location: location,
                    asyncDoctors: doctorsAsync,
                    onRetry: () => ref.invalidate(verifiedDoctorsProvider),
                    onEnableLocation: () => ref
                        .read(userLocationProvider.notifier)
                        .ensureResolved(context, forcePrompt: true),
                    onSearch: () => context.push(AppConstants.routeGlobalSearch),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              SliverToBoxAdapter(
                child: constrain(
                  MarketplaceSectionTitle(
                    title: 'Browse by Specialty',
                    actionLabel: 'View all',
                    onAction: () =>
                        context.push(AppConstants.routeFindSpecialists),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: constrain(
                  SizedBox(
                    height: 108,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: _homeSpecialties.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final item = _homeSpecialties[index];
                        return _SpecialtyChip(
                          organAsset: item.organAsset,
                          label: item.label,
                          softColor: item.softColor,
                          accentColor: item.accentColor,
                          onTap: () => _openDoctorSearch(
                            context,
                            specialization: item.searchTerm,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              SliverToBoxAdapter(
                child: constrain(
                  MarketplaceSectionTitle(
                    title: 'Health Packages',
                    actionLabel: 'See all',
                    onAction: () => _openServiceRoute(AppConstants.routeLabs),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: constrain(
                  HealthPackageList(
                    packages: _homeHealthPackages,
                    onPackageTap: (_) =>
                        _openServiceRoute(AppConstants.routeLabs),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: constrain(const UserScrollFooter()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _scrollToProvidersHint(BuildContext context) {
    // Categories sit above bookings; exploring means opening doctor search.
    _openDoctorSearch(context);
  }

  void _openUpcomingBooking(PatientBookingModel booking) {
    if (booking.needsHomeVisitPayment) {
      context.push(nursePaymentRoute(booking.id));
      return;
    }
    if (booking.canTrackHomeVisitLive) {
      context.push(nurseLiveTrackRoute(booking.id));
      return;
    }
    context.push(AppConstants.routeUserDashboard);
  }

  Future<void> _openMyBookings(BuildContext context) async {
    final loggedIn = await TokenStorage.instance.isPatientLoggedIn();
    if (!context.mounted) return;
    if (loggedIn) {
      context.push(AppConstants.routeUserDashboard);
    } else {
      context.push(AppConstants.routeUserLogin);
    }
  }

  void _openServiceRoute(String route) {
    final city = ref.read(userLocationProvider).city;
    context.push(routeWithPreferredCity(route, city));
  }

  void _openService(BuildContext context, _HomeService service) {
    final city = ref.read(userLocationProvider).city;
    final base = service.routeParams != null
        ? '${service.route}?${service.routeParams}'
        : service.route;
    context.push(routeWithPreferredCity(base, city));
  }

  void _openDoctorSearch(
    BuildContext context, {
    String? query,
    String? city,
    String? specialization,
  }) {
    if (query != null && query.isNotEmpty) {
      context.push(
        '${AppConstants.routeGlobalSearch}?q=${Uri.encodeComponent(query)}',
      );
      return;
    }

    final preferredCity = city ?? ref.read(userLocationProvider).city;
    final params = <String, String>{};
    if (preferredCity != null && preferredCity.isNotEmpty) {
      params['city'] = preferredCity;
    }
    if (specialization != null && specialization.isNotEmpty) {
      final resolved = findMedicalSpeciality(specialization);
      if (resolved != null) {
        params['speciality'] = resolved.slug;
      } else {
        params['specialization'] = specialization;
      }
    }

    final path = params.isEmpty
        ? AppConstants.routeDoctorSearch
        : '${AppConstants.routeDoctorSearch}?${Uri(queryParameters: params).query}';

    context.push(path);
  }
}

String _homeGreeting(String? firstName) {
  final hour = DateTime.now().hour;
  final salute = hour < 12
      ? 'Good morning'
      : hour < 17
          ? 'Good afternoon'
          : 'Good evening';
  final name = firstName?.trim();
  if (name == null || name.isEmpty) return salute;
  return '$salute, $name';
}

class _HomeQuickActions extends StatelessWidget {
  const _HomeQuickActions({
    required this.onEmergency,
    required this.onFindBlood,
    required this.onMyBookings,
  });

  final VoidCallback onEmergency;
  final VoidCallback onFindBlood;
  final VoidCallback onMyBookings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _QuickActionChip(
              emoji: '🚑',
              label: 'Emergency',
              onTap: onEmergency,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _QuickActionChip(
              emoji: '🩸',
              label: 'Find Blood',
              onTap: onFindBlood,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _QuickActionChip(
              emoji: '📅',
              label: 'My Bookings',
              onTap: onMyBookings,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
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

class _UpcomingBookingSection extends StatelessWidget {
  const _UpcomingBookingSection({
    required this.isLoading,
    required this.booking,
    required this.onRetry,
    required this.onExplore,
    required this.onOpenBooking,
    this.error,
  });

  final bool isLoading;
  final String? error;
  final PatientBookingModel? booking;
  final VoidCallback onRetry;
  final VoidCallback onExplore;
  final VoidCallback onOpenBooking;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: _HomeSectionSkeleton(height: 132),
      );
    }

    if (booking == null && error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: _HomeInlineMessage(
          title: 'Unable to load bookings',
          actionLabel: 'Retry',
          onAction: onRetry,
        ),
      );
    }

    if (booking == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: _HomeInlineMessage(
          title: 'No upcoming bookings',
          subtitle: 'Book a healthcare service when you need it.',
          actionLabel: 'Explore Providers',
          onAction: onExplore,
          compact: true,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MarketplaceSectionTitle(title: 'Upcoming Booking'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _UpcomingBookingCard(
            booking: booking!,
            onTap: onOpenBooking,
          ),
        ),
      ],
    );
  }
}

class _HomeProviderRail extends StatelessWidget {
  const _HomeProviderRail({
    required this.asyncDoctors,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.errorTitle,
    required this.onRetry,
    required this.onSearch,
    required this.itemBuilder,
  });

  final AsyncValue<List<DoctorModel>> asyncDoctors;
  final String emptyTitle;
  final String emptySubtitle;
  final String errorTitle;
  final VoidCallback onRetry;
  final VoidCallback onSearch;
  final Widget Function(List<DoctorModel> doctors) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return asyncDoctors.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: _HomeHorizontalSkeleton(),
      ),
      error: (_, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: _HomeInlineMessage(
          title: errorTitle,
          actionLabel: 'Retry',
          onAction: onRetry,
        ),
      ),
      data: (doctors) {
        if (doctors.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _HomeInlineMessage(
              title: emptyTitle,
              subtitle: emptySubtitle,
              actionLabel: 'Search Providers',
              onAction: onSearch,
              compact: true,
            ),
          );
        }
        return itemBuilder(doctors);
      },
    );
  }
}

class _NearbyProvidersSection extends StatelessWidget {
  const _NearbyProvidersSection({
    required this.location,
    required this.asyncDoctors,
    required this.onRetry,
    required this.onEnableLocation,
    required this.onSearch,
  });

  final UserLocationState location;
  final AsyncValue<List<DoctorModel>> asyncDoctors;
  final VoidCallback onRetry;
  final VoidCallback onEnableLocation;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    if (!location.hasCoordinates) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: _HomeInlineMessage(
          title: 'No providers found nearby',
          subtitle: location.isResolving
              ? 'Getting your location…'
              : 'Enable location to see providers near you.',
          actionLabel: location.isResolving ? null : 'Use my location',
          onAction: location.isResolving ? null : onEnableLocation,
          compact: true,
        ),
      );
    }

    return asyncDoctors.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: _HomeHorizontalSkeleton(),
      ),
      error: (_, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: _HomeInlineMessage(
          title: 'Unable to load nearby providers',
          actionLabel: 'Retry',
          onAction: onRetry,
        ),
      ),
      data: (doctors) {
        final nearby = sortDoctorsByDistance(
          doctors,
          location.latitude!,
          location.longitude!,
        )
            .where(
              (doctor) => doctorDistanceKm(
                    doctor,
                    location.latitude!,
                    location.longitude!,
                  ) !=
                  null,
            )
            .take(8)
            .toList(growable: false);

        if (nearby.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _HomeInlineMessage(
              title: 'No providers found nearby',
              subtitle: 'Try searching for a doctor, nurse, or hospital.',
              actionLabel: 'Search Providers',
              onAction: onSearch,
              compact: true,
            ),
          );
        }

        return _DoctorCardRail(
          doctors: nearby,
          userLatitude: location.latitude,
          userLongitude: location.longitude,
        );
      },
    );
  }
}

class _DoctorCardRail extends ConsumerWidget {
  const _DoctorCardRail({
    required this.doctors,
    this.userLatitude,
    this.userLongitude,
  });

  final List<DoctorModel> doctors;
  final double? userLatitude;
  final double? userLongitude;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveMap = ref
            .watch(doctorLiveStatusProvider(doctorIdsCacheKey(doctors)))
            .valueOrNull ??
        const <String, bool>{};

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth * 0.86).clamp(280.0, 360.0);
        return SizedBox(
          height: kDoctorListingCardHeight,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: doctors.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final doctor = applyLiveStatus(doctors[index], liveMap);
              final distance = userLatitude != null && userLongitude != null
                  ? doctorDistanceKm(doctor, userLatitude!, userLongitude!)
                  : null;
              return Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: cardWidth,
                  child: DoctorSearchResultTile(
                    doctor: doctor,
                    showBottomDivider: false,
                    distanceKm: distance,
                    availabilityLabel:
                        doctor.isLiveNow ? 'Available now' : null,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _HomeInlineMessage extends StatelessWidget {
  const _HomeInlineMessage({
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(14, compact ? 12 : 16, 14, compact ? 12 : 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (actionLabel != null && onAction != null)
              TextButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
          ],
        ),
      ),
    );
  }
}

class _HomeSectionSkeleton extends StatelessWidget {
  const _HomeSectionSkeleton({this.height = 120});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

class _HomeHorizontalSkeleton extends StatelessWidget {
  const _HomeHorizontalSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 148,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, _) => const SizedBox(
          width: 260,
          child: _HomeSectionSkeleton(height: 148),
        ),
      ),
    );
  }
}

class _UpcomingBookingCard extends StatelessWidget {
  const _UpcomingBookingCard({
    required this.booking,
    required this.onTap,
  });

  final PatientBookingModel booking;
  final VoidCallback onTap;

  String get _ctaLabel {
    if (booking.needsHomeVisitPayment) {
      return booking.consultationFee != null
          ? 'Pay ₹${booking.consultationFee} to confirm'
          : 'Pay to confirm booking';
    }
    if (booking.isNurseVisit) return 'Track Nurse';
    if (booking.isClinicVisit) return 'View Visit';
    return 'View Appointment';
  }

  IconData get _ctaIcon {
    if (booking.needsHomeVisitPayment) return Icons.payments_rounded;
    if (booking.isNurseVisit || booking.canTrackHomeVisitLive) {
      return Icons.my_location_rounded;
    }
    return Icons.event_available_rounded;
  }

  String? get _locationLine {
    final parts = <String>[
      if (booking.clinicName != null && booking.clinicName!.trim().isNotEmpty)
        booking.clinicName!.trim(),
      if (booking.clinicAddress != null &&
          booking.clinicAddress!.trim().isNotEmpty)
        booking.clinicAddress!.trim()
      else if (booking.patientAddress != null &&
          booking.patientAddress!.trim().isNotEmpty)
        booking.patientAddress!.trim()
      else if (booking.patientCity != null &&
          booking.patientCity!.trim().isNotEmpty)
        booking.patientCity!.trim(),
    ];
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('EEE, d MMM').format(booking.slotStart);
    final timeLabel = DateFormat('h:mm a').format(booking.slotStart);

    return Material(
      color: Colors.transparent,
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primarySoft),
          boxShadow: AppDecorations.softShadow(opacity: 0.04),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.event_available_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.statusLabel,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          booking.doctorName,
                          style: AppTextStyles.titleSmall.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${booking.typeLabel} · $dateLabel · $timeLabel',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_locationLine != null)
                          Text(
                            _locationLine!,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: () {
                if (booking.needsHomeVisitPayment) {
                  context.push(nursePaymentRoute(booking.id));
                  return;
                }
                if (booking.isNurseVisit && booking.canTrackHomeVisitLive) {
                  context.push(nurseLiveTrackRoute(booking.id));
                  return;
                }
                onTap();
              },
              icon: Icon(_ctaIcon, size: 18),
              label: Text(_ctaLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpecialtyChip extends StatelessWidget {
  const _SpecialtyChip({
    required this.organAsset,
    required this.label,
    required this.softColor,
    required this.accentColor,
    required this.onTap,
  });

  final String organAsset;
  final String label;
  final Color softColor;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSvg = organAsset.toLowerCase().endsWith('.svg');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 76,
          child: Column(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: softColor,
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.16),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: isSvg
                      ? SvgPicture.asset(
                          organAsset,
                          fit: BoxFit.contain,
                          colorFilter: ColorFilter.mode(
                            accentColor,
                            BlendMode.srcIn,
                          ),
                        )
                      : Image.asset(
                          organAsset,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeService {
  const _HomeService({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.illustrationImage,
    required this.route,
    this.routeParams,
    this.illustrationScale = 1.0,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String illustrationImage;
  final String route;
  final String? routeParams;
  final double illustrationScale;
}

class _SpecialtyItem {
  const _SpecialtyItem({
    required this.organAsset,
    required this.label,
    required this.softColor,
    required this.accentColor,
    required this.searchTerm,
  });

  final String organAsset;
  final String label;
  final Color softColor;
  final Color accentColor;
  final String searchTerm;
}

const _homeServices = [
  _HomeService(
    title: 'Doctors',
    subtitle: 'Consult verified specialists',
    icon: Icons.medical_services_outlined,
    color: Color(0xff2CB67D),
    illustrationImage:
        'assets/images/home_cards/doctor_card-removebg-preview.png',
    route: AppConstants.routeDoctorSearch,
  ),
  _HomeService(
    title: 'Nurses & Care',
    subtitle: 'Professional care at home',
    icon: Icons.health_and_safety_outlined,
    color: Color(0xff8B5CF6),
    illustrationImage:
        'assets/images/home_cards/nurse_card-removebg-preview.png',
    route: AppConstants.routeNurseSearch,
  ),
  _HomeService(
    title: 'Scans',
    subtitle: 'MRI, CT, X-ray and ultrasound',
    icon: Icons.radar_outlined,
    color: Color(0xff0EA5E9),
    illustrationImage:
        'assets/images/home_cards/scan_card-removebg-preview.png',
    route: AppConstants.routeScans,
  ),
  _HomeService(
    title: 'Labs &\nDiagnostics',
    subtitle: 'Tests, scans and reports',
    icon: Icons.science_outlined,
    color: Color(0xff3B82F6),
    illustrationImage:
        'assets/images/home_cards/lab_card-removebg-preview.png',
    route: AppConstants.routeLabs,
  ),
  _HomeService(
    title: 'Ambulance',
    subtitle: '24/7 emergency response',
    icon: Icons.local_hospital_outlined,
    color: Color(0xffEF4444),
    illustrationImage:
        'assets/images/home_cards/ambulance_remove_pg_preview.png',
    illustrationScale: 1.3,
    route: AppConstants.routeAmbulanceHub,
  ),
  _HomeService(
    title: 'Blood Banks',
    subtitle: 'Request or donate blood',
    icon: Icons.bloodtype_outlined,
    color: Color(0xffEC4899),
    illustrationImage:
        'assets/images/home_cards/blood-removebg-preview.png',
    route: AppConstants.routeBloodBanks,
  ),
];

const _homeSpecialties = [
  _SpecialtyItem(
    organAsset: OrganAssets.heart,
    label: 'Cardiology',
    softColor: Color(0xFFFFEBEE),
    accentColor: Color(0xFFE53935),
    searchTerm: 'Cardiology',
  ),
  _SpecialtyItem(
    organAsset: OrganAssets.skin,
    label: 'Dermatology',
    softColor: Color(0xFFE8EAF6),
    accentColor: Color(0xFF5C6BC0),
    searchTerm: 'Dermatology',
  ),
  _SpecialtyItem(
    organAsset: OrganAssets.spine,
    label: 'Neurology',
    softColor: Color(0xFFEDE7F6),
    accentColor: Color(0xFF7E57C2),
    searchTerm: 'Neurology',
  ),
  _SpecialtyItem(
    organAsset: OrganAssets.bone,
    label: 'Orthopedics',
    softColor: Color(0xFFFFF8E1),
    accentColor: Color(0xFFFB8C00),
    searchTerm: 'Orthopedics',
  ),
  _SpecialtyItem(
    organAsset: OrganAssets.vitamin,
    label: 'Pediatrics',
    softColor: Color(0xFFE8F5E9),
    accentColor: Color(0xFF43A047),
    searchTerm: 'Pediatrics',
  ),
  _SpecialtyItem(
    organAsset: OrganAssets.pregnancy,
    label: 'Gynecology',
    softColor: Color(0xFFFCE4EC),
    accentColor: Color(0xFFEC407A),
    searchTerm: 'Gynecology & Obstetrics',
  ),
  _SpecialtyItem(
    organAsset: OrganAssets.ear,
    label: 'ENT',
    softColor: Color(0xFFFFF8E1),
    accentColor: Color(0xFFF9A825),
    searchTerm: 'ENT (Otolaryngology)',
  ),
  _SpecialtyItem(
    organAsset: OrganAssets.eye,
    label: 'Ophthalmology',
    softColor: Color(0xFFE3F2FD),
    accentColor: Color(0xFF1E88E5),
    searchTerm: 'Ophthalmology',
  ),
  _SpecialtyItem(
    organAsset: OrganAssets.tooth,
    label: 'Dentistry',
    softColor: Color(0xFFE0F7FA),
    accentColor: Color(0xFF00ACC1),
    searchTerm: 'Dentistry',
  ),
];

List<HealthPackage> get _homeHealthPackages {
  const ids = [
    'full-body',
    'diabetic-health-checkup',
    'cardiac-checkup',
    'womens',
  ];
  return [
    for (final id in ids)
      if (HealthPackageCatalog.findById(id) != null)
        HealthPackageCatalog.findById(id)!,
  ];
}

Future<void> _onProfileTap(BuildContext context, WidgetRef ref) async {
  final loggedIn = await TokenStorage.instance.isPatientLoggedIn();
  if (!context.mounted) return;

  if (loggedIn) {
    ref.invalidate(patientDashboardProvider);
    context.push(AppConstants.routeUserDashboard);
  } else {
    context.push(AppConstants.routeUserLogin);
  }
}
