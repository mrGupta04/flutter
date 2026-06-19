import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/ambulance_care_filter_cards.dart';
import '../../../../shared/widgets/care_provider_listing_cards.dart';
import '../../../../shared/widgets/healthcare_ui.dart';
import '../../../../shared/widgets/home_provider_preview.dart';
import '../../../../shared/widgets/shimmer_widgets.dart';
import '../../provider/ambulance_search_provider.dart';

class VerifiedAmbulancesSection extends ConsumerStatefulWidget {
  const VerifiedAmbulancesSection({super.key});

  @override
  ConsumerState<VerifiedAmbulancesSection> createState() =>
      _VerifiedAmbulancesSectionState();
}

class _VerifiedAmbulancesSectionState
    extends ConsumerState<VerifiedAmbulancesSection> {
  AmbulanceCareFilter _selected = AmbulanceCareFilter.all;

  AmbulanceSearchParams get _params =>
      AmbulanceSearchParams(careFilter: _selected);

  @override
  Widget build(BuildContext context) {
    final asyncAmbulances = ref.watch(ambulanceSearchProvider(_params));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MarketplaceSectionTitle(
          title: 'Emergency ambulance services',
          actionLabel: 'See all',
          onAction: () => context.push(AppConstants.routeAmbulanceSearch),
        ),
        const SizedBox(height: 12),
        AmbulanceCareFilterCards(
          selected: _selected,
          onSelected: (filter) => setState(() => _selected = filter),
        ),
        const SizedBox(height: 8),
        asyncAmbulances.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(height: 140, child: ShimmerLoadingList()),
          ),
          error: (_, __) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Could not load ambulance services. Pull down to refresh.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'No verified ambulance services for ${_selected.label.toLowerCase()} yet.',
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
                    'Showing: ${_selected.label}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  HomeProviderScrollList(
                    itemCount: items.length,
                    itemBuilder: (context, i) =>
                        AmbulanceListingCard(ambulance: items[i]),
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
