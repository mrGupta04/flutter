import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/user_location_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/user_adaptive_scaffold.dart';
import '../../../../shared/widgets/user_app_footer.dart';
import '../../data/medical_specialities.dart';
import '../widgets/medical_specialities_section.dart';

/// Full catalog of medical specialities with organ-image logos.
class FindSpecialistsScreen extends ConsumerWidget {
  const FindSpecialistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return UserAdaptiveScaffold(
      currentTab: UserNavTab.care,
      backgroundColor: AppColors.background,
      constrainBody: true,
      appBar: AppBar(
        toolbarHeight: 72,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Find Specialists',
              style: AppTextStyles.titleMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '${medicalSpecialities.length} specialities available',
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 12,
              ),
            ),
          ],
        ),
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppColors.gradientHero,
            ),
          ),
        ),
      ),
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: MedicalSpecialitiesSection(
              showHeader: false,
              expandAll: true,
              onSpecialitySelected: (speciality) {
                final city = ref.read(userLocationProvider).city;
                final path = doctorSearchPathForSpeciality(
                  speciality.slug,
                  city: city,
                );
                context.push(path);
              },
            ),
          ),
        ],
      ),
    );
  }
}
