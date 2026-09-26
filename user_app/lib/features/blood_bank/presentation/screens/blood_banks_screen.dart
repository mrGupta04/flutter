import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/user_location_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../../../features/select_location/select_location_navigation.dart';
import '../../../../features/select_location/selected_location.dart';
import '../../../../shared/widgets/healthcare_ui.dart';
import '../../data/blood_bank_catalog.dart';

class BloodBanksScreen extends ConsumerStatefulWidget {
  const BloodBanksScreen({super.key, this.initialBloodGroup});

  final String? initialBloodGroup;

  @override
  ConsumerState<BloodBanksScreen> createState() => _BloodBanksScreenState();
}

class _BloodBanksScreenState extends ConsumerState<BloodBanksScreen> {
  String? _bloodGroup;
  String? _componentId = 'packed_rbc';
  int _units = 1;
  int _radiusKm = 10;

  @override
  void initState() {
    super.initState();
    _bloodGroup = widget.initialBloodGroup;
  }

  Future<void> _changeLocation() async {
    final current = ref.read(userLocationProvider);
    final selected = await openSelectLocation(
      context,
      args: SelectLocationArgs(
        title: 'Select a location',
        autofocusSearch: true,
        initial: current.hasCoordinates ||
                (current.city != null && current.city!.trim().isNotEmpty)
            ? SelectedLocationResult(
                addressLine: current.displayPlaceCity ?? current.displayCity,
                city: current.city,
                latitude: current.latitude,
                longitude: current.longitude,
              )
            : null,
      ),
    );
    if (selected == null || !mounted) return;
    await ref.read(userLocationProvider.notifier).applySelected(
          addressLine: selected.addressLine,
          city: selected.city,
          label: selected.label,
          latitude: selected.latitude,
          longitude: selected.longitude,
        );
  }

  void _search() {
    final location = ref.read(userLocationProvider);
    final params = <String, String>{
      if (_bloodGroup != null) 'bloodGroup': _bloodGroup!,
      if (_componentId != null) 'componentType': _componentId!,
      'units': '$_units',
      'radiusKm': '$_radiusKm',
      if (location.city != null && location.city!.isNotEmpty) 'city': location.city!,
    };
    context.push(
      '${AppConstants.routeBloodBankSearch}?${Uri(queryParameters: params).query}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(userLocationProvider);
    final place = location.displayPlaceCity ?? location.displayCity;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.headerGreen,
            foregroundColor: AppColors.white,
            titleSpacing: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Blood Bank',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                GestureDetector(
                  onTap: _changeLocation,
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: AppColors.white),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          place.isEmpty ? 'Select location' : place,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.white.withValues(alpha: 0.92),
                          ),
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.white),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              const NotificationBellButton(iconColor: AppColors.white),
              IconButton(
                tooltip: 'Search',
                icon: const Icon(Icons.search_rounded),
                onPressed: () => context.push(AppConstants.routeBloodBankSearch),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _EmergencyCard(
                    onTap: () => context.push(AppConstants.routeEmergencyBloodRequest),
                  ),
                  const SizedBox(height: 16),
                  _SearchCard(
                    bloodGroup: _bloodGroup,
                    componentId: _componentId,
                    units: _units,
                    radiusKm: _radiusKm,
                    onBloodGroup: (v) => setState(() => _bloodGroup = v),
                    onComponent: (v) => setState(() => _componentId = v),
                    onUnits: (v) => setState(() => _units = v),
                    onRadius: (v) => setState(() => _radiusKm = v),
                    onSearch: _search,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickTile(
                          title: 'My Requests',
                          subtitle: 'Track reservations',
                          icon: Icons.assignment_outlined,
                          onTap: () => context.push(AppConstants.routeMyBloodRequests),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _QuickTile(
                          title: 'Donate Blood',
                          subtitle: 'Camps & slots',
                          icon: Icons.volunteer_activism_outlined,
                          onTap: () => context.push(AppConstants.routeBloodDonationCamps),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _QuickTile(
                    title: 'My Blood Profile',
                    subtitle: 'Group, donations and emergency contact',
                    icon: Icons.badge_outlined,
                    onTap: () => context.push(AppConstants.routeBloodDonorProfile),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'This app helps you find published availability. '
                    'Final compatibility, eligibility and issue decisions stay with the blood bank.',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyCard extends StatelessWidget {
  const _EmergencyCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFB71C1C),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.emergency_rounded, color: AppColors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Emergency Blood',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Contact the hospital or blood bank directly. Availability is not guaranteed.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchCard extends StatelessWidget {
  const _SearchCard({
    required this.bloodGroup,
    required this.componentId,
    required this.units,
    required this.radiusKm,
    required this.onBloodGroup,
    required this.onComponent,
    required this.onUnits,
    required this.onRadius,
    required this.onSearch,
  });

  final String? bloodGroup;
  final String? componentId;
  final int units;
  final int radiusKm;
  final ValueChanged<String> onBloodGroup;
  final ValueChanged<String> onComponent;
  final ValueChanged<int> onUnits;
  final ValueChanged<int> onRadius;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Find Blood Near You',
            style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Text('Blood group', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kBloodGroups.map((group) {
              final selected = bloodGroup == group;
              return ChoiceChip(
                label: Text(group, style: const TextStyle(fontWeight: FontWeight.w800)),
                selected: selected,
                onSelected: (_) => onBloodGroup(group),
                selectedColor: AppColors.primaryLight,
                labelStyle: TextStyle(
                  color: selected ? AppColors.primaryDark : AppColors.textPrimary,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Text('Component', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: componentId,
            decoration: const InputDecoration(
              filled: true,
              fillColor: AppColors.grey50,
              border: OutlineInputBorder(),
            ),
            items: kBloodComponents
                .map(
                  (c) => DropdownMenuItem(
                    value: c['id'],
                    child: Text(c['name']!),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) onComponent(value);
            },
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Units', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        IconButton.outlined(
                          onPressed: units > 1 ? () => onUnits(units - 1) : null,
                          icon: const Icon(Icons.remove),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text('$units', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800)),
                        ),
                        IconButton.outlined(
                          onPressed: () => onUnits(units + 1),
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Radius', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      value: radiusKm,
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: AppColors.grey50,
                        border: OutlineInputBorder(),
                      ),
                      items: kBloodSearchRadiiKm
                          .map((km) => DropdownMenuItem(value: km, child: Text('$km km')))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) onRadius(value);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: onSearch,
              icon: const Icon(Icons.search_rounded),
              label: const Text('Search Availability'),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ServiceBenefitCard(
      title: title,
      subtitle: subtitle,
      icon: icon,
      color: AppColors.primary,
      onTap: onTap,
    );
  }
}
