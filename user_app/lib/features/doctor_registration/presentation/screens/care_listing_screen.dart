import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/interactive_styles.dart';
import '../../../../data/models/ambulance_model.dart';
import '../../../../data/models/blood_bank_model.dart';
import '../../../../data/models/consultation_type.dart';
import '../../../../data/models/doctor_model.dart';
import '../../../../data/models/nurse_model.dart';
import '../../../../shared/widgets/ambulance_care_filter_cards.dart';
import '../../../../shared/widgets/blood_bank_care_filter_cards.dart';
import '../../../../shared/widgets/care_provider_listing_cards.dart';
import '../../../../shared/widgets/consultation_type_cards.dart';
import '../../../../shared/widgets/doctor_listing_card.dart';
import '../../../../shared/widgets/healthcare_ui.dart';
import '../../../../shared/widgets/horizontal_filter_chips.dart';
import 'nurse_profile_screen.dart';
import '../../../../shared/widgets/shimmer_widgets.dart';
import '../../../../shared/widgets/user_app_footer.dart';
import '../../provider/ambulance_search_provider.dart';
import '../../provider/blood_bank_search_provider.dart';
import '../../provider/care_filter_constants.dart';
import '../../provider/nurse_search_provider.dart';
import '../../provider/verified_doctors_provider.dart';
import '../../../../core/utils/doctor_location_utils.dart';
import '../../../../core/utils/provider_location_utils.dart';
import '../../../nurse_home_visit/nurse_home_visit_navigation.dart';
import '../../../online_consult/online_consult_navigation.dart';

enum CareRole { doctor, nurse, ambulance, bloodBank }

CareRole careRoleFromValue(String? value) {
  switch (value) {
    case 'nurse':
      return CareRole.nurse;
    case 'ambulance':
      return CareRole.ambulance;
    case 'blood-bank':
    case 'bloodbank':
    case 'blood_bank':
      return CareRole.bloodBank;
    case 'doctor':
    default:
      return CareRole.doctor;
  }
}

class CareListingScreen extends ConsumerStatefulWidget {
  const CareListingScreen({
    super.key,
    required this.initialRole,
    this.initialDoctorType,
  });

  final CareRole initialRole;
  final ConsultationType? initialDoctorType;

  @override
  ConsumerState<CareListingScreen> createState() => _CareListingScreenState();
}

class _CareListingScreenState extends ConsumerState<CareListingScreen> {
  late CareRole _selectedRole;
  ConsultationType _doctorType = ConsultationType.onlineConsult;
  String? _nurseCity;
  String? _nurseSpecialization;
  String? _nurseGender;
  AmbulanceCareFilter _ambulanceFilter = AmbulanceCareFilter.all;
  String? _ambulanceCity;
  String? _ambulanceVehicleType;
  BloodBankCareFilter _bloodBankFilter = BloodBankCareFilter.all;
  String? _bloodBankCity;
  String? _bloodBankGroup;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole;
    if (widget.initialDoctorType != null) {
      _doctorType = widget.initialDoctorType!;
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_selectedRole) {
      case CareRole.nurse:
        return _buildNurseScaffold(context);
      case CareRole.ambulance:
        return _buildAmbulanceScaffold(context);
      case CareRole.bloodBank:
        return _buildBloodBankScaffold(context);
      case CareRole.doctor:
        return _buildDoctorScaffold(context);
    }
  }

  Widget _buildDoctorScaffold(BuildContext context) {
    final asyncDoctors =
        ref.watch(verifiedDoctorsByConsultationProvider(_doctorType));

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const UserBottomNavBar(currentTab: UserNavTab.care),
      appBar: AppBar(
        title: const Text('Care providers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.push(AppConstants.routeDoctorSearch),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(
            verifiedDoctorsByConsultationProvider(_doctorType),
          );
          await ref.read(
            verifiedDoctorsByConsultationProvider(_doctorType).future,
          );
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _buildRoleHeader(showConsultationTypes: true),
              ),
            ),
            ..._doctorResultSlivers(asyncDoctors),
          ],
        ),
      ),
    );
  }

  Widget _buildNurseScaffold(BuildContext context) {
    final params = NurseSearchParams(
      city: _nurseCity,
      specialization: _nurseSpecialization,
      gender: _nurseGender,
    );
    final asyncNurses = ref.watch(nurseSearchProvider(params));

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const UserBottomNavBar(currentTab: UserNavTab.care),
      appBar: AppBar(
        title: const Text('Verified nurses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.push(AppConstants.routeNurseSearch),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(nurseSearchProvider(params));
          await ref.read(nurseSearchProvider(params).future);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ..._buildRoleHeader(),
                  const SizedBox(height: 8),
                  HorizontalFilterChips(
                    labels: popularCareCities,
                    selected: _nurseCity,
                    onSelected: (c) => setState(() => _nurseCity = c),
                  ),
                  const SizedBox(height: 8),
                  HorizontalFilterChips(
                    labels: nurseSpecializationFilters,
                    selected: _nurseSpecialization,
                    onSelected: (s) => setState(() => _nurseSpecialization = s),
                  ),
                  const SizedBox(height: 8),
                  HorizontalFilterChips(
                    labels: nurseGenderFilters,
                    selected: _nurseGender,
                    onSelected: (g) => setState(() {
                      _nurseGender = _nurseGender == g ? null : g;
                    }),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            ..._nurseResultSlivers(asyncNurses),
          ],
        ),
      ),
    );
  }

  Widget _buildAmbulanceScaffold(BuildContext context) {
    final params = AmbulanceSearchParams(
      city: _ambulanceCity,
      vehicleType: _ambulanceVehicleType,
      careFilter: _ambulanceFilter,
    );
    final asyncAmbulances = ref.watch(ambulanceSearchProvider(params));

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const UserBottomNavBar(currentTab: UserNavTab.care),
      appBar: AppBar(
        title: const Text('Ambulance services'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.push(AppConstants.routeAmbulanceSearch),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(ambulanceSearchProvider(params));
          await ref.read(ambulanceSearchProvider(params).future);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ..._buildRoleHeader(),
                  AmbulanceCareFilterCards(
                    selected: _ambulanceFilter,
                    onSelected: (f) => setState(() => _ambulanceFilter = f),
                  ),
                  const SizedBox(height: 8),
                  HorizontalFilterChips(
                    labels: popularCareCities,
                    selected: _ambulanceCity,
                    onSelected: (c) => setState(() => _ambulanceCity = c),
                  ),
                  const SizedBox(height: 8),
                  HorizontalFilterChips(
                    labels: ambulanceVehicleTypeFilters,
                    selected: _ambulanceVehicleType,
                    onSelected: (t) => setState(() => _ambulanceVehicleType = t),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            ..._ambulanceResultSlivers(asyncAmbulances),
          ],
        ),
      ),
    );
  }

  Widget _buildBloodBankScaffold(BuildContext context) {
    final params = BloodBankSearchParams(
      city: _bloodBankCity,
      bloodGroup: _bloodBankGroup,
      careFilter: _bloodBankFilter,
    );
    final asyncBloodBanks = ref.watch(bloodBankSearchProvider(params));

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const UserBottomNavBar(currentTab: UserNavTab.care),
      appBar: AppBar(
        title: const Text('Blood banks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.push(AppConstants.routeBloodBankSearch),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(bloodBankSearchProvider(params));
          await ref.read(bloodBankSearchProvider(params).future);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ..._buildRoleHeader(),
                  BloodBankCareFilterCards(
                    selected: _bloodBankFilter,
                    onSelected: (f) => setState(() => _bloodBankFilter = f),
                  ),
                  const SizedBox(height: 8),
                  HorizontalFilterChips(
                    labels: popularCareCities,
                    selected: _bloodBankCity,
                    onSelected: (c) => setState(() => _bloodBankCity = c),
                  ),
                  const SizedBox(height: 8),
                  HorizontalFilterChips(
                    labels: bloodGroupFilters,
                    selected: _bloodBankGroup,
                    onSelected: (g) => setState(() => _bloodBankGroup = g),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            ..._bloodBankResultSlivers(asyncBloodBanks),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRoleHeader({bool showConsultationTypes = false}) {
    return [
      const SizedBox(height: 12),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _RoleChip(
              label: 'Doctor',
              icon: Icons.medical_services_rounded,
              selected: _selectedRole == CareRole.doctor,
              onTap: () => setState(() => _selectedRole = CareRole.doctor),
            ),
            _RoleChip(
              label: 'Nurse',
              icon: Icons.health_and_safety_rounded,
              selected: _selectedRole == CareRole.nurse,
              onTap: () => setState(() => _selectedRole = CareRole.nurse),
            ),
            _RoleChip(
              label: 'Ambulance',
              icon: Icons.local_shipping_rounded,
              selected: _selectedRole == CareRole.ambulance,
              onTap: () => setState(() => _selectedRole = CareRole.ambulance),
            ),
            _RoleChip(
              label: 'Blood bank',
              icon: Icons.bloodtype_rounded,
              selected: _selectedRole == CareRole.bloodBank,
              onTap: () => setState(() => _selectedRole = CareRole.bloodBank),
            ),
          ],
        ),
      ),
      if (showConsultationTypes) ...[
        const SizedBox(height: 14),
        ConsultationTypeCards(
          selected: _doctorType,
          onSelected: (type) => setState(() => _doctorType = type),
        ),
      ] else ...[
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Admin verified providers only',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
      const SizedBox(height: 10),
    ];
  }

  List<Widget> _doctorResultSlivers(
    AsyncValue<List<DoctorModel>> asyncDoctors,
  ) {
    return asyncDoctors.when(
      loading: () => const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: ShimmerLoadingList(),
          ),
        ),
      ],
      error: (error, _) => [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(error.toString(), textAlign: TextAlign.center),
          ),
        ),
      ],
      data: _doctorListSlivers,
    );
  }

  List<Widget> _doctorListSlivers(List<DoctorModel> items) {
    if (items.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'No verified doctors offer ${_doctorType.label.toLowerCase()} yet.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            const MarketplaceSectionTitle(title: 'Consult verified doctors'),
            const SizedBox(height: 8),
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(height: kDoctorCardSpacing),
              DoctorListingCard(
                doctor: items[i],
                showBottomDivider: false,
                showVerifiedIcon: true,
                consultationFilter: _doctorType,
                showActionButtons: items[i].offersOnlineConsult ||
                    items[i].offersVisitSite ||
                    items[i].offersBookHome ||
                    doctorHasMapLocation(items[i]),
                onTap: () => onDoctorCardTap(context, items[i]),
                onOnlineConsultTap: () =>
                    openOnlineConsultBooking(context, items[i]),
                onClinicTap: () => openHospitalVisitBooking(context, items[i]),
                onHomeVisitTap: () => openHomeVisitBooking(context, items[i]),
                onOpenMapTap: () => openDoctorInGoogleMaps(context, items[i]),
              ),
            ],
            const UserScrollFooter(),
          ]),
        ),
      ),
    ];
  }

  List<Widget> _nurseResultSlivers(AsyncValue<List<NurseModel>> asyncNurses) {
    return asyncNurses.when(
      loading: () => const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: ShimmerLoadingList(),
          ),
        ),
      ],
      error: (error, _) => [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: Text(error.toString())),
        ),
      ],
      data: _nurseListSlivers,
    );
  }

  List<Widget> _nurseListSlivers(List<NurseModel> items) {
    if (items.isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No verified nurses match your filters.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            const MarketplaceSectionTitle(title: 'Verified nurses'),
            const SizedBox(height: 8),
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(height: kDoctorCardSpacing),
              NurseListingCard(
                nurse: items[i],
                onTap: () => openNurseProfile(context, items[i]),
                onBookHomeVisit: () =>
                    openNurseHomeVisitBooking(context, items[i]),
                onOpenMapTap: nurseHasMapLocation(items[i])
                    ? () => openNurseInGoogleMaps(context, items[i])
                    : null,
              ),
            ],
            const UserScrollFooter(),
          ]),
        ),
      ),
    ];
  }

  List<Widget> _ambulanceResultSlivers(
    AsyncValue<List<AmbulanceModel>> asyncAmbulances,
  ) {
    return asyncAmbulances.when(
      loading: () => const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: ShimmerLoadingList(),
          ),
        ),
      ],
      error: (error, _) => [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: Text(error.toString())),
        ),
      ],
      data: _ambulanceListSlivers,
    );
  }

  List<Widget> _ambulanceListSlivers(List<AmbulanceModel> items) {
    if (items.isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No verified ambulance services match your filters.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            const MarketplaceSectionTitle(title: 'Verified ambulance services'),
            const SizedBox(height: 8),
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(height: kDoctorCardSpacing),
              AmbulanceListingCard(ambulance: items[i]),
            ],
            const UserScrollFooter(),
          ]),
        ),
      ),
    ];
  }

  List<Widget> _bloodBankResultSlivers(
    AsyncValue<List<BloodBankModel>> asyncBloodBanks,
  ) {
    return asyncBloodBanks.when(
      loading: () => const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: ShimmerLoadingList(),
          ),
        ),
      ],
      error: (error, _) => [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: Text(error.toString())),
        ),
      ],
      data: _bloodBankListSlivers,
    );
  }

  List<Widget> _bloodBankListSlivers(List<BloodBankModel> items) {
    if (items.isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No verified blood banks match your filters.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            const MarketplaceSectionTitle(title: 'Verified blood banks'),
            const SizedBox(height: 8),
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(height: kDoctorCardSpacing),
              BloodBankListingCard(
                bloodBank: items[i],
                onTap: () => context.push(
                  '${AppConstants.routeBloodBankDetail}/${items[i].id}',
                ),
                onOrder: () => context.push(
                  '${AppConstants.routeBloodBankDetail}/${items[i].id}',
                ),
              ),
            ],
            const UserScrollFooter(),
          ]),
        ),
      ),
    ];
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: InteractiveStyles.filterCard(
            context,
            selected: selected,
            radius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? AppColors.primaryDark
                      : InteractiveStyles.onSurface(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
