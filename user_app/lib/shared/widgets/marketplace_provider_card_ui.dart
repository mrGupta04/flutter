import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Golden specialty line (1mg-style doctor cards).
const Color kProviderSpecialtyGold = Color(0xFFC9922A);

/// Light mint stats strip behind satisfaction / consult counts.
const Color kProviderStatsBarBg = Color(0xFFE8F6F3);

class MarketplaceCardShell extends StatelessWidget {
  const MarketplaceCardShell({
    super.key,
    required this.child,
    this.onTap,
    this.borderColor,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor ?? AppColors.divider),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: child,
          ),
        ),
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
  });

  final String name;
  final String? specialty;
  final String? metaLine;
  final List<String> tags;
  final String? languagesLine;
  final Widget avatar;
  final Widget? trailing;
  final Color specialtyColor;

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
              if (specialty != null && specialty!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  specialty!,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: specialtyColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              if (metaLine != null && metaLine!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  metaLine!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.3,
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
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.3,
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

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final tag in visible) _ProviderTagChip(label: tag),
        if (remaining > 0) _ProviderTagChip(label: '+$remaining more'),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2F7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 11,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: kProviderStatsBarBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accentColor.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(icon: leftIcon, label: leftLabel, color: accentColor),
          ),
          Expanded(
            child: _StatItem(
              icon: rightIcon,
              label: rightLabel,
              color: accentColor,
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
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
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
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: price != null && price! > 0
              ? _PriceBlock(
                  price: price!,
                  originalPrice: originalPrice,
                  discountPercent: _discountPercent,
                )
              : const SizedBox.shrink(),
        ),
        if (showButton) ...[
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(
                width: 132,
                height: 40,
                child: FilledButton(
                  onPressed: buttonEnabled ? onButtonPressed : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: accentColor,
                    disabledBackgroundColor: AppColors.grey200,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: Text(
                    buttonLabel,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              if (availabilityLabel != null &&
                  availabilityLabel!.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  availabilityLabel!,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ],
          ),
        ],
      ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (discountPercent != null && originalPrice != null) ...[
          Row(
            children: [
              Text(
                '₹$originalPrice',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: AppColors.textTertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$discountPercent%',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.offer,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
        ],
        Text(
          '₹$price',
          style: AppTextStyles.headlineSmall.copyWith(
            fontWeight: FontWeight.w800,
            height: 1,
            letterSpacing: -0.5,
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
                fontSize: 10,
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
    this.size = 76,
    this.borderColor = AppColors.divider,
  });

  final Widget child;
  final double size;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
