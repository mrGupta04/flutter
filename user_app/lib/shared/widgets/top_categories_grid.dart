import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Item for the marketplace-style Top Categories grid.
class TopCategoryItem {
  const TopCategoryItem({
    required this.title,
    required this.softColor,
    required this.accentColor,
    required this.illustration,
    required this.onTap,
    this.selected = false,
  });

  final String title;
  final Color softColor;
  final Color accentColor;
  final Widget illustration;
  final VoidCallback onTap;
  final bool selected;
}

/// 3-column pastel cards: title top-left, illustration bottom (1mg-style).
class TopCategoriesGrid extends StatelessWidget {
  const TopCategoriesGrid({
    super.key,
    required this.items,
    this.title = 'Top Categories',
    this.padding = EdgeInsets.zero,
  });

  final String title;
  final List<TopCategoryItem> items;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.92,
            ),
            itemBuilder: (context, index) =>
                _TopCategoryCard(item: items[index]),
          ),
        ],
      ),
    );
  }
}

class _TopCategoryCard extends StatelessWidget {
  const _TopCategoryCard({required this.item});

  final TopCategoryItem item;

  @override
  Widget build(BuildContext context) {
    final bottomSoft = Color.lerp(item.softColor, Colors.white, 0.55)!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [item.softColor, bottomSoft],
            ),
            border: Border.all(
              color: item.selected
                  ? item.accentColor
                  : item.accentColor.withValues(alpha: 0.14),
              width: item.selected ? 1.6 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: item.accentColor.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.15,
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 36,
                          decoration: BoxDecoration(
                            color: item.accentColor.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(40),
                          ),
                        ),
                        item.illustration,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
