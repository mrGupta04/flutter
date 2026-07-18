import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/lab_browse_visuals.dart';
import '../../data/lab_catalog_metadata.dart';
import 'lab_organ_logos.dart';

/// Colorful browse card for health risks, conditions, and body organs.
class LabBrowseGroupCard extends StatelessWidget {
  const LabBrowseGroupCard({
    super.key,
    required this.group,
    required this.onTap,
    this.width = 128,
  });

  final LabBrowseGroup group;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    final visual = LabBrowseVisual.forGroup(group);

    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  visual.soft,
                  Color.lerp(visual.soft, Colors.white, 0.55)!,
                ],
              ),
              border: Border.all(
                color: visual.accent.withValues(alpha: 0.18),
              ),
              boxShadow: [
                BoxShadow(
                  color: visual.accent.withValues(alpha: 0.10),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LabBrowseLogo(group: group, size: 42),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Text(
                      group.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'From ₹${group.startingPriceInr}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: visual.deep,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Rounded color logo badge for a browse category.
class LabBrowseLogo extends StatelessWidget {
  const LabBrowseLogo({
    super.key,
    required this.group,
    this.size = 42,
  });

  final LabBrowseGroup group;
  final double size;

  @override
  Widget build(BuildContext context) {
    final visual = LabBrowseVisual.forGroup(group);
    final secondary = visual.secondary ?? visual.accent;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: size * 0.42,
              height: size * 0.42,
              decoration: BoxDecoration(
                color: secondary.withValues(alpha: 0.45),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size * 0.28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [visual.accent, visual.deep],
              ),
              boxShadow: [
                BoxShadow(
                  color: visual.accent.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: LabOrganLogoIcon(
                groupId: group.id,
                size: size * 0.55,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal carousel of colorful browse cards.
class LabBrowseGroupScroller extends StatelessWidget {
  const LabBrowseGroupScroller({
    super.key,
    required this.groups,
    required this.onTap,
    this.height = 138,
  });

  final List<LabBrowseGroup> groups;
  final ValueChanged<LabBrowseGroup> onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: groups.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final g = groups[index];
          return LabBrowseGroupCard(
            group: g,
            onTap: () => onTap(g),
          );
        },
      ),
    );
  }
}

/// Full-width list tile variant used on "See all" browse screens.
class LabBrowseGroupListTile extends StatelessWidget {
  const LabBrowseGroupListTile({
    super.key,
    required this.group,
    required this.onTap,
  });

  final LabBrowseGroup group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final visual = LabBrowseVisual.forGroup(group);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppDecorations.borderRadiusLg,
        border: Border.all(color: visual.accent.withValues(alpha: 0.16)),
        boxShadow: AppDecorations.softShadow(opacity: 0.04),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppDecorations.borderRadiusLg,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                LabBrowseLogo(group: group, size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: AppTextStyles.titleSmall.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${group.testCount} tests • From ₹${group.startingPriceInr}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: visual.deep,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: visual.accent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
