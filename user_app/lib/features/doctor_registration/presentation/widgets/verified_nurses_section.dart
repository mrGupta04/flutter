import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/care_provider_listing_cards.dart';
import '../../../../shared/widgets/healthcare_ui.dart';
import '../../../../shared/widgets/nurse_care_filter_cards.dart';
import '../../../../shared/widgets/home_provider_preview.dart';
import '../../../../shared/widgets/shimmer_widgets.dart';
import '../../provider/nurse_search_provider.dart';
import '../screens/nurse_profile_screen.dart';

class VerifiedNursesSection extends ConsumerStatefulWidget {
  const VerifiedNursesSection({super.key});

  @override
  ConsumerState<VerifiedNursesSection> createState() =>
      _VerifiedNursesSectionState();
}

class _VerifiedNursesSectionState extends ConsumerState<VerifiedNursesSection> {
  NurseCareFilter _selected = NurseCareFilter.all;

  NurseSearchParams get _params => NurseSearchParams(careFilter: _selected);

  @override
  Widget build(BuildContext context) {
    final asyncNurses = ref.watch(nurseSearchProvider(_params));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MarketplaceSectionTitle(
          title: 'Book verified nurses',
          actionLabel: 'See all',
          onAction: () => context.push(AppConstants.routeNurseSearch),
        ),
        const SizedBox(height: 12),
        NurseCareFilterCards(
          selected: _selected,
          onSelected: (filter) => setState(() => _selected = filter),
        ),
        const SizedBox(height: 8),
        asyncNurses.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(height: 140, child: ShimmerLoadingList()),
          ),
          error: (_, __) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Could not load nurses. Pull down to refresh.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          data: (nurses) {
            if (nurses.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'No verified nurses for ${_selected.label.toLowerCase()} yet.',
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
                    itemCount: nurses.length,
                    itemBuilder: (context, i) => NurseListingCard(
                      nurse: nurses[i],
                      onTap: () => openNurseProfile(context, nurses[i]),
                    ),
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
