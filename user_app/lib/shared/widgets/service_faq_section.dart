import 'package:flutter/material.dart';

import '../../core/constants/service_faqs.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

const _faqAnimDuration = Duration(milliseconds: 280);
const _faqAnimCurve = Curves.easeInOutCubic;

/// Expandable FAQ block matching the nursing-care accordion style.
class ServiceFaqSection extends StatefulWidget {
  const ServiceFaqSection({
    super.key,
    required this.title,
    required this.items,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 16),
  });

  final String title;
  final List<ServiceFaqItem> items;
  final EdgeInsetsGeometry padding;

  static Widget sliver({
    required String title,
    required List<ServiceFaqItem> items,
    EdgeInsetsGeometry padding = const EdgeInsets.fromLTRB(16, 12, 16, 16),
  }) {
    return SliverToBoxAdapter(
      child: ServiceFaqSection(
        title: title,
        items: items,
        padding: padding,
      ),
    );
  }

  @override
  State<ServiceFaqSection> createState() => _ServiceFaqSectionState();
}

class _ServiceFaqSectionState extends State<ServiceFaqSection> {
  int? _openIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: widget.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < widget.items.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            FaqAccordionCard(
              item: widget.items[i],
              expanded: _openIndex == i,
              onTap: () => setState(() {
                _openIndex = _openIndex == i ? null : i;
              }),
              backgroundColor: AppColors.primaryLight,
              borderColor: AppColors.primary.withValues(alpha: 0.16),
              questionColor: AppColors.primaryDark,
              answerColor: AppColors.primaryDark.withValues(alpha: 0.82),
              iconColor: AppColors.primaryDark,
            ),
          ],
        ],
      ),
    );
  }
}

class FaqAccordionCard extends StatelessWidget {
  const FaqAccordionCard({
    super.key,
    required this.item,
    required this.expanded,
    required this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.questionColor,
    this.answerColor,
    this.iconColor,
    this.margin = EdgeInsets.zero,
  });

  final ServiceFaqItem item;
  final bool expanded;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? questionColor;
  final Color? answerColor;
  final Color? iconColor;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.white;
    final border = borderColor ?? AppColors.grey200;
    final qColor = questionColor ?? AppColors.textPrimary;
    final aColor = answerColor ?? AppColors.textSecondary;
    final chevronColor = iconColor ?? AppColors.textSecondary;

    return Padding(
      padding: margin,
      child: Material(
        color: bg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.question,
                        style: AppTextStyles.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: qColor,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: _faqAnimDuration,
                      curve: _faqAnimCurve,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: chevronColor,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                AnimatedSize(
                  duration: _faqAnimDuration,
                  curve: _faqAnimCurve,
                  alignment: Alignment.topCenter,
                  child: expanded
                      ? Padding(
                          padding: const EdgeInsets.only(top: 10, right: 6),
                          child: Text(
                            item.answer,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: aColor,
                              height: 1.5,
                            ),
                          ),
                        )
                      : const SizedBox(width: double.infinity),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
