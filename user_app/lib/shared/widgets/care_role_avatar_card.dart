import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_text_styles.dart';

/// Circular avatar card for browsing care providers by role.
class CareRoleAvatarCard extends StatelessWidget {
  const CareRoleAvatarCard({
    super.key,
    required this.label,
    required this.imageUrl,
    required this.icon,
    required this.accentColor,
    required this.onTap,
    this.avatarSize = 68,
  });

  final String label;
  final String imageUrl;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;
  final double avatarSize;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: avatarSize + 8,
                    height: avatarSize + 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          accentColor,
                          accentColor.withValues(alpha: 0.55),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.28),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.white,
                            width: 2.5,
                          ),
                        ),
                        child: ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            width: avatarSize,
                            height: avatarSize,
                            placeholder: (_, __) => ColoredBox(
                              color: accentColor.withValues(alpha: 0.12),
                              child: Icon(
                                icon,
                                color: accentColor,
                                size: avatarSize * 0.38,
                              ),
                            ),
                            errorWidget: (_, __, ___) => ColoredBox(
                              color: accentColor.withValues(alpha: 0.12),
                              child: Icon(
                                icon,
                                color: accentColor,
                                size: avatarSize * 0.38,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: accentColor, width: 1.5),
                        boxShadow: AppDecorations.softShadow(opacity: 0.08),
                      ),
                      child: Icon(icon, size: 13, color: accentColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
