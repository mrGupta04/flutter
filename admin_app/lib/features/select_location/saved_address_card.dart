import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_text_styles.dart';
import 'address_type_icon.dart';
import 'selected_location.dart';

class SavedAddressCard extends StatelessWidget {
  const SavedAddressCard({
    super.key,
    required this.address,
    this.distanceLabel,
    this.selected = false,
    this.onTap,
    this.onMore,
    this.onShare,
    this.onEdit,
  });

  final SavedPlaceModel address;
  final String? distanceLabel;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onMore;
  final VoidCallback? onShare;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: AppDecorations.borderRadiusLg,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppDecorations.borderRadiusLg,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          decoration: BoxDecoration(
            borderRadius: AppDecorations.borderRadiusLg,
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.grey200,
              width: selected ? 1.6 : 1,
            ),
            boxShadow: AppDecorations.softShadow(opacity: 0.04),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      AddressTypeIcon(label: address.label),
                      if (distanceLabel != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          distanceLabel!,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          address.label,
                          style: AppTextStyles.titleSmall.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          address.displayLine,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                        if (address.phone != null &&
                            address.phone!.trim().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Phone number: ${address.phone}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _RoundAction(
                    icon: Icons.more_horiz_rounded,
                    onTap: onMore,
                  ),
                  const SizedBox(width: 8),
                  _RoundAction(
                    icon: Icons.reply_rounded,
                    onTap: onShare,
                  ),
                  const SizedBox(width: 8),
                  _RoundAction(
                    icon: Icons.edit_outlined,
                    onTap: onEdit,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.grey100,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
      ),
    );
  }
}
