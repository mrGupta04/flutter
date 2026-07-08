import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_text_styles.dart';

/// Tata 1mg home header — location + white search pill.
class OneMgHeader extends StatelessWidget {
  const OneMgHeader({
    super.key,
    this.locationLabel = 'Deliver to',
    this.locationValue = 'Your clinic location',
    this.searchHint = 'Search doctors, specialties...',
    this.trailing,
    this.onTrailingTap,
    this.onSearchTap,
  });

  final String locationLabel;
  final String locationValue;
  final String searchHint;
  final Widget? trailing;
  final VoidCallback? onTrailingTap;
  final VoidCallback? onSearchTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.gradientHero,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _OneMgLogo(),
                  const Spacer(),
                  if (trailing != null)
                    IconButton(
                      onPressed: onTrailingTap,
                      icon: trailing!,
                      style: IconButton.styleFrom(
                        foregroundColor: AppColors.white,
                        backgroundColor:
                            AppColors.white.withValues(alpha: 0.15),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    color: AppColors.white.withValues(alpha: 0.9),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          locationLabel,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.white.withValues(alpha: 0.85),
                          ),
                        ),
                        Text(
                          locationValue,
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.white.withValues(alpha: 0.9),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Material(
                color: AppColors.white,
                borderRadius: AppDecorations.borderRadiusMd,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onSearchTap,
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      boxShadow: AppDecorations.softShadow(opacity: 0.08),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search_rounded,
                          color: AppColors.grey400,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            searchHint,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.grey400,
                            ),
                          ),
                        ),
                        if (onSearchTap != null)
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: AppColors.grey400.withValues(alpha: 0.8),
                          ),
                      ],
                    ),
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

/// 1mg logo mark — green pill with "1mg" text.
class _OneMgLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '1mg',
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              height: 1,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Care',
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Quick actions row — partner onboarding shortcuts.
class OneMgQuickActions extends StatelessWidget {
  const OneMgQuickActions({
    super.key,
    this.onDoctorRegistration,
    this.onRegisterPractice,
  });

  final VoidCallback? onDoctorRegistration;
  final VoidCallback? onRegisterPractice;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _QuickAction(
              icon: Icons.medical_services_rounded,
              label: 'Doctor\nRegistration',
              color: AppColors.primary,
              onTap: onDoctorRegistration,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _QuickAction(
              icon: Icons.person_add_alt_1_rounded,
              label: 'Register\nPractice',
              color: AppColors.offer,
              onTap: onRegisterPractice,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: AppDecorations.borderRadiusMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppDecorations.borderRadiusMd,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: AppDecorations.borderRadiusMd,
            border: Border.all(color: AppColors.grey200),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum OneMgServiceCardStyle {
  standard,
  premium,
  asset,
}

class OneMgServiceFooterFeature {
  const OneMgServiceFooterFeature({
    required this.title,
    this.subtitle,
    required this.icon,
    this.iconColor,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Color? iconColor;
}

/// Service discovery card data for the home grid.
class OneMgServiceItem {
  const OneMgServiceItem({
    required this.title,
    this.description = '',
    this.imageUrl = '',
    this.color = AppColors.primary,
    this.onTap,
    this.style = OneMgServiceCardStyle.standard,
    this.icon,
    this.footerLeft,
    this.footerRight,
    this.footerFeatures,
    this.footerAccentTint = false,
    this.assetImage,
    this.assetAspectRatio,
  });

  final String title;
  final String description;
  final String imageUrl;
  final Color color;
  final VoidCallback? onTap;
  final OneMgServiceCardStyle style;
  final IconData? icon;
  final OneMgServiceFooterFeature? footerLeft;
  final OneMgServiceFooterFeature? footerRight;
  final List<OneMgServiceFooterFeature>? footerFeatures;
  final bool footerAccentTint;
  final String? assetImage;
  final double? assetAspectRatio;

  bool get isAssetCard => style == OneMgServiceCardStyle.asset;
  bool get isPremiumCard => style == OneMgServiceCardStyle.premium;
}

/// Modern 2-column service discovery grid (max 2 cards per row).
class OneMgServiceGrid extends StatelessWidget {
  const OneMgServiceGrid({
    super.key,
    required this.items,
    this.title = 'What are you looking for?',
    this.cardsPerRow = 2,
  });

  final List<OneMgServiceItem> items;
  final String title;
  final int cardsPerRow;

  @override
  Widget build(BuildContext context) {
    final perRow = cardsPerRow < 1 ? 1 : cardsPerRow;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          for (var row = 0; row < items.length; row += perRow) ...[
            if (row > 0) const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var col = 0; col < perRow; col++) ...[
                  if (col > 0) const SizedBox(width: 12),
                  Expanded(
                    child: row + col < items.length
                        ? _CareDiscoveryCard(item: items[row + col])
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CareDiscoveryCard extends StatelessWidget {
  const _CareDiscoveryCard({required this.item});

  final OneMgServiceItem item;

  @override
  Widget build(BuildContext context) {
    if (item.isAssetCard) {
      return _AssetServiceDiscoveryCard(item: item);
    }
    if (item.isPremiumCard) {
      return _PremiumServiceDiscoveryCard(item: item);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          height: 196,
          decoration: BoxDecoration(
            color: Color.alphaBlend(
              item.color.withValues(alpha: 0.07),
              const Color(0xFFF7F8FC),
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: item.color.withValues(alpha: 0.1),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Positioned(
                  right: -6,
                  bottom: 0,
                  width: 118,
                  height: 108,
                  child: _FeatheredCardImage(imageUrl: item.imageUrl),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: AppTextStyles.labelLarge.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          height: 1.2,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.description,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.35,
                          fontSize: 10.5,
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: item.color.withValues(alpha: 0.22),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.north_east_rounded,
                          size: 16,
                          color: item.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AssetServiceDiscoveryCard extends StatelessWidget {
  const _AssetServiceDiscoveryCard({required this.item});

  final OneMgServiceItem item;

  @override
  Widget build(BuildContext context) {
    final assetImage = item.assetImage;
    if (assetImage == null) {
      return const SizedBox.shrink();
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(22),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: AspectRatio(
            aspectRatio: item.assetAspectRatio ?? 1,
            child: Image.asset(
              assetImage,
              fit: BoxFit.cover,
              semanticLabel: item.title,
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumServiceDiscoveryCard extends StatelessWidget {
  const _PremiumServiceDiscoveryCard({required this.item});

  final OneMgServiceItem item;

  @override
  Widget build(BuildContext context) {
    final accent = item.color;
    final footerLeft = item.footerLeft;
    final footerRight = item.footerRight;
    final footerFeatures = item.footerFeatures;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          height: 232,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.grey100.withValues(alpha: 0.9)),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                Positioned(
                  top: 10,
                  right: 10,
                  child: _DecorativeDotGrid(color: AppColors.grey300),
                ),
                Positioned(
                  right: -12,
                  top: 34,
                  child: Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  right: -2,
                  bottom: 46,
                  width: 112,
                  height: 138,
                  child: CachedNetworkImage(
                    imageUrl: item.imageUrl,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    placeholder: (_, __) => Container(color: AppColors.grey100),
                    errorWidget: (_, __, ___) => Container(
                      color: AppColors.grey100,
                      child: Icon(
                        item.icon ?? Icons.medical_services_rounded,
                        color: accent,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(
                          item.icon ?? Icons.medical_services_rounded,
                          size: 19,
                          color: accent,
                        ),
                      ),
                      const SizedBox(height: 11),
                      Text(
                        item.title,
                        style: AppTextStyles.labelLarge.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          height: 1.12,
                          fontSize: 15.5,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.description,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.38,
                          fontSize: 10.5,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: AppColors.grey100,
                          ),
                        ),
                        child: Icon(
                          Icons.north_east_rounded,
                          size: 17,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                ),
                if (footerFeatures != null && footerFeatures.length >= 3)
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: item.footerAccentTint
                            ? accent.withValues(alpha: 0.09)
                            : AppColors.grey50,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          for (var i = 0; i < 3; i++) ...[
                            if (i > 0)
                              Container(
                                width: 1,
                                height: 22,
                                color: AppColors.divider,
                              ),
                            Expanded(
                              child: _ServiceCardCompactFooterFeature(
                                feature: footerFeatures[i],
                                accent: accent,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                else if (footerLeft != null && footerRight != null)
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 10,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: footerLeft.subtitle != null ? 8 : 9,
                      ),
                      decoration: BoxDecoration(
                        color: item.footerAccentTint
                            ? accent.withValues(alpha: 0.09)
                            : AppColors.grey50,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _ServiceCardFooterFeature(
                              feature: footerLeft,
                              accent: accent,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: footerLeft.subtitle != null ? 28 : 16,
                            color: AppColors.divider,
                          ),
                          Expanded(
                            child: _ServiceCardFooterFeature(
                              feature: footerRight,
                              accent: accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ServiceCardCompactFooterFeature extends StatelessWidget {
  const _ServiceCardCompactFooterFeature({
    required this.feature,
    required this.accent,
  });

  final OneMgServiceFooterFeature feature;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final iconColor = feature.iconColor ?? accent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(feature.icon, size: 12, color: iconColor),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              feature.title,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 7.8,
                height: 1.1,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceCardFooterFeature extends StatelessWidget {
  const _ServiceCardFooterFeature({
    required this.feature,
    required this.accent,
  });

  final OneMgServiceFooterFeature feature;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final iconColor = feature.iconColor ?? accent;

    if (feature.subtitle != null) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(feature.icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 9.8,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  feature.subtitle!,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 8.3,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(feature.icon, size: 14, color: iconColor),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            feature.title,
            style: AppTextStyles.labelSmall.copyWith(
              color: feature.iconColor == const Color(0xFFFFB300)
                  ? AppColors.textPrimary
                  : accent,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _DecorativeDotGrid extends StatelessWidget {
  const _DecorativeDotGrid({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        2,
        (_) => Row(
          children: List.generate(
            4,
            (_) => Container(
              width: 3,
              height: 3,
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatheredCardImage extends StatelessWidget {
  const _FeatheredCardImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) {
        return const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.transparent,
            Colors.black,
          ],
          stops: [0.08, 0.55],
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        height: 108,
        width: 118,
        placeholder: (_, __) => Container(
          color: AppColors.grey100,
        ),
        errorWidget: (_, __, ___) => Container(
          color: AppColors.grey100,
          child: const Icon(
            Icons.image_not_supported_outlined,
            color: AppColors.grey600,
            size: 20,
          ),
        ),
      ),
    );
  }
}

/// Dual quick-link row — 1mg style paired CTAs.
class OneMgDualCtaRow extends StatelessWidget {
  const OneMgDualCtaRow({
    super.key,
    required this.left,
    required this.right,
  });

  final OneMgDualCta left;
  final OneMgDualCta right;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: _DualCtaCard(cta: left)),
          const SizedBox(width: 10),
          Expanded(child: _DualCtaCard(cta: right)),
        ],
      ),
    );
  }
}

class OneMgDualCta {
  const OneMgDualCta({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
}

class _DualCtaCard extends StatelessWidget {
  const _DualCtaCard({required this.cta});

  final OneMgDualCta cta;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: AppDecorations.borderRadiusMd,
      child: InkWell(
        onTap: cta.onTap,
        borderRadius: AppDecorations.borderRadiusMd,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: AppDecorations.borderRadiusMd,
            border: Border.all(color: AppColors.grey200),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cta.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(cta.icon, color: cta.color, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cta.title,
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      cta.subtitle,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Category grid — 1mg health categories circles.
class OneMgCategoryGrid extends StatelessWidget {
  const OneMgCategoryGrid({super.key, this.onCategoryTap});

  final void Function(String label, String searchTerm)? onCategoryTap;

  static final _items = [
    (Icons.monitor_heart_outlined, 'Cardiology', const Color(0xFFE8F6F3)),
    (Icons.psychology_outlined, 'Mental', const Color(0xFFFFF0EE)),
    (Icons.child_care_outlined, 'Pediatric', const Color(0xFFE6F5ED)),
    (Icons.visibility_outlined, 'Eye Care', const Color(0xFFE8F1FD)),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: _items.map((item) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onCategoryTap != null
                      ? () => onCategoryTap!(item.$2, item.$2)
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: item.$3,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(item.$1, color: AppColors.primary, size: 26),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.$2,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// 1mg trust strip — Genuine · Fast · Secure
class OneMgTrustStrip extends StatelessWidget {
  const OneMgTrustStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: AppDecorations.borderRadiusMd,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _TrustItem(icon: Icons.verified_rounded, label: 'Genuine'),
          _TrustItem(icon: Icons.timer_outlined, label: '48hr verify'),
          _TrustItem(icon: Icons.lock_outline_rounded, label: 'Secure'),
        ],
      ),
    );
  }
}

class _TrustItem extends StatelessWidget {
  const _TrustItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Offer card — 1mg coral discount strip.
class OfferPromoCard extends StatelessWidget {
  const OfferPromoCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.badge = 'OFFER',
    this.icon = Icons.local_offer_rounded,
    this.includeMargin = true,
    this.compact = false,
  });

  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final bool includeMargin;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: includeMargin
          ? const EdgeInsets.symmetric(horizontal: 16)
          : EdgeInsets.zero,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 10 : 14,
      ),
      decoration: AppDecorations.offerStrip(),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 6 : 8,
              vertical: compact ? 2 : 4,
            ),
            decoration: BoxDecoration(
              color: AppColors.offer,
              borderRadius: AppDecorations.borderRadiusSm,
            ),
            child: Text(
              badge,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w800,
                fontSize: compact ? 9 : 10,
              ),
            ),
          ),
          SizedBox(width: compact ? 10 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: (compact
                          ? AppTextStyles.labelLarge
                          : AppTextStyles.titleSmall)
                      .copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: compact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!compact || subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: compact ? 11 : null,
                      height: compact ? 1.2 : null,
                    ),
                    maxLines: compact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Icon(icon, color: AppColors.offer, size: compact ? 18 : 22),
        ],
      ),
    );
  }
}

class ServiceBenefitCard extends StatelessWidget {
  const ServiceBenefitCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppDecorations.borderRadiusLg,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: AppDecorations.borderRadiusLg,
            border: Border.all(color: AppColors.grey200),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: AppDecorations.iconTile(color),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.grey400,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MarketplaceSectionTitle extends StatelessWidget {
  const MarketplaceSectionTitle({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel!,
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class BottomCtaBar extends StatelessWidget {
  const BottomCtaBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(top: false, child: child),
    );
  }
}

class FormStepHeader extends StatelessWidget {
  const FormStepHeader({
    super.key,
    required this.step,
    required this.total,
    required this.title,
    required this.subtitle,
  });

  final int step;
  final int total;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final progress = step / total;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppDecorations.borderRadiusLg,
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Step $step/$total',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).round()}%',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: AppDecorations.borderRadiusSm,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: AppColors.grey100,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: AppTextStyles.titleSmall.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            subtitle,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// Legacy alias
typedef HealthcareTopBar = OneMgHeader;
