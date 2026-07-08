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
                    onTrailingTap != null
                        ? IconButton(
                            onPressed: onTrailingTap,
                            icon: trailing!,
                            style: IconButton.styleFrom(
                              foregroundColor: AppColors.white,
                              backgroundColor:
                                  AppColors.white.withValues(alpha: 0.15),
                            ),
                          )
                        : trailing!,
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
          'Doctors',
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
    this.onNurseRegistration,
    this.onRegisterPractice,
  });

  final VoidCallback? onDoctorRegistration;
  final VoidCallback? onNurseRegistration;
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
              icon: Icons.health_and_safety_rounded,
              label: 'Nurse\nRegistration',
              color: AppColors.secondary,
              onTap: onNurseRegistration,
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
  });

  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.offerStrip(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.offer,
              borderRadius: AppDecorations.borderRadiusSm,
            ),
            child: Text(
              badge,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w800,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
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
          ),
          Icon(icon, color: AppColors.offer, size: 22),
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
          Text(title, style: AppTextStyles.titleSmall),
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

/// Compact row banner for application / verification status (provider app).
class ApplicationStatusHero extends StatelessWidget {
  const ApplicationStatusHero({
    super.key,
    required this.isVerified,
    required this.isRejected,
  });

  final bool isVerified;
  final bool isRejected;

  @override
  Widget build(BuildContext context) {
    final title = isVerified
        ? 'Verified'
        : isRejected
            ? 'Not approved'
            : 'Under review';
    final subtitle = isVerified
        ? 'Visible to patients in the app'
        : isRejected
            ? 'Contact support if you need help'
            : 'Usually reviewed within 24–48 hours';
    final icon = isVerified
        ? Icons.verified_rounded
        : isRejected
            ? Icons.cancel_outlined
            : Icons.hourglass_top_rounded;
    final colors = isVerified
        ? AppColors.gradientSuccess
        : isRejected
            ? [AppColors.error, AppColors.error.withValues(alpha: 0.88)]
            : [AppColors.primary, AppColors.primaryDark];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: AppDecorations.borderRadiusLg,
        boxShadow: AppDecorations.softShadow(opacity: 0.08),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.white, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.white.withValues(alpha: 0.92),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Legacy alias
typedef HealthcareTopBar = OneMgHeader;
