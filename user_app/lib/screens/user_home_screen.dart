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
import '../features/doctor_registration/presentation/widgets/verified_nurses_section.dart';
import '../features/doctor_registration/provider/nurse_search_provider.dart';
import '../shared/widgets/healthcare_ui.dart';
import '../shared/widgets/hero_wallpaper_carousel.dart';
import '../shared/widgets/user_app_footer.dart';

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

  List<OneMgServiceItem> _buildServiceItems(BuildContext context) {
    return _homeServices
        .map(
          (service) => OneMgServiceItem(
            title: service.title,
            description: service.description ?? '',
            imageUrl: service.imageUrl ?? '',
            color: service.color ?? AppColors.primary,
            style: service.style,
            icon: service.icon,
            footerLeft: service.footerLeft,
            footerRight: service.footerRight,
            footerFeatures: service.footerFeatures,
            footerAccentTint: service.footerAccentTint,
            assetImage: service.assetImage,
            assetAspectRatio: service.assetAspectRatio,
            onTap: () => _openService(context, service),
          ),
        )
        .toList();
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
          ref.invalidate(nurseSearchProvider);
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
              child: OneMgServiceGrid(items: _buildServiceItems(context)),
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
            const SliverToBoxAdapter(child: VerifiedNursesSection()),
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

class _FeaturedLabCard extends StatelessWidget {
  const _FeaturedLabCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF165C54), Color(0xFF2BA896)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.22),
                blurRadius: 12,
                offset: const Offset(0, 6),
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
                        vertical: 3,
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
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Book diagnostic tests',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Home collection · Reports in 24–48 hrs',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.biotech_rounded,
                  color: AppColors.white,
                  size: 30,
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
          width: 76,
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primary, size: 26),
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
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.grey200),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.offerLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.business_center_outlined,
                  color: AppColors.offer,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
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
                    const SizedBox(height: 2),
                    Text(
                      'Join as doctor, nurse, lab or ambulance partner.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
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
    required this.title,
    required this.route,
    this.routeParams,
    this.style = OneMgServiceCardStyle.asset,
    this.assetImage,
    this.assetAspectRatio,
    this.description,
    this.imageUrl,
    this.color,
    this.icon,
    this.footerLeft,
    this.footerRight,
    this.footerFeatures,
    this.footerAccentTint = false,
  });

  final String title;
  final String route;
  final String? routeParams;
  final OneMgServiceCardStyle style;
  final String? assetImage;
  final double? assetAspectRatio;
  final String? description;
  final String? imageUrl;
  final Color? color;
  final IconData? icon;
  final OneMgServiceFooterFeature? footerLeft;
  final OneMgServiceFooterFeature? footerRight;
  final List<OneMgServiceFooterFeature>? footerFeatures;
  final bool footerAccentTint;
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
    title: 'Doctor Consultation',
    route: AppConstants.routeDoctorSearch,
    assetImage: 'assets/images/home_cards/doctor_consultation.png',
    assetAspectRatio: 948 / 1024,
  ),
  _HomeService(
    title: 'Lab Tests',
    route: AppConstants.routeLabs,
    assetImage: 'assets/images/home_cards/lab_tests.png',
    assetAspectRatio: 1024 / 997,
  ),
  _HomeService(
    title: 'Nurse Home Care',
    route: AppConstants.routeNurseSearch,
    assetImage: 'assets/images/home_cards/nurse_home_care.png',
    assetAspectRatio: 1,
  ),
  _HomeService(
    title: 'Diagnostic Scans',
    route: AppConstants.routeScans,
    assetImage: 'assets/images/home_cards/diagnostic_scans.png',
    assetAspectRatio: 1,
  ),
  _HomeService(
    title: 'Ambulance Booking',
    description: 'Book 24/7 ambulance for emergencies & patient transfers.',
    imageUrl:
        'https://images.unsplash.com/photo-1601580110406-4eac4d6b56c6?w=500&h=650&fit=crop',
    color: Color(0xFFD84315),
    route: AppConstants.routeCareListing,
    routeParams: 'role=ambulance',
    style: OneMgServiceCardStyle.premium,
    icon: Icons.local_shipping_rounded,
    footerLeft: OneMgServiceFooterFeature(
      title: '24/7 Service',
      subtitle: 'Always available',
      icon: Icons.access_time_filled_rounded,
    ),
    footerRight: OneMgServiceFooterFeature(
      title: 'Fast Dispatch',
      subtitle: 'Nearest ambulance',
      icon: Icons.near_me_rounded,
      iconColor: Color(0xFF1565C0),
    ),
  ),
  _HomeService(
    title: 'Blood Bank',
    description: 'Find verified blood banks & request units when you need.',
    imageUrl:
        'https://images.unsplash.com/photo-1629909613654-28e377c37b0a?w=500&h=650&fit=crop',
    color: Color(0xFFC62828),
    route: AppConstants.routeBloodBanks,
    style: OneMgServiceCardStyle.premium,
    icon: Icons.bloodtype_rounded,
    footerLeft: OneMgServiceFooterFeature(
      title: 'Verified Banks',
      subtitle: 'Safe & reliable',
      icon: Icons.verified_user_rounded,
    ),
    footerRight: OneMgServiceFooterFeature(
      title: 'Emergency Units',
      subtitle: 'Quick requests',
      icon: Icons.emergency_rounded,
      iconColor: Color(0xFFD84315),
    ),
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
