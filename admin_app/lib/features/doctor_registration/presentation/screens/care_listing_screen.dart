import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/consultation_type.dart';
import '../../../../data/models/doctor_model.dart';
import '../../../../data/models/nurse_model.dart';
import '../../../../shared/widgets/consultation_type_cards.dart';
import '../../../../shared/widgets/doctor_listing_card.dart';
import '../../../../shared/widgets/healthcare_ui.dart';
import '../../../../shared/widgets/shimmer_widgets.dart';
import '../../provider/verified_doctors_provider.dart';
import '../../../nurse_registration/provider/verified_nurses_provider.dart';

enum CareRole { doctor, nurse }

CareRole careRoleFromValue(String? value) {
  switch (value) {
    case 'nurse':
      return CareRole.nurse;
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
  ConsultationType _selectedType = ConsultationType.onlineConsult;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole;
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedRole == CareRole.nurse) {
      return _buildNurseScaffold(context);
    }
    return _buildDoctorScaffold(context);
  }

  Widget _buildDoctorScaffold(BuildContext context) {
    final asyncDoctors = ref.watch(
      verifiedDoctorsByConsultationProvider(_selectedType),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Care providers'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ..._buildRoleHeader(),
          Expanded(
            child: asyncDoctors.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: ShimmerLoadingList(),
              ),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    error.toString(),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              data: (items) => _buildDoctorList(items),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNurseScaffold(BuildContext context) {
    final asyncNurses = ref.watch(verifiedNursesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Care providers'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ..._buildRoleHeader(showConsultationTypes: false),
          Expanded(
            child: asyncNurses.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: ShimmerLoadingList(),
              ),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    error.toString(),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              data: (items) => _buildNurseList(items),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRoleHeader({bool showConsultationTypes = true}) {
    return [
      const SizedBox(height: 12),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: _RoleCard(
                label: 'Doctor',
                icon: Icons.medical_services_rounded,
                selected: _selectedRole == CareRole.doctor,
                onTap: () => setState(() => _selectedRole = CareRole.doctor),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _RoleCard(
                label: 'Nurse',
                icon: Icons.health_and_safety_rounded,
                selected: _selectedRole == CareRole.nurse,
                onTap: () => setState(() => _selectedRole = CareRole.nurse),
              ),
            ),
          ],
        ),
      ),
      if (showConsultationTypes) ...[
        const SizedBox(height: 14),
        ConsultationTypeCards(
          selected: _selectedType,
          onSelected: (type) => setState(() => _selectedType = type),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Doctor • ${_selectedType.label}',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ] else ...[
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Verified nurses · admin approved only',
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No doctors available for ${_selectedType.label}.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView(
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
            showActionButtons: false,
          ),
        ],
      ],
    );
  }

  Widget _buildNurseList(List<NurseModel> items) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No verified nurses available yet.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        const MarketplaceSectionTitle(title: 'Verified nurses'),
        const SizedBox(height: 8),
        for (final nurse in items) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.secondary.withValues(alpha: 0.15),
                  child: const Icon(
                    Icons.health_and_safety_rounded,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nurse.firstName ?? 'Nurse',
                        style: AppTextStyles.labelLarge.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${nurse.qualification ?? ''} · ${nurse.city ?? ''}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.verified_rounded, color: AppColors.primary),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
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
      color: selected ? AppColors.primary.withValues(alpha: 0.10) : AppColors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.divider,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 24, color: AppColors.primary),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
