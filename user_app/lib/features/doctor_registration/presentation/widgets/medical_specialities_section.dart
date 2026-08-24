import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/accidental_selection_binder.dart';
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
    this.showHeader = true,
    this.showSearch = true,
    this.showEmptyState = true,
    this.expandAll = false,
    this.query,
    this.searchHint = 'Search doctor name or speciality...',
    this.onQueryChanged,
    this.title = 'Find Specialists',
    this.onViewAll,
  });

  final ValueChanged<MedicalSpeciality> onSpecialitySelected;
  final String? selectedSearchTerm;
  final EdgeInsetsGeometry padding;
  final bool showHeader;
  final bool showSearch;
  final bool showEmptyState;
  /// When true, every speciality is visible (used on the dedicated browse page).
  final bool expandAll;
  /// Optional external filter. When set, overrides the internal search box.
  final String? query;
  final String searchHint;
  final ValueChanged<String>? onQueryChanged;
  final String title;
  /// If set, "View all" navigates instead of expanding the compact grid.
  final VoidCallback? onViewAll;

  @override
  State<MedicalSpecialitiesSection> createState() =>
      _MedicalSpecialitiesSectionState();
}

class _MedicalSpecialitiesSectionState extends State<MedicalSpecialitiesSection> {
  bool _expanded = false;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int _previewCount(BuildContext context) {
    if (widget.expandAll || ResponsiveUtils.isLaptopOrUp(context)) {
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
    final activeQuery = widget.query ?? _query;
    final filtered = filterMedicalSpecialities(activeQuery);
    final previewCount = _previewCount(context);
    final searching = activeQuery.trim().isNotEmpty;
    final showAll =
        widget.expandAll || _expanded || searching || previewCount >= filtered.length;
    final visible = showAll
        ? filtered
        : filtered.take(previewCount).toList(growable: false);
    final canToggle = !widget.expandAll && !searching && filtered.length > previewCount;
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
          if (widget.showHeader) ...[
            Text(
              widget.title,
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
              '${medicalSpecialities.length} specialities available',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (widget.showSearch) ...[
            CaretOnTapTextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() => _query = value);
                widget.onQueryChanged?.call(value);
              },
              decoration: InputDecoration(
                hintText: widget.searchHint,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: activeQuery.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                          widget.onQueryChanged?.call('');
                        },
                      ),
                filled: true,
                fillColor: AppColors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          if (visible.isEmpty)
            if (widget.showEmptyState)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No speciality matches "$activeQuery".',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              )
            else
              const SizedBox.shrink()
          else
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
                remaining: filtered.length - previewCount,
                onTap: widget.onViewAll ??
                    () => setState(() => _expanded = !_expanded),
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
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: specialities.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: gap,
        crossAxisSpacing: gap,
        mainAxisExtent: 156,
      ),
      itemBuilder: (context, index) {
        final item = specialities[index];
        return SpecialityCard(
          speciality: item,
          selected: selectedSearchTerm != null &&
              selectedSearchTerm == item.searchTerm,
          onTap: () => onSpecialitySelected(item),
        );
      },
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
