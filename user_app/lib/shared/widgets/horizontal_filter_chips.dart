import 'package:flutter/material.dart';
import 'care_filter_chip.dart';

/// Horizontally scrollable filter chips for city / specialty filters.
///
/// Tapping the selected chip again clears the filter (`onSelected(null)`).
class HorizontalFilterChips extends StatelessWidget {
  const HorizontalFilterChips({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelected,
    this.height = 40,
  });

  final List<String> labels;
  final String? selected;
  final ValueChanged<String?> onSelected;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: labels.map((label) {
          final isSelected = selected == label;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CareFilterChip(
              label: label,
              selected: isSelected,
              onTap: () => onSelected(isSelected ? null : label),
            ),
          );
        }).toList(),
      ),
    );
  }
}
