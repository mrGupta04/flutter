import 'package:flutter/material.dart';
import '../../core/theme/interactive_styles.dart';
import '../../features/doctor_registration/provider/nurse_search_provider.dart';

class NurseCareFilterCards extends StatelessWidget {
  const NurseCareFilterCards({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final NurseCareFilter selected;
  final ValueChanged<NurseCareFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: NurseCareFilter.values.map((filter) {
          final isSelected = selected == filter;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: filter != NurseCareFilter.values.last ? 8 : 0,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onSelected(filter),
                  borderRadius: BorderRadius.circular(8),
                  child: Ink(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 6,
                    ),
                    decoration: InteractiveStyles.filterCard(
                      context,
                      selected: isSelected,
                    ),
                    child: Text(
                      filter.label,
                      textAlign: TextAlign.center,
                      style: InteractiveStyles.chipLabel(
                        context,
                        selected: isSelected,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
