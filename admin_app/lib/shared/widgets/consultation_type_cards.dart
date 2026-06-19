import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/consultation_type.dart';

/// Three selectable cards for consultation type (demo option 1).
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
            child: _TypeCard(
              icon: Icons.video_call_rounded,
              title: 'Online Book',
              subtitle: 'Video consult',
              selected: selected == ConsultationType.onlineConsult,
              onTap: () => onSelected(ConsultationType.onlineConsult),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _TypeCard(
              icon: Icons.location_on_rounded,
              title: 'Visit',
              subtitle: 'Clinic location',
              selected: selected == ConsultationType.visitSite,
              onTap: () => onSelected(ConsultationType.visitSite),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _TypeCard(
              icon: Icons.home_rounded,
              title: 'Book Home',
              subtitle: 'Home visit',
              selected: selected == ConsultationType.bookHome,
              onTap: () => onSelected(ConsultationType.bookHome),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.divider,
          width: selected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Icon(
                icon,
                size: 28,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.labelSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.labelSmall.copyWith(
                  fontSize: 9,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
