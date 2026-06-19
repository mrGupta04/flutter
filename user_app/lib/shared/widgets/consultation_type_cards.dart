import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/consultation_type.dart';

/// Compact filter chips for consultation type (home & care screens).
class ConsultationTypeCards extends StatelessWidget {
  const ConsultationTypeCards({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final ConsultationType? selected;
  final ValueChanged<ConsultationType> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _TypeChip(
              icon: Icons.videocam_rounded,
              label: 'Online',
              selected: selected == ConsultationType.onlineConsult,
              onTap: () => onSelected(ConsultationType.onlineConsult),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _TypeChip(
              icon: Icons.local_hospital_rounded,
              label: 'Clinic',
              selected: selected == ConsultationType.visitSite,
              onTap: () => onSelected(ConsultationType.visitSite),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _TypeChip(
              icon: Icons.home_rounded,
              label: 'Home',
              selected: selected == ConsultationType.bookHome,
              onTap: () => onSelected(ConsultationType.bookHome),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.1)
                : surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.55)
                  : AppColors.divider,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelSmall.copyWith(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected
                        ? AppColors.primaryDark
                        : AppColors.textSecondary,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
