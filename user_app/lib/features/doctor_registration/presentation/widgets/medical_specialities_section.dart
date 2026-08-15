import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../data/medical_specialities.dart';
import 'speciality_card.dart';

/// Responsive "Explore Medical Specialities" discovery grid.
class MedicalSpecialitiesSection extends StatefulWidget {
  const MedicalSpecialitiesSection({
    super.key,
    required this.onSpecialitySelected,
    this.selectedSearchTerm,
    this.padding = const EdgeInsets.fromLTRB(16, 4, 16, 16),
  });

  final ValueChanged<MedicalSpeciality> onSpecialitySelected;
  final String? selectedSearchTerm;
  final EdgeInsetsGeometry padding;

  @override
  State<MedicalSpecialitiesSection> createState() =>
      _MedicalSpecialitiesSectionState();
}

class _MedicalSpecialitiesSectionState extends State<MedicalSpecialitiesSection> {
  bool _expanded = false;

  int _previewCount(BuildContext context) {
    if (ResponsiveUtils.isLaptopOrUp(context)) {
      return medicalSpecialities.length;
    }
    if (ResponsiveUtils.isTabletOrUp(context)) {
      return kMedicalSpecialityPreviewCount;
    }
    return 8;
  }

  int _columns(BuildContext context) {
    final width = ResponsiveUtils.widthOf(context);
    if (width >= 1400) return 6;
    if (width >= 1100) return 5;
    if (width >= 840) return 4;
    if (width >= 600) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final previewCount = _previewCount(context);
    final showAll = _expanded || previewCount >= medicalSpecialities.length;
    final visible = showAll
        ? medicalSpecialities
        : medicalSpecialities.take(previewCount).toList(growable: false);
    final canToggle = medicalSpecialities.length > previewCount;
    final columns = _columns(context);
    final gap = ResponsiveUtils.valueFor(
      context,
      mobile: 10,
      tablet: 12,
      laptop: 14,
    );

    return Padding(
      padding: widget.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Explore Medical Specialities',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w800,
              fontSize: ResponsiveUtils.valueFor(
                context,
                mobile: 17,
                tablet: 18,
                desktop: 20,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Find the right doctor and healthcare specialist for your needs.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          _SpecialityGrid(
            specialities: visible,
            columns: columns,
            gap: gap,
            selectedSearchTerm: widget.selectedSearchTerm,
            onSpecialitySelected: widget.onSpecialitySelected,
          ),
          if (canToggle) ...[
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.center,
              child: _ViewAllButton(
                expanded: _expanded,
                remaining: medicalSpecialities.length - previewCount,
                onTap: () => setState(() => _expanded = !_expanded),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SpecialityGrid extends StatelessWidget {
  const _SpecialityGrid({
    required this.specialities,
    required this.columns,
    required this.gap,
    required this.onSpecialitySelected,
    this.selectedSearchTerm,
  });

  final List<MedicalSpeciality> specialities;
  final int columns;
  final double gap;
  final String? selectedSearchTerm;
  final ValueChanged<MedicalSpeciality> onSpecialitySelected;

  @override
  Widget build(BuildContext context) {
    final rowCount = (specialities.length / columns).ceil();

    return Column(
      children: [
        for (var row = 0; row < rowCount; row++) ...[
          if (row > 0) SizedBox(height: gap),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var col = 0; col < columns; col++) ...[
                  if (col > 0) SizedBox(width: gap),
                  Expanded(
                    child: colSlot(row, col),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget colSlot(int row, int col) {
    final index = row * columns + col;
    if (index >= specialities.length) {
      return const SizedBox.shrink();
    }
    final item = specialities[index];
    return SpecialityCard(
      speciality: item,
      selected: selectedSearchTerm != null &&
          selectedSearchTerm == item.searchTerm,
      onTap: () => onSpecialitySelected(item),
    );
  }
}

class _ViewAllButton extends StatelessWidget {
  const _ViewAllButton({
    required this.expanded,
    required this.remaining,
    required this.onTap,
  });

  final bool expanded;
  final int remaining;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        mouseCursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                expanded ? 'Show less' : 'View all specialities',
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              if (!expanded) ...[
                const SizedBox(width: 4),
                Text(
                  '+$remaining',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
