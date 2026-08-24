import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/user_location_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/doctor_model.dart';
import '../../../../shared/widgets/doctor_listing_card.dart';
import '../../../../shared/widgets/shimmer_widgets.dart';
import '../../../../shared/widgets/user_adaptive_scaffold.dart';
import '../../../../shared/widgets/user_app_footer.dart';
import '../../data/medical_specialities.dart';
import '../../provider/doctor_live_status_provider.dart';
import '../../provider/doctor_search_provider.dart';
import '../widgets/doctor_search_result_tile.dart';
import '../widgets/medical_specialities_section.dart';

/// Full catalog of medical specialities. Filters appear only after a card tap.
class FindSpecialistsScreen extends ConsumerStatefulWidget {
  const FindSpecialistsScreen({super.key});

  @override
  ConsumerState<FindSpecialistsScreen> createState() =>
      _FindSpecialistsScreenState();
}

class _FindSpecialistsScreenState extends ConsumerState<FindSpecialistsScreen> {
  String _query = '';

  bool get _searching => _query.trim().isNotEmpty;

  void _openSpeciality(MedicalSpeciality speciality) {
    final city = ref.read(userLocationProvider).city;
    final path = doctorSearchPathForSpeciality(
      speciality.slug,
      city: city,
    );
    context.push(path);
  }

  @override
  Widget build(BuildContext context) {
    final specialties = filterMedicalSpecialities(_query);
    final doctorsAsync = _searching
        ? ref.watch(
            doctorSearchProvider(
              DoctorSearchParams(query: _query.trim()),
            ),
          )
        : null;

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
              showEmptyState: !_searching,
              searchHint: 'Search doctor name or speciality...',
              onQueryChanged: (value) => setState(() => _query = value),
              onSpecialitySelected: _openSpeciality,
            ),
          ),
          if (_searching) ..._doctorResultSlivers(doctorsAsync, specialties),
        ],
      ),
    );
  }

  List<Widget> _doctorResultSlivers(
    AsyncValue<List<DoctorModel>>? doctorsAsync,
    List<MedicalSpeciality> specialties,
  ) {
    if (doctorsAsync == null) return const [];

    return doctorsAsync.when(
      loading: () => const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: ShimmerLoadingList(),
          ),
        ),
      ],
      error: (error, _) => [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Text(
              'Could not search doctors. Try again.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ],
      data: (doctors) {
        if (doctors.isEmpty && specialties.isEmpty) {
          return [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                child: Text(
                  'No speciality or doctor matches "$_query".',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ];
        }
        if (doctors.isEmpty) return const [];

        final liveMap = ref
                .watch(doctorLiveStatusProvider(doctorIdsCacheKey(doctors)))
                .valueOrNull ??
            const <String, bool>{};

        return [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: Text(
                'Doctors matching "$_query"',
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList.separated(
              itemCount: doctors.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: kDoctorCardSpacing),
              itemBuilder: (context, index) {
                final doctor = applyLiveStatus(doctors[index], liveMap);
                return DoctorSearchResultTile(
                  doctor: doctor,
                  showBottomDivider: false,
                );
              },
            ),
          ),
        ];
      },
    );
  }
}
