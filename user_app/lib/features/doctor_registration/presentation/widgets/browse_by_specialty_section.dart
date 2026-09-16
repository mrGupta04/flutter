import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../labs/data/health_package_visuals.dart';
import '../../../../shared/widgets/healthcare_ui.dart';
import '../../data/medical_specialities.dart';

class SpecialtyBrowseItem {
  const SpecialtyBrowseItem({
    required this.organAsset,
    required this.label,
    required this.softColor,
    required this.accentColor,
    required this.searchTerm,
  });

  final String organAsset;
  final String label;
  final Color softColor;
  final Color accentColor;
  final String searchTerm;
}

const kBrowseSpecialties = <SpecialtyBrowseItem>[
  SpecialtyBrowseItem(
    organAsset: OrganAssets.heart,
    label: 'Cardiology',
    softColor: Color(0xFFFFEBEE),
    accentColor: Color(0xFFE53935),
    searchTerm: 'Cardiology',
  ),
  SpecialtyBrowseItem(
    organAsset: OrganAssets.skin,
    label: 'Dermatology',
    softColor: Color(0xFFE8EAF6),
    accentColor: Color(0xFF5C6BC0),
    searchTerm: 'Dermatology',
  ),
  SpecialtyBrowseItem(
    organAsset: OrganAssets.spine,
    label: 'Neurology',
    softColor: Color(0xFFEDE7F6),
    accentColor: Color(0xFF7E57C2),
    searchTerm: 'Neurology',
  ),
  SpecialtyBrowseItem(
    organAsset: OrganAssets.bone,
    label: 'Orthopedics',
    softColor: Color(0xFFFFF8E1),
    accentColor: Color(0xFFFB8C00),
    searchTerm: 'Orthopedics',
  ),
  SpecialtyBrowseItem(
    organAsset: OrganAssets.vitamin,
    label: 'Pediatrics',
    softColor: Color(0xFFE8F5E9),
    accentColor: Color(0xFF43A047),
    searchTerm: 'Pediatrics',
  ),
  SpecialtyBrowseItem(
    organAsset: OrganAssets.pregnancy,
    label: 'Gynecology',
    softColor: Color(0xFFFCE4EC),
    accentColor: Color(0xFFEC407A),
    searchTerm: 'Gynecology & Obstetrics',
  ),
  SpecialtyBrowseItem(
    organAsset: OrganAssets.ear,
    label: 'ENT',
    softColor: Color(0xFFFFF8E1),
    accentColor: Color(0xFFF9A825),
    searchTerm: 'ENT (Otolaryngology)',
  ),
  SpecialtyBrowseItem(
    organAsset: OrganAssets.eye,
    label: 'Ophthalmology',
    softColor: Color(0xFFE3F2FD),
    accentColor: Color(0xFF1E88E5),
    searchTerm: 'Ophthalmology',
  ),
  SpecialtyBrowseItem(
    organAsset: OrganAssets.tooth,
    label: 'Dentistry',
    softColor: Color(0xFFE0F7FA),
    accentColor: Color(0xFF00ACC1),
    searchTerm: 'Dentistry',
  ),
];

class BrowseBySpecialtySection extends StatelessWidget {
  const BrowseBySpecialtySection({
    super.key,
    required this.onSpecialtySelected,
    this.onViewAll,
    this.selectedSearchTerm,
    this.titlePadding = const EdgeInsets.fromLTRB(16, 12, 16, 10),
  });

  final ValueChanged<SpecialtyBrowseItem> onSpecialtySelected;
  final VoidCallback? onViewAll;
  final String? selectedSearchTerm;
  final EdgeInsetsGeometry titlePadding;

  bool _isSelected(SpecialtyBrowseItem item) {
    final selected = selectedSearchTerm?.trim();
    if (selected == null || selected.isEmpty) return false;
    final selectedTerm =
        (resolveSpecialitySearchTerm(selected) ?? selected).toLowerCase();
    final itemTerm =
        (resolveSpecialitySearchTerm(item.searchTerm) ?? item.searchTerm)
            .toLowerCase();
    return selectedTerm == itemTerm ||
        selected.toLowerCase() == item.searchTerm.toLowerCase() ||
        selected.toLowerCase() == item.label.toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MarketplaceSectionTitle(
          title: 'Browse by Specialty',
          actionLabel: onViewAll == null ? null : 'View all',
          onAction: onViewAll,
          padding: titlePadding,
        ),
        SizedBox(
          height: 108,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: kBrowseSpecialties.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = kBrowseSpecialties[index];
              return _SpecialtyChip(
                item: item,
                selected: _isSelected(item),
                onTap: () => onSpecialtySelected(item),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SpecialtyChip extends StatelessWidget {
  const _SpecialtyChip({
    required this.item,
    required this.onTap,
    this.selected = false,
  });

  final SpecialtyBrowseItem item;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final isSvg = item.organAsset.toLowerCase().endsWith('.svg');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 76,
          child: Column(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: item.softColor,
                  border: Border.all(
                    color: selected
                        ? item.accentColor
                        : item.accentColor.withValues(alpha: 0.16),
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: isSvg
                      ? SvgPicture.asset(
                          item.organAsset,
                          fit: BoxFit.contain,
                          colorFilter: ColorFilter.mode(
                            item.accentColor,
                            BlendMode.srcIn,
                          ),
                        )
                      : Image.asset(
                          item.organAsset,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.label,
                style: AppTextStyles.labelSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: selected ? item.accentColor : AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
