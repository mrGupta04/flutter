import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/media_url_utils.dart';
import '../../../../data/models/patient_user_model.dart';

/// Profile avatar for the home header (top right).
class PatientHeaderAvatar extends StatelessWidget {
  const PatientHeaderAvatar({
    super.key,
    required this.user,
    this.size = 36,
  });

  final PatientUserModel user;
  final double size;

  @override
  Widget build(BuildContext context) {
    final imageUrl = MediaUrlUtils.resolve(user.profilePicture);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.85),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: imageUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => _InitialsBadge(
                  initials: user.initials,
                  size: size,
                ),
                errorWidget: (_, __, ___) => _InitialsBadge(
                  initials: user.initials,
                  size: size,
                ),
              )
            : _InitialsBadge(initials: user.initials, size: size),
      ),
    );
  }
}

class _InitialsBadge extends StatelessWidget {
  const _InitialsBadge({required this.initials, required this.size});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: AppTextStyles.labelMedium.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.38,
        ),
      ),
    );
  }
}
