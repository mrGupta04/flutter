import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class AddressTypeIcon extends StatelessWidget {
  const AddressTypeIcon({
    super.key,
    required this.label,
    this.size = 22,
    this.color,
  });

  final String label;
  final double size;
  final Color? color;

  static IconData iconFor(String label) {
    switch (label.trim().toLowerCase()) {
      case 'home':
        return Icons.home_outlined;
      case 'work':
      case 'office':
        return Icons.work_outline_rounded;
      default:
        return Icons.location_on_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Icon(
      iconFor(label),
      size: size,
      color: color ?? AppColors.primary,
    );
  }
}
