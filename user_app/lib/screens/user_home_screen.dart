import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../shared/widgets/healthcare_ui.dart';
import '../shared/widgets/hero_wallpaper_carousel.dart';
import '../shared/widgets/user_app_footer.dart';
import '../features/doctor_registration/presentation/widgets/verified_ambulances_section.dart';
import '../features/doctor_registration/presentation/widgets/verified_blood_banks_section.dart';
import '../features/doctor_registration/presentation/widgets/verified_doctors_section.dart';
import '../features/doctor_registration/presentation/widgets/verified_nurses_section.dart';
import '../features/doctor_registration/provider/ambulance_search_provider.dart';
import '../features/doctor_registration/provider/blood_bank_search_provider.dart';
import '../features/doctor_registration/provider/doctor_search_provider.dart';
import '../features/doctor_registration/provider/nurse_search_provider.dart';
import '../core/services/token_storage.dart';
import '../features/doctor_registration/provider/verified_doctors_provider.dart';
import '../features/user_auth/presentation/widgets/patient_header_avatar.dart';
import '../features/user_auth/provider/patient_auth_provider.dart';

/// Patient marketplace home — verified providers only, no registration flows.
class UserHomeScreen extends ConsumerWidget {
  const UserHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(patientAuthProvider);
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const UserBottomNavBar(currentTab: UserNavTab.home),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(verifiedDoctorsProvider);
          ref.invalidate(nurseSearchProvider);
          ref.invalidate(ambulanceSearchProvider);
          ref.invalidate(bloodBankSearchProvider);
          await Future.wait([
            ref.read(verifiedDoctorsProvider.future),
            ref.read(
              nurseSearchProvider(const NurseSearchParams()).future,
            ),
            ref.read(
              ambulanceSearchProvider(const AmbulanceSearchParams()).future,
            ),
            ref.read(
              bloodBankSearchProvider(const BloodBankSearchParams()).future,
            ),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            OneMgHeader(
              locationLabel: 'Find care',
              locationValue: 'Book verified doctors, nurses & more',
              searchHint: 'Search specialties, cities...',
              onSearchTap: () => context.push(AppConstants.routeGlobalSearch),
              trailing: user != null
                  ? PatientHeaderAvatar(user: user)
                  : const Icon(Icons.person_outline_rounded, size: 20),
              onTrailingTap: () => _onProfileTap(context, ref),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: HeroWallpaperCarousel(),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: OfferPromoCard(
                title: 'Trusted healthcare at your doorstep',
                subtitle: 'All providers are admin-verified before listing',
                badge: 'VERIFIED',
                includeMargin: false,
                compact: true,
              ),
            ),
            const SizedBox(height: 16),
            const MarketplaceSectionTitle(title: 'Find care by role'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Row(
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
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _RoleEntryCard(
                          label: 'Ambulance',
                          icon: Icons.local_shipping_rounded,
                          backgroundImageUrl:
                              'https://images.unsplash.com/photo-1576091160550-2173dba999ef?w=900&h=600&fit=crop',
                          onTap: () => context.push(
                            '${AppConstants.routeCareListing}?role=ambulance',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _RoleEntryCard(
                          label: 'Blood bank',
                          icon: Icons.bloodtype_rounded,
                          backgroundImageUrl:
                              'https://images.unsplash.com/photo-1629909613654-28e377c37b09?w=900&h=600&fit=crop',
                          onTap: () => context.push(
                            '${AppConstants.routeCareListing}?role=blood-bank',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const VerifiedDoctorsSection(),
            const SizedBox(height: 20),
            const VerifiedNursesSection(),
            const SizedBox(height: 20),
            const VerifiedAmbulancesSection(),
            const SizedBox(height: 20),
            const VerifiedBloodBanksSection(),
            const SizedBox(height: 20),
            const MarketplaceSectionTitle(title: 'Browse by specialty'),
            OneMgCategoryGrid(
              onCategoryTap: (label, _) => _openDoctorSearch(
                context,
                specialization: categorySpecializationMap[label] ?? label,
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Material(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => context.push(AppConstants.routeProviderLanding),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      children: [
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
                              const SizedBox(height: 6),
                              Text(
                                'Register as ambulance or blood bank partner. '
                                'Nurses register via the partner app.',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const UserScrollFooter(),
            ],
          ),
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

class _RoleEntryCard extends StatelessWidget {
  const _RoleEntryCard({
    required this.label,
    required this.icon,
    required this.onTap,
    this.backgroundImageUrl,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
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
            height: 130,
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
                  Text(
                    'Tap to explore',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: backgroundImageUrl != null
                          ? AppColors.white.withValues(alpha: 0.92)
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
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

Future<void> _onProfileTap(BuildContext context, WidgetRef ref) async {
  final loggedIn = await TokenStorage.instance.isPatientLoggedIn();
  if (!context.mounted) return;

  if (loggedIn) {
    context.push(AppConstants.routeUserDashboard);
  } else {
    context.push(AppConstants.routeUserLogin);
  }
}

