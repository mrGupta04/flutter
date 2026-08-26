import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/media_url_utils.dart';
import 'full_screen_image_viewer.dart';

/// Top-right profile avatar for signed-in healthcare partners.
class ProviderHeaderAvatar extends StatelessWidget {
  const ProviderHeaderAvatar({
    super.key,
    this.profilePictureUrl,
    this.displayName,
    this.onTap,
    this.size = 40,
  });

  final String? profilePictureUrl;
  final String? displayName;
  final VoidCallback? onTap;
  final double size;

  bool get _hasNetworkImage =>
      MediaUrlUtils.resolve(profilePictureUrl).isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(displayName);

    return Material(
      color: AppColors.white.withValues(alpha: 0.2),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _hasNetworkImage
            ? () => showFullScreenNetworkImage(
                  context,
                  imageUrl: MediaUrlUtils.resolve(profilePictureUrl),
                  title: displayName,
                )
            : onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: _hasNetworkImage
              ? DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: 0.85),
                      width: 2,
                    ),
                    image: DecorationImage(
                      image: NetworkImage(MediaUrlUtils.resolve(profilePictureUrl)),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              : CircleAvatar(
                  radius: size / 2,
                  backgroundColor: AppColors.white,
                  foregroundColor: AppColors.primary,
                  child: initials != null
                      ? Text(
                          initials,
                          style: TextStyle(
                            fontSize: size * 0.34,
                            fontWeight: FontWeight.w800,
                          ),
                        )
                      : Icon(Icons.person_rounded, size: size * 0.55),
                ),
        ),
      ),
    );
  }

  String? _initials(String? name) {
    if (name == null || name.trim().isEmpty) return null;
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }
}
