import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/consultation_type.dart';

/// Filter chips for consultation type (demo option 3).
class ConsultationFilterBar extends StatelessWidget {
  const ConsultationFilterBar({
    super.key,
    required this.selected,
    required this.onSelected,
    this.showAllOption = true,
  });

  final ConsultationType? selected;
  final ValueChanged<ConsultationType?> onSelected;
  final bool showAllOption;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (showAllOption) ...[
            _FilterChip(
              label: 'All doctors',
              selected: selected == null,
              onTap: () => onSelected(null),
            ),
            const SizedBox(width: 8),
          ],
          for (final type in ConsultationType.values) ...[
            _FilterChip(
              label: type.label,
              icon: _iconFor(type),
              selected: selected == type,
              onTap: () => onSelected(type),
            ),
            if (type != ConsultationType.values.last)
              const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  IconData _iconFor(ConsultationType type) {
    switch (type) {
      case ConsultationType.onlineConsult:
        return Icons.video_call_rounded;
      case ConsultationType.bookHome:
        return Icons.home_rounded;
      case ConsultationType.visitSite:
        return Icons.local_hospital_rounded;
    }
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: selected ? AppColors.white : AppColors.primary,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: selected ? AppColors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary,
      checkmarkColor: AppColors.white,
      backgroundColor: AppColors.white,
      side: BorderSide(
        color: selected ? AppColors.primary : AppColors.divider,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
