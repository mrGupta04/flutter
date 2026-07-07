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
import '../shared/widgets/care_role_avatar_card.dart';
import '../shared/widgets/healthcare_ui.dart';
import '../shared/widgets/hero_wallpaper_carousel.dart';
import '../shared/widgets/user_app_footer.dart';

/// Patient marketplace home — verified providers only, no registration flows.
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

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(patientAuthProvider);
    final user = auth.user;
    final dash = ref.watch(patientDashboardProvider);
    final nextBooking = dash.upcomingBookings.isNotEmpty
        ? dash.upcomingBookings.first
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const UserBottomNavBar(currentTab: UserNavTab.home),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
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
              child: _ModernHomeHeader(
                greeting: _greeting(),
                userName: user?.firstName,
                onSearchTap: () => context.push(AppConstants.routeGlobalSearch),
                onProfileTap: () => _onProfileTap(context, ref),
                trailing: user != null
                    ? PatientHeaderAvatar(user: user)
                    : const Icon(Icons.person_outline_rounded, size: 20),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            const SliverToBoxAdapter(child: _TrustStatsRow()),
            if (nextBooking != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _UpcomingBookingCard(
                    booking: nextBooking,
                    onTap: () => context.push(AppConstants.routeUserDashboard),
                  ),
                ),
              ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: HeroWallpaperCarousel(),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: _FeaturedLabCard(
                  onTap: () => context.push(AppConstants.routeLabs),
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: MarketplaceSectionTitle(
                title: 'Find care by role',
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        for (var i = 0; i < 3; i++) ...[
                          if (i > 0) const SizedBox(width: 8),
                          Expanded(
                            child: CareRoleAvatarCard(
                              label: _homeServices[i].label,
                              imageUrl: _homeServices[i].avatarImageUrl,
                              icon: _homeServices[i].icon,
                              accentColor: _homeServices[i].color,
                              onTap: () =>
                                  _openService(context, _homeServices[i]),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        for (var i = 3; i < 6; i++) ...[
                          if (i > 3) const SizedBox(width: 8),
                          Expanded(
                            child: CareRoleAvatarCard(
                              label: _homeServices[i].label,
                              imageUrl: _homeServices[i].avatarImageUrl,
                              icon: _homeServices[i].icon,
                              accentColor: _homeServices[i].color,
                              onTap: () =>
                                  _openService(context, _homeServices[i]),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
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
                      color: item.color,
                      onTap: () => _openDoctorSearch(
                        context,
                        specialization: item.searchTerm,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: OfferPromoCard(
                  title: 'Every provider is admin-verified',
                  subtitle: 'Book with confidence — quality care, transparent pricing',
                  badge: 'TRUSTED',
                  icon: Icons.verified_user_rounded,
                  includeMargin: false,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: _ProviderPartnerCard(
                  onTap: () => context.push(AppConstants.routeProviderLanding),
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

class _ModernHomeHeader extends StatelessWidget {
  const _ModernHomeHeader({
    required this.greeting,
    required this.onSearchTap,
    required this.onProfileTap,
    required this.trailing,
    this.userName,
  });

  final String greeting;
  final String? userName;
  final VoidCallback onSearchTap;
  final VoidCallback onProfileTap;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: AppColors.gradientHero,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 16, 72),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: AppDecorations.softShadow(opacity: 0.12),
                        ),
                        child: Text(
                          '1mg',
                          style: AppTextStyles.titleLarge.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w900,
                            height: 1,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Healthcare',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: onProfileTap,
                        icon: trailing,
                        style: IconButton.styleFrom(
                          foregroundColor: AppColors.white,
                          backgroundColor:
                              AppColors.white.withValues(alpha: 0.16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text(
                    userName != null ? '$greeting,' : greeting,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.white.withValues(alpha: 0.88),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userName ?? 'How can we help you today?',
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 26,
                      height: 1.15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Doctors · Nurses · Labs · Scans · Ambulance',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.white.withValues(alpha: 0.78),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: -26,
          child: Material(
            elevation: 8,
            shadowColor: AppColors.primary.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(16),
            color: AppColors.white,
            child: InkWell(
              onTap: onSearchTap,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.grey100),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.search_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Search doctors, tests, labs...',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.grey400,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        color: AppColors.white,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TrustStatsRow extends StatelessWidget {
  const _TrustStatsRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 36, 16, 0),
      child: Row(
        children: const [
          Expanded(
            child: _TrustStatPill(
              icon: Icons.verified_rounded,
              label: 'Verified',
              sublabel: 'providers',
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: _TrustStatPill(
              icon: Icons.home_work_outlined,
              label: 'Home visit',
              sublabel: 'available',
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: _TrustStatPill(
              icon: Icons.schedule_rounded,
              label: 'Same day',
              sublabel: 'booking',
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustStatPill extends StatelessWidget {
  const _TrustStatPill({
    required this.icon,
    required this.label,
    required this.sublabel,
  });

  final IconData icon;
  final String label;
  final String sublabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.grey100),
        boxShadow: AppDecorations.softShadow(opacity: 0.04),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.labelSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  sublabel,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
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
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.12),
                AppColors.primaryLight,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primarySoft),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.event_available_rounded,
                  color: AppColors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Next appointment',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primaryDark,
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
                      booking.typeLabel,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      dateLabel,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturedLabCard extends StatelessWidget {
  const _FeaturedLabCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF165C54), Color(0xFF2BA896)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.28),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'LAB TESTS',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Book diagnostic tests',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Home sample collection · Reports in 24–48 hrs',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.white.withValues(alpha: 0.88),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Explore labs',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.biotech_rounded,
                  color: AppColors.white,
                  size: 36,
                ),
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
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 84,
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.white, width: 2),
                  boxShadow: AppDecorations.softShadow(opacity: 0.06),
                ),
                child: Icon(icon, color: AppColors.primary, size: 28),
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

class _ProviderPartnerCard extends StatelessWidget {
  const _ProviderPartnerCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.grey200),
            boxShadow: AppDecorations.softShadow(opacity: 0.05),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.offer.withValues(alpha: 0.15),
                      AppColors.offerLight,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.business_center_outlined,
                  color: AppColors.offer,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Are you a healthcare provider?',
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Join as doctor, nurse, lab, ambulance or blood bank partner.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.primary,
                size: 22,
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
    required this.label,
    required this.icon,
    required this.color,
    required this.avatarImageUrl,
    required this.route,
    this.routeParams,
  });

  final String label;
  final IconData icon;
  final Color color;
  final String avatarImageUrl;
  final String route;
  final String? routeParams;
}

class _SpecialtyItem {
  const _SpecialtyItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.searchTerm,
  });

  final IconData icon;
  final String label;
  final Color color;
  final String searchTerm;
}

const _homeServices = [
  _HomeService(
    label: 'Doctor',
    icon: Icons.medical_services_rounded,
    color: AppColors.primary,
    avatarImageUrl:
        'https://images.unsplash.com/photo-1537368910025-700350fe46c7?w=400&h=400&fit=crop',
    route: AppConstants.routeDoctorSearch,
  ),
  _HomeService(
    label: 'Nurse',
    icon: Icons.health_and_safety_rounded,
    color: Color(0xFF5E35B1),
    avatarImageUrl:
        'https://images.unsplash.com/photo-1584515933487-779824d29309?w=400&h=400&fit=crop',
    route: AppConstants.routeNurseSearch,
  ),
  _HomeService(
    label: 'Lab test',
    icon: Icons.biotech_rounded,
    color: Color(0xFF00838F),
    avatarImageUrl:
        'https://images.unsplash.com/photo-1579154204601-01588f351e67?w=400&h=400&fit=crop',
    route: AppConstants.routeLabs,
  ),
  _HomeService(
    label: 'Scan',
    icon: Icons.radar_rounded,
    color: Color(0xFF1565C0),
    avatarImageUrl:
        'https://images.unsplash.com/photo-1516549655169-df83a0774514?w=400&h=400&fit=crop',
    route: AppConstants.routeScans,
  ),
  _HomeService(
    label: 'Ambulance',
    icon: Icons.local_shipping_rounded,
    color: Color(0xFFD84315),
    avatarImageUrl:
        'https://images.unsplash.com/photo-1576091160550-2173dba999ef?w=400&h=400&fit=crop',
    route: AppConstants.routeCareListing,
    routeParams: 'role=ambulance',
  ),
  _HomeService(
    label: 'Blood bank',
    icon: Icons.bloodtype_rounded,
    color: Color(0xFFC62828),
    avatarImageUrl:
        'https://images.unsplash.com/photo-1629909613654-28e377c37b09?w=400&h=400&fit=crop',
    route: AppConstants.routeBloodBanks,
  ),
];

const _specialties = [
  _SpecialtyItem(
    icon: Icons.monitor_heart_outlined,
    label: 'Cardiology',
    color: Color(0xFFE8F6F3),
    searchTerm: 'Cardiology',
  ),
  _SpecialtyItem(
    icon: Icons.psychology_outlined,
    label: 'Mental',
    color: Color(0xFFFFF0EE),
    searchTerm: 'Psychiatry',
  ),
  _SpecialtyItem(
    icon: Icons.child_care_outlined,
    label: 'Pediatric',
    color: Color(0xFFE6F5ED),
    searchTerm: 'Pediatric',
  ),
  _SpecialtyItem(
    icon: Icons.visibility_outlined,
    label: 'Eye care',
    color: Color(0xFFE8F1FD),
    searchTerm: 'Ophthalmology',
  ),
  _SpecialtyItem(
    icon: Icons.accessibility_new_rounded,
    label: 'Ortho',
    color: Color(0xFFFFF8E1),
    searchTerm: 'Orthopedics',
  ),
  _SpecialtyItem(
    icon: Icons.pregnant_woman_outlined,
    label: 'Gynae',
    color: Color(0xFFFCE4EC),
    searchTerm: 'Gynecology',
  ),
  _SpecialtyItem(
    icon: Icons.healing_outlined,
    label: 'Dermat',
    color: Color(0xFFE8EAF6),
    searchTerm: 'Dermatology',
  ),
  _SpecialtyItem(
    icon: Icons.coronavirus_outlined,
    label: 'General',
    color: Color(0xFFE0F2F1),
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
