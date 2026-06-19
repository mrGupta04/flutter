import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/consultation_type.dart';
import '../../../../shared/widgets/consultation_type_cards.dart';
import '../../../../shared/widgets/doctor_listing_card.dart';
import '../../../../shared/widgets/healthcare_ui.dart';
import '../../../../shared/widgets/shimmer_widgets.dart';
import '../../provider/verified_doctors_provider.dart';

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
    final asyncDoctors = ref.watch(
      verifiedDoctorsByConsultationProvider(_selected),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MarketplaceSectionTitle(title: 'Consult verified doctors'),
        const SizedBox(height: 12),
        ConsultationTypeCards(
          selected: _selected,
          onSelected: (type) => setState(() => _selected = type),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Showing doctors for: ${_selected.label}',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        asyncDoctors.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(height: 140, child: ShimmerLoadingList()),
          ),
          error: (error, stack) => const SizedBox.shrink(),
          data: (doctors) {
            if (doctors.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'No doctors available for ${_selected.label} yet.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  for (var i = 0; i < doctors.length; i++) ...[
                    if (i > 0) const SizedBox(height: kDoctorCardSpacing),
                    DoctorListingCard(
                      doctor: doctors[i],
                      showBottomDivider: false,
                      showVerifiedIcon: true,
                      showActionButtons: false,
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
