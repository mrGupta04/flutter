import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/consultation_type.dart';
import '../../../../shared/widgets/consultation_type_cards.dart';
import '../../../../shared/widgets/doctor_listing_card.dart';
import '../../../../shared/widgets/healthcare_ui.dart';
import '../../../../shared/widgets/home_provider_preview.dart';
import '../../../../shared/widgets/shimmer_widgets.dart';
import '../../provider/verified_doctors_provider.dart';
import '../../provider/doctor_live_status_provider.dart';
import '../../../../core/utils/doctor_location_utils.dart';
import '../../../online_consult/online_consult_navigation.dart';

/// Verified doctors with consultation type cards (Option 1).
class VerifiedDoctorsSection extends ConsumerStatefulWidget {
  const VerifiedDoctorsSection({super.key});

  @override
  ConsumerState<VerifiedDoctorsSection> createState() =>
      _VerifiedDoctorsSectionState();
}

class _VerifiedDoctorsSectionState extends ConsumerState<VerifiedDoctorsSection> {
  ConsultationType _selected = ConsultationType.onlineConsult;

  @override
  Widget build(BuildContext context) {
    final asyncDoctors = ref.watch(verifiedDoctorsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MarketplaceSectionTitle(
          title: 'Consult verified doctors',
          actionLabel: 'See all',
          onAction: () => context.push(AppConstants.routeDoctorSearch),
        ),
        const SizedBox(height: 12),
        ConsultationTypeCards(
          selected: _selected,
          onSelected: (type) => setState(() => _selected = type),
        ),
        const SizedBox(height: 8),
        asyncDoctors.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(height: 140, child: ShimmerLoadingList()),
          ),
          error: (error, stack) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Could not load doctors. Pull down to refresh.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          data: (allDoctors) {
            final filtered =
                filterDoctorsByConsultation(allDoctors, _selected);
            final doctors = filtered.isNotEmpty ? filtered : allDoctors;
            final usingFallback = filtered.isEmpty && allDoctors.isNotEmpty;
            final liveMap =
                ref.watch(doctorLiveStatusProvider(doctorIdsCacheKey(doctors))).valueOrNull ??
                    const <String, bool>{};

            if (doctors.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'No verified doctors yet. New providers appear here after admin approval.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    usingFallback
                        ? 'Showing all verified doctors'
                        : 'Showing doctors for: ${_selected.label}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  HomeProviderScrollList(
                    itemCount: doctors.length,
                    itemBuilder: (context, i) {
                      final doctor =
                          applyLiveStatus(doctors[i], liveMap);
                      return DoctorListingCard(
                        doctor: doctor,
                        selectedConsultationType: _selected,
                        showBottomDivider: false,
                        showVerifiedIcon: true,
                        showActionButtons: doctor.offersOnlineConsult ||
                            doctor.offersVisitSite ||
                            doctorHasMapLocation(doctor),
                        onTap: () => onDoctorCardTap(context, doctor),
                        onOnlineConsultTap: () =>
                            openOnlineConsultBooking(context, doctor),
                        onClinicTap: () =>
                            openHospitalVisitBooking(context, doctor),
                        onOpenMapTap: () =>
                            openDoctorInGoogleMaps(context, doctor),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
