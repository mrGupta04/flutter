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
import '../data/models/patient_booking_model.dart';
import '../features/doctor_registration/data/medical_specialities.dart';
import '../features/labs/data/health_package_visuals.dart';
import '../features/labs/data/lab_test_illustrations.dart';
import '../features/user_auth/presentation/widgets/patient_header_avatar.dart';
import '../features/user_auth/provider/patient_auth_provider.dart';
import '../features/user_dashboard/provider/patient_dashboard_provider.dart';
import '../core/utils/responsive_utils.dart';
import '../shared/widgets/health_service_card.dart';
import '../shared/widgets/healthcare_ui.dart';
import '../shared/widgets/hero_wallpaper_carousel.dart';
import '../shared/widgets/user_adaptive_scaffold.dart';
import '../shared/widgets/user_app_footer.dart';
import '../data/models/api_response_model.dart';
import '../data/services/dio_service.dart';

final homeHeroBannersProvider =
    FutureProvider.autoDispose<List<HeroSlide>>((ref) async {
  try {
    final response = await DioService().get(
      AppConstants.endpointCmsBanners,
      queryParameters: {'placement': 'home_hero'},
    );
    final body = response.data as Map<String, dynamic>;
    final list = extractApiList(body['data']);
    return list
        .whereType<Map>()
        .map((e) => HeroSlide.fromJson(Map<String, dynamic>.from(e)))
        .where((s) => s.imageUrl.isNotEmpty && s.title.isNotEmpty)
        .toList();
  } catch (_) {
    return const [];
  }
});

/// Patient marketplace home — 1mg Care style dashboard.
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
    await ref
        .read(userLocationProvider.notifier)
        .ensureResolved(context);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(patientAuthProvider);
    final user = auth.user;
    final dash = ref.watch(patientDashboardProvider);
    final location = ref.watch(userLocationProvider);
    final bannersAsync = ref.watch(homeHeroBannersProvider);
    final nextBooking = dash.upcomingBookings.isNotEmpty
        ? dash.upcomingBookings.first
        : null;

    Widget constrain(Widget child) => ResponsivePage(child: child);

    return UserTabBackScope(
      isHomeTab: true,
      homeRoute: AppConstants.routeUserHome,
      child: UserAdaptiveScaffold(
        currentTab: UserNavTab.home,
        body: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(homeHeroBannersProvider);
            if (mounted) {
              await ref
                  .read(userLocationProvider.notifier)
                  .ensureResolved(context, forcePrompt: false);
            }
            if (await TokenStorage.instance.isPatientLoggedIn()) {
              await ref.read(patientDashboardProvider.notifier).refreshAll();
            }
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // Header stays edge-to-edge; content below is max-width constrained.
              SliverToBoxAdapter(
                child: OneMgHeader(
                  locationLabel: location.hasCoordinates
                      ? 'Near you in'
                      : 'Service available in',
                  locationValue:
                      location.displayPlaceCity ?? location.displayCity,
                  searchHint: 'Search doctors, tests, labs...',
                  trailing: user != null
                      ? PatientHeaderAvatar(user: user)
                      : const Icon(Icons.person_outline_rounded, size: 20),
                  onTrailingTap: () => _onProfileTap(context, ref),
                  onSearchTap: () =>
                      context.push(AppConstants.routeGlobalSearch),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
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
              const SliverToBoxAdapter(child: SizedBox(height: 14)),
              SliverToBoxAdapter(
                child: constrain(
                  OneMgDualCtaRow(
                    left: OneMgDualCta(
                      icon: Icons.videocam_rounded,
                      title: 'Online consult',
                      subtitle: 'Video with verified doctors',
                      color: AppColors.primary,
                      onTap: () => context.push(
                        routeWithPreferredCity(
                          AppConstants.routeDoctorSearch,
                          ref.read(userLocationProvider).city,
                        ),
                      ),
                    ),
                    right: OneMgDualCta(
                      icon: Icons.biotech_rounded,
                      title: 'Lab tests',
                      subtitle: 'Home sample collection',
                      color: const Color(0xFF00838F),
                      onTap: () => context.push(
                        routeWithPreferredCity(
                          AppConstants.routeLabs,
                          ref.read(userLocationProvider).city,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 14)),
              SliverToBoxAdapter(
                child: constrain(const OneMgTrustStrip()),
              ),
              if (nextBooking != null) ...[
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                SliverToBoxAdapter(
                  child: constrain(
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _UpcomingBookingCard(
                        booking: nextBooking,
                        onTap: () =>
                            context.push(AppConstants.routeUserDashboard),
                      ),
                    ),
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverToBoxAdapter(
                child: constrain(
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: OfferPromoCard(
                      title: 'Every provider is admin-verified',
                      subtitle:
                          'Book with confidence — quality care, transparent pricing',
                      badge: 'TRUSTED',
                      icon: Icons.verified_user_rounded,
                      includeMargin: false,
                      compact: true,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: constrain(
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: HeroWallpaperCarousel(
                      slides: bannersAsync.asData?.value,
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              SliverToBoxAdapter(
                child: constrain(
                  MarketplaceSectionTitle(
                    title: 'Browse by specialty',
                    actionLabel: 'View doctors',
                    onAction: () => context.push(
                      routeWithPreferredCity(
                        AppConstants.routeDoctorSearch,
                        ref.read(userLocationProvider).city,
                      ),
                    ),
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
                      itemCount: _specialties.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final item = _specialties[index];
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
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              SliverToBoxAdapter(
                child: constrain(
                  MarketplaceSectionTitle(
                    title: 'Browse by role',
                    actionLabel: 'View nurses',
                    onAction: () => context.push(
                      routeWithPreferredCity(
                        AppConstants.routeNurseSearch,
                        ref.read(userLocationProvider).city,
                      ),
                    ),
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
                      itemCount: _nurseRoles.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final item = _nurseRoles[index];
                        return _SpecialtyChip(
                          organAsset: item.organAsset,
                          label: item.label,
                          softColor: item.softColor,
                          accentColor: item.accentColor,
                          onTap: () => _openNurseSearch(
                            context,
                            specialization: item.searchTerm,
                          ),
                        );
                      },
                    ),
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

  void _openNurseSearch(
    BuildContext context, {
    String? city,
    String? specialization,
  }) {
    final preferredCity = city ?? ref.read(userLocationProvider).city;
    final params = <String, String>{};
    if (preferredCity != null && preferredCity.isNotEmpty) {
      params['city'] = preferredCity;
    }
    if (specialization != null && specialization.isNotEmpty) {
      params['specialization'] = specialization;
    }

    final path = params.isEmpty
        ? AppConstants.routeNurseSearch
        : '${AppConstants.routeNurseSearch}?${Uri(queryParameters: params).query}';

    context.push(path);
  }
}

class _UpcomingBookingCard extends StatelessWidget {
  const _UpcomingBookingCard({
    required this.booking,
    required this.onTap,
  });

  final PatientBookingModel booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dateLabel =
        DateFormat('EEE, d MMM · h:mm a').format(booking.slotStart);

    return Material(
      color: Colors.transparent,
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primarySoft),
          boxShadow: AppDecorations.softShadow(opacity: 0.05),
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
                          booking.canTrackHomeVisitLive
                              ? (booking.visitProgress == 'en_route'
                                  ? 'Nurse/doctor on the way'
                                  : 'Upcoming appointment')
                              : 'Upcoming appointment',
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
                          '${booking.typeLabel} · $dateLabel',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
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
            if (booking.canTrackHomeVisitLive) ...[
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: () => context.push(
                  '${AppConstants.routeHomeVisitTrack}?bookingId=${Uri.encodeComponent(booking.id)}',
                ),
                icon: const Icon(Icons.my_location_rounded, size: 18),
                label: Text(
                  booking.isNurseVisit ? 'Track nurse live' : 'Track doctor live',
                ),
              ),
            ],
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
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      softColor,
                      Color.lerp(softColor, Colors.white, 0.35)!,
                    ],
                  ),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.16),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
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
    title: 'Doctor\nConsultation',
    subtitle: 'Talk to expert doctors online',
    icon: Icons.medical_services_outlined,
    color: Color(0xff2CB67D),
    illustrationImage:
        'assets/images/home_cards/doctor_card-removebg-preview.png',
    route: AppConstants.routeDoctorSearch,
  ),
  _HomeService(
    title: 'Nurse\nHome Care',
    subtitle: 'Professional nursing care at your home',
    icon: Icons.health_and_safety_outlined,
    color: Color(0xff8B5CF6),
    illustrationImage:
        'assets/images/home_cards/nurse_card-removebg-preview.png',
    route: AppConstants.routeNurseSearch,
  ),
  _HomeService(
    title: 'Lab\nTests',
    subtitle: 'Accurate reports, right on time',
    icon: Icons.science_outlined,
    color: Color(0xff3B82F6),
    illustrationImage:
        'assets/images/home_cards/lab_card-removebg-preview.png',
    route: AppConstants.routeLabs,
  ),
  _HomeService(
    title: 'Diagnostic\nScans',
    subtitle: 'Advanced imaging for accurate diagnosis',
    icon: Icons.monitor_heart_outlined,
    color: Color(0xff14B8A6),
    illustrationImage:
        'assets/images/home_cards/scan_card-removebg-preview.png',
    route: AppConstants.routeScans,
  ),
  _HomeService(
    title: 'Ambulance\nBooking',
    subtitle: '24/7 emergency ambulance service',
    icon: Icons.local_hospital_outlined,
    color: Color(0xffEF4444),
    illustrationImage:
        'assets/images/home_cards/ambulance_remove_pg_preview.png',
    illustrationScale: 1.3,
    route: AppConstants.routeAmbulanceSearch,
  ),
  _HomeService(
    title: 'Blood\nBank',
    subtitle: 'Donate blood, save lives',
    icon: Icons.bloodtype_outlined,
    color: Color(0xffEC4899),
    illustrationImage:
        'assets/images/home_cards/blood-removebg-preview.png',
    route: AppConstants.routeBloodBankSearch,
  ),
];

const _specialties = [
  _SpecialtyItem(
    organAsset: OrganAssets.heart,
    label: 'Cardiology',
    softColor: Color(0xFFFFEBEE),
    accentColor: Color(0xFFE53935),
    searchTerm: 'Cardiology',
  ),
  _SpecialtyItem(
    organAsset: LabTestIllustrations.brain,
    label: 'Mental',
    softColor: Color(0xFFF3E5F5),
    accentColor: Color(0xFF8E24AA),
    searchTerm: 'Psychiatry',
  ),
  _SpecialtyItem(
    organAsset: OrganAssets.vitamin,
    label: 'Pediatric',
    softColor: Color(0xFFE8F5E9),
    accentColor: Color(0xFF43A047),
    searchTerm: 'Pediatrics',
  ),
  _SpecialtyItem(
    organAsset: OrganAssets.eye,
    label: 'Eye care',
    softColor: Color(0xFFE3F2FD),
    accentColor: Color(0xFF1E88E5),
    searchTerm: 'Ophthalmology',
  ),
  _SpecialtyItem(
    organAsset: OrganAssets.bone,
    label: 'Ortho',
    softColor: Color(0xFFFFF8E1),
    accentColor: Color(0xFFFB8C00),
    searchTerm: 'Orthopedics',
  ),
  _SpecialtyItem(
    organAsset: OrganAssets.pregnancy,
    label: 'Gynae',
    softColor: Color(0xFFFCE4EC),
    accentColor: Color(0xFFEC407A),
    searchTerm: 'Gynecology',
  ),
  _SpecialtyItem(
    organAsset: OrganAssets.skin,
    label: 'Dermat',
    softColor: Color(0xFFE8EAF6),
    accentColor: Color(0xFF5C6BC0),
    searchTerm: 'Dermatology',
  ),
  _SpecialtyItem(
    organAsset: OrganAssets.blood,
    label: 'General',
    softColor: Color(0xFFE0F2F1),
    accentColor: Color(0xFF00897B),
    searchTerm: 'General Physician',
  ),
];

const _nurseRoles = [
  _SpecialtyItem(
    organAsset: OrganAssets.bone,
    label: 'Elder care',
    softColor: Color(0xFFEDE7F6),
    accentColor: Color(0xFF7E57C2),
    searchTerm: 'Elder care',
  ),
  _SpecialtyItem(
    organAsset: OrganAssets.vitamin,
    label: 'Pediatric',
    softColor: Color(0xFFE8F5E9),
    accentColor: Color(0xFF43A047),
    searchTerm: 'Pediatric',
  ),
  _SpecialtyItem(
    organAsset: OrganAssets.muscle,
    label: 'Post-op',
    softColor: Color(0xFFFFF3E0),
    accentColor: Color(0xFFFB8C00),
    searchTerm: 'Post-op',
  ),
  _SpecialtyItem(
    organAsset: OrganAssets.lungs,
    label: 'ICU',
    softColor: Color(0xFFFFEBEE),
    accentColor: Color(0xFFE53935),
    searchTerm: 'ICU',
  ),
  _SpecialtyItem(
    organAsset: 'assets/images/home_cards/nurse_home_care.png',
    label: 'Home care',
    softColor: Color(0xFFF3E5F5),
    accentColor: Color(0xFF8B5CF6),
    searchTerm: 'Home care',
  ),
  _SpecialtyItem(
    organAsset: OrganAssets.immuneSystem,
    label: 'Geriatric',
    softColor: Color(0xFFE0F2F1),
    accentColor: Color(0xFF00897B),
    searchTerm: 'Geriatric',
  ),
];

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
