import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_widgets.dart' as custom;
import '../../../../data/models/ambulance_model.dart';
import '../../../../data/models/blood_bank_model.dart';
import '../../../../data/models/doctor_model.dart';
import '../../../../data/models/nurse_model.dart';
import '../../../../shared/widgets/care_provider_listing_cards.dart';
import '../../../../shared/widgets/doctor_listing_card.dart';
import '../../../../shared/widgets/healthcare_ui.dart';
import '../../../../shared/widgets/shimmer_widgets.dart';
import '../../../../shared/widgets/user_app_footer.dart';
import '../../provider/global_search_provider.dart';
import '../../../../core/utils/doctor_location_utils.dart';
import '../../../online_consult/online_consult_navigation.dart';
import 'nurse_profile_screen.dart';

/// Search doctors, nurses, ambulances, and blood banks in one place.
class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  late final TextEditingController _controller;
  Timer? _debounce;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery?.trim() ?? '';
    _controller = TextEditingController(text: _query);
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() => _query = _controller.text.trim());
    });
  }

  void _openCategorySearch(String path) {
    final q = _query.isEmpty ? null : _query;
    final uri = q == null ? path : '$path?q=${Uri.encodeComponent(q)}';
    context.push(uri);
  }

  @override
  Widget build(BuildContext context) {
    final asyncResults = _query.isEmpty
        ? const AsyncValue<GlobalSearchResults>.data(GlobalSearchResults.empty)
        : ref.watch(globalSearchProvider(_query));

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const UserBottomNavBar(currentTab: UserNavTab.search),
      appBar: AppBar(
        title: const Text('Search care'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _controller,
              autofocus: widget.initialQuery == null,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Doctors, nurses, ambulance, blood bank, city...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _controller.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
              onSubmitted: (value) => setState(() => _query = value.trim()),
            ),
          ),
          Expanded(child: _buildBody(asyncResults)),
        ],
      ),
    );
  }

  Widget _buildBody(AsyncValue<GlobalSearchResults> asyncResults) {
    if (_query.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text(
            'Search across all verified providers',
            style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a doctor name, specialty, city, blood group, or ambulance service.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          _BrowseTile(
            icon: Icons.medical_services_rounded,
            label: 'Browse doctors',
            onTap: () => _openCategorySearch(AppConstants.routeDoctorSearch),
          ),
          const SizedBox(height: 8),
          _BrowseTile(
            icon: Icons.health_and_safety_rounded,
            label: 'Browse nurses',
            onTap: () => _openCategorySearch(AppConstants.routeNurseSearch),
          ),
          const SizedBox(height: 8),
          _BrowseTile(
            icon: Icons.local_shipping_rounded,
            label: 'Browse ambulance',
            onTap: () => _openCategorySearch(AppConstants.routeAmbulanceSearch),
          ),
          const SizedBox(height: 8),
          _BrowseTile(
            icon: Icons.bloodtype_rounded,
            label: 'Browse blood banks',
            onTap: () => _openCategorySearch(AppConstants.routeBloodBankSearch),
          ),
        ],
      );
    }

    return asyncResults.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: ShimmerLoadingList(),
      ),
      error: (error, _) => custom.AppErrorWidget(
        message: error.toString(),
        onRetry: () => ref.invalidate(globalSearchProvider(_query)),
      ),
      data: (results) {
        if (results.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.search_off_rounded,
                    size: 48,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(height: 12),
                  Text('No results for “$_query”', style: AppTextStyles.titleSmall),
                  const SizedBox(height: 8),
                  Text(
                    'Try another keyword, city, or specialty',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Text(
              '${results.totalCount} result${results.totalCount == 1 ? '' : 's'} for “$_query”',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            if (results.doctors.isNotEmpty)
              _ResultSection<DoctorModel>(
                title: 'Doctors',
                count: results.doctors.length,
                onSeeAll: () =>
                    _openCategorySearch(AppConstants.routeDoctorSearch),
                children: results.doctors
                    .take(5)
                    .map(
                      (d) => Padding(
                        padding: const EdgeInsets.only(bottom: kDoctorCardSpacing),
                        child: DoctorListingCard(
                          doctor: d,
                          showBottomDivider: false,
                          showVerifiedIcon: true,
                          showActionButtons: d.offersOnlineConsult ||
                              d.offersVisitSite ||
                              d.offersBookHome ||
                              doctorHasMapLocation(d),
                          onTap: () => onDoctorCardTap(context, d),
                          onOnlineConsultTap: () =>
                              openOnlineConsultBooking(context, d),
                          onClinicTap: () =>
                              openHospitalVisitBooking(context, d),
                          onHomeVisitTap: () =>
                              openHomeVisitBooking(context, d),
                          onOpenMapTap: () =>
                              openDoctorInGoogleMaps(context, d),
                        ),
                      ),
                    )
                    .toList(),
              ),
            if (results.nurses.isNotEmpty)
              _ResultSection<NurseModel>(
                title: 'Nurses',
                count: results.nurses.length,
                onSeeAll: () =>
                    _openCategorySearch(AppConstants.routeNurseSearch),
                children: results.nurses
                    .take(5)
                    .map(
                      (n) => Padding(
                        padding: const EdgeInsets.only(bottom: kDoctorCardSpacing),
                        child: NurseListingCard(
                          nurse: n,
                          onTap: () => openNurseProfile(context, n),
                        ),
                      ),
                    )
                    .toList(),
              ),
            if (results.ambulances.isNotEmpty)
              _ResultSection<AmbulanceModel>(
                title: 'Ambulance',
                count: results.ambulances.length,
                onSeeAll: () =>
                    _openCategorySearch(AppConstants.routeAmbulanceSearch),
                children: results.ambulances
                    .take(5)
                    .map(
                      (a) => Padding(
                        padding: const EdgeInsets.only(bottom: kDoctorCardSpacing),
                        child: AmbulanceListingCard(ambulance: a),
                      ),
                    )
                    .toList(),
              ),
            if (results.bloodBanks.isNotEmpty)
              _ResultSection<BloodBankModel>(
                title: 'Blood banks',
                count: results.bloodBanks.length,
                onSeeAll: () =>
                    _openCategorySearch(AppConstants.routeBloodBankSearch),
                children: results.bloodBanks
                    .take(5)
                    .map(
                      (b) => Padding(
                        padding: const EdgeInsets.only(bottom: kDoctorCardSpacing),
                        child: BloodBankListingCard(bloodBank: b),
                      ),
                    )
                    .toList(),
              ),
          ],
        );
      },
    );
  }
}

class _ResultSection<T> extends StatelessWidget {
  const _ResultSection({
    required this.title,
    required this.count,
    required this.onSeeAll,
    required this.children,
  });

  final String title;
  final int count;
  final VoidCallback onSeeAll;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MarketplaceSectionTitle(
            title: '$title ($count)',
            actionLabel: 'See all',
            onAction: onSeeAll,
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _BrowseTile extends StatelessWidget {
  const _BrowseTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
