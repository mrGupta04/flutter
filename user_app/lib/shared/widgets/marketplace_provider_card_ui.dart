import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Golden specialty line (1mg-style doctor cards).
const Color kProviderSpecialtyGold = Color(0xFFC9922A);

/// Light mint stats strip behind satisfaction / consult counts.
const Color kProviderStatsBarBg = Color(0xFFE6F7EE);

/// Approximate height for home doctor preview rails.
const double kDoctorListingCardHeight = 248;

class MarketplaceCardShell extends StatelessWidget {
  const MarketplaceCardShell({
    super.key,
    required this.child,
    this.onTap,
    this.borderColor,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color? borderColor;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final card = Ink(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor ?? const Color(0xFFE8E8EC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );

    if (onTap == null) {
      return Material(color: Colors.transparent, child: card);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: card,
      ),
    );
  }
}

class MarketplaceProviderHeader extends StatelessWidget {
  const MarketplaceProviderHeader({
    super.key,
    required this.name,
    required this.avatar,
    this.specialty,
    this.metaLine,
    this.tags = const [],
    this.languagesLine,
    this.trailing,
    this.specialtyColor = kProviderSpecialtyGold,
    this.specialtyLogo,
  });

  final String name;
  final String? specialty;
  final String? metaLine;
  final List<String> tags;
  final String? languagesLine;
  final Widget avatar;
  final Widget? trailing;
  final Color specialtyColor;
  final Widget? specialtyLogo;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        avatar,
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1D26),
                              height: 1.2,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        if (specialtyLogo != null) ...[
                          const SizedBox(width: 6),
                          specialtyLogo!,
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 6),
                    trailing!,
                  ],
                ],
              ),
              if (specialty != null && specialty!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  specialty!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: kProviderSpecialtyGold,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ],
              if (metaLine != null && metaLine!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  metaLine!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                    height: 1.35,
                  ),
                ),
              ],
              if (tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                _ProviderTagRow(tags: tags),
              ],
              if (languagesLine != null && languagesLine!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  languagesLine!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF374151),
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ProviderTagRow extends StatelessWidget {
  const _ProviderTagRow({required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    const maxVisible = 2;
    final visible = tags.take(maxVisible).toList();
    final remaining = tags.length - visible.length;

    return Row(
      children: [
        for (var i = 0; i < visible.length; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Flexible(
            child: _ProviderTagChip(label: visible[i]),
          ),
        ],
        if (remaining > 0) ...[
          const SizedBox(width: 4),
          _ProviderTagChip(label: '+$remaining'),
        ],
      ],
    );
  }
}

class _ProviderTagChip extends StatelessWidget {
  const _ProviderTagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F8),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF374151),
          fontWeight: FontWeight.w600,
          fontSize: 9,
          height: 1.2,
        ),
      ),
    );
  }
}

class MarketplaceStatsBar extends StatelessWidget {
  const MarketplaceStatsBar({
    super.key,
    required this.leftIcon,
    required this.leftLabel,
    required this.rightIcon,
    required this.rightLabel,
    this.accentColor = AppColors.primary,
  });

  final IconData leftIcon;
  final String leftLabel;
  final IconData rightIcon;
  final String rightLabel;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: kProviderStatsBarBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              icon: leftIcon,
              label: leftLabel,
              color: AppColors.primaryDark,
            ),
          ),
          Expanded(
            child: _StatItem(
              icon: rightIcon,
              label: rightLabel,
              color: AppColors.primaryDark,
              alignEnd: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.color,
    this.alignEnd = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ),
      ],
    );

    if (alignEnd) {
      return Align(alignment: Alignment.centerRight, child: content);
    }
    return content;
  }
}

class MarketplacePriceActionRow extends StatelessWidget {
  const MarketplacePriceActionRow({
    super.key,
    this.price,
    this.originalPrice,
    this.buttonLabel = 'Select Slot',
    this.onButtonPressed,
    this.availabilityLabel,
    this.showButton = true,
    this.buttonEnabled = true,
    this.accentColor = AppColors.primary,
    this.adminButtonLabel,
    this.adminButtonSubtitle,
    this.onAdminPressed,
    this.useAdminButton = false,
    this.secondaryButtonLabel,
    this.onSecondaryPressed,
  });

  final int? price;
  final int? originalPrice;
  final String buttonLabel;
  final VoidCallback? onButtonPressed;
  final String? availabilityLabel;
  final bool showButton;
  final bool buttonEnabled;
  final Color accentColor;
  final String? adminButtonLabel;
  final String? adminButtonSubtitle;
  final VoidCallback? onAdminPressed;
  final bool useAdminButton;
  final String? secondaryButtonLabel;
  final VoidCallback? onSecondaryPressed;

  int? get _discountPercent {
    if (price == null || originalPrice == null || originalPrice! <= price!) {
      return null;
    }
    return (((originalPrice! - price!) / originalPrice!) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    if (useAdminButton) {
      return _AdminActionButton(
        label: adminButtonLabel ?? 'Review application',
        subtitle: adminButtonSubtitle ?? 'View profile & documents',
        onPressed: onAdminPressed,
        accentColor: accentColor,
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: price != null && price! > 0
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: _PriceBlock(
                    price: price!,
                    originalPrice: originalPrice,
                    discountPercent: _discountPercent,
                  ),
                )
              : const SizedBox.shrink(),
        ),
        if (secondaryButtonLabel != null &&
            secondaryButtonLabel!.trim().isNotEmpty) ...[
          const SizedBox(width: 8),
          _CompactCardButton(
            label: secondaryButtonLabel!,
            filled: false,
            accentColor: accentColor,
            onPressed: onSecondaryPressed,
          ),
        ],
        if (showButton) ...[
          const SizedBox(width: 8),
          SizedBox(
            width: secondaryButtonLabel != null ? 108 : 138,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _CompactCardButton(
                  label: buttonLabel,
                  filled: true,
                  accentColor: accentColor,
                  enabled: buttonEnabled,
                  onPressed: onButtonPressed,
                  expand: true,
                  height: secondaryButtonLabel != null ? 36 : 42,
                ),
                if (availabilityLabel != null &&
                    availabilityLabel!.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    availabilityLabel!,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _CompactCardButton extends StatelessWidget {
  const _CompactCardButton({
    required this.label,
    required this.filled,
    required this.accentColor,
    this.onPressed,
    this.enabled = true,
    this.expand = false,
    this.height = 36,
  });

  final String label;
  final bool filled;
  final Color accentColor;
  final VoidCallback? onPressed;
  final bool enabled;
  final bool expand;
  final double height;

  @override
  Widget build(BuildContext context) {
    final child = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: filled ? AppColors.white : accentColor,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
    );

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    );
    final style = filled
        ? FilledButton.styleFrom(
            backgroundColor: accentColor,
            disabledBackgroundColor: AppColors.grey200,
            foregroundColor: AppColors.white,
            shape: shape,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            minimumSize: Size(0, height),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            elevation: 0,
          )
        : OutlinedButton.styleFrom(
            foregroundColor: accentColor,
            side: BorderSide(color: accentColor.withValues(alpha: 0.55)),
            backgroundColor: AppColors.white,
            shape: shape,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            minimumSize: Size(0, height),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          );

    final button = filled
        ? FilledButton(
            onPressed: enabled ? onPressed : null,
            style: style,
            child: child,
          )
        : OutlinedButton(
            onPressed: enabled ? onPressed : null,
            style: style,
            child: child,
          );

    if (!expand) {
      return SizedBox(height: height, child: button);
    }
    return SizedBox(
      width: double.infinity,
      height: height,
      child: button,
    );
  }
}

class _PriceBlock extends StatelessWidget {
  const _PriceBlock({
    required this.price,
    this.originalPrice,
    this.discountPercent,
  });

  final int price;
  final int? originalPrice;
  final int? discountPercent;

  @override
  Widget build(BuildContext context) {
    final showOriginal =
        originalPrice != null && originalPrice! > price;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showOriginal)
          Text(
            '₹$originalPrice',
            textAlign: TextAlign.left,
            style: const TextStyle(
              color: Color(0xFF9AA3AF),
              decoration: TextDecoration.lineThrough,
              decorationColor: Color(0xFF9AA3AF),
              fontWeight: FontWeight.w600,
              fontSize: 13,
              height: 1.2,
            ),
          ),
        Text(
          '₹$price',
          textAlign: TextAlign.left,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1D26),
            height: 1.15,
          ),
        ),
        if (showOriginal && discountPercent != null)
          Text(
            '$discountPercent% off',
            textAlign: TextAlign.left,
            style: const TextStyle(
              color: AppColors.offer,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              height: 1.2,
            ),
          ),
      ],
    );
  }
}

class _AdminActionButton extends StatelessWidget {
  const _AdminActionButton({
    required this.label,
    required this.subtitle,
    this.onPressed,
    required this.accentColor,
  });

  final String label;
  final String subtitle;
  final VoidCallback? onPressed;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              subtitle,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.white.withValues(alpha: 0.9),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MarketplaceSquareAvatar extends StatelessWidget {
  const MarketplaceSquareAvatar({
    super.key,
    required this.child,
    this.size = 96,
    this.borderColor = const Color(0xFFE4E7EC),
    this.borderRadius = 12,
  });

  final Widget child;
  final double size;
  final Color borderColor;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
