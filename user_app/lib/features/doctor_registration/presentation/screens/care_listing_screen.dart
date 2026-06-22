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
import '../../../../shared/widgets/nurse_care_filter_cards.dart';
import 'nurse_profile_screen.dart';
import '../../../../shared/widgets/shimmer_widgets.dart';
import '../../../../shared/widgets/user_app_footer.dart';
import '../../provider/ambulance_search_provider.dart';
import '../../provider/blood_bank_search_provider.dart';
import '../../provider/care_filter_constants.dart';
import '../../provider/nurse_search_provider.dart';
import '../../provider/verified_doctors_provider.dart';
import '../../../../core/utils/doctor_location_utils.dart';
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
  const CareListingScreen({super.key, required this.initialRole});

  final CareRole initialRole;

  @override
  ConsumerState<CareListingScreen> createState() => _CareListingScreenState();
}

class _CareListingScreenState extends ConsumerState<CareListingScreen> {
  late CareRole _selectedRole;
  ConsultationType _doctorType = ConsultationType.onlineConsult;
  NurseCareFilter _nurseFilter = NurseCareFilter.all;
  String? _nurseCity;
  String? _nurseSpecialization;
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
    final asyncDoctors = ref.watch(verifiedDoctorsProvider);

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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ..._buildRoleHeader(showConsultationTypes: true),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(verifiedDoctorsProvider);
                await ref.read(verifiedDoctorsProvider.future);
              },
              child: asyncDoctors.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: ShimmerLoadingList(),
                ),
                error: (error, _) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(error.toString(), textAlign: TextAlign.center),
                    ),
                  ],
                ),
                data: (allDoctors) {
                  final filtered =
                      filterDoctorsByConsultation(allDoctors, _doctorType);
                  final items = filtered.isNotEmpty ? filtered : allDoctors;
                  return _buildDoctorList(items);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNurseScaffold(BuildContext context) {
    final params = NurseSearchParams(
      city: _nurseCity,
      specialization: _nurseSpecialization,
      careFilter: _nurseFilter,
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
      body: Column(
        children: [
          ..._buildRoleHeader(),
          NurseCareFilterCards(
            selected: _nurseFilter,
            onSelected: (f) => setState(() => _nurseFilter = f),
          ),
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
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(nurseSearchProvider(params));
                await ref.read(nurseSearchProvider(params).future);
              },
              child: asyncNurses.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: ShimmerLoadingList(),
                ),
                error: (error, _) => Center(child: Text(error.toString())),
                data: (items) => _buildNurseList(items),
              ),
            ),
          ),
        ],
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
      body: Column(
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
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(ambulanceSearchProvider(params));
                await ref.read(ambulanceSearchProvider(params).future);
              },
              child: asyncAmbulances.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: ShimmerLoadingList(),
                ),
                error: (error, _) => Center(child: Text(error.toString())),
                data: (items) => _buildAmbulanceList(items),
              ),
            ),
          ),
        ],
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
      body: Column(
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
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(bloodBankSearchProvider(params));
                await ref.read(bloodBankSearchProvider(params).future);
              },
              child: asyncBloodBanks.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: ShimmerLoadingList(),
                ),
                error: (error, _) => Center(child: Text(error.toString())),
                data: (items) => _buildBloodBankList(items),
              ),
            ),
          ),
        ],
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

  Widget _buildDoctorList(List<DoctorModel> items) {
    if (items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No verified doctors yet. Profiles appear here after admin approval.',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        const MarketplaceSectionTitle(title: 'Consult verified doctors'),
        const SizedBox(height: 8),
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: kDoctorCardSpacing),
          DoctorListingCard(
            doctor: items[i],
            showBottomDivider: false,
            showVerifiedIcon: true,
            showActionButtons: items[i].offersOnlineConsult ||
                items[i].offersVisitSite ||
                doctorHasMapLocation(items[i]),
            onTap: () => onDoctorCardTap(context, items[i]),
            onOnlineConsultTap: () =>
                openOnlineConsultBooking(context, items[i]),
            onClinicTap: () => openHospitalVisitBooking(context, items[i]),
            onOpenMapTap: () => openDoctorInGoogleMaps(context, items[i]),
          ),
        ],
        const UserScrollFooter(),
      ],
    );
  }

  Widget _buildNurseList(List<NurseModel> items) {
    if (items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No verified nurses match your filters.',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        const MarketplaceSectionTitle(title: 'Verified nurses'),
        const SizedBox(height: 8),
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: kDoctorCardSpacing),
          NurseListingCard(
            nurse: items[i],
            onTap: () => openNurseProfile(context, items[i]),
          ),
        ],
        const UserScrollFooter(),
      ],
    );
  }

  Widget _buildAmbulanceList(List<AmbulanceModel> items) {
    if (items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No verified ambulance services match your filters.',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        const MarketplaceSectionTitle(title: 'Verified ambulance services'),
        const SizedBox(height: 8),
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: kDoctorCardSpacing),
          AmbulanceListingCard(ambulance: items[i]),
        ],
        const UserScrollFooter(),
      ],
    );
  }

  Widget _buildBloodBankList(List<BloodBankModel> items) {
    if (items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No verified blood banks match your filters.',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        const MarketplaceSectionTitle(title: 'Verified blood banks'),
        const SizedBox(height: 8),
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: kDoctorCardSpacing),
          BloodBankListingCard(bloodBank: items[i]),
        ],
        const UserScrollFooter(),
      ],
    );
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
