import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_constants.dart';
import '../core/services/token_storage.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_decorations.dart';
import '../core/theme/app_text_styles.dart';
import '../data/models/patient_booking_model.dart';
import '../features/user_auth/presentation/widgets/patient_header_avatar.dart';
import '../features/user_auth/provider/patient_auth_provider.dart';
import '../features/user_dashboard/provider/patient_dashboard_provider.dart';
import '../shared/widgets/health_service_card.dart';
import '../shared/widgets/healthcare_ui.dart';
import '../shared/widgets/hero_wallpaper_carousel.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeLoadBookings());
  }

  Future<void> _maybeLoadBookings() async {
    final loggedIn = await TokenStorage.instance.isPatientLoggedIn();
    if (loggedIn && mounted) {
      ref.read(patientDashboardProvider.notifier).loadBookings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(patientAuthProvider);
    final user = auth.user;
    final dash = ref.watch(patientDashboardProvider);
    final bannersAsync = ref.watch(homeHeroBannersProvider);
    final nextBooking = dash.upcomingBookings.isNotEmpty
        ? dash.upcomingBookings.first
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const UserBottomNavBar(currentTab: UserNavTab.home),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(homeHeroBannersProvider);
          if (await TokenStorage.instance.isPatientLoggedIn()) {
            await ref.read(patientDashboardProvider.notifier).refreshAll();
          }
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: OneMgHeader(
                locationLabel: 'Service available in',
                locationValue: 'All cities across India',
                searchHint: 'Search doctors, tests, labs...',
                trailing: user != null
                    ? PatientHeaderAvatar(user: user)
                    : const Icon(Icons.person_outline_rounded, size: 20),
                onTrailingTap: () => _onProfileTap(context, ref),
                onSearchTap: () => context.push(AppConstants.routeGlobalSearch),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(
              child: HealthServiceGrid(
                items: _homeServices
                    .map(
                      (service) => HealthServiceItem(
                        title: service.title,
                        image: service.image,
                        icon: service.icon,
                        color: service.color,
                        onTap: () => _openService(context, service),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            SliverToBoxAdapter(
              child: OneMgDualCtaRow(
                left: OneMgDualCta(
                  icon: Icons.videocam_rounded,
                  title: 'Online consult',
                  subtitle: 'Video with verified doctors',
                  color: AppColors.primary,
                  onTap: () => context.push(AppConstants.routeDoctorSearch),
                ),
                right: OneMgDualCta(
                  icon: Icons.biotech_rounded,
                  title: 'Lab tests',
                  subtitle: 'Home sample collection',
                  color: const Color(0xFF00838F),
                  onTap: () => context.push(AppConstants.routeLabs),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            const SliverToBoxAdapter(child: OneMgTrustStrip()),
            if (nextBooking != null) ...[
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _UpcomingBookingCard(
                    booking: nextBooking,
                    onTap: () => context.push(AppConstants.routeUserDashboard),
                  ),
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: OfferPromoCard(
                  title: 'Every provider is admin-verified',
                  subtitle: 'Book with confidence — quality care, transparent pricing',
                  badge: 'TRUSTED',
                  icon: Icons.verified_user_rounded,
                  includeMargin: false,
                  compact: true,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: HeroWallpaperCarousel(
                  slides: bannersAsync.asData?.value,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverToBoxAdapter(
              child: MarketplaceSectionTitle(
                title: 'Browse by specialty',
                actionLabel: 'View doctors',
                onAction: () => context.push(AppConstants.routeDoctorSearch),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 108,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: _specialties.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final item = _specialties[index];
                    return _SpecialtyChip(
                      icon: item.icon,
                      label: item.label,
                      softColor: item.softColor,
                      accentColor: item.accentColor,
                      deepColor: item.deepColor,
                      onTap: () => _openDoctorSearch(
                        context,
                        specialization: item.searchTerm,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: UserScrollFooter()),
          ],
        ),
      ),
    );
  }

  void _openService(BuildContext context, _HomeService service) {
    if (service.routeParams != null) {
      context.push('${service.route}?${service.routeParams}');
    } else {
      context.push(service.route);
    }
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

    final params = <String, String>{};
    if (city != null && city.isNotEmpty) params['city'] = city;
    if (specialization != null && specialization.isNotEmpty) {
      params['specialization'] = specialization;
    }

    final path = params.isEmpty
        ? AppConstants.routeDoctorSearch
        : '${AppConstants.routeDoctorSearch}?${Uri(queryParameters: params).query}';

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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primarySoft),
            boxShadow: AppDecorations.softShadow(opacity: 0.05),
          ),
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
                      'Upcoming appointment',
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
      ),
    );
  }
}

class _SpecialtyChip extends StatelessWidget {
  const _SpecialtyChip({
    required this.icon,
    required this.label,
    required this.softColor,
    required this.accentColor,
    required this.deepColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color softColor;
  final Color accentColor;
  final Color deepColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
                child: Center(
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [accentColor, deepColor],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 20),
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
    required this.image,
    required this.icon,
    required this.color,
    required this.route,
    this.routeParams,
  });

  final String title;
  final String image;
  final IconData icon;
  final Color color;
  final String route;
  final String? routeParams;
}

class _SpecialtyItem {
  const _SpecialtyItem({
    required this.icon,
    required this.label,
    required this.softColor,
    required this.accentColor,
    required this.deepColor,
    required this.searchTerm,
  });

  final IconData icon;
  final String label;
  final Color softColor;
  final Color accentColor;
  final Color deepColor;
  final String searchTerm;
}

const _homeServices = [
  _HomeService(
    title: 'Doctor\nConsultation',
    image: 'assets/images/home_cards/doctor_card.png',
    icon: Icons.medical_services_outlined,
    color: Color(0xff2CB67D),
    route: AppConstants.routeDoctorSearch,
  ),
  _HomeService(
    title: 'Nurse\nHome Care',
    image: 'assets/images/home_cards/nurse_card.png',
    icon: Icons.health_and_safety_outlined,
    color: Color(0xff8B5CF6),
    route: AppConstants.routeNurseSearch,
  ),
  _HomeService(
    title: 'Lab\nTests',
    image: 'assets/images/home_cards/lab_card.png',
    icon: Icons.science_outlined,
    color: Color(0xff3B82F6),
    route: AppConstants.routeLabs,
  ),
  _HomeService(
    title: 'Diagnostic\nScans',
    image: 'assets/images/home_cards/scan_card.png',
    icon: Icons.monitor_heart_outlined,
    color: Color(0xff14B8A6),
    route: AppConstants.routeScans,
  ),
  _HomeService(
    title: 'Ambulance\nBooking',
    image: 'assets/images/home_cards/ambulance.png',
    icon: Icons.local_hospital_outlined,
    color: Color(0xffEF4444),
    route: AppConstants.routeCareListing,
    routeParams: 'role=ambulance',
  ),
  _HomeService(
    title: 'Blood\nBank',
    image: 'assets/images/home_cards/blood.png',
    icon: Icons.bloodtype_outlined,
    color: Color(0xffEC4899),
    route: AppConstants.routeBloodBanks,
  ),
];

const _specialties = [
  _SpecialtyItem(
    icon: Icons.favorite_rounded,
    label: 'Cardiology',
    softColor: Color(0xFFFFEBEE),
    accentColor: Color(0xFFE53935),
    deepColor: Color(0xFFC62828),
    searchTerm: 'Cardiology',
  ),
  _SpecialtyItem(
    icon: Icons.psychology_rounded,
    label: 'Mental',
    softColor: Color(0xFFF3E5F5),
    accentColor: Color(0xFF8E24AA),
    deepColor: Color(0xFF6A1B9A),
    searchTerm: 'Psychiatry',
  ),
  _SpecialtyItem(
    icon: Icons.child_care_rounded,
    label: 'Pediatric',
    softColor: Color(0xFFE8F5E9),
    accentColor: Color(0xFF43A047),
    deepColor: Color(0xFF2E7D32),
    searchTerm: 'Pediatric',
  ),
  _SpecialtyItem(
    icon: Icons.visibility_rounded,
    label: 'Eye care',
    softColor: Color(0xFFE3F2FD),
    accentColor: Color(0xFF1E88E5),
    deepColor: Color(0xFF1565C0),
    searchTerm: 'Ophthalmology',
  ),
  _SpecialtyItem(
    icon: Icons.accessibility_new_rounded,
    label: 'Ortho',
    softColor: Color(0xFFFFF8E1),
    accentColor: Color(0xFFFB8C00),
    deepColor: Color(0xFFEF6C00),
    searchTerm: 'Orthopedics',
  ),
  _SpecialtyItem(
    icon: Icons.pregnant_woman_rounded,
    label: 'Gynae',
    softColor: Color(0xFFFCE4EC),
    accentColor: Color(0xFFEC407A),
    deepColor: Color(0xFFC2185B),
    searchTerm: 'Gynecology',
  ),
  _SpecialtyItem(
    icon: Icons.spa_rounded,
    label: 'Dermat',
    softColor: Color(0xFFE8EAF6),
    accentColor: Color(0xFF5C6BC0),
    deepColor: Color(0xFF3949AB),
    searchTerm: 'Dermatology',
  ),
  _SpecialtyItem(
    icon: Icons.medical_services_rounded,
    label: 'General',
    softColor: Color(0xFFE0F2F1),
    accentColor: Color(0xFF00897B),
    deepColor: Color(0xFF00695C),
    searchTerm: 'General Physician',
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
