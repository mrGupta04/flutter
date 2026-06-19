import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../shared/widgets/healthcare_ui.dart';
import '../../provider/doctor_search_provider.dart';
import '../widgets/verified_doctors_section.dart';

/// Landing screen — Tata 1mg partner onboarding layout.
class RegistrationLandingScreen extends ConsumerWidget {
  const RegistrationLandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OneMgHeader(
              locationLabel: 'Partner program',
              locationValue: 'Register your practice on 1mg',
              searchHint: 'Search specialties, cities...',
              onSearchTap: () => _openDoctorSearch(context),
              trailing: const Icon(Icons.person_outline_rounded, size: 20),
              onTrailingTap: () =>
                  context.push(AppConstants.routeDoctorDashboard),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                  const SizedBox(height: 16),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: _HeroWallpaperCarousel(),
                  ),
                  const SizedBox(height: 16),
                  const OfferPromoCard(
                    title: 'Join 1mg Doctor Network',
                    subtitle: 'Get verified in 48 hours · reach millions',
                    badge: 'NEW',
                  ),
                  const SizedBox(height: 16),
                  OneMgQuickActions(
                    onDoctorRegistration: () =>
                        context.push(AppConstants.routeRegistrationForm),
                    onNurseRegistration: () =>
                        context.push(AppConstants.routeNurseRegistration),
                    onRegisterPractice: () =>
                        context.push(AppConstants.routeRegistrationForm),
                  ),
                  const SizedBox(height: 20),
                  const OneMgTrustStrip(),
                  const SizedBox(height: 20),
                  const MarketplaceSectionTitle(title: 'Find care by role'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _RoleEntryCard(
                            label: 'Doctor',
                            icon: Icons.medical_services_rounded,
                            backgroundImageUrl:
                                'https://images.unsplash.com/photo-1537368910025-700350fe46c7?w=900&h=600&fit=crop',
                            onTap: () => context.push(
                              '${AppConstants.routeCareListing}?role=doctor',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _RoleEntryCard(
                            label: 'Nurse',
                            icon: Icons.health_and_safety_rounded,
                            backgroundImageUrl:
                                'https://images.unsplash.com/photo-1584515933487-779824d29309?w=900&h=600&fit=crop',
                            onTap: () => context.push(
                              '${AppConstants.routeCareListing}?role=nurse',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const VerifiedDoctorsSection(),
                  const SizedBox(height: 20),
                  const MarketplaceSectionTitle(title: 'Browse by specialty'),
                  OneMgCategoryGrid(
                    onCategoryTap: (label, _) => _openDoctorSearch(
                      context,
                      specialization:
                          categorySpecializationMap[label] ?? label,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const MarketplaceSectionTitle(title: 'Practice insights'),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: _HomeInsightsSection(),
                  ),
                  const SizedBox(height: 20),
                  const MarketplaceSectionTitle(title: 'User feedback'),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: _UserFeedbackSection(),
                  ),
                  const SizedBox(height: 20),
                  const MarketplaceSectionTitle(title: 'How it works'),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: _HowItWorksSection(),
                  ),
                  const SizedBox(height: 20),
                  const MarketplaceSectionTitle(title: 'Why join 1mg?'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        ServiceBenefitCard(
                          icon: Icons.verified_rounded,
                          title: '1mg verified badge',
                          subtitle: 'Build trust like genuine medicine seal',
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 8),
                        ServiceBenefitCard(
                          icon: Icons.people_rounded,
                          title: '2M+ patients',
                          subtitle: 'Get discovered by city & specialization',
                          color: AppColors.secondary,
                        ),
                        const SizedBox(height: 8),
                        ServiceBenefitCard(
                          icon: Icons.payments_rounded,
                          title: 'Set consultation fee',
                          subtitle: 'Transparent pricing · easy payouts',
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                  BottomCtaBar(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.only(top: 4, bottom: 2),
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(color: AppColors.divider),
                            ),
                          ),
                          child: Center(
                            child: TextButton.icon(
                              onPressed: () =>
                                  context.push(AppConstants.routeAdminLogin),
                              icon: const Icon(
                                Icons.admin_panel_settings_outlined,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              label: Text(
                                'Admin portal — sign in',
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'By continuing you agree to 1mg partner terms',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _openDoctorSearch(
    BuildContext context, {
    String? query,
    String? city,
    String? specialization,
  }) {
    final params = <String, String>{};
    if (query != null && query.isNotEmpty) params['q'] = query;
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

class _RoleEntryCard extends StatelessWidget {
  const _RoleEntryCard({
    required this.label,
    required this.icon,
    required this.onTap,
    this.minHeight,
    this.backgroundImageUrl,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final double? minHeight;
  final String? backgroundImageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Material(
        color: AppColors.white,
        child: InkWell(
          onTap: onTap,
          child: Ink(
            height: minHeight ?? 130,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
              image: backgroundImageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(backgroundImageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: backgroundImageUrl != null
                      ? [
                          Colors.black.withValues(alpha: 0.20),
                          Colors.black.withValues(alpha: 0.62),
                        ]
                      : [Colors.transparent, Colors.transparent],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    icon,
                    size: 26,
                    color: backgroundImageUrl != null
                        ? AppColors.white
                        : AppColors.primary,
                  ),
                  const Spacer(),
                  Text(
                    label,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: backgroundImageUrl != null
                          ? AppColors.white
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        'Tap to explore',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: backgroundImageUrl != null
                              ? AppColors.white.withValues(alpha: 0.92)
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 15,
                        color: backgroundImageUrl != null
                            ? AppColors.white
                            : AppColors.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroWallpaperCarousel extends StatefulWidget {
  const _HeroWallpaperCarousel();

  @override
  State<_HeroWallpaperCarousel> createState() => _HeroWallpaperCarouselState();
}

class _HeroWallpaperCarouselState extends State<_HeroWallpaperCarousel> {
  static const _slides = [
    _HeroSlide(
      imageUrl:
          'https://images.unsplash.com/photo-1666214280391-8ff5bd3c0bf0?w=1400&h=700&fit=crop',
      title: 'Book trusted doctors instantly',
      subtitle: 'Online, home visit, or clinic consultations',
    ),
    _HeroSlide(
      imageUrl:
          'https://images.unsplash.com/photo-1584432810601-6c7f27d2362b?w=1400&h=700&fit=crop',
      title: 'Care at your convenience',
      subtitle: 'Choose your slot and get care on your schedule',
    ),
    _HeroSlide(
      imageUrl:
          'https://images.unsplash.com/photo-1576091160550-2173dba999ef?w=1400&h=700&fit=crop',
      title: 'Verified providers, better outcomes',
      subtitle: 'Explore specialists by role, city, and service type',
    ),
    _HeroSlide(
      imageUrl:
          'https://images.unsplash.com/photo-1584982751601-97dcc096659c?w=1400&h=700&fit=crop',
      title: 'Experienced nurses at your doorstep',
      subtitle: 'Home care services with reliable support',
    ),
    _HeroSlide(
      imageUrl:
          'https://images.unsplash.com/photo-1579154204601-01588f351e67?w=1400&h=700&fit=crop',
      title: 'Multi-specialty healthcare network',
      subtitle: 'Discover providers across top departments',
    ),
    _HeroSlide(
      imageUrl:
          'https://images.unsplash.com/photo-1516549655169-df83a0774514?w=1400&h=700&fit=crop',
      title: 'Quick response and easy booking',
      subtitle: 'Get faster confirmations for your care needs',
    ),
  ];

  late final PageController _controller;
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      if (!_controller.hasClients) return;
      final currentPage = _controller.page?.round() ?? _index;
      final next = currentPage >= _slides.length - 1 ? 0 : currentPage + 1;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 8.6,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: _slides.length,
              onPageChanged: (value) => setState(() => _index = value),
              itemBuilder: (_, i) {
                final slide = _slides[i];
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      slide.imageUrl,
                      fit: BoxFit.cover,
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.68),
                            Colors.black.withValues(alpha: 0.20),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Spacer(),
                          Text(
                            slide.title,
                            style: AppTextStyles.titleMedium.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            slide.subtitle,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.white.withValues(alpha: 0.92),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _index == i ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _index == i
                          ? AppColors.white
                          : AppColors.white.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroSlide {
  const _HeroSlide({
    required this.imageUrl,
    required this.title,
    required this.subtitle,
  });

  final String imageUrl;
  final String title;
  final String subtitle;
}

class _HomeInsightsSection extends StatelessWidget {
  const _HomeInsightsSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: const Row(
        children: [
          Expanded(
            child: _HomeInsightTile(
              icon: Icons.people_alt_outlined,
              value: '2M+',
              label: 'Patient reach',
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: _HomeInsightTile(
              icon: Icons.verified_user_outlined,
              value: '48h',
              label: 'Verification',
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: _HomeInsightTile(
              icon: Icons.assured_workload_outlined,
              value: '100%',
              label: 'Secure payout',
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeInsightTile extends StatelessWidget {
  const _HomeInsightTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.labelLarge.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _UserFeedbackSection extends StatelessWidget {
  const _UserFeedbackSection();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: const [
          SizedBox(
            width: 280,
            child: _FeedbackCard(
              name: 'Rahul S.',
              rating: 5,
              comment:
                  'Booking was very smooth and doctor consultation started on time.',
            ),
          ),
          SizedBox(width: 10),
          SizedBox(
            width: 280,
            child: _FeedbackCard(
              name: 'Priya K.',
              rating: 4,
              comment:
                  'Nurse visit was professional and helpful. Would recommend.',
            ),
          ),
          SizedBox(width: 10),
          SizedBox(
            width: 280,
            child: _FeedbackCard(
              name: 'Aman V.',
              rating: 5,
              comment:
                  'Great experience. Easy to find providers by role and service.',
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({
    required this.name,
    required this.rating,
    required this.comment,
  });

  final String name;
  final int rating;
  final String comment;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  name.substring(0, 1),
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < rating ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 16,
                    color: AppColors.offer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            comment,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection();

  static const _steps = [
    (
      icon: Icons.search_rounded,
      title: 'Tell us what you need',
      subtitle:
          'Browse by specialty, language, or visit type — online, home, or clinic.',
    ),
    (
      icon: Icons.schedule_rounded,
      title: 'Pick a time that fits',
      subtitle:
          'Live availability for today, tomorrow, or next week. Lock it in.',
    ),
    (
      icon: Icons.video_call_rounded,
      title: 'Meet your provider',
      subtitle: 'Get seen at home, in clinic, or face-to-face on video.',
    ),
  ];

  static const _metrics = [
    ('12k+', 'Visits booked'),
    ('4.9★', 'Avg. provider rating'),
    ('27 min', 'Avg. response time'),
    ('98%', 'Would book again'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: AppDecorations.softShadow(opacity: 0.04),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...List.generate(_steps.length, (i) {
              final step = _steps[i];
              return Padding(
                padding: EdgeInsets.only(bottom: i == _steps.length - 1 ? 0 : 10),
                child: _HowRowCard(
                  number: '0${i + 1}',
                  icon: step.icon,
                  title: step.title,
                  subtitle: step.subtitle,
                ),
              );
            }),
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _metrics.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 2.1,
              ),
              itemBuilder: (_, i) {
                final metric = _metrics[i];
                return _HowStatTile(value: metric.$1, label: metric.$2);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HowRowCard extends StatelessWidget {
  const _HowRowCard({
    required this.number,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final String number;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: AppColors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$number  $title',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.3,
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

class _HowStatTile extends StatelessWidget {
  const _HowStatTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

