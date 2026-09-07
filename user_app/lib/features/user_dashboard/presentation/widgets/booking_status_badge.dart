import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../data/booking_status_config.dart';

class BookingStatusBadge extends StatelessWidget {
  const BookingStatusBadge({super.key, required this.status});

  final BookingStatusView status;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Status ${status.label}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: status.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(status.icon, size: 14, color: status.color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                status.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelSmall.copyWith(
                  color: status.color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
