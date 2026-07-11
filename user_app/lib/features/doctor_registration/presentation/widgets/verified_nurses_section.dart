import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/care_provider_listing_cards.dart';
import '../../../../shared/widgets/healthcare_ui.dart';
import '../../../../shared/widgets/home_provider_preview.dart';
import '../../../../shared/widgets/shimmer_widgets.dart';
import '../../provider/nurse_search_provider.dart';
import '../../provider/nurse_live_status_provider.dart';
import '../../../nurse_home_visit/nurse_home_visit_navigation.dart';
import '../../../../core/utils/provider_location_utils.dart';
import '../screens/nurse_profile_screen.dart';

class VerifiedNursesSection extends ConsumerWidget {
  const VerifiedNursesSection({super.key});

  static const _params = NurseSearchParams();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        asyncNurses.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(height: 220, child: ShimmerLoadingList()),
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
                  'No verified nurses for home visits yet.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              );
            }

            final liveMap = ref
                    .watch(
                      nurseLiveStatusProvider(nurseIdsCacheKey(nurses)),
                    )
                    .valueOrNull ??
                const <String, bool>{};

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: HomeProviderScrollList(
                cardHeight: kNurseListingCardHeight,
                itemCount: nurses.length,
                itemBuilder: (context, i) {
                  final nurse =
                      applyNurseLiveStatus(nurses[i], liveMap);
                  return NurseListingCard(
                    nurse: nurse,
                    showBottomDivider: false,
                    onTap: () => openNurseProfile(context, nurse),
                    onBookHomeVisit: () =>
                        openNurseHomeVisitBooking(context, nurse),
                    onOpenMapTap: nurseHasMapLocation(nurse)
                        ? () => openNurseInGoogleMaps(context, nurse)
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
