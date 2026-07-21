import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_text_styles.dart';
import 'full_screen_image_viewer.dart';

/// Gradient hero header for doctor/nurse profile pages.
class ProviderProfileHero extends StatelessWidget {
  const ProviderProfileHero({
    super.key,
    required this.name,
    this.subtitle,
    this.imageUrl,
    this.placeholderIcon = Icons.medical_services_rounded,
    this.gradientColors = AppColors.gradientHero,
    this.badges = const [],
    this.avatarOverlay,
    this.avatarBorder,
    this.trailing,
    this.avatarSize = 96,
    this.openFullImageOnTap = true,
  });

  final String name;
  final String? subtitle;
  final String? imageUrl;
  final IconData placeholderIcon;
  final List<Color> gradientColors;
  final List<Widget> badges;
  final Widget? avatarOverlay;
  final Widget? avatarBorder;
  final Widget? trailing;
  final double avatarSize;
  final bool openFullImageOnTap;

  static const double avatarCornerRadius = 16;

  void _openFullImage(BuildContext context) {
    final url = imageUrl?.trim() ?? '';
    if (!openFullImageOnTap || url.isEmpty) return;
    showFullScreenNetworkImage(
      context,
      imageUrl: url,
      title: name,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppDecorations.borderRadiusXl,
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (trailing != null)
                Align(alignment: Alignment.topRight, child: trailing!),
              Center(
                child: GestureDetector(
                  onTap: hasImage ? () => _openFullImage(context) : null,
                  behavior: HitTestBehavior.opaque,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      avatarBorder ??
                          ProviderProfilePhoto(
                            imageUrl: hasImage ? imageUrl : null,
                            placeholderIcon: placeholderIcon,
                            accentColor: gradientColors.last,
                            size: avatarSize,
                            fit: BoxFit.contain,
                          ),
                      if (avatarOverlay != null) avatarOverlay!,
                      if (hasImage && openFullImageOnTap)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.16),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.fullscreen_rounded,
                              size: 14,
                              color: gradientColors.last,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                name,
                textAlign: TextAlign.center,
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.white.withValues(alpha: 0.92),
                  ),
                ),
              ],
              if (badges.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: badges,
                ),
              ],
            ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Square rounded profile photo used on doctor / nurse / patient profile heroes.
class ProviderProfilePhoto extends StatelessWidget {
  const ProviderProfilePhoto({
    super.key,
    this.imageUrl,
    this.placeholderIcon = Icons.person_rounded,
    this.accentColor = AppColors.primary,
    this.size = 96,
    this.borderColor,
    this.borderWidth = 3,
    this.fit = BoxFit.cover,
  });

  final String? imageUrl;
  final IconData placeholderIcon;
  final Color accentColor;
  final double size;
  final Color? borderColor;
  final double borderWidth;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    final radius = ProviderProfileHero.avatarCornerRadius;

    return Container(
      width: size + borderWidth * 2 + 2,
      height: size + borderWidth * 2 + 2,
      padding: EdgeInsets.all(borderWidth > 0 ? 3 : 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius + 4),
        border: Border.all(
          color: borderColor ?? AppColors.white.withValues(alpha: 0.85),
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: ColoredBox(
          color: AppColors.white,
          child: hasImage
              ? CachedNetworkImage(
                  imageUrl: imageUrl!,
                  width: size,
                  height: size,
                  fit: fit,
                  alignment: Alignment.topCenter,
                  placeholder: (_, __) => _Placeholder(
                    icon: placeholderIcon,
                    color: accentColor,
                    size: size,
                  ),
                  errorWidget: (_, __, ___) => _Placeholder(
                    icon: placeholderIcon,
                    color: accentColor,
                    size: size,
                  ),
                )
              : _Placeholder(
                  icon: placeholderIcon,
                  color: accentColor,
                  size: size,
                ),
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({
    required this.icon,
    required this.color,
    required this.size,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Icon(icon, size: size * 0.5, color: color),
    );
  }
}

/// White info card with subtle shadow for profile details.
class ProviderInfoCard extends StatelessWidget {
  const ProviderInfoCard({
    super.key,
    required this.children,
    this.emptyMessage = 'No additional details provided.',
  });

  final List<Widget> children;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return _cardShell(
        child: Text(
          emptyMessage,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return _cardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 24),
            children[i],
          ],
        ],
      ),
    );
  }

  Widget _cardShell({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: AppDecorations.softShadow(opacity: 0.06),
      ),
      child: child,
    );
  }
}

/// Single info row with icon in a tinted circle.
class ProviderInfoRow extends StatelessWidget {
  const ProviderInfoRow({
    super.key,
    this.icon,
    required this.label,
    required this.value,
    this.iconColor,
  });

  final IconData? icon;
  final String label;
  final String value;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();

    final tint = iconColor ?? AppColors.primary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: tint),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Highlighted fee / service banner on profile pages.
class ProviderFeeBanner extends StatelessWidget {
  const ProviderFeeBanner({
    super.key,
    required this.title,
    required this.fee,
    this.subtitle,
    this.icon = Icons.currency_rupee_rounded,
    this.gradientColors = AppColors.gradientHero,
  });

  final String title;
  final int fee;
  final String? subtitle;
  final IconData icon;
  final List<Color> gradientColors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            gradientColors.first.withValues(alpha: 0.12),
            gradientColors.last.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: gradientColors.first.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradientColors),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            '₹$fee',
            style: AppTextStyles.titleMedium.copyWith(
              color: gradientColors.first,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

/// Service availability chips row.
class ProviderServiceChips extends StatelessWidget {
  const ProviderServiceChips({
    super.key,
    required this.services,
    this.accentColor = AppColors.primary,
  });

  final List<({String label, IconData icon, bool available})> services;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: services.map((s) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: s.available
                ? accentColor.withValues(alpha: 0.1)
                : AppColors.grey50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: s.available
                  ? accentColor.withValues(alpha: 0.3)
                  : AppColors.divider,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                s.icon,
                size: 16,
                color: s.available ? accentColor : AppColors.grey500,
              ),
              const SizedBox(width: 6),
              Text(
                s.label,
                style: AppTextStyles.labelSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: s.available ? accentColor : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Sticky bottom action bar for profile booking CTAs.
class ProviderStickyActionBar extends StatelessWidget {
  const ProviderStickyActionBar({
    super.key,
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(child: children[i]),
          ],
        ],
      ),
    );
  }
}
