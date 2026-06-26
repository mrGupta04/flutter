import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/consultation_type.dart';
import '../../../../data/models/doctor_model.dart';
import '../../../../shared/widgets/doctor_listing_card.dart';
import '../../../../shared/widgets/healthcare_ui.dart';
import '../../../../shared/widgets/home_provider_preview.dart';
import '../../../../shared/widgets/shimmer_widgets.dart';
import '../../provider/verified_doctors_provider.dart';
import '../../../../core/utils/doctor_location_utils.dart';
import '../../../online_consult/online_consult_navigation.dart';

/// Home visit doctors — dedicated marketplace section on the patient home screen.
class HomeVisitDoctorsSection extends ConsumerWidget {
  const HomeVisitDoctorsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDoctors = ref.watch(
      verifiedDoctorsByConsultationProvider(ConsultationType.bookHome),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.secondary.withValues(alpha: 0.18),
                  AppColors.secondaryLight.withValues(alpha: 0.45),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: AppDecorations.borderRadiusLg,
              border: Border.all(
                color: AppColors.secondary.withValues(alpha: 0.22),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.85),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.home_health_rounded,
                    color: AppColors.secondary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Doctors at your doorstep',
                        style: AppTextStyles.titleSmall.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Verified doctors who visit your home — book a slot and share your address.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        MarketplaceSectionTitle(
          title: 'Home visit doctors',
          actionLabel: 'See all',
          onAction: () => context.push(
            '${AppConstants.routeCareListing}?role=doctor&type=home',
          ),
        ),
        const SizedBox(height: 8),
        asyncDoctors.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(height: 140, child: ShimmerLoadingList()),
          ),
          error: (_, __) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Could not load home visit doctors.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          data: (doctors) {
            if (doctors.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'No home visit doctors listed yet. Check back after providers register for home visits.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: HomeProviderScrollList(
                itemCount: doctors.length.clamp(0, 8),
                itemBuilder: (context, i) {
                  final doctor = doctors[i];
                  return DoctorListingCard(
                    doctor: doctor,
                    showBottomDivider: false,
                    showVerifiedIcon: true,
                    showActionButtons: doctor.offersBookHome,
                    onTap: () => onDoctorCardTap(context, doctor),
                    onHomeVisitTap: () =>
                        openHomeVisitBooking(context, doctor),
                    onOpenMapTap: doctorHasMapLocation(doctor)
                        ? () => openDoctorInGoogleMaps(context, doctor)
                        : null,
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
