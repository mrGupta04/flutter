import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class BloodAvailabilityIndicator extends StatelessWidget {
  const BloodAvailabilityIndicator({
    super.key,
    required this.level,
    this.compact = false,
  });

  final String level;
  final bool compact;

  Color get _color {
    switch (level) {
      case 'high':
        return const Color(0xFF2E7D32);
      case 'medium':
        return const Color(0xFFF9A825);
      case 'low':
        return const Color(0xFFE65100);
      default:
        return const Color(0xFFC62828);
    }
  }

  String get _label {
    switch (level) {
      case 'high':
        return 'Available';
      case 'medium':
        return 'Limited';
      case 'low':
        return 'Low stock';
      default:
        return 'Unavailable';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 6 : 8,
            height: compact ? 6 : 8,
            decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
          ),
          if (!compact) ...[
            const SizedBox(width: 4),
            Text(
              _label,
              style: TextStyle(
                color: _color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class BloodGroupChip extends StatelessWidget {
  const BloodGroupChip({
    super.key,
    required this.group,
    this.availableUnits,
  });

  final String group;
  final int? availableUnits;

  @override
  Widget build(BuildContext context) {
    final level = availableUnits == null
        ? 'medium'
        : availableUnits! <= 0
            ? 'none'
            : availableUnits! <= 3
                ? 'low'
                : availableUnits! <= 10
                    ? 'medium'
                    : 'high';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            group,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          ),
          const SizedBox(width: 4),
          BloodAvailabilityIndicator(level: level, compact: true),
        ],
      ),
    );
  }
}
